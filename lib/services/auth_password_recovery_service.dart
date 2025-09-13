import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthPasswordRecoveryService {
  final String supabaseUrl;
  final String supabaseAnonKey;

  AuthPasswordRecoveryService(
      {required this.supabaseUrl, required this.supabaseAnonKey});

  /// Paso 0: Solicita un OTP al email del usuario
  Future<bool> requestOtp(String email) async {
    final url = Uri.parse('$supabaseUrl/auth/v1/otp');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseAnonKey,
      },
      body: jsonEncode({
        'email': email,
        'create_user': false,
      }),
    );

    if (response.statusCode == 200) {
      print('OTP enviado exitosamente a: $email');
      return true;
    } else {
      print('Error requestOtp: ${response.body}');
      return false;
    }
  }

  /// Paso 1: Verifica el código de recuperación y obtiene el access_token
  Future<String?> verifyRecoveryCode(String email, String code) async {
    final url = Uri.parse('$supabaseUrl/auth/v1/verify');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseAnonKey,
      },
      body: jsonEncode({
        'type': 'email',
        'email': email,
        'token': code,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'] as String?;
    } else {
      print('Error verifyRecoveryCode: ${response.body}');
      return null;
    }
  }

  /// Paso 2: Cambia la contraseña usando el access_token obtenido
  Future<bool> updatePasswordWithToken(
      String accessToken, String newPassword) async {
    final url = Uri.parse('$supabaseUrl/auth/v1/user');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'password': newPassword}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Error updatePasswordWithToken: ${response.body}');
      return false;
    }
  }

  /// Flujo completo: recibe el email, código y la nueva contraseña, realiza ambos pasos
  Future<bool> resetPasswordWithCode(
      String email, String code, String newPassword) async {
    try {
      print('Iniciando verificación de código para: $email');
      final accessToken = await verifyRecoveryCode(email, code);

      if (accessToken == null) {
        print('No se pudo obtener el access token');
        return false;
      }

      print('Access token obtenido, actualizando contraseña...');
      final result = await updatePasswordWithToken(accessToken, newPassword);

      if (result) {
        print('Contraseña actualizada exitosamente');
      } else {
        print('Error al actualizar la contraseña');
      }

      return result;
    } catch (e) {
      print('Error en resetPasswordWithCode: $e');
      return false;
    }
  }

  /// Flujo completo OTP: solicita OTP y luego verifica + cambia contraseña
  Future<bool> resetPasswordWithOtp(String email, String newPassword) async {
    try {
      print('Solicitando OTP para: $email');
      final otpSent = await requestOtp(email);

      if (!otpSent) {
        print('No se pudo enviar el OTP');
        return false;
      }

      print('OTP enviado exitosamente. El usuario debe ingresar el código.');
      return true;
    } catch (e) {
      print('Error en resetPasswordWithOtp: $e');
      return false;
    }
  }
}
