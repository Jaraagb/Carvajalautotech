import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/auth/presentation/screens/login_selection_screen.dart';
import '../../features/auth/presentation/screens/admin_login_screen.dart';
import '../../features/auth/presentation/screens/student_login_screen.dart';
import '../../features/auth/presentation/screens/student_register_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/questions_list_screen.dart';
import '../../features/admin/presentation/screens/create_question_screen.dart';
import '../../features/admin/presentation/screens/categories_screen.dart';
import '../../features/admin/presentation/screens/statistics_screen.dart';
import '../../features/student/presentation/screens/student_dashboard_screen.dart';
import '../../features/student/presentation/screens/quiz_screen.dart';
import '../../features/student/presentation/screens/quiz_result_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.splashRoute:
        return _buildRoute(const SplashScreen(), settings);

      case AppConstants.loginSelectionRoute:
        return _buildRoute(const LoginSelectionScreen(), settings);

      case AppConstants.adminLoginRoute:
        return _buildRoute(const AdminLoginScreen(), settings);

      case AppConstants.studentLoginRoute:
        return _buildRoute(const StudentLoginScreen(), settings);

      case AppConstants.studentRegisterRoute:
        return _buildRoute(const StudentRegisterScreen(), settings);

      case AppConstants.adminDashboardRoute:
        return _buildRoute(const AdminDashboardScreen(), settings);

      case AppConstants.studentDashboardRoute:
        return _buildRoute(const StudentDashboardScreen(), settings);

      case AppConstants.questionsListRoute:
        return _buildRoute(const QuestionsListScreen(), settings);

      case AppConstants.createQuestionRoute:
        return _buildRoute(const CreateQuestionScreen(), settings);

      case AppConstants.editQuestionRoute:
        final questionId = settings.arguments as String?;
        return _buildRoute(
            CreateQuestionScreen(questionId: questionId), settings);

      case AppConstants.categoriesRoute:
        return _buildRoute(const CategoriesScreen(), settings);

      case AppConstants.statisticsRoute:
        return _buildRoute(const StatisticsScreen(), settings);

      case AppConstants.quizRoute:
        final categoryId = settings.arguments as String?;
        return _buildRoute(QuizScreen(categoryId: categoryId), settings);

      case AppConstants.quizResultRoute:
        final results = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(QuizResultScreen(results: results ?? {}), settings);

      default:
        return _buildRoute(
            const ErrorScreen(message: 'Página no encontrada'), settings);
    }
  }

  static PageRouteBuilder<dynamic> _buildRoute(
      Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Animación de deslizamiento elegante
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        var offsetAnimation = animation.drive(tween);

        // Animación de fade para transiciones más suaves
        var fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: AppConstants.animationDuration,
      reverseTransitionDuration: AppConstants.fastAnimationDuration,
    );
  }

  // Métodos de navegación helper
  static void navigateToLoginSelection(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(
      AppConstants.loginSelectionRoute,
    );
  }

  static void navigateToAdminDashboard(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppConstants.adminDashboardRoute,
      (route) => false,
    );
  }

  static void navigateToStudentDashboard(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppConstants.studentDashboardRoute,
      (route) => false,
    );
  }

  static void navigateToQuiz(BuildContext context, String categoryId) {
    Navigator.of(context).pushNamed(
      AppConstants.quizRoute,
      arguments: categoryId,
    );
  }

  static void navigateToQuizResult(
      BuildContext context, Map<String, dynamic> results) {
    Navigator.of(context).pushReplacementNamed(
      AppConstants.quizResultRoute,
      arguments: results,
    );
  }

  static void navigateToCreateQuestion(BuildContext context) {
    Navigator.of(context).pushNamed(AppConstants.createQuestionRoute);
  }

  static void navigateToEditQuestion(BuildContext context, String questionId) {
    Navigator.of(context).pushNamed(
      AppConstants.editQuestionRoute,
      arguments: questionId,
    );
  }

  static void logout(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppConstants.loginSelectionRoute,
      (route) => false,
    );
  }
}

// Pantalla de error personalizada
class ErrorScreen extends StatelessWidget {
  final String message;

  const ErrorScreen({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Color(0xFFE53E3E),
              ),
              const SizedBox(height: 24),
              Text(
                '¡Oops!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[400],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(
                    AppConstants.loginSelectionRoute,
                  );
                },
                icon: const Icon(Icons.home),
                label: const Text('Ir al Inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
