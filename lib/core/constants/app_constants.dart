class AppConstants {
  // Rutas de navegación
  static const String splashRoute = '/';
  static const String loginSelectionRoute = '/login-selection';
  static const String adminLoginRoute = '/admin-login';
  static const String studentLoginRoute = '/student-login';
  static const String studentRegisterRoute = '/student-register';
  static const String adminDashboardRoute = '/admin-dashboard';
  static const String studentDashboardRoute = '/student-dashboard';
  static const String createQuestionRoute = '/create-question';
  static const String editQuestionRoute = '/edit-question';
  static const String questionsListRoute = '/questions-list';
  static const String categoriesRoute = '/categories';
  static const String statisticsRoute = '/statistics';
  static const String quizRoute = '/quiz';
  static const String quizResultRoute = '/quiz-result';

  // API Endpoints (para configurar con el backend)
  static const String baseUrl =
      'https://api.quizapp.com'; // Cambiar por la URL real
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';

  static const String usersEndpoint = '/users';
  static const String categoriesEndpoint = '/categories';
  static const String questionsEndpoint = '/questions';
  static const String answersEndpoint = '/answers';
  static const String statisticsEndpoint = '/statistics';

  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String isFirstTimeKey = 'is_first_time';

  // Validaciones
  static const int minPasswordLength = 6;
  static const int maxQuestionLength = 500;
  static const int maxOptionLength = 200;
  static const int minOptionsCount = 2;
  static const int maxOptionsCount = 6;
  static const int maxTimeLimitSeconds = 3600; // 1 hora
  static const int minTimeLimitSeconds = 10; // 10 segundos

  // Configuración de quiz
  static const int defaultQuizTimeLimit = 300; // 5 minutos por defecto
  static const int autoSaveInterval = 30; // Cada 30 segundos

  // Animaciones
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 200);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  // Mensajes
  static const String appName = 'QuizApp';
  static const String appVersion = '1.0.0';

  // Errores comunes
  static const String networkErrorMessage =
      'Error de conexión. Verifica tu internet.';
  static const String serverErrorMessage =
      'Error del servidor. Intenta más tarde.';
  static const String unauthorizedErrorMessage =
      'Sesión expirada. Inicia sesión nuevamente.';
  static const String validationErrorMessage =
      'Por favor verifica los datos ingresados.';
  static const String genericErrorMessage = 'Ha ocurrido un error inesperado.';

  // Títulos de pantallas
  static const String adminDashboardTitle = 'Panel Administrativo';
  static const String studentDashboardTitle = 'Mi Dashboard';
  static const String loginTitle = 'Iniciar Sesión';
  static const String registerTitle = 'Crear Cuenta';
  static const String questionsTitle = 'Gestión de Preguntas';
  static const String categoriesTitle = 'Categorías';
  static const String statisticsTitle = 'Estadísticas';
  static const String quizTitle = 'Quiz';
  static const String createQuestionTitle = 'Crear Pregunta';
  static const String editQuestionTitle = 'Editar Pregunta';

  // Tipos de preguntas - Labels
  static const Map<String, String> questionTypeLabels = {
    'multipleChoice': 'Opción Múltiple',
    'trueFalse': 'Verdadero/Falso',
    'freeText': 'Texto Libre',
  };

  // Configuración de paginación
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Configuración de caché
  static const Duration cacheExpiration = Duration(minutes: 30);
  static const int maxCacheSize = 100; // MB
}
