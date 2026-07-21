/// Warranty record aligned with database schema.
class WarrantyModel {
  const WarrantyModel({
    required this.id,
    required this.receiptId,
    this.receiptItemId,
    required this.consumerUserId,
    required this.warrantyStartDate,
    required this.warrantyEndDate,
    required this.warrantyStatus,
    required this.reminderStatus,
    this.claimReference,
    this.merchantContactDetails,
    this.notes,
    this.productName,
    this.merchantName,
    this.serialNumber,
    this.createdAt,
  });

  final String id;
  final String receiptId;
  final String? receiptItemId;
  final String consumerUserId;
  final DateTime warrantyStartDate;
  final DateTime warrantyEndDate;
  final String warrantyStatus;
  final String reminderStatus;
  final String? claimReference;
  final String? merchantContactDetails;
  final String? notes;
  final String? productName;
  final String? merchantName;
  final String? serialNumber;
  final DateTime? createdAt;

  int get daysRemaining {
    final now = DateTime.now();
    final end = DateTime(
      warrantyEndDate.year,
      warrantyEndDate.month,
      warrantyEndDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return end.difference(today).inDays;
  }

  bool get isExpired => daysRemaining < 0;
  bool get isExpiringSoon => daysRemaining >= 0 && daysRemaining <= 30;

  factory WarrantyModel.fromJson(Map<String, dynamic> json) {
    final receipt = json['receipts'];
    final item = json['receipt_items'];
    return WarrantyModel(
      id: json['id'] as String,
      receiptId: json['receipt_id'] as String,
      receiptItemId: json['receipt_item_id'] as String?,
      consumerUserId: json['consumer_user_id'] as String,
      warrantyStartDate: DateTime.parse(json['warranty_start_date'] as String),
      warrantyEndDate: DateTime.parse(json['warranty_end_date'] as String),
      warrantyStatus: json['warranty_status'] as String,
      reminderStatus: json['reminder_status'] as String,
      claimReference: json['claim_reference'] as String?,
      merchantContactDetails: json['merchant_contact_details'] as String?,
      notes: json['notes'] as String?,
      productName: item is Map ? item['item_name'] as String? : null,
      merchantName: receipt is Map
          ? receipt['merchant_name_raw'] as String?
          : null,
      serialNumber: item is Map ? item['serial_number'] as String? : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'receipt_id': receiptId,
      'receipt_item_id': receiptItemId,
      'consumer_user_id': consumerUserId,
      'warranty_start_date':
          warrantyStartDate.toIso8601String().split('T').first,
      'warranty_end_date': warrantyEndDate.toIso8601String().split('T').first,
      'warranty_status': warrantyStatus,
      'reminder_status': reminderStatus,
      'claim_reference': claimReference,
      'merchant_contact_details': merchantContactDetails,
      'notes': notes,
    };
  }
}

/// Return/refund record aligned with database schema.
class ReturnModel {
  const ReturnModel({
    required this.id,
    required this.receiptId,
    this.receiptItemId,
    required this.consumerUserId,
    required this.requestType,
    this.requestReason,
    this.requestDescription,
    this.supportingFileUrl,
    required this.requestStatus,
    this.refundAmount,
    this.merchantResponseNotes,
    this.returnDeadline,
    this.productName,
    this.merchantName,
    this.createdAt,
  });

  final String id;
  final String receiptId;
  final String? receiptItemId;
  final String consumerUserId;
  final String requestType;
  final String? requestReason;
  final String? requestDescription;
  final String? supportingFileUrl;
  final String requestStatus;
  final double? refundAmount;
  final String? merchantResponseNotes;
  final DateTime? returnDeadline;
  final String? productName;
  final String? merchantName;
  final DateTime? createdAt;

  int? get daysUntilDeadline {
    if (returnDeadline == null) return null;
    final now = DateTime.now();
    final deadline = DateTime(
      returnDeadline!.year,
      returnDeadline!.month,
      returnDeadline!.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return deadline.difference(today).inDays;
  }

  bool get isDeadlineSoon {
    final days = daysUntilDeadline;
    return days != null && days >= 0 && days <= 7;
  }

  factory ReturnModel.fromJson(Map<String, dynamic> json) {
    final receipt = json['receipts'];
    final item = json['receipt_items'];
    return ReturnModel(
      id: json['id'] as String,
      receiptId: json['receipt_id'] as String,
      receiptItemId: json['receipt_item_id'] as String?,
      consumerUserId: json['consumer_user_id'] as String,
      requestType: json['request_type'] as String,
      requestReason: json['request_reason'] as String?,
      requestDescription: json['request_description'] as String?,
      supportingFileUrl: json['supporting_file_url'] as String?,
      requestStatus: json['request_status'] as String,
      refundAmount: (json['refund_amount'] as num?)?.toDouble(),
      merchantResponseNotes: json['merchant_response_notes'] as String?,
      returnDeadline: json['return_deadline'] != null
          ? DateTime.parse(json['return_deadline'] as String)
          : null,
      productName: item is Map ? item['item_name'] as String? : null,
      merchantName: receipt is Map
          ? receipt['merchant_name_raw'] as String?
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'receipt_id': receiptId,
      'receipt_item_id': receiptItemId,
      'consumer_user_id': consumerUserId,
      'request_type': requestType,
      'request_reason': requestReason,
      'request_description': requestDescription,
      'supporting_file_url': supportingFileUrl,
      'request_status': requestStatus,
      'refund_amount': refundAmount,
      'merchant_response_notes': merchantResponseNotes,
      'return_deadline': returnDeadline?.toIso8601String().split('T').first,
    };
  }
}

/// Warranty status options for UI.
abstract final class WarrantyStatuses {
  static const all = [
    'active',
    'claim_started',
    'awaiting_response',
    'repair_in_progress',
    'replaced',
    'refunded',
    'rejected',
    'expired',
    'closed',
  ];
}

/// Return status options for UI.
abstract final class ReturnStatuses {
  static const all = [
    'not_started',
    'contacted_merchant',
    'awaiting_response',
    'product_returned',
    'refund_pending',
    'refund_received',
    'exchange_completed',
    'rejected',
    'closed',
  ];
}

/// Reminder preference options.
abstract final class ReminderStatuses {
  static const pending = 'pending';
  static const sent30 = 'sent_30_days';
  static const sent7 = 'sent_7_days';
  static const sentExpiry = 'sent_on_expiry';
  static const disabled = 'disabled';
}
