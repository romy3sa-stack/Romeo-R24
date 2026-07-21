import 'package:receipt24_shared/receipt24_shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountantAccessService {
  AccountantAccessService(this._client);

  final SupabaseClient _client;

  Future<List<ClientAccessModel>> fetchPendingRequests(String userId) async {
    final rows = await _client
        .from('accountant_client_access')
        .select('*, accountants(firm_name)')
        .eq('consumer_user_id', userId)
        .eq('access_status', 'pending')
        .order('created_at', ascending: false);

    return (rows as List).map((r) {
      final map = Map<String, dynamic>.from(r as Map<String, dynamic>);
      final accountant = map['accountants'];
      final firmName =
          accountant is Map ? accountant['firm_name'] as String? : null;
      map['users'] = {
        'full_name': firmName,
        'email': map['invitation_email'],
      };
      return ClientAccessModel.fromJson(map);
    }).toList();
  }

  Future<void> approveAccess(String accessId) async {
    await _client.from('accountant_client_access').update({
      'access_status': 'approved',
      'approved_at': DateTime.now().toIso8601String(),
    }).eq('id', accessId);
  }

  Future<void> denyAccess(String accessId) async {
    await _client.from('accountant_client_access').update({
      'access_status': 'revoked',
      'revoked_at': DateTime.now().toIso8601String(),
    }).eq('id', accessId);
  }
}
