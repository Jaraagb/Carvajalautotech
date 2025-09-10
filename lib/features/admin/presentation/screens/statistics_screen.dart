import 'package:carvajal_autotech/features/admin/presentation/screens/student_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool _isLoading = true;

  final supabase = Supabase.instance.client;

  // Datos cargados desde la BD
  Map<String, dynamic>? _overallStats;
  List<Map<String, dynamic>> _categoryStats = [];
  List<Map<String, dynamic>> _topStudents = [];
  List<Map<String, dynamic>> _trends = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchStats();
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

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);

    try {
      // 1️⃣ Resumen general
      final overallRes = await supabase.from('stats_overall').select();
      // Usando la vista pública que ya existe en schema public (app_users)
      final totalStudentsRes = await supabase.from('app_users').select('id');
      final totalStudents = (totalStudentsRes as List).length;

      _overallStats = {
        'totalStudents': totalStudents,
        'totalQuestions': overallRes[0]['total_questions'],
        'totalAnswers': overallRes[0]['total_answers'],
        'averageAccuracy': overallRes[0]['average_accuracy'],
        'completedQuizzes': overallRes[0]['completed_quizzes'],
      };

      // 2️⃣ Rendimiento por categoría
      final categoryRes = await supabase.from('stats_by_category').select();

      _categoryStats = categoryRes.map<Map<String, dynamic>>((c) {
        return {
          'name': c['category_name'],
          'questions': c['total_questions'],
          'answers': c['total_answers'],
          'accuracy': c['average_accuracy'],
          'color': AppTheme.info, // puedes mapear por categoría si quieres
        };
      }).toList();

      // 3️⃣ Top estudiantes
      final topRes = await supabase.from('stats_top_students').select();
      _topStudents = topRes.map<Map<String, dynamic>>((s) {
        return {
          'name': s['name'] ?? 'Sin nombre',
          'email': s['email'],
          'accuracy': s['accuracy'],
          'questionsAnswered': s['questions_answered'],
          'rank': s['rank'],
        };
      }).toList();

      // 4️⃣ Tendencias
      final trendsRes = await supabase.from('stats_trends').select();
      _trends = trendsRes.map<Map<String, dynamic>>((t) {
        return {
          'day': t['day'],
          'answers': t['answers'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error al cargar estadísticas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar estadísticas: $e'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }

    setState(() => _isLoading = false);
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
            child: _isLoading || _overallStats == null
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryRed),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: AnimationLimiter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOverallStats(),
                          const SizedBox(height: 16),
                          _buildStudentsCard(), // <-- nuevo widget
                          const SizedBox(height: 32),
                          _buildCategoryStats(),
                          const SizedBox(height: 32),
                          _buildTopStudents(),
                          const SizedBox(height: 32),
                          _buildTrendsChart(),
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
          onPressed: _fetchStats,
          icon: const Icon(Icons.refresh, color: AppTheme.white),
        ),
      ],
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
              _overallStats!['totalStudents'].toString(),
              Icons.school_outlined,
              AppTheme.info,
            ),
            _buildStatCard(
              'Preguntas Creadas',
              _overallStats!['totalQuestions'].toString(),
              Icons.quiz_outlined,
              AppTheme.success,
            ),
            _buildStatCard(
              'Respuestas Totales',
              _overallStats!['totalAnswers'].toString(),
              Icons.question_answer_outlined,
              AppTheme.warning,
            ),
            _buildStatCard(
              'Precisión Promedio',
              '${_overallStats!['averageAccuracy']}%',
              Icons.trending_up_outlined,
              AppTheme.primaryRed,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStudentsCard() {
    final total = _overallStats?['totalStudents'] ?? '—';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentsListScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.lightBlack,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.greyDark.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
                color: AppTheme.primaryRed.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.info.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.people, color: AppTheme.info, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estudiantes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('$total disponibles',
                      style: const TextStyle(
                          color: AppTheme.greyLight, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.greyLight),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          data: _trends, // le pasamos la data real
        ),
      ],
    );
  }
}
