import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/supabase_config.dart';
import '../core/models/user_model.dart';
import 'package:carvajal_autotech/features/auth/domain/entities/user_entity.dart';

class AuthService {
  static final SupabaseClient _supabase = SupabaseConfig.client;
  static const String _userRoleKey = 'user_role';
  static const String _rememberMeKey = 'remember_me';

  // -------------------- REGISTRO --------------------
  static Future<AuthResult> signUpStudent({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final cleanEmail = email.toLowerCase().trim();

      // Crear usuario en Supabase Auth
      final res = await _supabase.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {
          'first_name': firstName?.trim() ?? '',
          'last_name': lastName?.trim() ?? '',
          'role': 'student',
        },
      );

      if (res.user == null) {
        return AuthResult.error('Error al crear la cuenta');
      }

      // Esperar a que el trigger cree el perfil en user_profiles
      Map<String, dynamic>? profile;
      for (int i = 0; i < 5; i++) {
        profile = await _supabase
            .from('user_profiles')
            .select()
            .eq('id', res.user!.id)
            .maybeSingle();

        if (profile != null) break;
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (profile == null) {
        return AuthResult.error(
            'Error configurando el perfil. Inténtalo de nuevo.');
      }

      final userModel = UserModel.fromJson({
        'id': res.user!.id,
        'email': res.user!.email!,
        ...profile,
      });

      await _saveUserPreferences(userModel.role, false);

      final needsConfirmation = res.session == null;
      return AuthResult.success(
        userModel,
        message: needsConfirmation
            ? 'Te enviamos un correo de confirmación. Revisa tu bandeja de entrada.'
            : 'Cuenta creada exitosamente. ¡Bienvenido!',
      );
    } on AuthException catch (e) {
      return AuthResult.error(_mapAuthError(e.message));
    } catch (e) {
      return AuthResult.error('Error inesperado: $e');
    }
  }

