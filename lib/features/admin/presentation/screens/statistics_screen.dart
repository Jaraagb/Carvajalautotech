import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/stats_chart_card.dart';
import '../widgets/student_performance_card.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _selectedPeriod = '7d';
  bool _isLoading = false;

  // Datos simulados
  final Map<String, dynamic> _overallStats = {
    'totalStudents': 89,
    'totalQuestions': 156,
    'totalAnswers': 2341,
    'averageAccuracy': 78.5,
    'activeToday': 23,
    'completedQuizzes': 145,
  };

  final List<Map<String, dynamic>> _categoryStats = [
    {
      'name': 'Matemáticas',
      'questions': 45,
      'answers': 892,
      'accuracy': 82.3,
      'color': AppTheme.info,
    },
    {
      'name': 'Ciencias',
      'questions': 38,
      'answers': 673,
      'accuracy': 75.1,
      'color': AppTheme.success,
    },
    {
      'name': 'Historia',
      'questions': 32,
      'answers': 521,
      'accuracy': 79.8,
      'color': AppTheme.warning,
    },
    {
      'name': 'Literatura',
      'questions': 25,
      'answers': 255,
      'accuracy': 71.2,
      'color': AppTheme.primaryRed,
    },
  ];

  final List<Map<String, dynamic>> _topStudents = [
    {
      'name': 'María García',
      'email': 'maria@email.com',
      'accuracy': 94.5,
      'questionsAnswered': 78,
      'rank': 1,
    },
    {
      'name': 'Juan Pérez',
      'email': 'juan@email.com',
      'accuracy': 91.2,
      'questionsAnswered': 65,
      'rank': 2,
    },
    {
      'name': 'Ana López',
      'email': 'ana@email.com',
      'accuracy': 88.7,
      'questionsAnswered': 72,
      'rank': 3,
    },
    {
      'name': 'Carlos Ruiz',
      'email': 'carlos@email.com',
      'accuracy': 86.3,
      'questionsAnswered': 58,
      'rank': 4,
    },
    {
      'name': 'Laura Díaz',
      'email': 'laura@email.com',
      'accuracy': 84.1,
      'questionsAnswered': 63,
      'rank': 5,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryRed),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: AnimationLimiter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Filtros de período
                          AnimationConfiguration.staggeredList(
                            position: 0,
                            duration: const Duration(milliseconds: 600),
                            child: SlideAnimation(
                              verticalOffset: -30.0,
                              child: FadeInAnimation(
                                child: _buildPeriodSelector(),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Estadísticas generales
                          AnimationConfiguration.staggeredList(
                            position: 1,
                            duration: const Duration(milliseconds: 700),
                            child: SlideAnimation(
                              horizontalOffset: -30.0,
                              child: FadeInAnimation(
                                child: _buildOverallStats(),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Estadísticas por categoría
                          AnimationConfiguration.staggeredList(
                            position: 2,
                            duration: const Duration(milliseconds: 800),
                            child: SlideAnimation(
                              verticalOffset: 30.0,
                              child: FadeInAnimation(
                                child: _buildCategoryStats(),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Top estudiantes
                          AnimationConfiguration.staggeredList(
                            position: 3,
                            duration: const Duration(milliseconds: 900),
                            child: SlideAnimation(
                              horizontalOffset: 30.0,
                              child: FadeInAnimation(
                                child: _buildTopStudents(),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Gráficos de tendencias
                          AnimationConfiguration.staggeredList(
                            position: 4,
                            duration: const Duration(milliseconds: 1000),
                            child: SlideAnimation(
                              verticalOffset: 30.0,
                              child: FadeInAnimation(
                                child: _buildTrendsChart(),
                              ),
                            ),
                          ),
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
      title: const Text(
        'Estadísticas',
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
            Future.delayed(const Duration(seconds: 2), () {
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
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, color: AppTheme.white),
                  SizedBox(width: 12),
                  Text('Exportar Reporte', style: TextStyle(color: AppTheme.white)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    final periods = [
      {'value': '1d', 'label': '24h'},
      {'value': '7d', 'label': '7 días'},
      {'value': '30d', 'label': '30 días'},
      {'value': '90d', 'label': '3 meses'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.greyDark.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Período de Análisis',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: periods.map((period) {
              final isSelected = _selectedPeriod == period['value'];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPeriod = period['value']!;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.primaryRed.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? AppTheme.primaryRed
                            : AppTheme.greyDark.withOpacity(0.5),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      period['label']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? AppTheme.primaryRed : AppTheme.greyLight,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen General',
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
          childAspectRatio: 1.2,
          children: [
            _buildStatCard(
              'Estudiantes Totales',
              _overallStats['totalStudents'].toString(),
              Icons.school_outlined,
              AppTheme.info,
            ),
            _buildStatCard(
              'Preguntas Creadas',
              _overallStats['totalQuestions'].toString(),
              Icons.quiz_outlined,
              AppTheme.success,
            ),
            _buildStatCard(
              'Respuestas Totales',
              _overallStats['totalAnswers'].toString(),
              Icons.question_answer_outlined,
              AppTheme.warning,
            ),
            _buildStatCard(
              'Precisión Promedio',
              '${_overallStats['averageAccuracy']}%',
              Icons.trending_up_outlined,
              AppTheme.primaryRed,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.lightBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.greyLight,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rendimiento por Categoría',
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
            itemCount: _categoryStats.length,
            separatorBuilder: (context, index) => const Divider(
              color: AppTheme.greyDark,
              height: 24,
            ),
            itemBuilder: (context, index) {
              final category = _categoryStats[index];
              return Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: category['color'],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category['name'],
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${category['questions']} preguntas • ${category['answers']} respuestas',
                          style: const TextStyle(
                            color: AppTheme.greyLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: category['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${category['accuracy']}%',
                      style: TextStyle(
                        color: category['color'],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopStudents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top 5 Estudiantes',
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
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _topStudents.length,
            itemBuilder: (context, index) {
              final student = _topStudents[index];
              final isTop3 = student['rank'] <= 3;
              
              return StudentPerformanceCard(
                student: student,
                isTop3: isTop3,
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tendencias de Actividad',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        StatsChartCard(
          title: 'Respuestas por Día',
          period: _selectedPeriod,
        ),
      ],
    );
  }
}