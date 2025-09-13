import 'package:carvajal_autotech/services/auth_password_recovery_service.dart';
import '../../../../core/config/supabase_config.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

class PasswordRecoveryWithCodeScreen extends StatefulWidget {
  final String email;
  final String newPassword;

  const PasswordRecoveryWithCodeScreen({
    Key? key,
    required this.email,
    required this.newPassword,
  }) : super(key: key);

  @override
  State<PasswordRecoveryWithCodeScreen> createState() =>
      _PasswordRecoveryWithCodeScreenState();
}

class _PasswordRecoveryWithCodeScreenState
    extends State<PasswordRecoveryWithCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  late AuthPasswordRecoveryService _service;

  @override
  void initState() {
    super.initState();
    _service = AuthPasswordRecoveryService(
      supabaseUrl: SupabaseConfig.url,
      supabaseAnonKey: SupabaseConfig.anonKey,
    );
  }

  Future<void> _handleRecovery() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final code = _codeController.text.trim();
    final email = widget.email;
    final newPassword = widget.newPassword;

    final success =
        await _service.resetPasswordWithCode(email, code, newPassword);
    setState(() => _isLoading = false);

    if (success) {
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Código inválido o expirado. Intenta de nuevo.'),
          backgroundColor: AppTheme.error,
        ),
      );
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppConstants.studentLoginRoute,
                (route) => false,
              );
            },
            child: Text(
              'Ir a iniciar sesión',
              style: TextStyle(color: AppTheme.success),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Código'),
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
                Icons.verified_user_outlined,
                size: 80,
                color: AppTheme.success,
              ),
              const SizedBox(height: 24),
              Text(
                'Código de Verificación',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Hemos enviado un código OTP de 6 dígitos a:\n${widget.email}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.greyLight,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'El código expira en 60 segundos',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.warning,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Código de verificación',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security_outlined),
                  hintText: 'Ingresa el código de 6 dígitos',
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el código recibido por correo';
                  }
                  if (value.length < 6) {
                    return 'El código debe tener 6 dígitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Información sobre la nueva contraseña
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.info.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.info,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tu nueva contraseña será aplicada automáticamente al verificar el código.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.greyLight,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Verificar y Cambiar Contraseña'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _handleRecovery,
                ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Volver atrás',
                  style: TextStyle(color: AppTheme.greyLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
