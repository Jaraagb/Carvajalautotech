// lib/features/quiz/presentation/quiz_screen.dart
import 'dart:async';
import 'package:carvajal_autotech/services/student_answer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/question_models.dart';
import '../../../../core/navigation/app_router.dart';
import '../../presentation/widgets/custom_button.dart';
import '../../../../services/questions_service.dart';

class QuizScreen extends StatefulWidget {
  final String? categoryId;

  const QuizScreen({Key? key, this.categoryId}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _timerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  final QuestionsService _questionsService = QuestionsService();
  final StudentAnswersService _answersService = StudentAnswersService();

  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  Map<String, String> _answers =
      {}; // questionId -> answer (persistir selección)
  Map<String, TextEditingController> _freeTextControllers =
      {}; // mantener texto libre
  Timer? _questionTimer;
  int _timeRemaining = 0;
  DateTime? _questionStartTime;
  bool _isAnswered = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadQuestions();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _timerController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _timerController, curve: Curves.linear),
    );

    _animationController.forward();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('unanswered_questions')
          .select('*')
          .eq('category_id',
              widget.categoryId as Object) // siempre aplica filtro
          .order('created_at', ascending: false);

      final fetchedQuestions =
          (response as List).map((row) => Question.fromMap(row)).toList();

      setState(() {
        _questions = fetchedQuestions;
        _currentQuestionIndex = 0;
      });

      if (_questions.isNotEmpty) _startQuestion();
    } catch (e, st) {
      debugPrint('❌ Error cargando preguntas: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error cargando preguntas'),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startQuestion() {
    if (_currentQuestionIndex < _questions.length) {
      final question = _questions[_currentQuestionIndex];

      // asegurarse de tener controlador para texto libre
      if (question.type == QuestionType.freeText) {
        _freeTextControllers.putIfAbsent(
          question.id,
          () => TextEditingController(text: _answers[question.id] ?? ''),
        );
      }

      setState(() {
        _isAnswered = false;
        _questionStartTime = DateTime.now();
      });

      // Solo iniciar timer si la pregunta tiene timeLimit
      if (question.timeLimit != null) {
        setState(() {
          _timeRemaining = question.timeLimit!;
        });
        _startTimer();
      } else {
        // cancelar timer si existía
        _questionTimer?.cancel();
        _timerController.reset();
        setState(() => _timeRemaining = 0);
      }
    }
  }

  void _startTimer() {
    _timerController.reset();
    _questionTimer?.cancel();

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _timeRemaining--);

      if (_timeRemaining <= 0) {
        timer.cancel();
        _handleTimeUp();
      }
    });

    _timerController.forward();
  }

  void _handleTimeUp() {
    if (!_isAnswered) {
      _handleAnswer(''); // respuesta vacía por tiempo agotado
    }
  }

  Future<void> _handleAnswer(String answer) async {
    if (_isAnswered) return;

    final question = _questions[_currentQuestionIndex];

    setState(() {
      _isAnswered = true;
      _answers[question.id] = answer;
    });

    _questionTimer?.cancel();

    final elapsed = _questionStartTime == null
        ? 0
        : DateTime.now()
            .difference(_questionStartTime!)
            .inSeconds
            .clamp(0, 999);

    // determinar isCorrect solo por comparación simple (puedes ajustar lógica)
    final isCorrect = answer.trim().toLowerCase() ==
        question.correctAnswer.trim().toLowerCase();

    try {
      await _answersService.saveAnswer(
        questionId: question.id,
        answer: answer,
        isCorrect: isCorrect,
        timeSpent: elapsed,
      );
    } catch (e) {
      debugPrint('❌ Error guardando respuesta: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error guardando respuesta: $e'),
          backgroundColor: AppTheme.error,
        ));
      }
    }

    // esperar 1.2s para animación/feedback (no mostrar correct/incorrect here)
    Future.delayed(const Duration(milliseconds: 1200), _nextQuestion);
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _startQuestion();
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    int correctAnswers = 0;
    for (var question in _questions) {
      final userAnswer = _answers[question.id] ?? '';
      if (userAnswer.toLowerCase() == question.correctAnswer.toLowerCase()) {
        correctAnswers++;
      }
    }

    final results = {
      'totalQuestions': _questions.length,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': _questions.length - correctAnswers,
      'accuracy': (_questions.isEmpty
          ? 0
          : (correctAnswers / _questions.length * 100).round()),
      'categoryId': widget.categoryId,
      'answers': _answers,
      'questions': _questions,
    };

    AppRouter.navigateToQuizResult(context, results);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timerController.dispose();
    _questionTimer?.cancel();

    // dispose controllers
    for (final c in _freeTextControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Abre la imagen en el navegador (para descargar)
  Future<void> _openImageUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No se pudo abrir la imagen'),
            backgroundColor: AppTheme.error,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error abriendo URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        body: Center(child: CircularProgressIndicator(color: AppTheme.info)),
      );
    }

    if (_questions.isEmpty) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        body: Center(
            child: Text('No hay preguntas disponibles',
                style: TextStyle(color: AppTheme.white))),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: _buildAppBar(progress),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) => FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AnimationLimiter(
              child: Column(
                children: [
                  // Timer (solo si la pregunta tiene timeLimit)
                  if (currentQuestion.hasTimeLimit) _buildTimerSection(),
                  if (currentQuestion.hasTimeLimit) const SizedBox(height: 24),

                  _buildQuestionSection(currentQuestion),
                  const SizedBox(height: 32),

                  Expanded(child: _buildAnswerSection(currentQuestion)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(double progress) {
    return AppBar(
      backgroundColor: AppTheme.primaryBlack,
      title: Text(
        'Pregunta ${_currentQuestionIndex + 1} de ${_questions.length}',
        style:
            const TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600),
      ),
      leading: IconButton(
        onPressed: () => _showExitDialog(),
        icon: const Icon(Icons.close, color: AppTheme.white),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: AppTheme.greyDark.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.info),
          minHeight: 4,
        ),
      ),
    );
  }

  Widget _buildTimerSection() {
    // Si la pregunta no tiene límite, no mostrar
    if (_timeRemaining <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _timeRemaining <= 10
              ? [AppTheme.error, AppTheme.error.withOpacity(0.8)]
              : [AppTheme.info, AppTheme.info.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_timeRemaining <= 10 ? AppTheme.error : AppTheme.info)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                  _timeRemaining <= 10
                      ? Icons.timer_outlined
                      : Icons.access_time,
                  color: AppTheme.white,
                  size: 24),
              const SizedBox(width: 8),
              Text('Tiempo restante',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.white,
                        fontWeight: FontWeight.w500,
                      )),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_timeRemaining}s',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionSection(Question question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.lightBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.greyDark.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tipo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getQuestionTypeColor(question.type).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getQuestionTypeColor(question.type).withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getQuestionTypeIcon(question.type),
                    color: _getQuestionTypeColor(question.type), size: 16),
                const SizedBox(width: 6),
                Text(_getQuestionTypeLabel(question.type),
                    style: TextStyle(
                        color: _getQuestionTypeColor(question.type),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Imagen (si existe)
          if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                question.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) => Container(
                  height: 180,
                  color: AppTheme.greyDark,
                  child: const Center(
                      child: Icon(Icons.broken_image,
                          color: AppTheme.greyLight, size: 48)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openImageUrl(question.imageUrl!),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir imagen'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed),
                ),
                const SizedBox(width: 12),
                Text(
                  question.categoryId.toUpperCase(),
                  style:
                      const TextStyle(color: AppTheme.greyMedium, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Pregunta texto
          Text(question.question,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  )),
        ],
      ),
    );
  }

  Widget _buildAnswerSection(Question question) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return _buildMultipleChoiceAnswers(question);
      case QuestionType.trueFalse:
        return _buildTrueFalseAnswers(question);
      case QuestionType.freeText:
        return _buildFreeTextAnswer(question);
    }
  }

  Widget _buildMultipleChoiceAnswers(Question question) {
    return ListView.builder(
      itemCount: question.options.length,
      itemBuilder: (context, index) {
        final option = question.options[index];
        final isSelected = _answers[question.id] == option;

        Color cardColor = AppTheme.lightBlack;
        Color borderColor = AppTheme.greyDark.withOpacity(0.5);

        if (isSelected) {
          cardColor = AppTheme.info.withOpacity(0.2);
          borderColor = AppTheme.info;
        }

        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 400),
          child: SlideAnimation(
            horizontalOffset: 30.0,
            child: FadeInAnimation(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: _isAnswered ? null : () => _handleAnswer(option),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor, width: 2),
                            color:
                                isSelected ? borderColor : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: AppTheme.white, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(option,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                      color: AppTheme.white,
                                      fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrueFalseAnswers(Question question) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildTrueFalseOption(
                    question, 'Verdadero', Icons.check_circle)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildTrueFalseOption(question, 'Falso', Icons.cancel)),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildTrueFalseOption(
      Question question, String option, IconData icon) {
    final isSelected = _answers[question.id] == option;

    Color cardColor = AppTheme.lightBlack;
    Color borderColor = AppTheme.greyDark.withOpacity(0.5);

    if (isSelected) {
      cardColor = AppTheme.info.withOpacity(0.2);
      borderColor = AppTheme.info;
    }

    return GestureDetector(
      onTap: _isAnswered ? null : () => _handleAnswer(option),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: borderColor, size: 40),
            const SizedBox(height: 12),
            Text(option,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeTextAnswer(Question question) {
    final controller = _freeTextControllers.putIfAbsent(question.id,
        () => TextEditingController(text: _answers[question.id] ?? ''));

    return Column(
      children: [
        TextField(
          controller: controller,
          enabled: !_isAnswered,
          style: const TextStyle(color: AppTheme.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Escribe tu respuesta aquí...',
            hintStyle: const TextStyle(color: AppTheme.greyMedium),
            filled: true,
            fillColor: AppTheme.lightBlack,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppTheme.greyDark.withOpacity(0.5))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.info, width: 2)),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
        const SizedBox(height: 24),
        if (!_isAnswered)
          CustomButton(
            text: 'Confirmar Respuesta',
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) _handleAnswer(text);
            },
            gradient: LinearGradient(
                colors: [AppTheme.info, AppTheme.info.withOpacity(0.8)]),
          ),
      ],
    );
  }

  Color _getQuestionTypeColor(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return AppTheme.info;
      case QuestionType.trueFalse:
        return AppTheme.warning;
      case QuestionType.freeText:
        return AppTheme.success;
    }
  }

  IconData _getQuestionTypeIcon(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return Icons.radio_button_checked;
      case QuestionType.trueFalse:
        return Icons.check_box;
      case QuestionType.freeText:
        return Icons.text_fields;
    }
  }

  String _getQuestionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Opción Múltiple';
      case QuestionType.trueFalse:
        return 'Verdadero/Falso';
      case QuestionType.freeText:
        return 'Texto Libre';
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightBlack,
        title: const Text('¿Salir del Quiz?',
            style: TextStyle(color: AppTheme.white)),
        content: const Text('Perderás todo el progreso actual. ¿Estás seguro?',
            style: TextStyle(color: AppTheme.greyLight)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continuar Quiz',
                  style: TextStyle(color: AppTheme.info))),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}
