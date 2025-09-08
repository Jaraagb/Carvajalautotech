import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/supabase_config.dart';
import '../core/models/user_model.dart';
import 'package:carvajal_autotech/features/auth/domain/entities/user_entity.dart';

class AuthService {
  static final SupabaseClient _supabase = SupabaseConfig.client;
  static const String _userRoleKey = 'user_role';
  static const String _rememberMeKey = 'remember_me';

  // Login con email y contraseña
  static Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
    required UserRole expectedRole,
    bool rememberMe = false,
  }) async {
    try {
      // 1. Autenticar con Supabase
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return AuthResult.error('Error en la autenticación');
      }

      // 2. Obtener datos adicionales del usuario desde tu tabla personalizada
      final userData = await _getUserProfile(response.user!.id);

      if (userData == null) {
        return AuthResult.error('Perfil de usuario no encontrado');
      }

      final userModel = UserModel.fromJson({
        'id': response.user!.id,
        'email': response.user!.email!,
        ...userData,
      });

      // 3. Verificar rol
      if (userModel.role != expectedRole) {
        await signOut(); // Cerrar sesión si el rol no coincide
        return AuthResult.error(expectedRole == UserRole.admin
            ? 'Este usuario no tiene permisos de administrador'
            : 'Este usuario no es un estudiante');
      }

      // 4. Verificar si la cuenta está activa
      if (!userModel.isActive) {
        await signOut();
        return AuthResult.error(
            'Tu cuenta está desactivada. Contacta al administrador.');
      }

      // 5. Guardar preferencias
      await _saveUserPreferences(userModel.role, rememberMe);

      return AuthResult.success(userModel);
    } on AuthException catch (e) {
      return AuthResult.error(_getErrorMessage(e.message));
    } catch (e) {
      return AuthResult.error('Error inesperado: ${e.toString()}');
    }
  }

  // Registro de estudiante
  static Future<AuthResult> signUpStudent({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      // 1. Crear usuario en Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return AuthResult.error('Error al crear la cuenta');
      }

      // 2. Crear perfil en tabla personalizada
      await _supabase.from('user_profiles').insert({
        'id': response.user!.id,
        'email': email,
        'role': 'student',
        'first_name': firstName,
        'last_name': lastName,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      final userModel = UserModel(
        id: response.user!.id,
        email: email,
        role: UserRole.student,
        firstName: firstName,
        lastName: lastName,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _saveUserPreferences(UserRole.student, false);

      return AuthResult.success(userModel);
    } on AuthException catch (e) {
      return AuthResult.error(_getErrorMessage(e.message));
    } catch (e) {
      return AuthResult.error('Error inesperado: ${e.toString()}');
    }
  }

  // Obtener usuario actual
  static Future<UserModel?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final userData = await _getUserProfile(user.id);
      if (userData == null) return null;

      return UserModel.fromJson({
        'id': user.id,
        'email': user.email!,
        ...userData,
      });
    } catch (e) {
      return null;
    }
  }

  // Cerrar sesión
  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await _clearUserPreferences();
    } catch (e) {
      // Silenciar errores de logout
    }
  }

  // Recuperar contraseña
  static Future<AuthResult> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return AuthResult.success(null,
          message: 'Se ha enviado un enlace de recuperación a tu correo');
    } on AuthException catch (e) {
      return AuthResult.error(_getErrorMessage(e.message));
    } catch (e) {
      return AuthResult.error('Error inesperado: ${e.toString()}');
    }
  }

  // Actualizar perfil
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

      await _supabase.from('users').update({
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      }).eq('id', user.id);

      return AuthResult.success(null,
          message: 'Perfil actualizado correctamente');
    } catch (e) {
      return AuthResult.error('Error al actualizar perfil: ${e.toString()}');
    }
  }

  // Cambiar contraseña
  static Future<AuthResult> changePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      return AuthResult.success(null,
          message: 'Contraseña actualizada correctamente');
    } on AuthException catch (e) {
      return AuthResult.error(_getErrorMessage(e.message));
    } catch (e) {
      return AuthResult.error('Error al cambiar contraseña: ${e.toString()}');
    }
  }

  // Verificar si está autenticado
  static bool get isAuthenticated => _supabase.auth.currentUser != null;

  // Stream de cambios de autenticación
  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  // Métodos privados
  static Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }

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

  static String _getErrorMessage(String? error) {
    if (error == null) return 'Error desconocido';

    // Personalizar mensajes de error
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

    return error;
  }
}

// Clase para resultados de autenticación
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