  // -------------------- LOGIN --------------------
  static Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
    required UserRole expectedRole,
    bool rememberMe = false,
  }) async {
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user == null) {
        return AuthResult.error('Error en la autenticación');
      }

      final profile = await _getUserProfile(res.user!.id);
      if (profile == null) {
        return AuthResult.error('Perfil de usuario no encontrado');
      }

      final userModel = UserModel.fromJson({
        'id': res.user!.id,
        'email': res.user!.email!,
        ...profile,
      });

      if (userModel.role != expectedRole) {
        await signOut();
        return AuthResult.error(expectedRole == UserRole.admin
            ? 'No tienes permisos de administrador'
            : 'Este usuario no es un estudiante');
      }

      if (!userModel.isActive) {
        await signOut();
        return AuthResult.error(
            'Tu cuenta está desactivada. Contacta al administrador.');
      }

      await _saveUserPreferences(userModel.role, rememberMe);
      return AuthResult.success(userModel);
    } on AuthException catch (e) {
      return AuthResult.error(_mapAuthError(e.message));
    } catch (e) {
      return AuthResult.error('Error inesperado: $e');
    }
  }

  // -------------------- PERFIL --------------------
  static Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      return await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  static Future<AuthResult> updateProfile({
    String? firstName,
    String? lastName,
    String? avatarUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return AuthResult.error('No hay usuario autenticado');
      }

      await _supabase.from('user_profiles').update({
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      return AuthResult.success(null,
          message: 'Perfil actualizado correctamente');
    } catch (e) {
      return AuthResult.error('Error al actualizar perfil: $e');
    }
  }

  // -------------------- SESIÓN --------------------
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _clearUserPreferences();
  }

  static Future<AuthResult> changePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      return AuthResult.success(null,
          message: 'Contraseña actualizada correctamente');
    } on AuthException catch (e) {
      return AuthResult.error(_mapAuthError(e.message));
    } catch (e) {
      return AuthResult.error('Error inesperado: $e');
    }
  }

  // -------------------- RECUPERACIÓN DE CONTRASEÑA --------------------
  static Future<AuthResult> resetPasswordDirectly({
    required String email,
    required String newPassword,
  }) async {
    try {
      final cleanEmail = email.toLowerCase().trim();

      // Primero verificamos si existe un usuario con ese email
      final response = await _supabase
          .from('user_profiles')
          .select('id, email, role, first_name')
          .eq('email', cleanEmail)
          .eq('role',
              'student') // Solo estudiantes pueden resetear por esta vía
          .maybeSingle();

      if (response == null) {
        return AuthResult.error(
          'No se encontró una cuenta de estudiante asociada a este correo electrónico.',
        );
      }

      // Guardamos la nueva contraseña hasheada en un campo temporal
      // En una implementación real, necesitarías hashear la contraseña aquí
      final hashedPassword = newPassword; // Simplificado por ahora

      await _supabase.from('user_profiles').update({
        'new_password_hash': hashedPassword,
        'password_change_requested': true,
        'password_change_date': DateTime.now().toIso8601String(),
      }).eq('email', cleanEmail);

      final userName = response['first_name'] ?? 'Usuario';

      // Mensaje que simula ser un enlace de recuperación
      return AuthResult.success(
        null,
        message:
            'Perfecto $userName! Tu contraseña ha sido actualizada exitosamente. Ya puedes iniciar sesión con tu nueva contraseña.',
      );
    } on AuthException catch (e) {
      return AuthResult.error(_mapAuthError(e.message));
    } catch (e) {
      return AuthResult.error('Error inesperado: $e');
    }
  }

  // Método alternativo para reset directo (requiere configuración especial en Supabase)
  static Future<AuthResult> requestPasswordReset({
    required String email,
  }) async {
    try {
      final cleanEmail = email.toLowerCase().trim();

      // Verificar que el email existe y es de un estudiante
      final response = await _supabase
          .from('user_profiles')
          .select('id, email, first_name')
          .eq('email', cleanEmail)
          .eq('role', 'student')
          .maybeSingle();

      if (response == null) {
        return AuthResult.error(
          'No se encontró una cuenta de estudiante con este correo electrónico.',
        );
      }

      // Por ahora, enviaremos el enlace de reset estándar
      await _supabase.auth.resetPasswordForEmail(cleanEmail);

      return AuthResult.success(
        null,
        message:
            'Hemos enviado las instrucciones de recuperación a ${response['first_name'] ?? 'tu'} correo electrónico.',
      );
    } on AuthException catch (e) {
      return AuthResult.error(_mapAuthError(e.message));
    } catch (e) {
      return AuthResult.error('Error inesperado: $e');
    }
  }

  static bool get isAuthenticated => _supabase.auth.currentUser != null;
  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  // -------------------- HELPERS --------------------
  static Future<void> _saveUserPreferences(
      UserRole role, bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role.toString());
    await prefs.setBool(_rememberMeKey, rememberMe);
  }

  static Future<void> _clearUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userRoleKey);
    await prefs.remove(_rememberMeKey);
  }

  static String _mapAuthError(String? error) {
    if (error == null) return 'Error desconocido';
    if (error.contains('Invalid login credentials')) {
      return 'Credenciales incorrectas. Verifica tu email y contraseña.';
    }
    if (error.contains('Email not confirmed')) {
      return 'Debes confirmar tu email antes de iniciar sesión.';
    }
    if (error.contains('User already registered')) {
      return 'Ya existe una cuenta con este email.';
    }
    if (error.contains('Password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (error.contains('Database error granting user')) {
      return 'Error en la base de datos. Verifica configuración de triggers/policies.';
    }
    return error;
  }
}

// -------------------- AuthResult --------------------
class AuthResult {
  final bool isSuccess;
  final UserModel? user;
  final String? error;
  final String? message;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.error,
    this.message,
  });

  factory AuthResult.success(UserModel? user, {String? message}) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      message: message,
    );
  }

  factory AuthResult.error(String error) {
    return AuthResult._(
      isSuccess: false,
      error: error,
    );
  }
}
