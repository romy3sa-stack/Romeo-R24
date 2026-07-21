import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'analytics_providers.dart';

final _appOpenedProvider = Provider<void>((ref) {
  ref.read(analyticsServiceProvider).track('app_open');
});

/// Identifies authenticated users and tracks the initial app open event.
class AnalyticsListener extends ConsumerWidget {
  const AnalyticsListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(_appOpenedProvider);

    ref.listen(authStateProvider, (previous, next) {
      final analytics = ref.read(analyticsServiceProvider);
      final user = next.valueOrNull?.user;
      if (user != null) {
        analytics.identify(user.id, traits: {'email': user.email ?? ''});
      } else {
        analytics.reset();
      }
    });

    return child;
  }
}
