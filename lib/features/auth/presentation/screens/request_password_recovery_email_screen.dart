import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../services/auth_password_recovery_service.dart';
import 'password_recovery_with_code_screen.dart';

class RequestPasswordRecoveryEmailScreen extends StatefulWidget {
  const RequestPasswordRecoveryEmailScreen({Key? key}) : super(key: key);

  @override
  State<RequestPasswordRecoveryEmailScreen> createState() =>
      _RequestPasswordRecoveryEmailScreenState();
}

class _RequestPasswordRecoveryEmailScreenState
    extends State<RequestPasswordRecoveryEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  late AuthPasswordRecoveryService _service;

  @override
  void initState() {
    super.initState();
    _service = AuthPasswordRecoveryService(
      supabaseUrl: SupabaseConfig.url,
      supabaseAnonKey: SupabaseConfig.anonKey,
    );
  }

  Future<void> _sendRecoveryEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final newPassword = _passwordController.text;

    try {
      final success = await _service.requestOtp(email);
      setState(() => _isLoading = false);

      if (success) {
        // Navegar a la pantalla de verificación de código pasando los datos
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PasswordRecoveryWithCodeScreen(
              email: email,
              newPassword: newPassword,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Error al enviar el código de verificación. Intenta de nuevo.'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: ${e.toString()}'),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperación de Contraseña'),
        backgroundColor: AppTheme.primaryBlack,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.lock_reset,
                size: 80,
                color: AppTheme.info,
              ),
              const SizedBox(height: 24),
              Text(
                'Recuperar Contraseña',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ingresa tu correo y nueva contraseña. Te enviaremos un código de verificación.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.greyLight,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Campo de email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu correo electrónico';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo de nueva contraseña
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa una nueva contraseña';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo de confirmar contraseña
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirmar nueva contraseña',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isConfirmPasswordVisible,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirma tu nueva contraseña';
                  }
                  if (value != _passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send_outlined),
                  label: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Enviar código de verificación'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.info,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _sendRecoveryEmail,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
