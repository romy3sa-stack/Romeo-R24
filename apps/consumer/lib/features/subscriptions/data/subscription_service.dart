import 'package:receipt24_shared/receipt24_shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionService {
  SubscriptionService(this._client);

  final SupabaseClient _client;

  Future<SubscriptionModel?> fetchCurrentSubscription({
    String? userId,
    String? accountantId,
  }) async {
    var query = _client.from('subscriptions').select();

    if (userId != null) {
      query = query.eq('user_id', userId);
    } else if (accountantId != null) {
      query = query.eq('accountant_id', accountantId);
    } else {
      return null;
    }

    final rows = await query
        .inFilter('subscription_status', ['active', 'trialing', 'past_due'])
        .order('created_at', ascending: false)
        .limit(1);

    final list = rows as List;
    if (list.isEmpty) return null;
    return SubscriptionModel.fromJson(list.first as Map<String, dynamic>);
  }

  Future<String?> createCheckoutSession({
    required String userId,
    required String planId,
    String billingCycle = 'monthly',
    String ownerType = 'consumer',
    String? accountantId,
    String? successUrl,
    String? cancelUrl,
  }) async {
    final response = await _client.functions.invoke(
      'create-checkout-session',
      body: {
        'userId': userId,
        'planId': planId,
        'billingCycle': billingCycle,
        'ownerType': ownerType,
        'accountantId': accountantId,
        'successUrl': successUrl,
        'cancelUrl': cancelUrl,
      },
    );

    final data = response.data as Map<String, dynamic>?;
    return data?['checkoutUrl'] as String?;
  }

  Future<void> cancelSubscription(String subscriptionId) async {
    await _client.functions.invoke(
      'cancel-subscription',
      body: {'subscriptionId': subscriptionId},
    );
  }

  SubscriptionPlanDefinition? currentPlanDefinition(SubscriptionModel? sub) {
    if (sub == null) return null;
    return SubscriptionPlans.findById(sub.planName);
  }

  SubscriptionPlanDefinition effectivePlan({
    SubscriptionModel? subscription,
    required String ownerType,
  }) {
    if (subscription != null && subscription.isActive) {
      return SubscriptionPlans.findById(subscription.planName) ??
          (ownerType == 'accountant'
              ? SubscriptionPlans.accountantSolo
              : SubscriptionPlans.consumerFree);
    }
    return ownerType == 'accountant'
        ? SubscriptionPlans.accountantSolo
        : SubscriptionPlans.consumerFree;
  }
}
