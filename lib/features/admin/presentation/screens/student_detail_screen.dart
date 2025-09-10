import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';

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

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _byCategory = [];
  List<Map<String, dynamic>> _answers = [];

  // UI filter
  String? _selectedCategoryId; // null = all

  @override
  void initState() {
    super.initState();
    _loadStudentDetail();
  }

  Future<void> _loadStudentDetail() async {
    setState(() {
      _loading = true;
      _error = null;
      _byCategory = [];
      _answers = [];
      _selectedCategoryId = null;
    });

    try {
      // 1) categories: usa la vista stats_by_category (ya existe en tu BD)
      final dynamic catResRaw = await supabase
          .from('stats_by_category')
          .select()
          .eq('user_id', widget.studentId);

      // 2) answers: consulta la vista que acabamos de crear
      final dynamic ansResRaw = await supabase
          .from('student_answers_detailed')
          .select()
          .eq('student_id', widget.studentId)
          .order('answered_at', ascending: false);

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

      // Si algún campo viene con nombres distintos, hacemos correcciones simples:
      ansList = ansList.map((r) {
        final m = Map<String, dynamic>.from(r);
        // renombra si hace falta: 'answer' -> 'selected_answer'
        if (!m.containsKey('selected_answer') && m.containsKey('answer')) {
          m['selected_answer'] = m['answer']?.toString();
        }
        return m;
      }).toList();

      setState(() {
        _byCategory = catList;
        _answers = ansList;
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
  double get overallAccuracy {
    final num total =
        _byCategory.fold(0, (p, c) => p + (c['total_answers'] ?? 0));
    final num correct =
        _byCategory.fold(0, (p, c) => p + (c['correct_answers'] ?? 0));
    if (total == 0) return 0.0;
    return (correct / total) * 100.0;
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
                Text('Correcta?: ${q['is_correct'] == true ? "Sí" : "No"}',
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
        IconButton(
            onPressed: _loadStudentDetail,
            icon: const Icon(Icons.refresh, color: AppTheme.white)),
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
    final correct = rows.where((r) => r['is_correct'] == true).length;
    final total = rows.length;
    final accuracy = total == 0 ? 0.0 : (correct / total) * 100.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          color: AppTheme.white, fontWeight: FontWeight.w700))),
              Text('${accuracy.toStringAsFixed(0)}%',
                  style: const TextStyle(color: AppTheme.greyLight)),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: rows.map((q) {
              final isCorrect = q['is_correct'] == true;
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        title: Text(widget.studentName ?? 'Detalle Estudiante',
            style: const TextStyle(color: AppTheme.white)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryRed))
          : _error != null
              ? Center(
                  child: Text('Error: $_error',
                      style: const TextStyle(color: AppTheme.primaryRed)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      Text('Filtrar por categoría',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  color: AppTheme.white,
                                  fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _buildCategoryChips(),
                      const SizedBox(height: 16),
                      _buildAnswersSections(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}
