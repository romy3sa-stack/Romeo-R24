import 'package:receipt24_shared/receipt24_shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  AdminService(this._client);

  final SupabaseClient _client;

  Future<Map<String, int>> getDashboardStats() async {
    final users = await _client.from('users').select('id, role');
    final userList = users as List;
    final consumers =
        userList.where((u) => u['role'] == 'consumer').length;
    final accountants = userList
        .where((u) =>
            u['role'] == 'accountant' ||
            u['role'] == 'accounting_firm_manager')
        .length;

    final pending = await _client
        .from('accountants')
        .select('id')
        .eq('verification_status', 'pending');
    final tickets = await _client
        .from('support_tickets')
        .select('id')
        .inFilter('ticket_status', ['open', 'in_progress', 'waiting_on_user']);
    final receipts = await _client
        .from('receipts')
        .select('id')
        .isFilter('soft_deleted_at', null);

    return {
      'totalUsers': userList.length,
      'consumers': consumers,
      'accountants': accountants,
      'pendingVerifications': (pending as List).length,
      'openTickets': (tickets as List).length,
      'totalReceipts': (receipts as List).length,
    };
  }

  Future<List<AdminUserSummary>> fetchUsers({String? roleFilter}) async {
    var query = _client.from('users').select();
    if (roleFilter != null) {
      query = query.eq('role', roleFilter);
    }
    final rows = await query.order('created_at', ascending: false).limit(100);
    return (rows as List)
        .map((r) => AdminUserSummary.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateUserStatus(String userId, String status) async {
    await _client
        .from('users')
        .update({'account_status': status})
        .eq('id', userId);
  }

  Future<List<AdminAccountantSummary>> fetchAccountants({
    String? verificationFilter,
  }) async {
    var query = _client
        .from('accountants')
        .select('*, users(full_name, email)');
    if (verificationFilter != null) {
      query = query.eq('verification_status', verificationFilter);
    }
    final rows = await query.order('created_at', ascending: false).limit(100);
    return (rows as List)
        .map((r) => AdminAccountantSummary.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> verifyAccountant(String accountantId, String userId) async {
    await _client.from('accountants').update({
      'verification_status': 'verified',
    }).eq('id', accountantId);
    await _client.from('users').update({
      'account_status': 'active',
    }).eq('id', userId);
  }

  Future<void> rejectAccountant(String accountantId, String userId) async {
    await _client.from('accountants').update({
      'verification_status': 'rejected',
    }).eq('id', accountantId);
    await _client.from('users').update({
      'account_status': 'suspended',
    }).eq('id', userId);
  }

  Future<List<SupportTicketModel>> fetchTickets({String? statusFilter}) async {
    var query =
        _client.from('support_tickets').select('*, users(full_name, email)');
    if (statusFilter != null) {
      query = query.eq('ticket_status', statusFilter);
    }
    final rows = await query.order('created_at', ascending: false).limit(100);
    return (rows as List)
        .map((r) => SupportTicketModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    await _client
        .from('support_tickets')
        .update({'ticket_status': status})
        .eq('id', ticketId);
  }

  Future<List<AuditLogModel>> fetchAuditLogs({int limit = 100}) async {
    final rows = await _client
        .from('audit_logs')
        .select('*, users(full_name)')
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => AuditLogModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
