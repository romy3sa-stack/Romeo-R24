import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../core/auth/auth_providers.dart';
import '../data/subscription_service.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService(ref.watch(supabaseClientProvider));
});

final currentSubscriptionProvider =
    FutureProvider.autoDispose<SubscriptionModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.read(subscriptionServiceProvider).fetchCurrentSubscription(
        userId: user.id,
      );
});

final effectivePlanProvider =
    FutureProvider.autoDispose<SubscriptionPlanDefinition>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return SubscriptionPlans.consumerFree;
  final sub = await ref
      .read(subscriptionServiceProvider)
      .fetchCurrentSubscription(userId: user.id);
  return ref.read(subscriptionServiceProvider).effectivePlan(
        subscription: sub,
        ownerType: 'consumer',
      );
});
