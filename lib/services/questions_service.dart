import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carvajal_autotech/core/models/question_models.dart';

class QuestionsService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtener todas las preguntas (admin: solo las suyas, student: solo lectura)
  Future<List<Question>> getQuestions() async {
    try {
      final response = await _client
          .from('questions')
          .select('*')
          .order('created_at', ascending: false);

      final questions = (response as List)
          .map((q) => Question.fromJson(Map<String, dynamic>.from(q)))
          .toList();

      return questions;
    } on PostgrestException catch (e) {
      throw Exception('❌ Error obteniendo preguntas: ${e.message}');
    } catch (e) {
      throw Exception('❌ Error inesperado: $e');
    }
  }

  /// Obtener preguntas por categoría
  Future<List<Question>> getQuestionsByCategory(String categoryId) async {
    try {
      final response = await _client
          .from('questions')
          .select('*')
          .eq('category_id', categoryId)
          .order('created_at', ascending: false);

      final questions = (response as List)
          .map((q) => Question.fromJson(Map<String, dynamic>.from(q)))
          .toList();

      return questions;
    } on PostgrestException catch (e) {
      throw Exception(
          '❌ Error obteniendo preguntas por categoría: ${e.message}');
    } catch (e) {
      throw Exception('❌ Error inesperado: $e');
    }
  }

  /// Crear una nueva pregunta (solo admins)
  Future<Question> createQuestion(QuestionForm form) async {
    try {
      final response = await _client
          .from('questions')
          .insert({
            'category_id': form.categoryId,
            'type': form.type.name,
            'question': form.question,
            'options': form.options,
            'correct_answer': form.correctAnswer,
            'time_limit': form.timeLimit,
            'image_url': form.imageUrl, // 👈 nuevo
            'explanation': form.explanation,
            'created_by': _client.auth.currentUser!.id,
          })
          .select()
          .single();

      return Question.fromJson(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      throw Exception('❌ Error creando pregunta: ${e.message}');
    } catch (e) {
      throw Exception('❌ Error inesperado: $e');
    }
  }

  /// Actualizar pregunta (solo admins dueños de la pregunta)
  Future<Question> updateQuestion(QuestionForm form) async {
    if (form.id == null) {
      throw Exception('❌ ID requerido para actualizar la pregunta');
    }

    try {
      final response = await _client
          .from('questions')
          .update({
            'category_id': form.categoryId,
            'type': form.type.name,
            'question': form.question,
            'options': form.options,
            'correct_answer': form.correctAnswer,
            'time_limit': form.timeLimit,
            'image_url': form.imageUrl, // 👈 nuevo
            'explanation': form.explanation,
          })
          .eq('id', form.id!)
          .select()
          .single();

      return Question.fromJson(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      throw Exception('❌ Error actualizando pregunta: ${e.message}');
    } catch (e) {
      throw Exception('❌ Error inesperado: $e');
    }
  }

  /// Eliminar pregunta (solo admins dueños de la pregunta)
  Future<void> deleteQuestion(String questionId) async {
    try {
      await _client.from('questions').delete().eq('id', questionId);
    } on PostgrestException catch (e) {
      throw Exception('❌ Error eliminando pregunta: ${e.message}');
    } catch (e) {
      throw Exception('❌ Error inesperado: $e');
    }
  }

  /// Obtener pregunta por ID
  Future<Question> getQuestionById(String id) async {
    try {
      final response =
          await _client.from('questions').select('*').eq('id', id).single();

      return Question.fromJson(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      throw Exception('❌ Error obteniendo pregunta: ${e.message}');
    } catch (e) {
      throw Exception('❌ Error inesperado: $e');
    }
  }
}
