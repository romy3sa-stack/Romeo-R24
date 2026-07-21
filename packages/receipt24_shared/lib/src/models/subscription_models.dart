/// Subscription record aligned with database schema.
class SubscriptionModel {
  const SubscriptionModel({
    required this.id,
    this.userId,
    this.accountantId,
    required this.planName,
    required this.billingCycle,
    required this.amount,
    required this.currency,
    required this.subscriptionStatus,
    required this.startDate,
    this.renewalDate,
    this.paymentProvider,
    this.externalSubscriptionId,
    this.createdAt,
  });

  final String id;
  final String? userId;
  final String? accountantId;
  final String planName;
  final String billingCycle;
  final double amount;
  final String currency;
  final String subscriptionStatus;
  final DateTime startDate;
  final DateTime? renewalDate;
  final String? paymentProvider;
  final String? externalSubscriptionId;
  final DateTime? createdAt;

  bool get isActive =>
      subscriptionStatus == 'active' || subscriptionStatus == 'trialing';

  bool get isCancelled => subscriptionStatus == 'cancelled';

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      accountantId: json['accountant_id'] as String?,
      planName: json['plan_name'] as String,
      billingCycle: json['billing_cycle'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      subscriptionStatus: json['subscription_status'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      renewalDate: json['renewal_date'] != null
          ? DateTime.parse(json['renewal_date'] as String)
          : null,
      paymentProvider: json['payment_provider'] as String?,
      externalSubscriptionId: json['external_subscription_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}

/// Available subscription plan definition.
class SubscriptionPlanDefinition {
  const SubscriptionPlanDefinition({
    required this.id,
    required this.nameKey,
    required this.monthlyPrice,
    required this.annualPrice,
    this.currency = 'USD',
    required this.ownerType,
    this.stripePriceIdMonthly,
    this.stripePriceIdAnnual,
    this.features = const [],
  });

  final String id;
  final String nameKey;
  final double monthlyPrice;
  final double annualPrice;
  final String currency;
  final String ownerType;
  final String? stripePriceIdMonthly;
  final String? stripePriceIdAnnual;
  final List<String> featureKeys;

  double priceForCycle(String cycle) =>
      cycle == 'annual' ? annualPrice : monthlyPrice;

  bool get isFree => monthlyPrice == 0 && annualPrice == 0;
}

/// Subscription status constants.
abstract final class SubscriptionStatuses {
  static const active = 'active';
  static const trialing = 'trialing';
  static const pastDue = 'past_due';
  static const cancelled = 'cancelled';
  static const expired = 'expired';
}

/// Plan catalog for consumer and accountant subscriptions.
abstract final class SubscriptionPlans {
  static const consumerFree = SubscriptionPlanDefinition(
    id: 'consumer_free',
    nameKey: 'planConsumerFree',
    monthlyPrice: 0,
    annualPrice: 0,
    ownerType: 'consumer',
    featureKeys: [
      'featureReceiptScan',
      'featureBasicInsights',
      'featureWarrantyTracking',
    ],
  );

  static const consumerPlus = SubscriptionPlanDefinition(
    id: 'consumer_plus',
    nameKey: 'planConsumerPlus',
    monthlyPrice: 4.99,
    annualPrice: 49.99,
    ownerType: 'consumer',
    featureKeys: [
      'featureReceiptScan',
      'featureAdvancedInsights',
      'featureWarrantyTracking',
      'featureExport',
      'featureAccountantSharing',
    ],
  );

  static const consumerPro = SubscriptionPlanDefinition(
    id: 'consumer_pro',
    nameKey: 'planConsumerPro',
    monthlyPrice: 9.99,
    annualPrice: 99.99,
    ownerType: 'consumer',
    featureKeys: [
      'featureReceiptScan',
      'featureAdvancedInsights',
      'featureWarrantyTracking',
      'featureExport',
      'featureAccountantSharing',
      'featurePrioritySupport',
      'featureUnlimitedStorage',
    ],
  );

  static const accountantSolo = SubscriptionPlanDefinition(
    id: 'solo_accountant',
    nameKey: 'planSolo',
    monthlyPrice: 29.99,
    annualPrice: 299.99,
    ownerType: 'accountant',
    featureKeys: [
      'featureUpTo25Clients',
      'featureClientReceipts',
      'featureClassification',
    ],
  );

  static const accountantProfessional = SubscriptionPlanDefinition(
    id: 'professional_firm',
    nameKey: 'planProfessional',
    monthlyPrice: 79.99,
    annualPrice: 799.99,
    ownerType: 'accountant',
    featureKeys: [
      'featureUpTo100Clients',
      'featureClientReceipts',
      'featureClassification',
      'featureTeamMembers',
    ],
  );

  static const accountantEnterprise = SubscriptionPlanDefinition(
    id: 'enterprise_firm',
    nameKey: 'planEnterprise',
    monthlyPrice: 199.99,
    annualPrice: 1999.99,
    ownerType: 'accountant',
    featureKeys: [
      'featureUnlimitedClients',
      'featureClientReceipts',
      'featureClassification',
      'featureTeamMembers',
      'featurePrioritySupport',
    ],
  );

  static const consumerPlans = [consumerFree, consumerPlus, consumerPro];

  static const accountantPlans = [
    accountantSolo,
    accountantProfessional,
    accountantEnterprise,
  ];

  static SubscriptionPlanDefinition? findById(String id) {
    for (final p in [...consumerPlans, ...accountantPlans]) {
      if (p.id == id) return p;
    }
    return null;
  }
}
