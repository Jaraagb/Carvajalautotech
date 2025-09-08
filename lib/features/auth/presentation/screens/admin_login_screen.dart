import 'package:flutter/material.dart';
import 'package:carvajal_autotech/services/auth_service.dart';
import 'package:carvajal_autotech/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isPasswordVisible = false;
  bool _isLoading = false;

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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        expectedRole: UserRole.admin,
      );

      if (result.isSuccess && result.user != null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            AppConstants.adminDashboardRoute,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Error desconocido'),
              backgroundColor: AppTheme.primaryRed,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryBlack, AppTheme.lightBlack],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: AnimationLimiter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Botón de volver
                          AnimationConfiguration.staggeredList(
                            position: 0,
                            duration: const Duration(milliseconds: 600),
                            child: SlideAnimation(
                              horizontalOffset: -50.0,
                              child: FadeInAnimation(
                                child: IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.arrow_back_ios,
                                    color: AppTheme.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Header con diseño especial para admin
                          AnimationConfiguration.staggeredList(
                            position: 1,
                            duration: const Duration(milliseconds: 800),
                            child: SlideAnimation(
                              verticalOffset: -30.0,
                              child: FadeInAnimation(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Logo especial para admin
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primaryRed
                                                .withOpacity(0.4),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.admin_panel_settings_outlined,
                                        size: 50,
                                        color: AppTheme.white,
                                      ),
                                    ),

                                    const SizedBox(height: 32),

                                    Text(
                                      'Administrador',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineLarge
                                          ?.copyWith(
                                            color: AppTheme.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      'Acceso exclusivo para administradores del sistema',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: AppTheme.greyLight,
                                          ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Badge de seguridad
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryRed
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppTheme.primaryRed
                                              .withOpacity(0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.security,
                                            size: 16,
                                            color: AppTheme.primaryRed,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Acceso Seguro',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppTheme.primaryRed,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 50),

                          // Formulario
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Email
                                AnimationConfiguration.staggeredList(
                                  position: 2,
                                  duration: const Duration(milliseconds: 600),
                                  child: SlideAnimation(
                                    horizontalOffset: -30.0,
                                    child: FadeInAnimation(
                                      child: CustomTextField(
                                        controller: _emailController,
                                        label: 'Correo de administrador',
                                        hint: 'admin@sistema.com',
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        prefixIcon:
                                            Icons.admin_panel_settings_outlined,
                                        validator: (value) {
                                          if (value?.isEmpty ?? true) {
                                            return 'Ingresa tu correo de administrador';
                                          }
                                          if (!value!.contains('@')) {
                                            return 'Ingresa un correo válido';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Contraseña
                                AnimationConfiguration.staggeredList(
                                  position: 3,
                                  duration: const Duration(milliseconds: 600),
                                  child: SlideAnimation(
                                    horizontalOffset: 30.0,
                                    child: FadeInAnimation(
                                      child: CustomTextField(
                                        controller: _passwordController,
                                        label: 'Contraseña de administrador',
                                        hint: 'Tu contraseña segura',
                                        isPassword: true,
                                        isPasswordVisible: _isPasswordVisible,
                                        prefixIcon: Icons.security,
                                        suffixIcon: _isPasswordVisible
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        onSuffixTap: () {
                                          setState(() {
                                            _isPasswordVisible =
                                                !_isPasswordVisible;
                                          });
                                        },
                                        validator: (value) {
                                          if (value?.isEmpty ?? true) {
                                            return 'Ingresa tu contraseña';
                                          }
                                          if (value!.length <
                                              AppConstants.minPasswordLength) {
                                            return 'Contraseña muy corta';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Enlace de recuperación
                                AnimationConfiguration.staggeredList(
                                  position: 4,
                                  duration: const Duration(milliseconds: 500),
                                  child: FadeInAnimation(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          // TODO: Implementar recuperación de contraseña para admin
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Contacta al super administrador para recuperar tu contraseña'),
                                              backgroundColor: AppTheme.warning,
                                            ),
                                          );
                                        },
                                        child: Text(
                                          '¿Olvidaste tu contraseña?',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppTheme.primaryRed,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 40),

                                // Botón de login
                                AnimationConfiguration.staggeredList(
                                  position: 5,
                                  duration: const Duration(milliseconds: 600),
                                  child: SlideAnimation(
                                    verticalOffset: 30.0,
                                    child: FadeInAnimation(
                                      child: CustomButton(
                                        text: 'Acceder al Sistema',
                                        onPressed: _handleLogin,
                                        isLoading: _isLoading,
                                        gradient: AppTheme.primaryGradient,
                                        icon: Icons.login,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 40),

                                // Advertencia de seguridad
                                AnimationConfiguration.staggeredList(
                                  position: 6,
                                  duration: const Duration(milliseconds: 500),
                                  child: FadeInAnimation(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color:
                                            AppTheme.warning.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color:
                                              AppTheme.warning.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.warning_outlined,
                                            color: AppTheme.warning,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Solo personal autorizado. Todos los accesos son monitoreados.',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: AppTheme.warning,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
