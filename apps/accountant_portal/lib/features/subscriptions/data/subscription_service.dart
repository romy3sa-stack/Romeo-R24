import 'package:receipt24_shared/receipt24_shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionService {
  SubscriptionService(this._client);

  final SupabaseClient _client;

  Future<AccountantProfileModel?> _getProfile(String userId) async {
    final row = await _client
        .from('accountants')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return AccountantProfileModel.fromJson(row);
  }

  Future<SubscriptionModel?> fetchCurrentSubscription(String userId) async {
    final profile = await _getProfile(userId);
    if (profile == null) return null;

    final rows = await _client
        .from('subscriptions')
        .select()
        .eq('accountant_id', profile.id)
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
  }) async {
    final profile = await _getProfile(userId);
    if (profile == null) return null;

    final response = await _client.functions.invoke(
      'create-checkout-session',
      body: {
        'userId': userId,
        'planId': planId,
        'billingCycle': billingCycle,
        'ownerType': 'accountant',
        'accountantId': profile.id,
        'successUrl':
            'https://accountant.receipt24.com/subscription?success=true',
        'cancelUrl':
            'https://accountant.receipt24.com/subscription?cancelled=true',
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

  SubscriptionPlanDefinition effectivePlan(SubscriptionModel? subscription) {
    if (subscription != null && subscription.isActive) {
      return SubscriptionPlans.findById(subscription.planName) ??
          SubscriptionPlans.accountantSolo;
    }
    return SubscriptionPlans.accountantSolo;
  }
}
