import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/question_models.dart';
import '../../auth/presentation/widgets/custom_text_field.dart';
import '../../auth/presentation/widgets/custom_button.dart';
import '../widgets/category_card.dart';

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

  void _loadCategories() {
    // Datos simulados
    _categories = [
      Category(
        id: 'math',
        name: 'Matemáticas',
        description: 'Álgebra, geometría, cálculo y más',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        createdBy: 'admin1',
      ),
      Category(
        id: 'science',
        name: 'Ciencias',
        description: 'Física, química, biología',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        createdBy: 'admin1',
      ),
      Category(
        id: 'history',
        name: 'Historia',
        description: 'Historia mundial y nacional',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        createdBy: 'admin1',
      ),
      Category(
        id: 'literature',
        name: 'Literatura',
        description: 'Literatura clásica y contemporánea',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        createdBy: 'admin1',
      ),
    ];
    _filteredCategories = List.from(_categories);
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
                // Búsqueda
                AnimationConfiguration.staggeredList(
                  position: 0,
                  duration: const Duration(milliseconds: 600),
                  child: SlideAnimation(
                    verticalOffset: -30.0,
                    child: FadeInAnimation(
                      child: _buildSearchSection(),
                    ),
                  ),
                ),

                // Lista de categorías
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
      floatingActionButton: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return ScaleTransition(
            scale: _fadeAnimation,
            child: FloatingActionButton.extended(
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
        },
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
            Future.delayed(const Duration(seconds: 1), () {
              setState(() {
                _isLoading = false;
              });
            });
          },
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
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _filterCategories();
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
    );
  }

  Widget _buildCategoriesList() {
    return AnimationLimiter(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: _filteredCategories.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 500),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: CategoryCard(
                  category: _filteredCategories[index],
                  onEdit: () => _showEditCategoryDialog(_filteredCategories[index]),
                  onDelete: () => _showDeleteCategoryDialog(_filteredCategories[index]),
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
              Icons.category_outlined,
              size: 50,
              color: AppTheme.greyMedium,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No se encontraron categorías',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera categoría para organizar las preguntas',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.greyLight,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showCreateCategoryDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Crear Primera Categoría'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateCategoryDialog() {
    _showCategoryDialog();
  }

  void _showEditCategoryDialog(Category category) {
    _showCategoryDialog(category: category);
  }

  void _showCategoryDialog({Category? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController = TextEditingController(text: category?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.category_outlined,
                color: AppTheme.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isEditing ? 'Editar Categoría' : 'Nueva Categoría',
              style: const TextStyle(color: AppTheme.white),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: nameController,
                label: 'Nombre de la categoría',
                hint: 'Ej: Matemáticas',
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: descriptionController,
                label: 'Descripción',
                hint: 'Breve descripción de la categoría',
                maxLines: 3,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'La descripción es obligatoria';
                  }
                  return null;
                },
              ),
            ],
          ),
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
              if (nameController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                if (isEditing) {
                  // Actualizar categoría existente
                  final index = _categories.indexWhere((c) => c.id == category!.id);
                  if (index != -1) {
                    _categories[index] = category!.copyWith(
                      name: nameController.text,
                      description: descriptionController.text,
                    );
                  }
                } else {
                  // Crear nueva categoría
                  final newCategory = Category(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    description: descriptionController.text,
                    createdAt: DateTime.now(),
                    createdBy: 'admin1',
                  );
                  _categories.add(newCategory);
                }

                setState(() {
                  _filterCategories();
                });

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEditing 
                        ? 'Categoría actualizada' 
                        : 'Categoría creada'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
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
        title: const Text(
          '¿Eliminar Categoría?',
          style: TextStyle(color: AppTheme.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta acción eliminará la categoría y TODAS las preguntas asociadas.',
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
              child: Row(
                children: [
                  const Icon(Icons.warning_outlined, color: AppTheme.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          category.description,
                          style: const TextStyle(
                            color: AppTheme.greyLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
              setState(() {
                _categories.removeWhere((c) => c.id == category.id);
                _filterCategories();
              });

              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Categoría eliminada'),
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