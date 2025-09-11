import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:carvajal_autotech/services/auth_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
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
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.resetPasswordDirectly(
        email: _emailController.text.trim(),
        newPassword: _passwordController.text,
      );

      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(result.message ?? 'Contraseña actualizada exitosamente'),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 5),
            ),
          );

          // Mostrar un diálogo con información de éxito
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.lightBlack,
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.success),
                  SizedBox(width: 8),
                  Text('¡Contraseña Actualizada!',
                      style: TextStyle(color: AppTheme.white)),
                ],
              ),
              content: Text(
                'Tu contraseña ha sido cambiada exitosamente.\n\nYa puedes iniciar sesión con tu nueva contraseña en ${_emailController.text.trim()}.',
                style: const TextStyle(color: AppTheme.greyLight),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Cerrar diálogo
                    Navigator.of(context).pushReplacementNamed(
                      AppConstants.studentLoginRoute,
                    );
                  },
                  child: const Text('Ir a Iniciar Sesión',
                      style: TextStyle(color: AppTheme.info)),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(result.error ?? 'Error al actualizar la contraseña'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
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

                          // Icono principal
                          AnimationConfiguration.staggeredList(
                            position: 1,
                            duration: const Duration(milliseconds: 800),
                            child: SlideAnimation(
                              verticalOffset: -30.0,
                              child: FadeInAnimation(
                                child: Center(
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.success,
                                          AppTheme.success.withOpacity(0.8)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(50),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              AppTheme.success.withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.lock_person_outlined,
                                      size: 50,
                                      color: AppTheme.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Header
                          AnimationConfiguration.staggeredList(
                            position: 2,
                            duration: const Duration(milliseconds: 800),
                            child: SlideAnimation(
                              verticalOffset: -30.0,
                              child: FadeInAnimation(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Reestablecer Contraseña',
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
                                      'Ingresa tu correo electrónico y la nueva contraseña que deseas usar. Te enviaremos un enlace seguro para completar el cambio.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: AppTheme.greyLight,
                                            height: 1.5,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Formulario
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Email
                                AnimationConfiguration.staggeredList(
                                  position: 3,
                                  duration: const Duration(milliseconds: 600),
                                  child: SlideAnimation(
                                    horizontalOffset: -30.0,
                                    child: FadeInAnimation(
                                      child: CustomTextField(
                                        controller: _emailController,
                                        label: 'Correo electrónico',
                                        hint: 'estudiante@email.com',
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        prefixIcon: Icons.email_outlined,
                                        validator: (value) {
                                          if (value?.isEmpty ?? true) {
                                            return 'Ingresa tu correo electrónico';
                                          }
                                          if (!RegExp(
                                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                              .hasMatch(value!)) {
                                            return 'Ingresa un correo válido';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Nueva Contraseña
                                AnimationConfiguration.staggeredList(
                                  position: 4,
                                  duration: const Duration(milliseconds: 600),
                                  child: SlideAnimation(
                                    horizontalOffset: -30.0,
                                    child: FadeInAnimation(
                                      child: CustomTextField(
                                        controller: _passwordController,
                                        label: 'Nueva contraseña',
                                        hint: 'Mínimo 6 caracteres',
                                        isPassword: true,
                                        isPasswordVisible: _isPasswordVisible,
                                        prefixIcon: Icons.lock_outlined,
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
                                            return 'Ingresa una contraseña';
                                          }
                                          if (value!.length <
                                              AppConstants.minPasswordLength) {
                                            return 'La contraseña debe tener al menos ${AppConstants.minPasswordLength} caracteres';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Confirmar Contraseña
                                AnimationConfiguration.staggeredList(
                                  position: 5,
                                  duration: const Duration(milliseconds: 600),
                                  child: SlideAnimation(
                                    horizontalOffset: 30.0,
                                    child: FadeInAnimation(
                                      child: CustomTextField(
                                        controller: _confirmPasswordController,
                                        label: 'Confirmar nueva contraseña',
                                        hint: 'Repite tu nueva contraseña',
                                        isPassword: true,
                                        isPasswordVisible:
                                            _isConfirmPasswordVisible,
                                        prefixIcon: Icons.lock_outlined,
                                        suffixIcon: _isConfirmPasswordVisible
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        onSuffixTap: () {
                                          setState(() {
                                            _isConfirmPasswordVisible =
                                                !_isConfirmPasswordVisible;
                                          });
                                        },
                                        validator: (value) {
                                          if (value?.isEmpty ?? true) {
                                            return 'Confirma tu nueva contraseña';
                                          }
                                          if (value !=
                                              _passwordController.text) {
                                            return 'Las contraseñas no coinciden';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Consejos de seguridad
                                AnimationConfiguration.staggeredList(
                                  position: 6,
                                  duration: const Duration(milliseconds: 500),
                                  child: FadeInAnimation(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.info.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.info.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.lightbulb_outline,
                                                color: AppTheme.info,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Consejos de seguridad:',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: AppTheme.info,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '• Usa al menos 8 caracteres\n• Incluye mayúsculas y minúsculas\n• Agrega números y símbolos\n• No uses información personal',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppTheme.greyLight,
                                                  height: 1.4,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Botón de actualizar
                                AnimationConfiguration.staggeredList(
                                  position: 7,
                                  duration: const Duration(milliseconds: 600),
                                  child: SlideAnimation(
                                    verticalOffset: 30.0,
                                    child: FadeInAnimation(
                                      child: CustomButton(
                                        text: 'Enviar Enlace de Recuperación',
                                        onPressed: _handleResetPassword,
                                        isLoading: _isLoading,
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.warning,
                                            AppTheme.warning.withOpacity(0.8)
                                          ],
                                        ),
                                        icon: Icons.send_outlined,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Volver a login
                                AnimationConfiguration.staggeredList(
                                  position: 8,
                                  duration: const Duration(milliseconds: 600),
                                  child: FadeInAnimation(
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pushReplacementNamed(
                                          AppConstants.studentLoginRoute,
                                        );
                                      },
                                      child: Text(
                                        'Volver al inicio de sesión',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppTheme.info,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
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
