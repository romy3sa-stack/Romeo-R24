import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../core/auth/auth_providers.dart';
import '../data/insights_service.dart';

final insightsServiceProvider = Provider<InsightsService>((ref) {
  return InsightsService(ref.watch(supabaseClientProvider));
});

final insightsFilterProvider =
    StateProvider<InsightsFilter>((ref) => const InsightsFilter());

final insightsDataProvider =
    FutureProvider.autoDispose<InsightsData>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return InsightsData.empty;
  final filter = ref.watch(insightsFilterProvider);
  return ref.read(insightsServiceProvider).computeInsights(
        userId: user.id,
        filter: filter,
      );
});
