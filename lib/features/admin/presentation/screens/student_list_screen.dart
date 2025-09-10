import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import 'student_detail_screen.dart';

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({Key? key}) : super(key: key);

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  final supabase = Supabase.instance.client;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  List<Map<String, dynamic>> _students = [];

  // pagination
  final int _limit = 30;
  int _offset = 0;
  bool _hasMore = true;

  String _filter = '';

  @override
  void initState() {
    super.initState();
    _loadStudents(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents({bool reset = false}) async {
    try {
      setState(() {
        _error = null;
        if (reset) {
          _loading = true;
          _offset = 0;
          _hasMore = true;
        }
      });

      if (reset) _students = [];

      // Build base query (declare as dynamic to avoid static type conflicts)
      // antes: supabase.from('app_users').select('id, email, raw_user_meta_data');
      dynamic query = supabase
          .from('app_users_enriched')
          .select('id, email, raw_user_meta_data, full_name');

      // Server-side search by email (ilike) using .filter for compatibility
      if (_filter.isNotEmpty) {
        query = query.filter('email', 'ilike', '%$_filter%');
      }

      // Execute with ordering and range
      final dynamic res = await query
          .order('email', ascending: true)
          .range(_offset, _offset + _limit - 1);

      // Normalize response into a List<dynamic> called `data`
      List<dynamic> data;
      if (res is List) {
        // New API often returns list directly
        data = res;
      } else if (res is Map && res.containsKey('data')) {
        // Sometimes the response is a Map like {'data': [...], 'error': ...}
        if (res['error'] != null) {
          throw Exception(res['error'].toString());
        }
        data = (res['data'] as List<dynamic>?) ?? [];
      } else {
        // Fallback: try dynamic properties (.error / .data)
        try {
          final dynamic err = (res as dynamic).error;
          final dynamic d = (res as dynamic).data;
          if (err != null) throw err;
          if (d is List) {
            data = d;
          } else if (d == null) {
            data = [];
          } else {
            data = [d];
          }
        } catch (e) {
          // Unexpected shape
          throw Exception(
              'Unexpected response shape from Supabase query: ${res.runtimeType} -> $e');
        }
      }

      // map rows into List<Map<String,dynamic>>
      final newItems = data.map<Map<String, dynamic>>((e) {
        final m = Map<String, dynamic>.from(e as Map);
        // Normalize raw_user_meta_data
        final raw = m['raw_user_meta_data'];
        if (raw is String && raw.isNotEmpty) {
          try {
            m['meta'] = jsonDecode(raw) as Map<String, dynamic>;
          } catch (_) {
            m['meta'] = <String, dynamic>{};
          }
        } else if (raw is Map) {
          m['meta'] = Map<String, dynamic>.from(raw);
        } else {
          m['meta'] = <String, dynamic>{};
        }
        return m;
      }).toList();

      setState(() {
        if (reset) {
          _students = newItems;
        } else {
          // avoid duplicates
          final ids = _students.map((s) => s['id']).toSet();
          for (final it in newItems) {
            if (!ids.contains(it['id'])) _students.add(it);
          }
        }

        // update hasMore based on number of rows returned
        _hasMore = newItems.length == _limit;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore) return;
    setState(() => _loadingMore = true);
    _offset += _limit;
    await _loadStudents(reset: false);
  }

  Future<void> _onRefresh() async {
    await _loadStudents(reset: true);
  }

  void _onSearchChanged(String q) {
    // update filter and reload (debounced)
    setState(() {
      _filter = q.trim();
    });
    // simple debounce
    Future.delayed(const Duration(milliseconds: 350), () {
      if (q.trim() == _filter) _loadStudents(reset: true);
    });
  }

  String _prettifyEmail(String email) {
    if (email.isEmpty) return 'Estudiante';
    final local = email.split('@').first;
    final cleaned = local.replaceAll(RegExp(r'[\._\-+]'), ' ');
    final parts =
        cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final capitalized = parts.map((p) {
      if (p.length <= 1) return p.toUpperCase();
      return p[0].toUpperCase() + p.substring(1);
    }).join(' ');
    return capitalized.isNotEmpty ? capitalized : email;
  }

  String _displayName(Map<String, dynamic> s) {
    // 1) full_name desde la vista
    final full = s['full_name']?.toString();
    if (full != null && full.trim().isNotEmpty && !full.contains('@'))
      return full.trim();

    // 2) metadata ya parseada (m['meta'])
    final meta = s['meta'] as Map<String, dynamic>? ?? {};
    final cand = (meta['full_name'] ??
        meta['name'] ??
        meta['first_name'] ??
        meta['firstName']);
    if (cand != null) {
      final str = cand.toString().trim();
      if (str.isNotEmpty && !str.contains('@')) return str;
    }

    // 3) fallback: convertir email a un nombre presentable
    final email = s['email']?.toString() ?? '';
    return _prettifyEmail(email);
  }

  String _initials(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        title:
            const Text('Estudiantes', style: TextStyle(color: AppTheme.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: AppTheme.white),
              decoration: InputDecoration(
                hintText: 'Buscar por email o nombre',
                hintStyle: const TextStyle(color: AppTheme.greyLight),
                prefixIcon: const Icon(Icons.search, color: AppTheme.greyLight),
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
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.primaryRed))
                  : _error != null
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text('Error: $_error',
                                  style: const TextStyle(
                                      color: AppTheme.primaryRed)),
                            ),
                          ],
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemBuilder: (context, index) {
                            if (index >= _students.length) {
                              // loading more indicator
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                    child: CircularProgressIndicator(
                                        color: AppTheme.primaryRed)),
                              );
                            }
                            final s = _students[index];
                            final name = _displayName(s);
                            final email = s['email']?.toString() ?? '';
                            final studentId = s['id']?.toString();

                            return ListTile(
                              onTap: () {
                                if (studentId != null) {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StudentDetailScreen(
                                            studentId: studentId,
                                            studentName: name),
                                      ));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('No hay id disponible')));
                                }
                              },
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.lightBlack,
                                child: Text(_initials(name),
                                    style:
                                        const TextStyle(color: AppTheme.white)),
                              ),
                              title: Text(name,
                                  style:
                                      const TextStyle(color: AppTheme.white)),
                              subtitle: Text(email,
                                  style: const TextStyle(
                                      color: AppTheme.greyLight)),
                              trailing: const Icon(Icons.chevron_right,
                                  color: AppTheme.greyLight),
                            );
                          },
                          separatorBuilder: (_, __) =>
                              const Divider(color: AppTheme.greyDark),
                          itemCount: _students.length + (_loadingMore ? 1 : 0),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
