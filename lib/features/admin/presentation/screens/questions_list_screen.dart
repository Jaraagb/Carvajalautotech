import 'package:carvajal_autotech/services/category_service.dart';
import 'package:carvajal_autotech/services/questions_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/question_models.dart';
import '../widgets/question_card.dart';
import '../widgets/filter_chip_widget.dart';

class QuestionsListScreen extends StatefulWidget {
  const QuestionsListScreen({Key? key}) : super(key: key);

  @override
  State<QuestionsListScreen> createState() => _QuestionsListScreenState();
}

class _QuestionsListScreenState extends State<QuestionsListScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Todas';
  String _selectedType = 'Todos';

  List<Question> _questions = [];
  List<Question> _filteredQuestions = [];
  List<Category> _categories = [];

  bool _isLoading = false;

  final QuestionsService _questionsService = QuestionsService();
  final CategoryService _categoryService = CategoryService();

  final List<String> _types = [
    'Todos',
    'Opción Múltiple',
    'Verdadero/Falso',
    'Texto Libre'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final questions = await _questionsService.getQuestions();
      final categories = await _categoryService.getAllCategories();

      setState(() {
        _questions = questions;
        _filteredQuestions = questions;
        _categories = categories;
      });
    } on PostgrestException catch (e) {
      debugPrint('❌ Error cargando datos (PG): ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando datos: ${e.message}'),
          backgroundColor: AppTheme.error,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error cargando datos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error inesperado cargando datos'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterQuestions() {
    setState(() {
      _filteredQuestions = _questions.where((question) {
        final searchMatch = _searchController.text.isEmpty ||
            question.question
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());

        final categoryMatch = _selectedCategory == 'Todas' ||
            _getCategoryName(question.categoryId) == _selectedCategory;

        final typeMatch = _selectedType == 'Todos' ||
            _getTypeLabel(question.type) == _selectedType;

        return searchMatch && categoryMatch && typeMatch;
      }).toList();
    });
  }

  String _getTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Opción Múltiple';
      case QuestionType.trueFalse:
        return 'Verdadero/Falso';
      case QuestionType.freeText:
        return 'Texto Libre';
    }
  }

  String _getCategoryName(String categoryId) {
    final cat = _categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => Category(
        id: categoryId,
        name: 'Desconocida',
        description: '',
        createdBy: '',
        createdAt: DateTime.now(),
        isActive: false,
      ),
    );
    return cat.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: _buildAppBar(),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildFiltersSection(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryRed,
                          ),
                        )
                      : _filteredQuestions.isEmpty
                          ? _buildEmptyState()
                          : _buildQuestionsList(),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fadeAnimation,
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).pushNamed(AppConstants.createQuestionRoute);
          },
          backgroundColor: AppTheme.primaryRed,
          icon: const Icon(Icons.add, color: AppTheme.white),
          label: const Text(
            'Nueva Pregunta',
            style: TextStyle(
              color: AppTheme.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryBlack,
      title: const Text(
        'Gestión de Preguntas',
        style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600),
      ),
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_ios, color: AppTheme.white),
      ),
      actions: [
        IconButton(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh, color: AppTheme.white),
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 🔎 Barra de búsqueda
          TextField(
            controller: _searchController,
            onChanged: (value) => _filterQuestions(),
            style: const TextStyle(color: AppTheme.white),
            decoration: InputDecoration(
              hintText: 'Buscar preguntas...',
              hintStyle: const TextStyle(color: AppTheme.greyMedium),
              prefixIcon: const Icon(Icons.search, color: AppTheme.greyMedium),
              filled: true,
              fillColor: AppTheme.lightBlack,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 📌 2 columnas: Categorías y Tipos
          Row(
            children: [
              // 👉 Columna categorías
              Expanded(
                child: Container(
                  height: 120, // 🔥 ajusta altura visible
                  padding: const EdgeInsets.only(right: 8),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView(
                      children: [
                        FilterChipWidget(
                          label: 'Todas',
                          isSelected: _selectedCategory == 'Todas',
                          onSelected: (selected) {
                            setState(() => _selectedCategory = 'Todas');
                            _filterQuestions();
                          },
                        ),
                        ..._categories.map((cat) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: FilterChipWidget(
                              label: cat.name,
                              isSelected: _selectedCategory == cat.name,
                              onSelected: (selected) {
                                setState(() => _selectedCategory = cat.name);
                                _filterQuestions();
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 👉 Columna tipos
              Expanded(
                child: Container(
                  height: 120, // 🔥 igual altura
                  padding: const EdgeInsets.only(left: 8),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView(
                      children: _types.map((type) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: FilterChipWidget(
                            label: type,
                            isSelected: _selectedType == type,
                            onSelected: (selected) {
                              setState(() {
                                _selectedType = type;
                              });
                              _filterQuestions();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsList() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredQuestions.length,
        itemBuilder: (context, index) {
          final question = _filteredQuestions[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: QuestionCard(
                    question: question,
                    onEdit: () {
                      Navigator.of(context).pushNamed(
                        AppConstants.editQuestionRoute,
                        arguments: _filteredQuestions[index]
                            .id, // 👈 ahora sí es un String
                      );
                    },
                    onDelete: () {
                      _showDeleteDialog(question);
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No se encontraron preguntas',
        style: TextStyle(color: AppTheme.white),
      ),
    );
  }

  void _showDeleteDialog(Question question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightBlack,
        title: const Text(
          '¿Eliminar Pregunta?',
          style: TextStyle(color: AppTheme.white),
        ),
        content: Text(
          question.question,
          style: const TextStyle(color: AppTheme.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.greyLight)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _questions.remove(question);
                _filterQuestions();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pregunta eliminada'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
