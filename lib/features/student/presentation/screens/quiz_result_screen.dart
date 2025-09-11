import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/question_models.dart';
import '../../presentation/widgets/custom_button.dart';

class QuizResultScreen extends StatefulWidget {
  final Map<String, dynamic>? results;
  final String? categoryId;
  final String? categoryName;

  const QuizResultScreen({
    Key? key,
    this.results,
    this.categoryId,
    this.categoryName,
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

  // Variables para manejar datos cargados desde la base de datos
  Map<String, dynamic>? _loadedResults;
  bool _isLoading = false;
  String? _errorMessage;

  // Getter para obtener los datos efectivos (pasados o cargados)
  Map<String, dynamic>? get effectiveResults =>
      widget.results ?? _loadedResults;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Si no tenemos results pero sí categoryId, cargar desde DB
    if (widget.results == null && widget.categoryId != null) {
      _loadResultsFromDatabase();
    }
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

    // Solo mostrar confetti si tenemos datos y el puntaje es alto
    final results = effectiveResults;
    if (results != null && (results['accuracy'] as int? ?? 0) >= 80) {
      Future.delayed(const Duration(milliseconds: 600), () {
        _confettiController.forward();
      });
    }
  }

  Future<void> _loadResultsFromDatabase() async {
    if (widget.categoryId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Primero, obtener todas las preguntas de la categoría
      final questionsResponse = await client
          .from('questions')
          .select(
              'id, question, options, correct_answer, explanation, category_id')
          .eq('category_id', widget.categoryId!);

      if (questionsResponse.isEmpty) {
        throw Exception('No se encontraron preguntas para esta categoría');
      }

      // Luego, obtener las respuestas del estudiante
      final questionIds = questionsResponse.map((q) => q['id']).toList();
      final answersResponse = await client
          .from('student_answers')
          .select('question_id, student_id, answer, is_correct, time_spent')
          .eq('student_id', user.id)
          .inFilter('question_id', questionIds);

      if (answersResponse.isEmpty) {
        throw Exception('No se encontraron respuestas para esta categoría');
      }

      // Crear un mapa de respuestas por question_id para fácil búsqueda
      final answersMap = <String, Map<String, dynamic>>{};
      for (final answerData in answersResponse) {
        final questionId = answerData['question_id'].toString();
        answersMap[questionId] = answerData;
      }

      // Procesar las preguntas y sus respuestas
      final questions = <Question>[];
      final answers = <String, String>{};
      int correctAnswers = 0;
      int totalQuestions = questionsResponse.length;

      for (final questionData in questionsResponse) {
        final questionId = questionData['id'].toString();
        final answerData = answersMap[questionId];

        if (answerData == null) {
          // Esta pregunta no fue respondida por el estudiante
          continue;
        }

        final isCorrect = answerData['is_correct'] ?? false;
        if (isCorrect == true || isCorrect == 1 || isCorrect == 'true') {
          correctAnswers++;
        }

        // Crear objeto Question
        final question = Question(
          id: questionId,
          categoryId: questionData['category_id'] ?? widget.categoryId!,
          type: QuestionType.multipleChoice,
          question: questionData['question'] ?? '',
          options: List<String>.from(questionData['options'] ?? []),
          correctAnswer: questionData['correct_answer'] ?? '',
          explanation: questionData['explanation'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'system',
        );

        questions.add(question);

        // Guardar la respuesta del estudiante
        final selectedAnswer = answerData['answer'] ?? '';
        answers[questionId] = selectedAnswer;
      }

      // Actualizar totalQuestions basado en preguntas realmente respondidas
      totalQuestions = questions.length;

      final accuracy = totalQuestions > 0
          ? ((correctAnswers / totalQuestions) * 100).round()
          : 0;

      setState(() {
        _loadedResults = {
          'categoryId': widget.categoryId,
          'categoryName': widget.categoryName ?? 'Categoría',
          'correctAnswers': correctAnswers,
          'incorrectAnswers': totalQuestions - correctAnswers,
          'totalQuestions': totalQuestions,
          'accuracy': accuracy,
          'published':
              true, // Asumimos que está publicado si podemos ver los resultados
          'questions': questions, // Preguntas reales con explicaciones
          'answers': answers, // Respuestas del estudiante
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
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
    final results = effectiveResults;
    if (results == null) return AppTheme.greyLight;
    final accuracy = results['accuracy'] as int;
    if (accuracy >= 90) return AppTheme.success;
    if (accuracy >= 80) return AppTheme.info;
    if (accuracy >= 70) return AppTheme.warning;
    return AppTheme.error;
  }

  String _getResultMessage() {
    final results = effectiveResults;
    if (results == null) return 'Cargando resultados...';
    final accuracy = results['accuracy'] as int;
    if (accuracy >= 90) return '¡Excelente trabajo!';
    if (accuracy >= 80) return '¡Muy bien hecho!';
    if (accuracy >= 70) return '¡Buen trabajo!';
    if (accuracy >= 60) return 'Puedes mejorar';
    return 'Sigue practicando';
  }

  IconData _getResultIcon() {
    final results = effectiveResults;
    if (results == null) return Icons.help;
    final accuracy = results['accuracy'] as int;
    if (accuracy >= 90) return Icons.emoji_events;
    if (accuracy >= 80) return Icons.thumb_up;
    if (accuracy >= 70) return Icons.sentiment_satisfied;
    return Icons.sentiment_neutral;
  }

  @override
  Widget build(BuildContext context) {
    // Si estamos cargando, mostrar indicador
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.info),
        ),
      );
    }

    // Si hay error, mostrar mensaje
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryBlack,
          title: const Text('Error', style: TextStyle(color: AppTheme.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppTheme.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    final results = effectiveResults;
    if (results == null) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        body: const Center(
          child: Text(
            'No hay datos disponibles',
            style: TextStyle(color: AppTheme.white),
          ),
        ),
      );
    }

    final bool resultsPublished = results['published'] ?? false;

    if (!resultsPublished) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryBlack,
          title: const Text(
            'Resultados',
            style:
                TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Text(
            'Los resultados aún no han sido publicados.',
            style: TextStyle(fontSize: 18, color: AppTheme.greyDark),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        title: const Text(
          'Resultados',
          style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
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
                    // Debug: Mostrar información sobre las preguntas
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.greyDark.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                      ),
                    ),
                    // Solo mostrar revisión de preguntas si tenemos preguntas cargadas
                    if (results['questions'] != null &&
                        (results['questions'] as List).isNotEmpty)
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
    final results = effectiveResults!;
    final accuracy = results['accuracy'] as int;
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
            'Respondiste ${results['correctAnswers']} de ${results['totalQuestions']} preguntas correctamente',
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
    final results = effectiveResults!;
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
                    results['correctAnswers'].toString(),
                    Icons.check_circle,
                    AppTheme.success,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Incorrectas',
                    results['incorrectAnswers'].toString(),
                    Icons.cancel,
                    AppTheme.error,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Total',
                    results['totalQuestions'].toString(),
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
                    value:
                        results['correctAnswers'] / results['totalQuestions'],
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
    final results = effectiveResults!;
    final questions = results['questions'] as List<Question>;
    final answers = results['answers'] as Map<String, String>;

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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.quiz, color: AppTheme.info, size: 24),
                const SizedBox(width: 12),
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

          // Explicación (si existe)
          if (question.explanation != null &&
              question.explanation!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.info.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: AppTheme.info, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Explicación:',
                        style: TextStyle(
                          color: AppTheme.info,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    question.explanation!,
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 13,
                      height: 1.4,
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

// SOLUCIÓN 3: Usar Container con margen bottom
  Widget _buildActionButtons() {
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        children: [
          CustomButton(
            text: 'Intentar de Nuevo',
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed(
                AppConstants.quizRoute,
                arguments: widget.categoryId ?? effectiveResults?['categoryId'],
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
      ),
    );
  }
}
