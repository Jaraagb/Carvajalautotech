import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:carvajal_autotech/services/auth_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _emailSent = false;

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
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.requestPasswordReset(
        email: _emailController.text.trim(),
      );

      if (result.isSuccess) {
        setState(() {
          _emailSent = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(result.message ?? 'Instrucciones enviadas exitosamente'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Error al procesar la solicitud'),
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

  Widget _buildSuccessView() {
    return AnimationLimiter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono de éxito
          AnimationConfiguration.staggeredList(
            position: 0,
            duration: const Duration(milliseconds: 800),
            child: SlideAnimation(
              verticalOffset: -30.0,
              child: FadeInAnimation(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.success,
                        AppTheme.success.withOpacity(0.8)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.success.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 60,
                    color: AppTheme.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Título
          AnimationConfiguration.staggeredList(
            position: 1,
            duration: const Duration(milliseconds: 600),
            child: FadeInAnimation(
              child: Text(
                '¡Correo Enviado!',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Descripción
          AnimationConfiguration.staggeredList(
            position: 2,
            duration: const Duration(milliseconds: 600),
            child: FadeInAnimation(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Hemos enviado un enlace de recuperación a ${_emailController.text.trim()}.\n\nRevisa tu bandeja de entrada y haz clic en el enlace para reestablecer tu contraseña.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.greyLight,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Botones
          AnimationConfiguration.staggeredList(
            position: 3,
            duration: const Duration(milliseconds: 600),
            child: FadeInAnimation(
              child: Column(
                children: [
                  CustomButton(
                    text: 'Volver al Inicio de Sesión',
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed(
                        AppConstants.studentLoginRoute,
                      );
                    },
                    gradient: LinearGradient(
                      colors: [AppTheme.info, AppTheme.info.withOpacity(0.8)],
                    ),
                    icon: Icons.login_outlined,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _emailSent = false;
                        _emailController.clear();
                      });
                    },
                    child: Text(
                      'Enviar a otro correo',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.info,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return AnimationLimiter(
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
                          AppTheme.warning,
                          AppTheme.warning.withOpacity(0.8)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.warning.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_reset_outlined,
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
                      '¿Olvidaste tu contraseña?',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: AppTheme.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No te preocupes, ingresa tu correo electrónico y te enviaremos un enlace para reestablecer tu contraseña.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Ingresa tu correo electrónico';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value!)) {
                            return 'Ingresa un correo válido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Botón de enviar
                AnimationConfiguration.staggeredList(
                  position: 4,
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

                const SizedBox(height: 32),

                // Volver a login
                AnimationConfiguration.staggeredList(
                  position: 5,
                  duration: const Duration(milliseconds: 600),
                  child: FadeInAnimation(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿Recordaste tu contraseña? ',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.greyLight,
                                  ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed(
                              AppConstants.studentLoginRoute,
                            );
                          },
                          child: Text(
                            'Inicia sesión',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.info,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
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
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          48,
                      child:
                          _emailSent ? _buildSuccessView() : _buildFormView(),
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
