import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'package:carvajal_autotech/services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
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

      if (!mounted) return;

      if (result.isSuccess) {
        _showSuccessDialog();
      } else {
        _showErrorSnackBar(result.error ?? 'Error al cambiar la contraseña');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error de conexión: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 50,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¡Contraseña cambiada!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Tu contraseña ha sido actualizada exitosamente.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.greyLight,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Iniciar Sesión',
              onPressed: () {
                Navigator.of(context).pushReplacementNamed(
                  AppConstants.studentLoginRoute,
                );
              },
              gradient: LinearGradient(
                colors: [AppTheme.success, AppTheme.success.withOpacity(0.8)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlack, AppTheme.lightBlack],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 12,
                  bottom: math.max(24, keyboardHeight + 12),
                ),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Botón de volver
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios,
                              color: AppTheme.white,
                              size: 24,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Icono principal
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.success,
                                    AppTheme.success.withOpacity(0.8)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.success.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.lock_person_outlined,
                                size: 40,
                                color: AppTheme.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Header
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cambiar Contraseña',
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
                                'Ingresa tu email y nueva contraseña para cambiarla directamente.',
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

                          const SizedBox(height: 32),

                          // Formulario
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Email
                                CustomTextField(
                                  controller: _emailController,
                                  label: 'Correo electrónico',
                                  hint: 'estudiante@email.com',
                                  keyboardType: TextInputType.emailAddress,
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

                                const SizedBox(height: 16),

                                // Nueva Contraseña
                                CustomTextField(
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
                                      _isPasswordVisible = !_isPasswordVisible;
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

                                const SizedBox(height: 16),

                                // Confirmar Contraseña
                                CustomTextField(
                                  controller: _confirmPasswordController,
                                  label: 'Confirmar nueva contraseña',
                                  hint: 'Repite tu nueva contraseña',
                                  isPassword: true,
                                  isPasswordVisible: _isConfirmPasswordVisible,
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
                                    if (value != _passwordController.text) {
                                      return 'Las contraseñas no coinciden';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 24),

                                // Consejos de seguridad
                                Container(
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
                                                  fontWeight: FontWeight.w600,
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

                                const SizedBox(height: 24),

                                // Botón de actualizar
                                CustomButton(
                                  text: 'Cambiar Contraseña',
                                  onPressed: _handleResetPassword,
                                  isLoading: _isLoading,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.success,
                                      AppTheme.success.withOpacity(0.8)
                                    ],
                                  ),
                                  icon: Icons.check_circle_outline,
                                ),

                                const SizedBox(height: 16),

                                // Volver a login
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pushReplacementNamed(
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
                                          decoration: TextDecoration.underline,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
