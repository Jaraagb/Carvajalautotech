import 'package:flutter/material.dart';
import '../services/student_service.dart';

/// Widget de prueba para mostrar el estado de publicación de categorías
class CategoryPublicationTestWidget extends StatefulWidget {
  final String studentId;

  const CategoryPublicationTestWidget({
    Key? key,
    required this.studentId,
  }) : super(key: key);

  @override
  State<CategoryPublicationTestWidget> createState() =>
      _CategoryPublicationTestWidgetState();
}

class _CategoryPublicationTestWidgetState
    extends State<CategoryPublicationTestWidget> {
  final StudentService _studentService = StudentService();
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final categories = await _studentService
          .getStudentCategoryPublicationStatus(widget.studentId);
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _togglePublication(String categoryId, bool currentState) async {
    try {
      final categoryName = _categories.firstWhere(
          (cat) => cat['category_id'] == categoryId)['category_name'];

      await _studentService.toggleCategoryPublication(
        widget.studentId,
        categoryId,
        !currentState,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !currentState
                ? 'Categoría "$categoryName" publicada'
                : 'Categoría "$categoryName" despublicada',
          ),
        ),
      );

      // Recargar los datos
      await _loadCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCategories,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_categories.isEmpty) {
      return const Center(
        child: Text('No hay categorías asignadas para este estudiante.'),
      );
    }

    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final categoryId = category['category_id']?.toString() ?? '';
        final categoryName =
            category['category_name']?.toString() ?? 'Sin nombre';
        final isPublished = category['published'] as bool? ?? false;
        final totalAnswers = category['total_answers'] as int? ?? 0;
        final successPercentage = category['success_percentage'] as num? ?? 0;

        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(categoryName),
            subtitle: Text(
              'Respuestas: $totalAnswers | Aciertos: ${successPercentage.toStringAsFixed(1)}%',
            ),
            trailing: Switch(
              value: isPublished,
              onChanged: totalAnswers > 0
                  ? (value) => _togglePublication(categoryId, isPublished)
                  : null,
            ),
            leading: Icon(
              isPublished ? Icons.visibility : Icons.visibility_off,
              color: isPublished ? Colors.green : Colors.grey,
            ),
          ),
        );
      },
    );
  }
}
