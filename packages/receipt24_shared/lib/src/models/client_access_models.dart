/// Accountant profile aligned with database schema.
class AccountantProfileModel {
  const AccountantProfileModel({
    required this.id,
    required this.userId,
    required this.firmName,
    required this.verificationStatus,
    this.professionalRegistrationNumber,
    this.taxNumber,
    this.country,
    this.subscriptionPlan,
  });

  final String id;
  final String userId;
  final String firmName;
  final String verificationStatus;
  final String? professionalRegistrationNumber;
  final String? taxNumber;
  final String? country;
  final String? subscriptionPlan;

  factory AccountantProfileModel.fromJson(Map<String, dynamic> json) {
    return AccountantProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      firmName: json['firm_name'] as String,
      verificationStatus: json['verification_status'] as String,
      professionalRegistrationNumber:
          json['professional_registration_number'] as String?,
      taxNumber: json['tax_number'] as String?,
      country: json['country'] as String?,
      subscriptionPlan: json['subscription_plan'] as String?,
    );
  }
}

/// Client access record between accountant and consumer.
class ClientAccessModel {
  const ClientAccessModel({
    required this.id,
    required this.accountantId,
    required this.consumerUserId,
    required this.accessStatus,
    required this.accessScope,
    this.clientName,
    this.clientEmail,
    this.invitationEmail,
    this.invitationToken,
    this.approvedAt,
    this.createdAt,
  });

  final String id;
  final String accountantId;
  final String consumerUserId;
  final String accessStatus;
  final String accessScope;
  final String? clientName;
  final String? clientEmail;
  final String? invitationEmail;
  final String? invitationToken;
  final DateTime? approvedAt;
  final DateTime? createdAt;

  bool get isApproved => accessStatus == 'approved';
  bool get isPending => accessStatus == 'pending';
  bool get isRevoked => accessStatus == 'revoked';

  String get displayName =>
      clientName ?? clientEmail ?? invitationEmail ?? 'Client';

  factory ClientAccessModel.fromJson(Map<String, dynamic> json) {
    final user = json['users'];
    return ClientAccessModel(
      id: json['id'] as String,
      accountantId: json['accountant_id'] as String,
      consumerUserId: json['consumer_user_id'] as String,
      accessStatus: json['access_status'] as String,
      accessScope: json['access_scope'] as String,
      clientName: user is Map ? user['full_name'] as String? : null,
      clientEmail: user is Map ? user['email'] as String? : null,
      invitationEmail: json['invitation_email'] as String?,
      invitationToken: json['invitation_token'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}

/// Access scope options for client sharing.
abstract final class AccessScopes {
  static const all = 'all_receipts';
  static const businessOnly = 'business_only';
  static const taxRelatedOnly = 'tax_related_only';

  static const options = [all, businessOnly, taxRelatedOnly];
}
