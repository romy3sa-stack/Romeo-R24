import 'package:receipt24_shared/receipt24_shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  NotificationService(this._client);

  final SupabaseClient _client;

  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    final rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(100);

    return (rows as List)
        .map((r) => NotificationModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount(String userId) async {
    final rows = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('read_status', false);
    return (rows as List).length;
  }

  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'read_status': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _client
        .from('notifications')
        .update({'read_status': true})
        .eq('user_id', userId)
        .eq('read_status', false);
  }

  Future<NotificationPreferences> getPreferences(String userId) async {
    final row = await _client
        .from('consumer_profiles')
        .select('notification_preferences')
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) return const NotificationPreferences();
    final prefs = row['notification_preferences'];
    if (prefs is Map<String, dynamic>) {
      return NotificationPreferences.fromJson(prefs);
    }
    return const NotificationPreferences();
  }

  Future<void> updatePreferences(
    String userId,
    NotificationPreferences preferences,
  ) async {
    await _client.from('consumer_profiles').update({
      'notification_preferences': preferences.toJson(),
    }).eq('user_id', userId);
  }

  Future<NotificationModel> createNotification({
    required String userId,
    required String notificationType,
    required String title,
    required String message,
    String? relatedRecordType,
    String? relatedRecordId,
  }) async {
    final row = await _client
        .from('notifications')
        .insert({
          'user_id': userId,
          'notification_type': notificationType,
          'title': title,
          'message': message,
          'related_record_type': relatedRecordType,
          'related_record_id': relatedRecordId,
          'read_status': false,
        })
        .select()
        .single();

    return NotificationModel.fromJson(row);
  }

  Future<void> sendViaEdgeFunction({
    required String userId,
    required String notificationType,
    required String title,
    required String message,
    String? relatedRecordType,
    String? relatedRecordId,
    List<String> channels = const ['push', 'email'],
    String? templateKey,
    Map<String, String>? templateVars,
  }) async {
    try {
      await _client.functions.invoke(
        'send-notification',
        body: {
          'userId': userId,
          'notificationType': notificationType,
          'title': title,
          'message': message,
          'relatedRecordType': relatedRecordType,
          'relatedRecordId': relatedRecordId,
          'channels': channels,
          'templateKey': templateKey,
          'templateVars': templateVars,
        },
      );
    } catch (_) {
      await createNotification(
        userId: userId,
        notificationType: notificationType,
        title: title,
        message: message,
        relatedRecordType: relatedRecordType,
        relatedRecordId: relatedRecordId,
      );
    }
  }

  Future<void> registerDeviceToken({
    required String userId,
    required String token,
    String platform = 'unknown',
  }) async {
    await _client.from('device_tokens').upsert({
      'user_id': userId,
      'token': token,
      'platform': platform,
    }, onConflict: 'user_id,token');
  }
}
