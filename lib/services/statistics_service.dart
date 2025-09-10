import 'package:supabase_flutter/supabase_flutter.dart';

class StatisticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene el resumen general de estadísticas.
  /// Si el usuario es estudiante, devuelve sus propios datos.
  /// Si el usuario es admin, se puede traer datos agregados (ajustado en RLS).
  Future<Map<String, dynamic>?> getOverallStats(String userId) async {
    final response = await _supabase
        .from('stats_overall')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return response;
  }

  /// Obtiene estadísticas por categoría para un usuario.
  Future<List<Map<String, dynamic>>> getCategoryStats(String userId) async {
    final response = await _supabase
        .from('stats_by_category')
        .select()
        .eq('user_id', userId);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Obtiene el top 5 de estudiantes (solo admin).
  Future<List<Map<String, dynamic>>> getTopStudents() async {
    final response = await _supabase.from('stats_top_students').select();

    return List<Map<String, dynamic>>.from(response);
  }

  /// Obtiene tendencias de respuestas por día para un usuario.
  Future<List<Map<String, dynamic>>> getTrends(String userId) async {
    final response = await _supabase
        .from('stats_trends')
        .select()
        .eq('user_id', userId)
        .order('day', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }
}
