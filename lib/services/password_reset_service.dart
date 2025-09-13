import 'package:supabase/supabase.dart';
import 'package:flutter/material.dart';

class PasswordResetService {
  final SupabaseClient supabase;
  final String serviceRoleKey;

  PasswordResetService(String supabaseUrl, this.serviceRoleKey)
      : supabase = SupabaseClient(supabaseUrl, serviceRoleKey);

  /// Aprueba la solicitud y actualiza la contraseña en Supabase Auth
  Future<void> approveRequest({
    required String userId, // UUID del usuario en Supabase Auth
    required String newPassword,
    required int requestId,
    required String adminId, // UUID del admin
  }) async {
    // 1. Actualiza la contraseña en Supabase Auth
    final response = await supabase.auth.admin.updateUserById(
      userId,
      attributes: AdminUserAttributes(password: newPassword),
    );
    if (response.user == null) {
      throw Exception('Error actualizando contraseña: ${response.toString()}');
    }

    // 2. Actualiza la solicitud en la base de datos
    final updateResponse =
        await supabase.from('password_reset_requests').update({
      'status': 'approved',
      'admin_id': adminId,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);

    if (updateResponse.error != null) {
      throw Exception(
          'Error actualizando solicitud: ${updateResponse.error!.message}');
    }
  }

  /// Rechaza la solicitud
  Future<void> rejectRequest({
    required int requestId,
    required String adminId,
  }) async {
    final updateResponse =
        await supabase.from('password_reset_requests').update({
      'status': 'rejected',
      'admin_id': adminId,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
    if (updateResponse.error != null) {
      throw Exception(
          'Error actualizando solicitud: ${updateResponse.error!.message}');
    }
  }
}
