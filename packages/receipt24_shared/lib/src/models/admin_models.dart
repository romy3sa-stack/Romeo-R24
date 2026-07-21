/// Summary user record for admin listing.
class AdminUserSummary {
  const AdminUserSummary({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.accountStatus,
    this.country,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
  final String accountStatus;
  final String? country;
  final DateTime? createdAt;

  factory AdminUserSummary.fromJson(Map<String, dynamic> json) {
    return AdminUserSummary(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      accountStatus: json['account_status'] as String,
      country: json['country'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}

/// Accountant record for admin verification.
class AdminAccountantSummary {
  const AdminAccountantSummary({
    required this.id,
    required this.userId,
    required this.firmName,
    required this.verificationStatus,
    this.fullName,
    this.email,
    this.professionalRegistrationNumber,
    this.verificationDocumentUrl,
    this.country,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String firmName;
  final String verificationStatus;
  final String? fullName;
  final String? email;
  final String? professionalRegistrationNumber;
  final String? verificationDocumentUrl;
  final String? country;
  final DateTime? createdAt;

  bool get isPending => verificationStatus == 'pending';

  factory AdminAccountantSummary.fromJson(Map<String, dynamic> json) {
    final user = json['users'];
    return AdminAccountantSummary(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      firmName: json['firm_name'] as String,
      verificationStatus: json['verification_status'] as String,
      fullName: user is Map ? user['full_name'] as String? : null,
      email: user is Map ? user['email'] as String? : null,
      professionalRegistrationNumber:
          json['professional_registration_number'] as String?,
      verificationDocumentUrl: json['verification_document_url'] as String?,
      country: json['country'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}

/// Support ticket for admin handling.
class SupportTicketModel {
  const SupportTicketModel({
    required this.id,
    required this.userId,
    required this.ticketNumber,
    required this.subject,
    required this.description,
    this.category,
    required this.priority,
    required this.ticketStatus,
    this.userName,
    this.userEmail,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String ticketNumber;
  final String subject;
  final String description;
  final String? category;
  final String priority;
  final String ticketStatus;
  final String? userName;
  final String? userEmail;
  final DateTime? createdAt;

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    final user = json['users'];
    return SupportTicketModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      ticketNumber: json['ticket_number'] as String,
      subject: json['subject'] as String,
      description: json['description'] as String,
      category: json['category'] as String?,
      priority: json['priority'] as String,
      ticketStatus: json['ticket_status'] as String,
      userName: user is Map ? user['full_name'] as String? : null,
      userEmail: user is Map ? user['email'] as String? : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}

/// Audit log entry for admin review.
class AuditLogModel {
  const AuditLogModel({
    required this.id,
    this.userId,
    required this.actionType,
    required this.recordType,
    this.recordId,
    this.userName,
    this.createdAt,
  });

  final String id;
  final String? userId;
  final String actionType;
  final String recordType;
  final String? recordId;
  final String? userName;
  final DateTime? createdAt;

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    final user = json['users'];
    return AuditLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      actionType: json['action_type'] as String,
      recordType: json['record_type'] as String,
      recordId: json['record_id'] as String?,
      userName: user is Map ? user['full_name'] as String? : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
