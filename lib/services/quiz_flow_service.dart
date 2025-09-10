// import 'package:supabase_flutter/supabase_flutter.dart';

// class QuizStatus {
//   final bool hasUnanswered;
//   final bool allAnswered;
//   final bool published;

//   QuizStatus({
//     required this.hasUnanswered,
//     required this.allAnswered,
//     required this.published,
//   });
// }

// class QuizFlowService {
//   final SupabaseClient _client = Supabase.instance.client;

//   Future<QuizStatus> getQuizStatus(String categoryId) async {
//     final user = _client.auth.currentUser;
//     if (user == null) {
//       throw Exception("Usuario no autenticado");
//     }

//     try {
//       // 1. Total preguntas de la categoría
//       final totalQuestionsRes = await _client
//           .from('questions')
//           .select('id')
//           .eq('category_id', categoryId);

//       final totalQuestions = (totalQuestionsRes as List).length;

//       // 2. Total respondidas por este estudiante en esa categoría
//       final answeredRes = await _client
//           .from('student_answers')
//           .select('id, question_id')
//           .eq('student_id', user.id)
//           .in_('question_id',
//               (totalQuestionsRes as List).map((q) => q['id']).toList());

//       final answered = (answeredRes as List).length;

//       // 3. Estado publicado
//       final publishRes = await _client
//           .from('student_results_publish')
//           .select('published')
//           .eq('student_id', user.id)
//           .maybeSingle();

//       final published = publishRes?['published'] == true;

//       final hasUnanswered = answered < totalQuestions;
//       final allAnswered = !hasUnanswered;

//       return QuizStatus(
//         hasUnanswered: hasUnanswered,
//         allAnswered: allAnswered,
//         published: published,
//       );
//     } on PostgrestException catch (e) {
//       throw Exception("❌ Error en Supabase: ${e.message}");
//     } catch (e) {
//       throw Exception("❌ Error en getQuizStatus: $e");
//     }
//   }
// }
