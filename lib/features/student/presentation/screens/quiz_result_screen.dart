import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/question_models.dart';
import '../../presentation/widgets/custom_button.dart';

class QuizResultScreen extends StatefulWidget {
  final Map<String, dynamic> results;

  const QuizResultScreen({
    Key? key,
    required this.results,
  }) : super(key: key);

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _confettiController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    if ((widget.results['accuracy'] as int) >= 80) {
      Future.delayed(const Duration(milliseconds: 600), () {
        _confettiController.forward();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Color _getResultColor() {
    final accuracy = widget.results['accuracy'] as int;
    if (accuracy >= 90) return AppTheme.success;
    if (accuracy >= 80) return AppTheme.info;
    if (accuracy >= 70) return AppTheme.warning;
    return AppTheme.error;
  }

  String _getResultMessage() {
    final accuracy = widget.results['accuracy'] as int;
    if (accuracy >= 90) return '¡Excelente trabajo!';
    if (accuracy >= 80) return '¡Muy bien hecho!';
    if (accuracy >= 70) return '¡Buen trabajo!';
    if (accuracy >= 60) return 'Puedes mejorar';
    return 'Sigue practicando';
  }

  IconData _getResultIcon() {
    final accuracy = widget.results['accuracy'] as int;
    if (accuracy >= 90) return Icons.emoji_events;
    if (accuracy >= 80) return Icons.thumb_up;
    if (accuracy >= 70) return Icons.sentiment_satisfied;
    return Icons.sentiment_neutral;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        title: const Text(
          'Resultados',
          style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600),
        ),
        leading: const SizedBox(),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AnimationLimiter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimationConfiguration.staggeredList(
                      position: 0,
                      duration: const Duration(milliseconds: 600),
                      child: ScaleAnimation(
                        scale: _scaleAnimation.value,
                        child: FadeInAnimation(
                          child: _buildMainResultCard(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimationConfiguration.staggeredList(
                      position: 1,
                      duration: const Duration(milliseconds: 700),
                      child: SlideAnimation(
                        verticalOffset: 30.0,
                        child: FadeInAnimation(
                          child: _buildDetailedStatsCard(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimationConfiguration.staggeredList(
                      position: 2,
                      duration: const Duration(milliseconds: 800),
                      child: SlideAnimation(
                        verticalOffset: 30.0,
                        child: FadeInAnimation(
                          child: _buildQuestionReviewCard(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    AnimationConfiguration.staggeredList(
                      position: 3,
                      duration: const Duration(milliseconds: 900),
                      child: SlideAnimation(
                        verticalOffset: 30.0,
                        child: FadeInAnimation(
                          child: _buildActionButtons(),
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

  Widget _buildMainResultCard() {
    final accuracy = widget.results['accuracy'] as int;
    final resultColor = _getResultColor();

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [resultColor, resultColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: resultColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 0.1,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getResultIcon(),
                    color: AppTheme.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            '$accuracy%',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _getResultMessage(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Respondiste ${widget.results['correctAnswers']} de ${widget.results['totalQuestions']} preguntas correctamente',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.white.withOpacity(0.9),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStatsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightBlack,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.greyDark.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Estadísticas Detalladas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Correctas',
                    widget.results['correctAnswers'].toString(),
                    Icons.check_circle,
                    AppTheme.success,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Incorrectas',
                    widget.results['incorrectAnswers'].toString(),
                    Icons.cancel,
                    AppTheme.error,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Total',
                    widget.results['totalQuestions'].toString(),
                    Icons.quiz,
                    AppTheme.info,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progreso Visual',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.greyLight,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: widget.results['correctAnswers'] /
                        widget.results['totalQuestions'],
                    backgroundColor: AppTheme.greyDark.withOpacity(0.3),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_getResultColor()),
                    minHeight: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.greyLight,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionReviewCard() {
    final questions = widget.results['questions'] as List<Question>;
    final answers = widget.results['answers'] as Map<String, String>;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightBlack,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.greyDark.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min, // ✅ CLAVE: Solo toma el espacio mínimo necesario
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Repaso de Preguntas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${questions.length} preguntas',
                    style: const TextStyle(
                      color: AppTheme.info,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ✅ SOLUCIÓN DEFINITIVA: Usamos Column con mapeo directo
          ...questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            final userAnswer = answers[question.id] ?? '';
            final isCorrect = userAnswer.toLowerCase() ==
                question.correctAnswer.toLowerCase();

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: index == questions.length - 1 ? 20 : 12,
              ),
              child: _buildQuestionItem(question, userAnswer, isCorrect, index),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuestionItem(
      Question question, String userAnswer, bool isCorrect, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppTheme.success.withOpacity(0.05)
            : AppTheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? AppTheme.success.withOpacity(0.3)
              : AppTheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con número y estado
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCorrect ? AppTheme.success : AppTheme.error,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? AppTheme.success : AppTheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCorrect ? 'Correcta' : 'Incorrecta',
                  style: TextStyle(
                    color: isCorrect ? AppTheme.success : AppTheme.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pregunta
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.greyDark.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pregunta:',
                  style: TextStyle(
                    color: AppTheme.greyLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  question.question,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Respuestas (solo si hay respuesta incorrecta o sin respuesta)
          if (!isCorrect || userAnswer.isEmpty) ...[
            const SizedBox(height: 12),

            // Tu respuesta (si existe)
            if (userAnswer.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.error.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: AppTheme.error, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Tu respuesta:',
                          style: TextStyle(
                            color: AppTheme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userAnswer,
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ] else ...[
              // Sin respuesta
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warning.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_off, color: AppTheme.warning, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Sin respuesta (tiempo agotado)',
                      style: TextStyle(
                        color: AppTheme.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Respuesta correcta
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.success.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: AppTheme.success, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Respuesta correcta:',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    question.correctAnswer,
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        CustomButton(
          text: 'Intentar de Nuevo',
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushReplacementNamed(
              AppConstants.quizRoute,
              arguments: widget.results['categoryId'],
            );
          },
          gradient: LinearGradient(
            colors: [AppTheme.info, AppTheme.info.withOpacity(0.8)],
          ),
          icon: Icons.refresh,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'Volver al Dashboard',
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppConstants.studentDashboardRoute,
              (route) => false,
            );
          },
          isOutlined: true,
          icon: Icons.home,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'Compartir Resultado',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Función de compartir próximamente'),
                backgroundColor: AppTheme.info,
              ),
            );
          },
          backgroundColor: AppTheme.greyDark,
          icon: Icons.share,
        ),
      ],
    );
  }
}
