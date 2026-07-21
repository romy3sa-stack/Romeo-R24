/// In-app notification aligned with database schema.
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.notificationType,
    required this.title,
    required this.message,
    this.relatedRecordType,
    this.relatedRecordId,
    required this.readStatus,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String notificationType;
  final String title;
  final String message;
  final String? relatedRecordType;
  final String? relatedRecordId;
  final bool readStatus;
  final DateTime? createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      notificationType: json['notification_type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      relatedRecordType: json['related_record_type'] as String?,
      relatedRecordId: json['related_record_id'] as String?,
      readStatus: json['read_status'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'notification_type': notificationType,
      'title': title,
      'message': message,
      'related_record_type': relatedRecordType,
      'related_record_id': relatedRecordId,
      'read_status': readStatus,
    };
  }
}

/// User notification channel preferences from consumer_profiles.
class NotificationPreferences {
  const NotificationPreferences({
    this.push = true,
    this.email = true,
    this.sms = false,
    this.warrantyReminders = true,
    this.returnReminders = true,
    this.marketing = false,
  });

  final bool push;
  final bool email;
  final bool sms;
  final bool warrantyReminders;
  final bool returnReminders;
  final bool marketing;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      push: json['push'] as bool? ?? true,
      email: json['email'] as bool? ?? true,
      sms: json['sms'] as bool? ?? false,
      warrantyReminders: json['warranty_reminders'] as bool? ?? true,
      returnReminders: json['return_reminders'] as bool? ?? true,
      marketing: json['marketing'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'push': push,
      'email': email,
      'sms': sms,
      'warranty_reminders': warrantyReminders,
      'return_reminders': returnReminders,
      'marketing': marketing,
    };
  }

  NotificationPreferences copyWith({
    bool? push,
    bool? email,
    bool? sms,
    bool? warrantyReminders,
    bool? returnReminders,
    bool? marketing,
  }) {
    return NotificationPreferences(
      push: push ?? this.push,
      email: email ?? this.email,
      sms: sms ?? this.sms,
      warrantyReminders: warrantyReminders ?? this.warrantyReminders,
      returnReminders: returnReminders ?? this.returnReminders,
      marketing: marketing ?? this.marketing,
    );
  }
}

/// Notification type constants matching database enum.
abstract final class NotificationTypes {
  static const receiptProcessed = 'receipt_processed';
  static const receiptProcessingCompleted = 'receipt_processing_completed';
  static const receiptProcessingFailed = 'receipt_processing_failed';
  static const receiptRequiresReview = 'receipt_requires_review';
  static const duplicateDetected = 'duplicate_detected';
  static const warrantyExpiryReminder = 'warranty_expiry_reminder';
  static const returnDeadlineReminder = 'return_deadline_reminder';
  static const accountantInvitation = 'accountant_invitation';
  static const accountantAccessApproved = 'accountant_access_approved';
  static const accountantAccessRevoked = 'accountant_access_revoked';
  static const subscriptionRenewal = 'subscription_renewal';
  static const securityAlert = 'security_alert';
  static const supportTicketUpdate = 'support_ticket_update';
  static const general = 'general';
}
