import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt24_shared/receipt24_shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../auth/auth_providers.dart';
import '../auth/auth_state.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final authState = authAsync.valueOrNull ?? const AuthState();

  return GoRouter(
    initialLocation: '/welcome',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/welcome') ||
          state.matchedLocation.startsWith('/auth');

      if (!isAuthenticated && !isAuthRoute) {
        return '/welcome';
      }

      if (isAuthenticated && isAuthRoute) {
        return _homeRouteForRole(authState.role);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      // Phase 3+ routes will be added here:
      // /auth/register, /auth/login, /onboarding, /home, etc.
    ],
  );
});

String _homeRouteForRole(UserRole? role) {
  if (role == null) return '/welcome';
  switch (appAreaForRole(role)) {
    case AppArea.consumer:
      return '/home';
    case AppArea.accountant:
      return '/accountant';
    case AppArea.admin:
      return '/admin';
  }
}
