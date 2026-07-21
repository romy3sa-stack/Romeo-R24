import 'package:receipt24_shared/receipt24_shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WarrantyService {
  WarrantyService(this._client);

  final SupabaseClient _client;

  static const _selectQuery = '''
    *,
    receipts(merchant_name_raw, transaction_date),
    receipt_items(item_name, serial_number)
  ''';

  Future<List<WarrantyModel>> fetchWarranties(String userId) async {
    final rows = await _client
        .from('warranties')
        .select(_selectQuery)
        .eq('consumer_user_id', userId)
        .order('warranty_end_date');

    return (rows as List)
        .map((r) => WarrantyModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<WarrantyModel>> fetchActiveWarranties(String userId) async {
    final all = await fetchWarranties(userId);
    return all
        .where((w) =>
            w.warrantyStatus == 'active' && !w.isExpired)
        .toList();
  }

  Future<List<WarrantyModel>> fetchExpiringSoon(String userId, {int days = 30}) async {
    final all = await fetchWarranties(userId);
    return all
        .where((w) =>
            w.warrantyStatus == 'active' &&
            w.daysRemaining >= 0 &&
            w.daysRemaining <= days)
        .toList();
  }

  Future<WarrantyModel?> fetchWarranty(String id) async {
    final row = await _client
        .from('warranties')
        .select(_selectQuery)
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return WarrantyModel.fromJson(row);
  }

  Future<WarrantyModel> createWarranty({
    required String userId,
    required String receiptId,
    String? receiptItemId,
    required DateTime startDate,
    required int warrantyPeriodDays,
    String? merchantContact,
    String? notes,
    bool remindersEnabled = true,
  }) async {
    final endDate = startDate.add(Duration(days: warrantyPeriodDays));

    final row = await _client
        .from('warranties')
        .insert({
          'receipt_id': receiptId,
          'receipt_item_id': receiptItemId,
          'consumer_user_id': userId,
          'warranty_start_date': startDate.toIso8601String().split('T').first,
          'warranty_end_date': endDate.toIso8601String().split('T').first,
          'warranty_status': 'active',
          'reminder_status':
              remindersEnabled ? ReminderStatuses.pending : ReminderStatuses.disabled,
          'merchant_contact_details': merchantContact,
          'notes': notes,
        })
        .select(_selectQuery)
        .single();

    await _client.from('receipts').update({
      'warranty_available': true,
    }).eq('id', receiptId);

    return WarrantyModel.fromJson(row);
  }

  Future<WarrantyModel> updateWarranty(
    String id,
    Map<String, dynamic> data,
  ) async {
    final row = await _client
        .from('warranties')
        .update(data)
        .eq('id', id)
        .select(_selectQuery)
        .single();
    return WarrantyModel.fromJson(row);
  }

  Future<void> updateClaimStatus({
    required String warrantyId,
    required String status,
    String? claimReference,
    String? notes,
  }) async {
    await updateWarranty(warrantyId, {
      'warranty_status': status,
      if (claimReference != null) 'claim_reference': claimReference,
      if (notes != null) 'notes': notes,
    });
  }

  Future<void> setReminderStatus(String id, String reminderStatus) async {
    await _client
        .from('warranties')
        .update({'reminder_status': reminderStatus})
        .eq('id', id);
  }

  Future<int> countActive(String userId) async {
    final active = await fetchActiveWarranties(userId);
    return active.length;
  }
}

class ReturnService {
  ReturnService(this._client);

  final SupabaseClient _client;

  static const _selectQuery = '''
    *,
    receipts(merchant_name_raw, transaction_date, return_deadline),
    receipt_items(item_name)
  ''';

  Future<List<ReturnModel>> fetchReturns(String userId) async {
    final rows = await _client
        .from('returns_and_refunds')
        .select(_selectQuery)
        .eq('consumer_user_id', userId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => ReturnModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<ReturnModel>> fetchUpcomingDeadlines(String userId) async {
    final all = await fetchReturns(userId);
    return all.where((r) {
      final days = r.daysUntilDeadline;
      return days != null &&
          days >= 0 &&
          days <= 30 &&
          r.requestStatus != 'closed' &&
          r.requestStatus != 'refund_received';
    }).toList();
  }

  Future<ReturnModel?> fetchReturn(String id) async {
    final row = await _client
        .from('returns_and_refunds')
        .select(_selectQuery)
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return ReturnModel.fromJson(row);
  }

  Future<ReturnModel> createReturn({
    required String userId,
    required String receiptId,
    String? receiptItemId,
    String requestType = 'return',
    String? reason,
    String? description,
    DateTime? returnDeadline,
    double? refundAmount,
  }) async {
    final row = await _client
        .from('returns_and_refunds')
        .insert({
          'receipt_id': receiptId,
          'receipt_item_id': receiptItemId,
          'consumer_user_id': userId,
          'request_type': requestType,
          'request_reason': reason,
          'request_description': description,
          'request_status': 'not_started',
          'return_deadline': returnDeadline?.toIso8601String().split('T').first,
          'refund_amount': refundAmount,
        })
        .select(_selectQuery)
        .single();

    if (returnDeadline != null) {
      await _client.from('receipts').update({
        'return_deadline': returnDeadline.toIso8601String().split('T').first,
      }).eq('id', receiptId);
    }

    return ReturnModel.fromJson(row);
  }

  Future<ReturnModel> updateReturn(
    String id,
    Map<String, dynamic> data,
  ) async {
    final row = await _client
        .from('returns_and_refunds')
        .update(data)
        .eq('id', id)
        .select(_selectQuery)
        .single();
    return ReturnModel.fromJson(row);
  }

  Future<void> updateStatus({
    required String returnId,
    required String status,
    String? merchantNotes,
    double? refundReceived,
  }) async {
    await updateReturn(returnId, {
      'request_status': status,
      if (merchantNotes != null) 'merchant_response_notes': merchantNotes,
      if (refundReceived != null) 'refund_amount': refundReceived,
    });
  }

  Future<int> countUpcomingDeadlines(String userId) async {
    final upcoming = await fetchUpcomingDeadlines(userId);
    return upcoming.length;
  }
}
