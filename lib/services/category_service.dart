import 'package:carvajal_autotech/core/models/question_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';

class CategoryService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Crear una categoría (solo admins)
  Future<Category?> createCategory({
    required String name,
    required String description,
    required String createdBy, // ID del admin
  }) async {
    try {
      final response = await _client
          .from('categories')
          .insert({
            'name': name,
            'description': description,
            'created_by': createdBy,
          })
          .select()
          .single();

      return Category.fromJson(response);
    } catch (e) {
      print('❌ Error creando categoría: $e');
      return null;
    }
  }

  /// Obtener todas las categorías activas (estudiantes)
  Future<List<Category>> getActiveCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select(
              '*, question_count:category_question_count(question_count), student_count:category_student_count(student_count)')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      print('✅ Categorías activas obtenidas:');
      print(response);

      return (response as List)
          .map((json) => Category.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo categorías: $e');
      return [];
    }
  }

  /// Obtener todas las categorías (solo admins)
  Future<List<Category>> getAllCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select(
              '*, question_count:category_question_count(question_count), student_count:category_student_count(student_count)')
          .order('created_at', ascending: false);

      print('✅ Todas las categorías obtenidas:');
      print(response);

      return (response as List)
          .map((json) => Category.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo categorías (admin): $e');
      return [];
    }
  }

  /// Actualizar nombre/descrición de la categoría
  Future<bool> updateCategory({
    required String categoryId,
    required String name,
    required String description,
  }) async {
    try {
      await _client.from('categories').update({
        'name': name,
        'description': description,
      }).eq('id', categoryId);

      return true;
    } catch (e) {
      print('❌ Error actualizando categoría: $e');
      return false;
    }
  }

  /// Activar o desactivar categoría
  Future<bool> toggleCategoryActive({
    required String categoryId,
    required bool isActive,
  }) async {
    try {
      await _client.from('categories').update({
        'is_active': isActive,
      }).eq('id', categoryId);

      return true;
    } catch (e) {
      print('❌ Error cambiando estado de categoría: $e');
      return false;
    }
  }

  /// Eliminar una categoría
  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _client.from('categories').delete().eq('id', categoryId);
      return true;
    } catch (e) {
      print('❌ Error eliminando categoría: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchCategoriesWithProgress(
      String studentId) async {
    try {
      final client = Supabase.instance.client;

      print(
          '🔍 Iniciando consulta para progreso del estudiante con ID: $studentId');

      // Consulta para obtener el progreso del estudiante en cada categoría
      final response = await client.rpc('get_student_progress', params: {
        'student_id': studentId,
      });

      print('✅ Respuesta de la base de datos: $response');

      if (response == null || response.isEmpty) {
        print(
            '⚠️ No se encontraron categorías con progreso para el estudiante.');
        return [];
      }

      // Procesar los datos obtenidos
      final categoriesWithProgress = (response as List).map((item) {
        print('🔹 Procesando categoría: $item');
        return {
          'id': item['category_id'],
          'name': item['category_name'] ?? 'Sin nombre',
          'description': item['category_description'] ?? 'Sin descripción',
          'questionCount': item['total_questions'] ?? 0,
          'completed': item['answered_questions'] ?? 0,
        };
      }).toList();

      print('✅ Categorías procesadas con progreso: $categoriesWithProgress');

      return categoriesWithProgress;
    } catch (e) {
      print("❌ Error cargando categorías con progreso: $e");
      return [];
    }
  }
}
