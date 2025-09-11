import 'package:supabase_flutter/supabase_flutter.dart';

class StudentService {
  final _client = Supabase.instance.client;

  Future<void> assignCategoryToStudent(
      String studentId, String categoryId) async {
    try {
      // Depuración: Verificar valores antes de la inserción
      print(
          'Intentando asignar categoría: studentId=$studentId, categoryId=$categoryId');

      // Verificar si la relación ya existe
      final existingRelation = await _client
          .from('student_categories')
          .select()
          .eq('student_id', studentId)
          .eq('category_id', categoryId)
          .maybeSingle();

      if (existingRelation != null) {
        // Si ya existe, no hacer nada
        print(
            'La relación ya existe: studentId=$studentId, categoryId=$categoryId');
        return;
      }

      // Insertar la nueva relación (published = false por defecto)
      await _client.from('student_categories').insert({
        'student_id': studentId,
        'category_id': categoryId,
        'published': false,
      });
      print(
          'Relación insertada exitosamente: studentId=$studentId, categoryId=$categoryId');
    } catch (e) {
      print('Error al asignar categoría: $e');
      throw Exception('Error al asignar categoría: $e');
    }
  }

  /// Publica o despublica las respuestas de una categoría específica para un estudiante
  Future<bool> toggleCategoryPublication(
      String studentId, String categoryId, bool publish) async {
    try {
      print(
          'Cambiando estado de publicación: studentId=$studentId, categoryId=$categoryId, publish=$publish');

      // Actualizar el campo published en student_categories
      final result = await _client
          .from('student_categories')
          .update({'published': publish})
          .eq('student_id', studentId)
          .eq('category_id', categoryId)
          .select('published')
          .single();

      print(
          'Estado de publicación actualizado exitosamente: ${result['published']}');
      return result['published'] as bool;
    } catch (e) {
      print('Error al cambiar estado de publicación: $e');
      throw Exception('Error al actualizar estado de publicación: $e');
    }
  }

  /// Obtiene el estado de publicación de todas las categorías de un estudiante
  Future<List<Map<String, dynamic>>> getStudentCategoryPublicationStatus(
      String studentId) async {
    try {
      final result = await _client
          .from('student_category_publication_status')
          .select()
          .eq('student_id', studentId)
          .order('category_name');

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('Error al obtener estado de publicación: $e');
      throw Exception('Error al obtener estado de publicación: $e');
    }
  }

  /// Obtiene las categorías publicadas para un estudiante (para la vista del estudiante)
  Future<List<Map<String, dynamic>>> getPublishedCategoriesForStudent(
      String studentId) async {
    try {
      final result = await _client
          .from('student_category_publication_status')
          .select()
          .eq('student_id', studentId)
          .eq('published', true)
          .order('category_name');

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('Error al obtener categorías publicadas: $e');
      throw Exception('Error al obtener categorías publicadas: $e');
    }
  }

  /// Método de prueba para verificar el estado actual de student_categories
  Future<List<Map<String, dynamic>>> debugStudentCategories(
      String studentId) async {
    try {
      final result = await _client
          .from('student_categories')
          .select('*, categories(name)')
          .eq('student_id', studentId);

      print('Estado actual de student_categories para $studentId:');
      for (final row in result) {
        print(
            '  Category: ${row['categories']?['name']} - Published: ${row['published']}');
      }

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('Error al obtener debug info: $e');
      throw Exception('Error al obtener debug info: $e');
    }
  }

  /// Método de prueba para publicar directamente una categoría
  Future<bool> debugTogglePublication(
      String studentId, String categoryId) async {
    try {
      // Primero verificar el estado actual
      final current = await _client
          .from('student_categories')
          .select('published')
          .eq('student_id', studentId)
          .eq('category_id', categoryId)
          .single();

      final currentPublished = current['published'] as bool;
      final newState = !currentPublished;

      print(
          'DEBUG: Cambiando de $currentPublished a $newState para student=$studentId, category=$categoryId');

      // Hacer el toggle
      final result = await _client
          .from('student_categories')
          .update({'published': newState})
          .eq('student_id', studentId)
          .eq('category_id', categoryId)
          .select('published')
          .single();

      final finalState = result['published'] as bool;
      print('DEBUG: Estado final: $finalState');

      return finalState;
    } catch (e) {
      print('ERROR en debug toggle: $e');
      throw Exception('Error en debug toggle: $e');
    }
  }
}
