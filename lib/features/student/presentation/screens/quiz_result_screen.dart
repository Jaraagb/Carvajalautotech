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
    
    // Si es un buen resultado, mostrar confetti
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
        leading: const SizedBox(), // Quitar botón de volver
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
                  children: [
                    // Resultado principal
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

                    // Estadísticas detalladas
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

                    // Repaso de preguntas
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

                    // Botones de acción
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
      width: double.infinity,
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
          // Icono animado
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

          // Porcentaje principal
          Text(
            '$accuracy%',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 8),

          // Mensaje de resultado
          Text(
            _getResultMessage(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.w600,
                ),
          ),

          const SizedBox(height: 16),

          // Resumen rápido
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
      width: double.infinity,
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
          
          // Stats grid
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
          
          // Barra de progreso
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
                    value: widget.results['correctAnswers'] / widget.results['totalQuestions'],
                    backgroundColor: AppTheme.greyDark.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(_getResultColor()),
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

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
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
      width: double.infinity,
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
              'Repaso de Preguntas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          
          ...questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            final userAnswer = answers[question.id] ?? '';
            final isCorrect = userAnswer.toLowerCase() == question.correctAnswer.toLowerCase();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 1),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCorrect 
                    ? AppTheme.success.withOpacity(0.1)
                    : AppTheme.error.withOpacity(0.1),
                border: Border(
                  left: BorderSide(
                    color: isCorrect ? AppTheme.success : AppTheme.error,
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Número de pregunta
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
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Icono de resultado
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? AppTheme.success : AppTheme.error,
                    size: 20,
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Información de la pregunta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.question,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.white,
                                fontWeight: FontWeight.w500,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (!isCorrect && userAnswer.isNotEmpty) ...[
                          Text(
                            'Tu respuesta: $userAnswer',
                            style: const TextStyle(
                              color: AppTheme.error,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Correcta: ${question.correctAnswer}',
                            style: const TextStyle(
                              color: AppTheme.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else if (userAnswer.isEmpty) ...[
                          const Text(
                            'Sin respuesta (tiempo agotado)',
                            style: TextStyle(
                              color: AppTheme.warning,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Correcta: ${question.correctAnswer}',
                            style: const TextStyle(
                              color: AppTheme.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          
          const SizedBox(height: 20),
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
            Navigator.of(context).pop(); // Volver al quiz
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