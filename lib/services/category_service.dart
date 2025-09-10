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
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

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
          .select()
          .order('created_at', ascending: false);

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
}
