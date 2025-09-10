import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class LoginSelectionScreen extends StatefulWidget {
  const LoginSelectionScreen({Key? key}) : super(key: key);

  @override
  State<LoginSelectionScreen> createState() => _LoginSelectionScreenState();
}

class _LoginSelectionScreenState extends State<LoginSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _backgroundController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlack,
                  AppTheme.lightBlack,
                  AppTheme.primaryBlack,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: AnimationLimiter(
                child: Column(
                  children: [
                    // Header con logo y título
                    Expanded(
                      flex: 2,
                      child: AnimationConfiguration.staggeredList(
                        position: 0,
                        duration: const Duration(milliseconds: 800),
                        child: SlideAnimation(
                          verticalOffset: -50.0,
                          child: FadeInAnimation(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Logo con animación de pulso (imagen local)
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.8, end: 1.0),
                                    duration:
                                        const Duration(milliseconds: 1000),
                                    builder: (context, scale, child) {
                                      return Transform.scale(
                                        scale: scale,
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            // Mantengo el gradiente alrededor si quieres borde degradado
                                            gradient: AppTheme.primaryGradient,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.primaryRed
                                                    .withOpacity(0.4),
                                                blurRadius: 20,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          // ClipOval para que la imagen quede circular y respete el contenedor
                                          child: ClipOval(
                                            child: Image.asset(
                                              'assets/images/logo.jpeg',
                                              fit: BoxFit.cover,
                                              width: 100,
                                              height: 100,
                                              errorBuilder:
                                                  (ctx, error, stack) {
                                                // Fallback si no existe la imagen
                                                return Container(
                                                  color: AppTheme.lightBlack,
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.quiz_outlined,
                                                      size: 50,
                                                      color: AppTheme.white,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 24),

                                  Text(
                                    '¡Bienvenido!',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: AppTheme.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),

                                  const SizedBox(height: 8),

                                  Text(
                                    'Selecciona tu tipo de acceso',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: AppTheme.greyLight,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Botones de selección
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Botón de Estudiante
                            AnimationConfiguration.staggeredList(
                              position: 1,
                              duration: const Duration(milliseconds: 600),
                              child: SlideAnimation(
                                horizontalOffset: -50.0,
                                child: FadeInAnimation(
                                  child: _buildUserTypeCard(
                                    context,
                                    title: 'Estudiante',
                                    subtitle:
                                        'Responde cuestionarios y ve tus resultados',
                                    icon: Icons.school_outlined,
                                    onTap: () => Navigator.of(context)
                                        .pushNamed(
                                            AppConstants.studentLoginRoute),
                                    isStudent: true,
                                  ),
                                ),
                              ),
                            ),

                            // Divider animado
                            AnimationConfiguration.staggeredList(
                              position: 2,
                              duration: const Duration(milliseconds: 400),
                              child: FadeInAnimation(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              AppTheme.greyDark,
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Text(
                                        'o',
                                        style: TextStyle(
                                          color: AppTheme.greyMedium,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              AppTheme.greyDark,
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Botón de Administrador
                            AnimationConfiguration.staggeredList(
                              position: 3,
                              duration: const Duration(milliseconds: 600),
                              child: SlideAnimation(
                                horizontalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: _buildUserTypeCard(
                                    context,
                                    title: 'Administrador',
                                    subtitle:
                                        'Gestiona preguntas y ve estadísticas',
                                    icon: Icons.admin_panel_settings_outlined,
                                    onTap: () => Navigator.of(context)
                                        .pushNamed(
                                            AppConstants.adminLoginRoute),
                                    isStudent: false,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Footer
                    Expanded(
                      flex: 1,
                      child: AnimationConfiguration.staggeredList(
                        position: 4,
                        duration: const Duration(milliseconds: 500),
                        child: FadeInAnimation(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'CarvajalAutotechApp v${AppConstants.appVersion}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.greyMedium,
                                    ),
                              ),
                              const SizedBox(height: 24),
                            ],
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

  Widget _buildUserTypeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool isStudent,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.fastAnimationDuration,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.lightBlack,
              AppTheme.lightBlack.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isStudent
                ? AppTheme.info.withOpacity(0.3)
                : AppTheme.primaryRed.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isStudent ? AppTheme.info : AppTheme.primaryRed)
                  .withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icono
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isStudent
                      ? [AppTheme.info, AppTheme.info.withOpacity(0.8)]
                      : [AppTheme.primaryRed, AppTheme.darkRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: (isStudent ? AppTheme.info : AppTheme.primaryRed)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 28,
                color: AppTheme.white,
              ),
            ),

            const SizedBox(width: 20),

            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.greyLight,
                        ),
                  ),
                ],
              ),
            ),

            // Flecha
            Icon(
              Icons.arrow_forward_ios,
              color: isStudent ? AppTheme.info : AppTheme.primaryRed,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
