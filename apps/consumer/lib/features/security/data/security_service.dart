import 'package:receipt24_shared/receipt24_shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecurityService {
  SecurityService(this._client);

  final SupabaseClient _client;

  Future<void> logLoginEvent(String userId, {String? platform}) async {
    await _client.from('audit_logs').insert({
      'user_id': userId,
      'action_type': 'login',
      'record_type': 'session',
      'device_information': platform ?? 'unknown',
    });

    await _client.from('user_devices').upsert({
      'user_id': userId,
      'device_label': 'primary',
      'platform': platform ?? 'unknown',
      'last_active_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,platform,device_label');
  }

  Future<List<AuditLogModel>> fetchLoginHistory(String userId) async {
    final rows = await _client
        .from('audit_logs')
        .select('*, users(full_name)')
        .eq('user_id', userId)
        .eq('action_type', 'login')
        .order('created_at', ascending: false)
        .limit(20);

    return (rows as List)
        .map((r) => AuditLogModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchDevices(String userId) async {
    final rows = await _client
        .from('user_devices')
        .select()
        .eq('user_id', userId)
        .order('last_active_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<String?> getSignedUrl({
    required String bucket,
    required String path,
    int expiresIn = 3600,
  }) async {
    final response = await _client.functions.invoke(
      'get-signed-url',
      body: {'bucket': bucket, 'path': path, 'expiresIn': expiresIn},
    );
    final data = response.data as Map<String, dynamic>?;
    return data?['signedUrl'] as String?;
  }
}
