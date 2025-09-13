import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/password_reset_service.dart';

class PasswordResetRequestsScreen extends StatefulWidget {
  final String supabaseUrl;
  final String serviceRoleKey;
  final String adminId; // UUID del admin

  const PasswordResetRequestsScreen({
    Key? key,
    required this.supabaseUrl,
    required this.serviceRoleKey,
    required this.adminId,
  }) : super(key: key);

  @override
  State<PasswordResetRequestsScreen> createState() =>
      _PasswordResetRequestsScreenState();
}

class _PasswordResetRequestsScreenState
    extends State<PasswordResetRequestsScreen> {
  late PasswordResetService _service;
  late SupabaseClient _supabase;
  bool _isLoading = false;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _service = PasswordResetService(widget.supabaseUrl, widget.serviceRoleKey);
    _supabase = SupabaseClient(widget.supabaseUrl, widget.serviceRoleKey);
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    final response = await _supabase
        .from('password_reset_requests')
        .select()
        .eq('status', 'pending');
    setState(() {
      _requests = List<Map<String, dynamic>>.from(response);
      _isLoading = false;
    });
  }

  Future<void> _approveRequest(Map<String, dynamic> request) async {
    setState(() => _isLoading = true);
    try {
      await _service.approveRequest(
        userId: request['user_id'],
        newPassword: request['requested_password'],
        requestId: request['id'],
        adminId: widget.adminId,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Solicitud aprobada y contraseña actualizada'),
            backgroundColor: AppTheme.success),
      );
      await _fetchRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.error),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectRequest(Map<String, dynamic> request) async {
    setState(() => _isLoading = true);
    try {
      await _service.rejectRequest(
        requestId: request['id'],
        adminId: widget.adminId,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Solicitud rechazada'),
            backgroundColor: AppTheme.info),
      );
      await _fetchRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.error),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes de Cambio de Contraseña'),
        backgroundColor: AppTheme.primaryBlack,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(
                  child: Text('No hay solicitudes pendientes',
                      style: TextStyle(color: AppTheme.greyLight)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    return Card(
                      color: AppTheme.lightBlack,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Usuario: ${req['user_id']}',
                                style: TextStyle(
                                    color: AppTheme.white,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                                'Nueva contraseña: ${req['requested_password']}',
                                style: TextStyle(color: AppTheme.greyLight)),
                            const SizedBox(height: 8),
                            Text('Solicitado: ${req['requested_at']}',
                                style: TextStyle(color: AppTheme.greyLight)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.success),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Aprobar'),
                                  onPressed: _isLoading
                                      ? null
                                      : () => _approveRequest(req),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.error),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Rechazar'),
                                  onPressed: _isLoading
                                      ? null
                                      : () => _rejectRequest(req),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
