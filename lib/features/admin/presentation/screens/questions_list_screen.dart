import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/question_models.dart';
import '../widgets/question_card.dart';
import '../widgets/filter_chip_widget.dart';
import 'questions_list_screen.dart';

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
  List<Question> _filteredQuestions = [];
  bool _isLoading = false;

  // Datos simulados
  final List<Question> _questions = [
    Question(
      id: '1',
      categoryId: 'math',
      type: QuestionType.multipleChoice,
      question: '¿Cuál es el resultado de 2 + 2?',
      options: ['3', '4', '5', '6'],
      correctAnswer: '4',
      timeLimit: 30,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      createdBy: 'admin1',
    ),
    Question(
      id: '2',
      categoryId: 'science',
      type: QuestionType.trueFalse,
      question: 'La Tierra es plana',
      options: ['Verdadero', 'Falso'],
      correctAnswer: 'Falso',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      createdBy: 'admin1',
    ),
    Question(
      id: '3',
      categoryId: 'history',
      type: QuestionType.freeText,
      question: '¿En qué año se descubrió América?',
      options: [],
      correctAnswer: '1492',
      timeLimit: 60,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      createdBy: 'admin1',
    ),
    Question(
      id: '4',
      categoryId: 'math',
      type: QuestionType.multipleChoice,
      question: '¿Cuál es la raíz cuadrada de 16?',
      options: ['2', '4', '6', '8'],
      correctAnswer: '4',
      timeLimit: 25,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
      createdBy: 'admin1',
    ),
    Question(
      id: '5',
      categoryId: 'science',
      type: QuestionType.trueFalse,
      question: 'El agua hierve a 100°C',
      options: ['Verdadero', 'Falso'],
      correctAnswer: 'Verdadero',
      timeLimit: 15,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      createdBy: 'admin1',
    ),
  ];

  final List<String> _categories = [
    'Todas',
    'Matemáticas',
    'Ciencias',
    'Historia'
  ];
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
    _filteredQuestions = _questions;
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

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterQuestions() {
    setState(() {
      _filteredQuestions = _questions.where((question) {
        // Filtro por búsqueda
        final searchMatch = _searchController.text.isEmpty ||
            question.question
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());

        // Filtro por categoría
        final categoryMatch = _selectedCategory == 'Todas' ||
            question.categoryId == _selectedCategory.toLowerCase();

        // Filtro por tipo
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
                // Filtros y búsqueda
                AnimationConfiguration.staggeredList(
                  position: 0,
                  duration: const Duration(milliseconds: 600),
                  child: SlideAnimation(
                    verticalOffset: -30.0,
                    child: FadeInAnimation(
                      child: _buildFiltersSection(),
                    ),
                  ),
                ),

                // Lista de preguntas
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
      floatingActionButton: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return ScaleTransition(
            scale: _fadeAnimation,
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context)
                    .pushNamed(AppConstants.createQuestionRoute);
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
          );
        },
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
          onPressed: () {
            setState(() {
              _isLoading = true;
            });
            // Simular recarga
            Future.delayed(const Duration(seconds: 1), () {
              setState(() {
                _isLoading = false;
              });
            });
          },
          icon: const Icon(Icons.refresh, color: AppTheme.white),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.white),
          color: AppTheme.lightBlack,
          onSelected: (value) {
            switch (value) {
              case 'export':
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Exportar próximamente'),
                    backgroundColor: AppTheme.info,
                  ),
                );
                break;
              case 'import':
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Importar próximamente'),
                    backgroundColor: AppTheme.info,
                  ),
                );
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, color: AppTheme.white),
                  SizedBox(width: 12),
                  Text('Exportar', style: TextStyle(color: AppTheme.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'import',
              child: Row(
                children: [
                  Icon(Icons.upload, color: AppTheme.white),
                  SizedBox(width: 12),
                  Text('Importar', style: TextStyle(color: AppTheme.white)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            onChanged: (value) => _filterQuestions(),
            style: const TextStyle(color: AppTheme.white),
            decoration: InputDecoration(
              hintText: 'Buscar preguntas...',
              hintStyle: const TextStyle(color: AppTheme.greyMedium),
              prefixIcon: const Icon(Icons.search, color: AppTheme.greyMedium),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _filterQuestions();
                      },
                      icon: const Icon(Icons.clear, color: AppTheme.greyMedium),
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.lightBlack,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Filtros por chips
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Categorías',
                      style: TextStyle(
                        color: AppTheme.greyLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _categories.map((category) {
                        return FilterChipWidget(
                          label: category,
                          isSelected: _selectedCategory == category,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                            _filterQuestions();
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipos',
                      style: TextStyle(
                        color: AppTheme.greyLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _types.map((type) {
                        return FilterChipWidget(
                          label: type,
                          isSelected: _selectedType == type,
                          onSelected: (selected) {
                            setState(() {
                              _selectedType = type;
                            });
                            _filterQuestions();
                          },
                        );
                      }).toList(),
                    ),
                  ],
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
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: QuestionCard(
                    question: _filteredQuestions[index],
                    onEdit: () {
                      Navigator.of(context).pushNamed(
                        AppConstants.editQuestionRoute,
                        arguments: _filteredQuestions[index].id,
                      );
                    },
                    onDelete: () {
                      _showDeleteDialog(_filteredQuestions[index]);
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.greyDark.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.quiz_outlined,
              size: 50,
              color: AppTheme.greyMedium,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No se encontraron preguntas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajusta los filtros o crea una nueva pregunta',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.greyLight,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(AppConstants.createQuestionRoute);
            },
            icon: const Icon(Icons.add),
            label: const Text('Crear Primera Pregunta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(color: AppTheme.greyLight),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.error.withOpacity(0.3)),
              ),
              child: Text(
                question.question,
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.greyLight),
            ),
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
