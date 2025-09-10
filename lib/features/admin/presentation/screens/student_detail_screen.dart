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

  // --- Publish state ---
  bool _isPublished = false;
  bool _loadingPublish = false;

  @override
  void initState() {
    super.initState();
    _loadStudentDetail();
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

      // 3) estado de publicación: tabla student_results_publish
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

  Future<void> _togglePublish() async {
    final newState = !_isPublished;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            newState ? 'Publicar calificación' : 'Despublicar calificación'),
        content: Text(newState
            ? '¿Confirmas que deseas publicar las calificaciones para este estudiante?'
            : '¿Confirmas que deseas retirar la publicación de las calificaciones?'),
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
      final row = {
        'student_id': widget.studentId,
        'published': newState,
        'published_at': DateTime.now().toUtc().toIso8601String(),
      };

      // CORRECCIÓN: onConflict debe ser un String con el nombre de la columna
      final dynamic upsertRes = await supabase
          .from('student_results_publish')
          .upsert(row, onConflict: 'student_id') // <-- aquí la corrección
          .select()
          .maybeSingle();

      // Normalizar respuesta a bool
      bool published = newState;
      if (upsertRes != null) {
        // upsertRes puede ser Map, List o PostgrestResponse-like
        if (upsertRes is Map && upsertRes.containsKey('published')) {
          final p = upsertRes['published'];
          if (p is bool)
            published = p;
          else {
            final s = p?.toString().toLowerCase();
            published = (s == 'true' || s == 't' || s == '1');
          }
        } else if (upsertRes is List && upsertRes.isNotEmpty) {
          final m = Map<String, dynamic>.from(upsertRes[0] as Map);
          final p = m['published'];
          if (p is bool)
            published = p;
          else {
            final s = p?.toString().toLowerCase();
            published = (s == 'true' || s == 't' || s == '1');
          }
        } else {
          // fallback: si viene otra cosa (p.ej. PostgrestResponse), intentar extraer .data
          try {
            final maybeData = (upsertRes as dynamic).data;
            if (maybeData is Map && maybeData.containsKey('published')) {
              final p = maybeData['published'];
              if (p is bool)
                published = p;
              else {
                final s = p?.toString().toLowerCase();
                published = (s == 'true' || s == 't' || s == '1');
              }
            }
          } catch (_) {}
        }
      }

      setState(() {
        _isPublished = published;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(published
              ? 'Calificación publicada'
              : 'Calificación despublicada'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e, st) {
      debugPrint('Error toggling publish: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al actualizar el estado: $e'),
            backgroundColor: AppTheme.primaryRed),
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
                      backgroundColor: _isPublished
                          ? AppTheme.success.withOpacity(0.12)
                          : AppTheme.primaryRed.withOpacity(0.12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _togglePublish,
                    icon: Icon(
                      _isPublished ? Icons.lock_open : Icons.lock,
                      size: 18,
                      color:
                          _isPublished ? AppTheme.success : AppTheme.primaryRed,
                    ),
                    label: Text(
                      _isPublished ? 'Publicado' : 'Publicar',
                      style: TextStyle(
                        color: _isPublished
                            ? AppTheme.success
                            : AppTheme.primaryRed,
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
