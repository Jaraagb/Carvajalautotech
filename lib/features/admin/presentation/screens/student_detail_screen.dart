import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/student_service.dart';

class StudentDetailScreen extends StatefulWidget {
  final String studentId;
  final String? studentName;
  const StudentDetailScreen({
    Key? key,
    required this.studentId,
    this.studentName,
  }) : super(key: key);

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final supabase = Supabase.instance.client;
  final studentService = StudentService();

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _byCategory = [];
  List<Map<String, dynamic>> _answers = [];
  List<Map<String, dynamic>> _categoryPublicationStatus = [];

  // UI filter
  String? _selectedCategoryId; // null = all

  // --- Publish state ---
  bool _isPublished = false;
  bool _loadingPublish = false;

  @override
  void initState() {
    super.initState();
    _loadStudentDetail();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mover cualquier lógica que dependa del contexto aquí
  }

  // ----- Helper to interpret different representations of "true" -----
  bool _isCorrectValue(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase().trim();
    return s == 'true' || s == 't' || s == '1' || s == 'yes' || s == 'y';
  }

  // ---- Overall accuracy computed from actual answers list ----
  double get overallAccuracy {
    final total = _answers.length;
    if (total == 0) return 0.0;
    final correct =
        _answers.where((a) => _isCorrectValue(a['is_correct'])).length;
    return (correct / total) * 100.0;
  }

