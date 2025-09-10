import 'package:supabase_flutter/supabase_flutter.dart';

class StudentAnswersService {
  final _client = Supabase.instance.client;

  Future<void> saveAnswer({
    required String questionId,
    required String answer,
    required bool isCorrect,
    required int timeSpent,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      // 1) Verificar si ya existe - evita duplicados y violaciones RLS por clave única
      final existing = await _client
          .from('student_answers')
          .select('id')
          .eq('question_id', questionId)
          .eq('student_id', user.id);

      if ((existing as List).isNotEmpty) {
        // Ya respondida: no intentar insertar de nuevo
        return;
      }

      // 2) Insertar la respuesta
      await _client.from('student_answers').insert({
        'question_id': questionId,
        'student_id': user.id,
        'answer': answer,
        'is_correct': isCorrect,
        'time_spent': timeSpent,
        'answered_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      // Re-lanzar con detalle para que el caller muestre snackbar si hace falta
      throw Exception('Postgrest error: ${e.message}');
    } catch (e) {
      throw Exception('Error guardando respuesta: $e');
    }
  }
}
