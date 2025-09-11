import 'package:carvajal_autotech/services/category_service.dart';
import 'package:carvajal_autotech/services/student_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/question_models.dart';
import '../widgets/category_card.dart';
import 'assign_students_screen.dart'; // Importar la pantalla para asignar estudiantes
import 'package:carvajal_autotech/widgets/custom_notification_bar.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  final CategoryService _categoryService = CategoryService(); // 👈 Servicio
  final StudentService _studentService =
      StudentService(); // Instancia del servicio

  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCategories();
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

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    final categories = await _categoryService.getAllCategories();

    setState(() {
      _categories = categories;
      _filteredCategories = categories;
      _isLoading = false;
    });
  }

  void _filterCategories() {
    setState(() {
      _filteredCategories = _categories.where((category) {
        return category.name.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
            category.description.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                );
      }).toList();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
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
                _buildSearchSection(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryRed,
                          ),
                        )
                      : _filteredCategories.isEmpty
                          ? _buildEmptyState()
                          : _buildCategoriesList(),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCategoryDialog(),
        backgroundColor: AppTheme.primaryRed,
        icon: const Icon(Icons.add, color: AppTheme.white),
        label: const Text(
          'Nueva Categoría',
          style: TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryBlack,
      title: const Text(
        'Categorías',
        style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600),
      ),
      actions: [
        IconButton(
          onPressed: _loadCategories,
          icon: const Icon(Icons.refresh, color: AppTheme.white),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => _filterCategories(),
        style: const TextStyle(color: AppTheme.white),
        decoration: InputDecoration(
          hintText: 'Buscar categorías...',
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
    );
  }

  Widget _buildCategoriesList() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredCategories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CategoryCard(
              category: _filteredCategories[index],
              onEdit: () => _showEditCategoryDialog(_filteredCategories[index]),
              onDelete: () =>
                  _showDeleteCategoryDialog(_filteredCategories[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No hay categorías',
        style: TextStyle(color: AppTheme.white),
      ),
    );
  }

  /// ----------- DIÁLOGOS -----------------

  void _showCreateCategoryDialog() {
    _showCategoryDialog();
  }

  void _showEditCategoryDialog(Category category) {
    _showCategoryDialog(category: category);
  }

  void _showCategoryDialog({Category? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController =
        TextEditingController(text: category?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightBlack,
        title: Text(isEditing ? 'Editar Categoría' : 'Nueva Categoría'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              const SizedBox(height: 16),
              if (isEditing) // Mostrar el botón solo al editar
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AssignStudentsScreen(
                          categoryId: category.id, // Eliminado el operador `!`
                        ),
                      ),
                    );

                    if (result == true) {
                      showCustomNotification(
                        context,
                        'Estudiantes asignados correctamente.',
                        isSuccess: true,
                      );
                    }
                  },
                  icon: const Icon(Icons.group_add),
                  label: const Text('Asignar Estudiantes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (isEditing) {
                await _categoryService.updateCategory(
                  categoryId: category.id,
                  name: nameController.text,
                  description: descriptionController.text,
                );
              } else {
                final userId =
                    Supabase.instance.client.auth.currentUser?.id ?? '';
                await _categoryService.createCategory(
                  name: nameController.text,
                  description: descriptionController.text,
                  createdBy: userId,
                );
              }

              Navigator.of(context).pop();
              _loadCategories(); // 👈 refresca lista

              showCustomNotification(
                context,
                isEditing ? 'Categoría actualizada.' : 'Categoría creada.',
                isSuccess: true,
              );
            },
            child: Text(isEditing ? 'Actualizar' : 'Crear'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightBlack,
        title: const Text('¿Eliminar Categoría?'),
        content: Text(
          'Esto eliminará la categoría y todas sus preguntas asociadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _categoryService.deleteCategory(category.id);
              Navigator.of(context).pop();
              _loadCategories();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
