import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carvajal_autotech/widgets/custom_notification_bar.dart';

import '../../../../core/theme/app_theme.dart';
import 'package:carvajal_autotech/services/student_service.dart';

class AssignStudentsScreen extends StatefulWidget {
  final String categoryId;

  const AssignStudentsScreen({Key? key, required this.categoryId})
      : super(key: key);

  @override
  State<AssignStudentsScreen> createState() => _AssignStudentsScreenState();
}

class _AssignStudentsScreenState extends State<AssignStudentsScreen> {
  final StudentService _studentService = StudentService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  List<String> _selectedStudents = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _loadAssignedStudents(); // Cargar estudiantes ya asignados
  }

  Future<void> _loadStudents() async {
    final response = await Supabase.instance.client
        .from('app_users_enriched')
        .select('id, full_name, email');

    setState(() {
      _students = List<Map<String, dynamic>>.from(response);
      _filteredStudents = _students;
    });
  }

  Future<void> _loadAssignedStudents() async {
    final response = await Supabase.instance.client
        .from('student_categories')
        .select('student_id')
        .eq('category_id', widget.categoryId);

    setState(() {
      _selectedStudents =
          List<String>.from(response.map((e) => e['student_id']));
    });
  }

  void _filterStudents(String query) {
    setState(() {
      _filteredStudents = _students.where((student) {
        return student['full_name']
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            student['email'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _assignStudents() async {
    final previouslyAssigned = await Supabase.instance.client
        .from('student_categories')
        .select('student_id')
        .eq('category_id', widget.categoryId);

    final previouslyAssignedIds =
        List<String>.from(previouslyAssigned.map((e) => e['student_id']));

    // Estudiantes a agregar
    final studentsToAdd = _selectedStudents
        .where((id) => !previouslyAssignedIds.contains(id))
        .toList();

    // Estudiantes a eliminar
    final studentsToRemove = previouslyAssignedIds
        .where((id) => !_selectedStudents.contains(id))
        .toList();

    // Agregar estudiantes
    for (final studentId in studentsToAdd) {
      try {
        await _studentService.assignCategoryToStudent(
            studentId, widget.categoryId);
      } catch (e) {
        showCustomNotification(
          context,
          'Error al asignar estudiante: $e',
          isSuccess: false,
        );
      }
    }

    // Eliminar estudiantes
    for (final studentId in studentsToRemove) {
      try {
        await Supabase.instance.client
            .from('student_categories')
            .delete()
            .match({'student_id': studentId, 'category_id': widget.categoryId});
      } catch (e) {
        showCustomNotification(
          context,
          'Error al eliminar estudiante: $e',
          isSuccess: false,
        );
      }
    }

    showCustomNotification(
      context,
      'Estudiantes asignados correctamente.',
      isSuccess: true,
    );

    Navigator.of(context).pop(true); // Retornar true para confirmar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignar Estudiantes'),
        backgroundColor: AppTheme.primaryBlack,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterStudents,
              decoration: InputDecoration(
                hintText: 'Buscar estudiantes...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppTheme.lightBlack,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredStudents.length,
              itemBuilder: (context, index) {
                final student = _filteredStudents[index];
                return CheckboxListTile(
                  title: Text(student['full_name']),
                  subtitle: Text(student['email']),
                  value: _selectedStudents.contains(student['id']),
                  onChanged: (isSelected) {
                    setState(() {
                      if (isSelected == true) {
                        _selectedStudents.add(student['id']);
                      } else {
                        _selectedStudents.remove(student['id']);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _assignStudents,
        backgroundColor: AppTheme.primaryRed,
        label: const Text('Asignar'),
        icon: const Icon(Icons.check),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
