import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:carvajal_autotech/features/auth/domain/entities/user_entity.dart';
import 'package:carvajal_autotech/services/auth_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class StudentRegisterScreen extends StatefulWidget {
  const StudentRegisterScreen({Key? key}) : super(key: key);

  @override
  State<StudentRegisterScreen> createState() => _StudentRegisterScreenState();
}

class _StudentRegisterScreenState extends State<StudentRegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;

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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Iniciando registro...'); // Debug
      print('Email: ${_emailController.text.trim()}'); // Debug

      final result = await AuthService.signUpStudent(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim().isEmpty
            ? null
            : _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty
            ? null
            : _lastNameController.text.trim(),
      );

      print('Resultado: ${result.isSuccess}'); // Debug
      if (!result.isSuccess) {
        print('Error: ${result.error}'); // Debug
      }

      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '¡Cuenta creada exitosamente! Revisa tu email para confirmar tu cuenta.'),
              backgroundColor: AppTheme.success,
            ),
          );

          Navigator.of(context).pushReplacementNamed(
            AppConstants.studentLoginRoute,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Error al crear la cuenta'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      print('Exception: $e'); // Debug
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

                          // Header
                          AnimationConfiguration.staggeredList(
                            position: 1,
                            duration: const Duration(milliseconds: 800),
                            child: SlideAnimation(
                              verticalOffset: -30.0,
                              child: FadeInAnimation(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Crear Cuenta',
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
                                      'Completa los datos para crear tu cuenta de estudiante',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: AppTheme.greyLight,
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
                                // Nombre y Apellido (fila)
                                AnimationConfiguration.staggeredList(
                                  position: 2,
                                  duration: const Duration(milliseconds: 600),
                                  child: SlideAnimation(
                                    horizontalOffset: -30.0,
                                    child: FadeInAnimation(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: CustomTextField(
                                              controller: _firstNameController,
                                              label: 'Nombre',
                                              hint: 'Tu nombre',
                                              prefixIcon: Icons.person_outline,
                                              validator: (value) {
                                                if (value?.isEmpty ?? true) {
                                                  return 'Ingresa tu nombre';
                                                }
                                                if (value!.length < 2) {
                                                  return 'Nombre muy corto';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: CustomTextField(
                                              controller: _lastNameController,
                                              label: 'Apellido',
                                              hint: 'Tu apellido',
                                              prefixIcon: Icons.person_outline,
                                              validator: (value) {
                                                if (value?.isEmpty ?? true) {
                                                  return 'Ingresa tu apellido';
                                                }
                                                if (value!.length < 2) {
                                                  return 'Apellido muy corto';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Email
                                AnimationConfiguration.staggeredList(
                                  position: 3,
                                  duration: const Duration(milliseconds: 600),
                                  child: SlideAnimation(
                                    horizontalOffset: 30.0,
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

                                // Contraseña
                                AnimationConfiguration.staggeredList(
                                  position: 4,
                                  duration: const Duration(milliseconds: 600),
                                  child: SlideAnimation(
                                    horizontalOffset: -30.0,
                                    child: FadeInAnimation(
                                      child: CustomTextField(
                                        controller: _passwordController,
                                        label: 'Contraseña',
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
                                        label: 'Confirmar contraseña',
                                        hint: 'Repite tu contraseña',
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
                                            return 'Confirma tu contraseña';
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

                                const SizedBox(height: 24),

                                // Términos y condiciones
                                AnimationConfiguration.staggeredList(
                                  position: 6,
                                  duration: const Duration(milliseconds: 500),
                                  child: FadeInAnimation(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: Checkbox(
                                            value: _acceptTerms,
                                            onChanged: (value) {
                                              setState(() {
                                                _acceptTerms = value ?? false;
                                              });
                                            },
                                            activeColor: AppTheme.info,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Acepto los términos y condiciones y la política de privacidad',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: AppTheme.greyLight,
                                                    ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  // TODO: Mostrar términos y condiciones
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Términos y condiciones próximamente'),
                                                      backgroundColor:
                                                          AppTheme.info,
                                                    ),
                                                  );
                                                },
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  minimumSize: Size.zero,
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                                child: Text(
                                                  'Leer términos completos',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: AppTheme.info,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
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

                                const SizedBox(height: 32),

                                // Botón de registro
                                AnimationConfiguration.staggeredList(
                                  position: 7,
                                  duration: const Duration(milliseconds: 600),
                                  child: SlideAnimation(
                                    verticalOffset: 30.0,
                                    child: FadeInAnimation(
                                      child: CustomButton(
                                        text: 'Crear Cuenta',
                                        onPressed: _handleRegister,
                                        isLoading: _isLoading,
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.info,
                                            AppTheme.info.withOpacity(0.8)
                                          ],
                                        ),
                                        icon: Icons.person_add_outlined,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Ya tienes cuenta
                                AnimationConfiguration.staggeredList(
                                  position: 8,
                                  duration: const Duration(milliseconds: 600),
                                  child: FadeInAnimation(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '¿Ya tienes cuenta? ',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppTheme.greyLight,
                                              ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pushReplacementNamed(
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
