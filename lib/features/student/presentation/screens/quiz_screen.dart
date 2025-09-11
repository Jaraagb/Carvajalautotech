import 'dart:async';
import 'package:carvajal_autotech/services/student_answer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:auto_size_text/auto_size_text.dart';
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
  Map<String, String> _answers = {};
  Map<String, TextEditingController> _freeTextControllers = {};
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
          .eq('category_id', widget.categoryId as Object)
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

      if (question.timeLimit != null) {
        setState(() {
          _timeRemaining = question.timeLimit!;
        });
        _startTimer();
      } else {
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
      _handleAnswer('');
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

  void _finishQuiz() async {
    int correctAnswers = 0;
    for (var question in _questions) {
      final userAnswer = _answers[question.id] ?? '';
      if (userAnswer.toLowerCase() == question.correctAnswer.toLowerCase()) {
        correctAnswers++;
      }
    }

    // Verificar si esta categoría está publicada para el estudiante actual
    bool isPublished = false;
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user != null && widget.categoryId != null) {
        final response = await client
            .from('student_categories')
            .select('published')
            .eq('student_id', user.id)
            .eq('category_id', widget.categoryId!)
            .maybeSingle();

        isPublished = response?['published'] as bool? ?? false;
        print(
            'Estado de publicación para categoría ${widget.categoryId}: $isPublished');
      }
    } catch (e) {
      print('Error verificando estado de publicación: $e');
      isPublished = false;
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
      'published': isPublished, // Estado real de publicación de la categoría
    };

    AppRouter.navigateToQuizResult(context, results);
  }

  Future<void> _openImageUrl(String url) async {
    try {
      final uri = Uri.parse(url);

      if (!uri.hasScheme) {
        throw 'URL inválida: no tiene esquema HTTP/HTTPS';
      }

      bool opened = false;

      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          opened = true;
        }
      } catch (e) {
        debugPrint('Falló modo externo: $e');
      }

      if (!opened) {
        try {
          await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
            webViewConfiguration: const WebViewConfiguration(
              enableJavaScript: true,
              enableDomStorage: true,
            ),
          );
          opened = true;
        } catch (e) {
          debugPrint('Falló modo interno: $e');
        }
      }

      if (!opened) {
        try {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
          opened = true;
        } catch (e) {
          debugPrint('Falló modo platformDefault: $e');
        }
      }

      if (!opened) {
        throw 'No se pudo abrir la URL con ningún método';
      }
    } catch (e) {
      debugPrint('Error completo abriendo imagen: $e');
      if (mounted) {
        _showImageErrorDialog(url, e.toString());
      }
    }
  }

  void _showImageErrorDialog(String url, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightBlack,
        title: const Text(
          'No se pudo abrir la imagen',
          style: TextStyle(color: AppTheme.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prueba las siguientes opciones:',
              style: TextStyle(color: AppTheme.greyLight),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Copiar URL y pegar en el navegador',
              style: TextStyle(color: AppTheme.greyLight, fontSize: 14),
            ),
            const Text(
              '• Ver imagen en pantalla completa',
              style: TextStyle(color: AppTheme.greyLight, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              'Error: ${error.length > 50 ? error.substring(0, 50) + "..." : error}',
              style: const TextStyle(
                color: AppTheme.error,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.greyLight)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _copyUrlToClipboard(url);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.info),
            child: const Text('Copiar URL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showFullScreenImage(url);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Ver completa'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(Question question) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightBlack.withOpacity(0.8),
            AppTheme.greyDark.withOpacity(0.6),
          ],
        ),
        border: Border.all(
          color: AppTheme.info.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showFullScreenImage(question.imageUrl!),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlack.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Image.network(
                      question.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.greyDark.withOpacity(0.8),
                                AppTheme.lightBlack.withOpacity(0.8),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: AppTheme.info,
                                  strokeWidth: 3,
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Cargando imagen...',
                                  style: TextStyle(
                                    color: AppTheme.greyLight,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.error.withOpacity(0.1),
                                AppTheme.greyDark.withOpacity(0.8),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.broken_image,
                                  color: AppTheme.error, size: 48),
                              SizedBox(height: 8),
                              Text(
                                'Error al cargar imagen',
                                style: TextStyle(
                                    color: AppTheme.greyLight, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlack.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.info.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.zoom_in,
                        color: AppTheme.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.info,
                              AppTheme.info.withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.info.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showFullScreenImage(question.imageUrl!),
                          icon: const Icon(Icons.fullscreen_rounded, size: 18),
                          label: const Text(
                            'Ampliar',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppTheme.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.success,
                              AppTheme.success.withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.success.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _openImageUrl(question.imageUrl!),
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text(
                            'Abrir',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppTheme.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.warning,
                            AppTheme.warning.withOpacity(0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.warning.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () =>
                            _copyUrlToClipboard(question.imageUrl!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: AppTheme.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.all(14),
                          minimumSize: const Size(50, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Icon(Icons.copy_rounded, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.info.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    question.categoryId.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.info,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyUrlToClipboard(String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL copiada al portapapeles'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error copiando URL: $e');
    }
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: AppTheme.primaryBlack,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: AppTheme.error, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'Error al cargar imagen',
                        style: TextStyle(color: AppTheme.white, fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _openImageUrl(imageUrl),
                        child: const Text('Abrir en navegador'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppTheme.white, size: 30),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlack.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timerController.dispose();
    _questionTimer?.cancel();

    for (final c in _freeTextControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryBlack,
          title: const Text(
            'Quiz',
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
            'Aún no hay preguntas disponibles.',
            style: TextStyle(fontSize: 18, color: AppTheme.greyDark),
          ),
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
            child: SingleChildScrollView(
              // 🔹 Solución: Agregar desplazamiento
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTimerSection(),
                    const SizedBox(height: 16),
                    _buildQuestionSection(currentQuestion),
                    const SizedBox(height: 16),
                    _buildAnswerSection(currentQuestion),
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
          if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
            _buildImageSection(question),
            const SizedBox(height: 12),
          ],
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
    return Column(
      children: question.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
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
      }).toList(),
    );
  }

  Widget _buildTrueFalseAnswers(Question question) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
      mainAxisSize: MainAxisSize.min,
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
