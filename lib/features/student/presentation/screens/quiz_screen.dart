import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/question_models.dart';
import '../../../../core/navigation/app_router.dart';
import '../../presentation/widgets/custom_button.dart';

class QuizScreen extends StatefulWidget {
  final String? categoryId;

  const QuizScreen({
    Key? key,
    this.categoryId,
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _timerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  Map<String, String> _answers = {};
  Timer? _questionTimer;
  int _timeRemaining = 0;
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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _timerController,
      curve: Curves.linear,
    ));

    _animationController.forward();
  }

  void _loadQuestions() {
    // Datos simulados de preguntas
    _questions = [
      Question(
        id: '1',
        categoryId: widget.categoryId ?? 'math',
        type: QuestionType.multipleChoice,
        question: '¿Cuál es el resultado de 15 + 27?',
        options: ['40', '42', '45', '48'],
        correctAnswer: '42',
        timeLimit: 30,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'admin1',
      ),
      Question(
        id: '2',
        categoryId: widget.categoryId ?? 'math',
        type: QuestionType.trueFalse,
        question: 'El número π (pi) es igual a 3.14159...',
        options: ['Verdadero', 'Falso'],
        correctAnswer: 'Verdadero',
        timeLimit: 20,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'admin1',
      ),
      Question(
        id: '3',
        categoryId: widget.categoryId ?? 'math',
        type: QuestionType.freeText,
        question: '¿Cuál es la raíz cuadrada de 64?',
        options: [],
        correctAnswer: '8',
        timeLimit: 25,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'admin1',
      ),
    ];

    _startQuestion();
  }

  void _startQuestion() {
    if (_currentQuestionIndex < _questions.length) {
      final question = _questions[_currentQuestionIndex];
      setState(() {
        _isAnswered = false;
        _timeRemaining = question.timeLimit ?? 30;
      });

      _startTimer();
    }
  }

  void _startTimer() {
    _timerController.reset();
    _questionTimer?.cancel();
    
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
      });

      if (_timeRemaining <= 0) {
        timer.cancel();
        _handleTimeUp();
      }
    });

    _timerController.forward();
  }

  void _handleTimeUp() {
    if (!_isAnswered) {
      _handleAnswer(''); // Respuesta vacía por tiempo agotado
    }
  }

  void _handleAnswer(String answer) {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _answers[_questions[_currentQuestionIndex].id] = answer;
    });

    _questionTimer?.cancel();

    // Mostrar resultado por 2 segundos antes de continuar
    Future.delayed(const Duration(seconds: 2), () {
      _nextQuestion();
    });
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
    // Calcular resultados
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
      'accuracy': (correctAnswers / _questions.length * 100).round(),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.info),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: _buildAppBar(progress),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AnimationLimiter(
                child: Column(
                  children: [
                    // Timer y progreso
                    AnimationConfiguration.staggeredList(
                      position: 0,
                      duration: const Duration(milliseconds: 600),
                      child: SlideAnimation(
                        verticalOffset: -30.0,
                        child: FadeInAnimation(
                          child: _buildTimerSection(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Pregunta
                    AnimationConfiguration.staggeredList(
                      position: 1,
                      duration: const Duration(milliseconds: 700),
                      child: SlideAnimation(
                        verticalOffset: 30.0,
                        child: FadeInAnimation(
                          child: _buildQuestionSection(currentQuestion),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Opciones de respuesta
                    Expanded(
                      child: AnimationConfiguration.staggeredList(
                        position: 2,
                        duration: const Duration(milliseconds: 800),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildAnswerSection(currentQuestion),
                          ),
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

  PreferredSizeWidget _buildAppBar(double progress) {
    return AppBar(
      backgroundColor: AppTheme.primaryBlack,
      title: Text(
        'Pregunta ${_currentQuestionIndex + 1} de ${_questions.length}',
        style: const TextStyle(
          color: AppTheme.white,
          fontWeight: FontWeight.w600,
        ),
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
            color: (_timeRemaining <= 10 ? AppTheme.error : AppTheme.info).withOpacity(0.3),
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
                _timeRemaining <= 10 ? Icons.timer_outlined : Icons.access_time,
                color: AppTheme.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Tiempo restante',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.w500,
                    ),
              ),
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
      padding: const EdgeInsets.all(24),
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
          // Tipo de pregunta
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
                Icon(
                  _getQuestionTypeIcon(question.type),
                  color: _getQuestionTypeColor(question.type),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _getQuestionTypeLabel(question.type),
                  style: TextStyle(
                    color: _getQuestionTypeColor(question.type),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Pregunta
          Text(
            question.question,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
          ),
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
        final isCorrect = option == question.correctAnswer;
        
        Color cardColor = AppTheme.lightBlack;
        Color borderColor = AppTheme.greyDark.withOpacity(0.5);
        Color textColor = AppTheme.white;
        
        if (_isAnswered) {
          if (isCorrect) {
            cardColor = AppTheme.success.withOpacity(0.2);
            borderColor = AppTheme.success;
          } else if (isSelected && !isCorrect) {
            cardColor = AppTheme.error.withOpacity(0.2);
            borderColor = AppTheme.error;
          }
        } else if (isSelected) {
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
                            color: isSelected ? borderColor : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: AppTheme.white, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        if (_isAnswered && isCorrect)
                          const Icon(Icons.check_circle, color: AppTheme.success),
                        if (_isAnswered && isSelected && !isCorrect)
                          const Icon(Icons.cancel, color: AppTheme.error),
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
            Expanded(child: _buildTrueFalseOption(question, 'Verdadero', Icons.check_circle)),
            const SizedBox(width: 16),
            Expanded(child: _buildTrueFalseOption(question, 'Falso', Icons.cancel)),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildTrueFalseOption(Question question, String option, IconData icon) {
    final isSelected = _answers[question.id] == option;
    final isCorrect = option == question.correctAnswer;
    
    Color cardColor = AppTheme.lightBlack;
    Color borderColor = AppTheme.greyDark.withOpacity(0.5);
    
    if (_isAnswered) {
      if (isCorrect) {
        cardColor = AppTheme.success.withOpacity(0.2);
        borderColor = AppTheme.success;
      } else if (isSelected && !isCorrect) {
        cardColor = AppTheme.error.withOpacity(0.2);
        borderColor = AppTheme.error;
      }
    } else if (isSelected) {
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
            Icon(
              icon,
              color: borderColor,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              option,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeTextAnswer(Question question) {
    final textController = TextEditingController();
    final isAnswered = _answers.containsKey(question.id);

    return Column(
      children: [
        TextField(
          controller: textController,
          enabled: !_isAnswered,
          style: const TextStyle(color: AppTheme.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Escribe tu respuesta aquí...',
            hintStyle: const TextStyle(color: AppTheme.greyMedium),
            filled: true,
            fillColor: AppTheme.lightBlack,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.greyDark.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.info, width: 2),
            ),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
        
        const SizedBox(height: 24),
        
        if (!_isAnswered)
          CustomButton(
            text: 'Confirmar Respuesta',
            onPressed: () {
              if (textController.text.isNotEmpty) {
                _handleAnswer(textController.text);
              }
            },
            gradient: LinearGradient(
              colors: [AppTheme.info, AppTheme.info.withOpacity(0.8)],
            ),
          ),
        
        if (_isAnswered) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: textController.text.toLowerCase() == question.correctAnswer.toLowerCase()
                  ? AppTheme.success.withOpacity(0.2)
                  : AppTheme.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: textController.text.toLowerCase() == question.correctAnswer.toLowerCase()
                    ? AppTheme.success
                    : AppTheme.error,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      textController.text.toLowerCase() == question.correctAnswer.toLowerCase()
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: textController.text.toLowerCase() == question.correctAnswer.toLowerCase()
                          ? AppTheme.success
                          : AppTheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      textController.text.toLowerCase() == question.correctAnswer.toLowerCase()
                          ? 'Correcto'
                          : 'Incorrecto',
                      style: TextStyle(
                        color: textController.text.toLowerCase() == question.correctAnswer.toLowerCase()
                            ? AppTheme.success
                            : AppTheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (textController.text.toLowerCase() != question.correctAnswer.toLowerCase()) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Respuesta correcta: ${question.correctAnswer}',
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        
        const Spacer(),
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
        title: const Text(
          '¿Salir del Quiz?',
          style: TextStyle(color: AppTheme.white),
        ),
        content: const Text(
          'Perderás todo el progreso actual. ¿Estás seguro?',
          style: TextStyle(color: AppTheme.greyLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Continuar Quiz',
              style: TextStyle(color: AppTheme.info),
            ),
          ),
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