  Future<void> _loadStudentDetail() async {
    setState(() {
      _loading = true;
      _error = null;
      _byCategory = [];
      _answers = [];
      _categoryPublicationStatus = [];
      _selectedCategoryId = null;
      _isPublished = false;
    });

    try {
      // 1) categories: usa la vista stats_by_category (ajusta si tu vista cambia)
      final dynamic catResRaw = await supabase
          .from('stats_by_category')
          .select()
          .eq('user_id', widget.studentId);

      // 2) answers: consulta la vista student_answers_detailed (o la vista que uses)
      final dynamic ansResRaw = await supabase
          .from('student_answers_detailed')
          .select()
          .eq('student_id', widget.studentId)
          .order('answered_at', ascending: false);

      // 3) estado de publicación por categoría: nueva vista
      final categoryPublicationStatus = await studentService
          .getStudentCategoryPublicationStatus(widget.studentId);

      // 4) estado de publicación general (mantener para compatibilidad)
      final dynamic pubRes = await supabase
          .from('student_results_publish')
          .select('published')
          .eq('student_id', widget.studentId)
          .maybeSingle();

      // Normalizar respuestas / categories en listas manejables
      List<Map<String, dynamic>> catList = [];
      List<Map<String, dynamic>> ansList = [];

      // catResRaw puede venir como List o Map con data, normalizamos:
      if (catResRaw is List) {
        catList =
            catResRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else if (catResRaw is Map && catResRaw.containsKey('data')) {
        catList = (catResRaw['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      // ansResRaw normalizar (PostgREST suele devolver List directamente)
      if (ansResRaw is List) {
        ansList =
            ansResRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else if (ansResRaw is Map && ansResRaw.containsKey('data')) {
        ansList = (ansResRaw['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      // normalizar pubRes
      bool published = false;
      if (pubRes == null) {
        published = false;
      } else if (pubRes is Map) {
        // pubRes puede ser {'published': true}
        final p = pubRes['published'];
        if (p is bool)
          published = p;
        else {
          final s = p?.toString().toLowerCase();
          published = (s == 'true' || s == 't' || s == '1');
        }
      } else if (pubRes is List && pubRes.isNotEmpty) {
        final m = Map<String, dynamic>.from(pubRes[0] as Map);
        final p = m['published'];
        if (p is bool)
          published = p;
        else {
          final s = p?.toString().toLowerCase();
          published = (s == 'true' || s == 't' || s == '1');
        }
      }

      // Si algún campo viene con nombres distintos, hacemos correcciones simples:
      ansList = ansList.map((r) {
        final m = Map<String, dynamic>.from(r);
        // renombra si hace falta: 'answer' -> 'selected_answer'
        if (!m.containsKey('selected_answer') && m.containsKey('answer')) {
          m['selected_answer'] = m['answer']?.toString();
        }
        // asegurar is_correct está presente (si viene como 't'/'f' en string)
        if (!m.containsKey('is_correct') && m.containsKey('correct')) {
          m['is_correct'] = m['correct'];
        }
        return m;
      }).toList();

      setState(() {
        _byCategory = catList;
        _answers = ansList;
        _categoryPublicationStatus = categoryPublicationStatus;
        _isPublished = published;
      });
    } catch (e, st) {
      debugPrint('Error loading student detail: $e\n$st');
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // grouping answers by category_id for faster rendering
  Map<String, List<Map<String, dynamic>>> get _answersGrouped {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final a in _answers) {
      final catId = (a['category_id'] ?? 'uncategorized').toString();
      map.putIfAbsent(catId, () => []).add(a);
    }
    return map;
  }

  // quick aggregate
  int get totalAnswers => _answers.length;

  /// Publica o despublica una categoría específica
  Future<void> _toggleCategoryPublish(
      String categoryId, String categoryName, bool currentState) async {
    final newState = !currentState;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(newState ? 'Publicar categoría' : 'Despublicar categoría'),
        content: Text(newState
            ? '¿Confirmas que deseas publicar las calificaciones de "$categoryName" para este estudiante?'
            : '¿Confirmas que deseas retirar la publicación de las calificaciones de "$categoryName"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loadingPublish = true);

    try {
      final published = await studentService.toggleCategoryPublication(
          widget.studentId, categoryId, newState);

      // Actualizar el estado local
      setState(() {
        final index = _categoryPublicationStatus
            .indexWhere((cat) => cat['category_id'] == categoryId);
        if (index != -1) {
          _categoryPublicationStatus[index]['published'] = published;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(published
              ? 'Categoría "$categoryName" publicada'
              : 'Categoría "$categoryName" despublicada'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e, st) {
      debugPrint('Error toggling category publish: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al actualizar el estado: $e'),
            backgroundColor: AppTheme.primaryRed),
      );
    } finally {
      setState(() => _loadingPublish = false);
    }
  }

  /// Método para obtener el estado de publicación de una categoría
  bool _getCategoryPublicationState(String categoryId) {
    final category = _categoryPublicationStatus.firstWhere(
        (cat) => cat['category_id'] == categoryId,
        orElse: () => {'published': false});
    return category['published'] as bool? ?? false;
  }

  /// Muestra el diálogo para gestionar la publicación por categorías
  void _showPublicationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gestionar Publicación por Categorías'),
        content: Container(
          width: double.maxFinite,
          child: _categoryPublicationStatus.isEmpty
              ? const Text('No hay categorías asignadas para este estudiante.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Selecciona las categorías que deseas publicar para este estudiante:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ..._categoryPublicationStatus
                        .map((category) =>
                            _buildCategoryPublicationTile(category))
                        .toList(),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Construye cada item de categoría con su switch de publicación
  Widget _buildCategoryPublicationTile(Map<String, dynamic> category) {
    final categoryId = category['category_id']?.toString() ?? '';
    final categoryName = category['category_name']?.toString() ?? 'Sin nombre';
    final isPublished = category['published'] as bool? ?? false;
    final totalAnswers = category['total_answers'] as int? ?? 0;
    final successPercentage = category['success_percentage'] as num? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.greyLight.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: isPublished
            ? AppTheme.success.withOpacity(0.1)
            : AppTheme.greyLight.withOpacity(0.1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Respuestas: $totalAnswers | Aciertos: ${successPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: AppTheme.greyLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isPublished,
            onChanged: totalAnswers > 0
                ? (value) async {
                    await _toggleCategoryPublish(
                        categoryId, categoryName, isPublished);
                    Navigator.of(context).pop();
                    _showPublicationDialog(); // Reabrir el diálogo para mostrar cambios
                  }
                : null,
            activeColor: AppTheme.success,
          ),
        ],
      ),
    );
  }

  Future<void> _publishCategory(String categoryId, String categoryName) async {
    setState(() => _loadingPublish = true);
    try {
      // Usar el nuevo método que actualiza student_categories
      await studentService.toggleCategoryPublication(
          widget.studentId, categoryId, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Categoría "$categoryName" publicada correctamente')),
      );

      // Reload details to reflect changes
      await _loadStudentDetail();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error publicando categoría: $e')),
      );
    } finally {
      setState(() => _loadingPublish = false);
    }
  }

  void _openQuestionModal(Map<String, dynamic> q) {
    showDialog(
      context: context,
      builder: (ctx) {
        final answeredAt = q['answered_at'] != null
            ? DateTime.tryParse(q['answered_at'].toString())
            : null;
        return AlertDialog(
          backgroundColor: AppTheme.primaryBlack,
          title: Text('Detalle de Pregunta',
              style: const TextStyle(color: AppTheme.white)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q['question']?.toString() ?? '',
                    style: const TextStyle(color: AppTheme.white)),
                const SizedBox(height: 12),
                Text('Seleccionada: ${q['selected_answer'] ?? '—'}',
                    style: const TextStyle(color: AppTheme.greyLight)),
                Text('Correcta: ${q['correct_answer'] ?? '—'}',
                    style: const TextStyle(color: AppTheme.greyLight)),
                Text(
                    'Correcta?: ${_isCorrectValue(q['is_correct']) ? "Sí" : "No"}',
                    style: const TextStyle(color: AppTheme.greyLight)),
                if (answeredAt != null)
                  Text(
                      'Respondida: ${answeredAt.toLocal().toString().split('.').first}',
                      style: const TextStyle(color: AppTheme.greyLight)),
                if (q['time_spent'] != null)
                  Text('Tiempo (s): ${q['time_spent']}',
                      style: const TextStyle(color: AppTheme.greyLight)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cerrar',
                  style: TextStyle(color: AppTheme.primaryRed)),
            )
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.lightBlack,
          child: Text(
            (widget.studentName?.isNotEmpty == true
                ? widget.studentName![0].toUpperCase()
                : 'S'),
            style: const TextStyle(color: AppTheme.white, fontSize: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.studentName ?? 'Estudiante',
                  style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                  'Respuestas: $totalAnswers • Precisión: ${overallAccuracy.toStringAsFixed(1)}%',
                  style:
                      const TextStyle(color: AppTheme.greyLight, fontSize: 13)),
            ],
          ),
        ),
        // Botones: refrescar y publicar
        Column(
          children: [
            IconButton(
                onPressed: _loadStudentDetail,
                icon: const Icon(Icons.refresh, color: AppTheme.white)),
            const SizedBox(height: 4),
            _loadingPublish
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      backgroundColor: AppTheme.primaryRed.withOpacity(0.12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showPublicationDialog(),
                    icon: const Icon(
                      Icons.publish,
                      size: 18,
                      color: AppTheme.primaryRed,
                    ),
                    label: const Text(
                      'Gestionar Publicación',
                      style: TextStyle(
                        color: AppTheme.primaryRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    final chips = <Widget>[];
    chips.add(
      ChoiceChip(
        label: const Text('Todas'),
        selected: _selectedCategoryId == null,
        onSelected: (_) => setState(() => _selectedCategoryId = null),
        selectedColor: AppTheme.primaryRed.withOpacity(0.15),
      ),
    );

    for (final c in _byCategory) {
      final id = c['category_id']?.toString() ?? '';
      final name = c['category_name']?.toString() ?? 'Sin categoría';
      chips.add(
        ChoiceChip(
          label: Text(name),
          selected: _selectedCategoryId == id,
          onSelected: (_) => setState(() => _selectedCategoryId = id),
          selectedColor: AppTheme.primaryRed.withOpacity(0.15),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
          children: chips
              .map((w) =>
                  Padding(padding: const EdgeInsets.only(right: 8), child: w))
              .toList()),
    );
  }

  Widget _buildAnswersSections() {
    final grouped = _answersGrouped;
    final displayedCategoryIds = _selectedCategoryId == null
        ? grouped.keys.toList()
        : [_selectedCategoryId!];

    if (_answers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Este estudiante aún no responde preguntas.',
            style: TextStyle(color: AppTheme.greyLight)),
      );
    }

    return Column(
      children: [
        for (final catId in displayedCategoryIds)
          if (grouped.containsKey(catId))
            _buildCategoryBlock(catId, grouped[catId]!)
      ],
    );
  }

  Widget _buildCategoryBlock(String catId, List<Map<String, dynamic>> rows) {
    final name = rows.first['category_name'] ?? 'Sin categoría';
    final correct = rows.where((r) => _isCorrectValue(r['is_correct'])).length;
    final total = rows.length;
    final accuracy = total == 0 ? 0.0 : (correct / total) * 100.0;
    final isPublished = _getCategoryPublicationState(catId);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: AppTheme.white,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPublished
                            ? AppTheme.success.withOpacity(0.2)
                            : AppTheme.greyLight.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPublished
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 12,
                            color: isPublished
                                ? AppTheme.success
                                : AppTheme.greyLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPublished ? 'Publicado' : 'No publicado',
                            style: TextStyle(
                              color: isPublished
                                  ? AppTheme.success
                                  : AppTheme.greyLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Text('${accuracy.toStringAsFixed(1)}%',
                  style: const TextStyle(color: AppTheme.greyLight)),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: rows.map((q) {
              final isCorrect = _isCorrectValue(q['is_correct']);
              final answeredAt = q['answered_at'] != null
                  ? DateTime.tryParse(q['answered_at'].toString())
                  : null;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlack,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.greyDark.withOpacity(0.3)),
                ),
                child: ListTile(
                  onTap: () => _openQuestionModal(q),
                  title: Text(q['question'] ?? 'Pregunta',
                      style: const TextStyle(color: AppTheme.white)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text('Seleccionada: ${q['selected_answer'] ?? '—'}',
                          style: const TextStyle(color: AppTheme.greyLight)),
                      Text('Correcta: ${q['correct_answer'] ?? '—'}',
                          style: const TextStyle(color: AppTheme.greyLight)),
                      if (answeredAt != null)
                        Text(
                            '${answeredAt.toLocal().toString().split('.').first}',
                            style: const TextStyle(
                                color: AppTheme.greyLight, fontSize: 12)),
                    ],
                  ),
                  trailing: CircleAvatar(
                    radius: 20,
                    backgroundColor: isCorrect
                        ? AppTheme.success.withOpacity(0.12)
                        : AppTheme.primaryRed.withOpacity(0.12),
                    child: Icon(isCorrect ? Icons.check : Icons.close,
                        color:
                            isCorrect ? AppTheme.success : AppTheme.primaryRed),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Asegurarse de no acceder al contexto aquí
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentName ?? 'Detalle del Estudiante'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _byCategory.length,
                        itemBuilder: (context, index) {
                          final category = _byCategory[index];
                          final categoryId = category['category_id'];
                          final categoryName = category['category_name'];
                          final answers = _answersGrouped[categoryId] ?? [];
                          final isPublished = category['published'] == true;

                          return Card(
                            margin: const EdgeInsets.all(8.0),
                            child: ExpansionTile(
                              title: Text(categoryName ?? 'Sin categoría'),
                              children: [
                                ...answers.map((answer) {
                                  return ListTile(
                                    title:
                                        Text(answer['selected_answer'] ?? '—'),
                                    subtitle: Text(
                                        'Correcta: ${_isCorrectValue(answer['is_correct']) ? "Sí" : "No"}'),
                                    onTap: () => _openQuestionModal(answer),
                                  );
                                }).toList(),
                                ElevatedButton(
                                  onPressed: isPublished
                                      ? null
                                      : () async {
                                          await _publishCategory(
                                              categoryId, categoryName);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Categoría "$categoryName" publicada correctamente.'),
                                              ),
                                            );
                                          }
                                          await _loadStudentDetail();
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isPublished
                                        ? Colors.green
                                        : Theme.of(context).primaryColor,
                                  ),
                                  child: Text(
                                    isPublished
                                        ? 'Categoría publicada'
                                        : 'Publicar esta categoría',
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
