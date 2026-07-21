import 'package:receipt24_shared/receipt24_shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ClientService {
  ClientService(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();

  Future<AccountantProfileModel?> getAccountantProfile(String userId) async {
    final row = await _client
        .from('accountants')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return AccountantProfileModel.fromJson(row);
  }

  Future<List<ClientAccessModel>> fetchClients(String userId) async {
    final profile = await getAccountantProfile(userId);
    if (profile == null) return [];

    final rows = await _client
        .from('accountant_client_access')
        .select('*, users(full_name, email)')
        .eq('accountant_id', profile.id)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => ClientAccessModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<ClientAccessModel?> fetchClient(String accessId) async {
    final row = await _client
        .from('accountant_client_access')
        .select('*, users(full_name, email)')
        .eq('id', accessId)
        .maybeSingle();
    if (row == null) return null;
    return ClientAccessModel.fromJson(row);
  }

  Future<ClientAccessModel> inviteClient({
    required String userId,
    required String invitationEmail,
    String accessScope = AccessScopes.all,
  }) async {
    final profile = await getAccountantProfile(userId);
    if (profile == null) {
      throw Exception('Accountant profile not found');
    }

    final consumer = await _client
        .from('users')
        .select('id')
        .eq('email', invitationEmail.trim().toLowerCase())
        .eq('role', 'consumer')
        .maybeSingle();

    if (consumer == null) {
      throw Exception('consumer_not_found');
    }

    final consumerId = consumer['id'] as String;
    final token = _uuid.v4();

    final row = await _client
        .from('accountant_client_access')
        .upsert({
          'accountant_id': profile.id,
          'consumer_user_id': consumerId,
          'access_status': 'pending',
          'access_scope': accessScope,
          'invitation_email': invitationEmail.trim(),
          'invitation_token': token,
        }, onConflict: 'accountant_id,consumer_user_id')
        .select('*, users(full_name, email)')
        .single();

    try {
      await _client.functions.invoke(
        'send-notification',
        body: {
          'userId': consumerId,
          'notificationType': 'accountant_invitation',
          'title': 'Accountant access request',
          'message':
              '${profile.firmName} requests access to your receipts.',
          'relatedRecordType': 'accountant_access',
          'relatedRecordId': row['id'],
          'channels': ['push', 'email'],
          'templateKey': 'accountant_invitation',
          'templateVars': {
            'accountant_name': profile.firmName,
            'firm_name': profile.firmName,
          },
        },
      );
    } catch (_) {
      // Falls back to in-app pending requests list on consumer side
    }

    return ClientAccessModel.fromJson(row);
  }

  Future<void> revokeAccess(String accessId) async {
    await _client.from('accountant_client_access').update({
      'access_status': 'revoked',
      'revoked_at': DateTime.now().toIso8601String(),
    }).eq('id', accessId);
  }

  Future<Map<String, int>> getDashboardStats(String userId) async {
    final clients = await fetchClients(userId);
    final approved =
        clients.where((c) => c.isApproved).map((c) => c.consumerUserId).toList();
    final pending = clients.where((c) => c.isPending).length;

    var receiptCount = 0;
    if (approved.isNotEmpty) {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
      final rows = await _client
          .from('receipts')
          .select('id')
          .inFilter('consumer_user_id', approved)
          .gte('created_at', monthStart)
          .isFilter('soft_deleted_at', null);
      receiptCount = (rows as List).length;
    }

    return {
      'totalClients': approved.length,
      'pendingInvitations': pending,
      'receiptsThisMonth': receiptCount,
    };
  }
}
