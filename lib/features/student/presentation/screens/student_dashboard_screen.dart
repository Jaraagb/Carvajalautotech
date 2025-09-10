import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/navigation/app_router.dart';
import '../widgets/student_stats_card.dart';
import '../widgets/category_quiz_card.dart';
import '../../../../core/models/question_models.dart';
import '../../../../services/category_service.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({Key? key}) : super(key: key);

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Servicio
  final CategoryService _categoryService = CategoryService();

  // Estado de categorías
  List<Category> _categories = [];
  bool _isLoadingCategories = true;
  String? _errorCategories;

  // Datos simulados del estudiante
  final Map<String, dynamic> _studentStats = {
    'totalAnswered': 45,
    'correctAnswers': 38,
    'incorrectAnswers': 7,
    'accuracyPercentage': 84.4,
    'streak': 5,
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchCategories();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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

  Future<void> _fetchCategories() async {
    try {
      final cats = await _categoryService.getActiveCategories();
      setState(() {
        _categories = cats;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _errorCategories = "Error cargando categorías";
        _isLoadingCategories = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AnimationLimiter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(),
                    const SizedBox(height: 24),
                    _buildStatsSection(),
                    const SizedBox(height: 32),
                    _buildCategoriesSection(),
                    const SizedBox(height: 32),
                    _buildRecentProgressSection(),
                  ],
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
      elevation: 0,
      title: const Text(
        'Mi Dashboard',
        style: TextStyle(
          color: AppTheme.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Perfil próximamente'),
                backgroundColor: AppTheme.info,
              ),
            );
          },
          icon: const CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.info,
            child: Icon(
              Icons.person,
              color: AppTheme.white,
              size: 18,
            ),
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.white),
          color: AppTheme.lightBlack,
          onSelected: (value) {
            switch (value) {
              case 'profile':
                // TODO: Ir a perfil
                break;
              case 'history':
                // TODO: Ver historial
                break;
              case 'logout':
                _showLogoutDialog();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: AppTheme.white),
                  SizedBox(width: 12),
                  Text('Mi Perfil', style: TextStyle(color: AppTheme.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'history',
              child: Row(
                children: [
                  Icon(Icons.history, color: AppTheme.white),
                  SizedBox(width: 12),
                  Text('Historial', style: TextStyle(color: AppTheme.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: AppTheme.error),
                  SizedBox(width: 12),
                  Text('Cerrar Sesión',
                      style: TextStyle(color: AppTheme.error)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.info, AppTheme.info.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.info.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: AppTheme.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '¡Hola, Juan!',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Continúa aprendiendo y mejorando',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.white.withOpacity(0.8),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: AppTheme.white, size: 16),
              const SizedBox(width: 4),
              Text(
                'Racha de ${_studentStats['streak']} días',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mis Estadísticas',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            StudentStatsCard(
              title: 'Total Respondidas',
              value: _studentStats['totalAnswered'].toString(),
              icon: Icons.quiz_outlined,
              color: AppTheme.info,
            ),
            StudentStatsCard(
              title: 'Correctas',
              value: _studentStats['correctAnswers'].toString(),
              icon: Icons.check_circle_outline,
              color: AppTheme.success,
            ),
            StudentStatsCard(
              title: 'Incorrectas',
              value: _studentStats['incorrectAnswers'].toString(),
              icon: Icons.cancel_outlined,
              color: AppTheme.error,
            ),
            StudentStatsCard(
              title: 'Precisión',
              value: '${_studentStats['accuracyPercentage']}%',
              icon: Icons.trending_up_outlined,
              color: AppTheme.warning,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Categorías Disponibles',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingCategories)
          const Center(
            child: CircularProgressIndicator(color: AppTheme.info),
          )
        else if (_errorCategories != null)
          Text(
            _errorCategories!,
            style: const TextStyle(color: AppTheme.error),
          )
        else if (_categories.isEmpty)
          const Text(
            "No hay categorías disponibles",
            style: TextStyle(color: AppTheme.greyLight),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: CategoryQuizCard(
                  category: {
                    'id': cat.id,
                    'name': cat.name,
                    'description': cat.description,
                    'questionCount': 0, // TODO: traer desde Supabase
                    'completed': 0, // TODO: progreso real
                    'lastScore': null, // TODO: historial real
                    'icon': Icons.category,
                    'color': AppTheme.info,
                  },
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppConstants.quizRoute,
                      arguments: cat.id,
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildRecentProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progreso Reciente',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightBlack,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.greyDark.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: 3,
            separatorBuilder: (context, index) => const Divider(
              color: AppTheme.greyDark,
              height: 24,
            ),
            itemBuilder: (context, index) {
              return _buildProgressItem(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressItem(int index) {
    final activities = [
      {
        'title': 'Quiz de Matemáticas',
        'subtitle': '8/10 correctas - 80%',
        'time': 'Hace 2 horas',
        'icon': Icons.calculate_outlined,
        'color': AppTheme.info,
        'score': 80,
      },
      {
        'title': 'Quiz de Ciencias',
        'subtitle': '9/10 correctas - 90%',
        'time': 'Ayer',
        'icon': Icons.science_outlined,
        'color': AppTheme.success,
        'score': 90,
      },
      {
        'title': 'Quiz de Historia',
        'subtitle': '6/8 correctas - 75%',
        'time': 'Hace 2 días',
        'icon': Icons.history_edu_outlined,
        'color': AppTheme.warning,
        'score': 75,
      },
    ];

    final activity = activities[index];

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (activity['color'] as Color).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            activity['icon'] as IconData,
            color: activity['color'] as Color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity['title'] as String,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                activity['subtitle'] as String,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.greyLight,
                    ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color:
                    _getScoreColor(activity['score'] as int).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${activity['score']}%',
                style: TextStyle(
                  color: _getScoreColor(activity['score'] as int),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              activity['time'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.greyMedium,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return AppTheme.success;
    if (score >= 80) return AppTheme.info;
    if (score >= 70) return AppTheme.warning;
    return AppTheme.error;
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightBlack,
        title: const Text(
          '¿Cerrar Sesión?',
          style: TextStyle(color: AppTheme.white),
        ),
        content: const Text(
          '¿Estás seguro de que deseas cerrar tu sesión?',
          style: TextStyle(color: AppTheme.greyLight),
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
              AppRouter.logout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.info,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
