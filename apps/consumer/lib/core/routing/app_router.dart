import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/accountant_register_screen.dart';
import '../../features/auth/presentation/screens/consumer_register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/profile_screen.dart';
import '../../features/home/presentation/screens/receipts_placeholder_screen.dart';
import '../../features/legal/presentation/screens/legal_content_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../auth/auth_providers.dart';
import '../auth/auth_state.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final authState = authAsync.valueOrNull ?? const AuthState();

  return GoRouter(
    initialLocation: '/welcome',
    redirect: (context, state) {
      final path = state.matchedLocation;
      final isPublic = _isPublicRoute(path);

      if (!authState.isAuthenticated && !isPublic) {
        return '/welcome';
      }

      if (authState.isAuthenticated) {
        if (authState.isPendingAccountant &&
            path != '/accountant-pending' &&
            !path.startsWith('/legal')) {
          return '/accountant-pending';
        }

        if (authState.role == UserRole.consumer) {
          if (authState.needsOnboarding && path != '/onboarding') {
            return '/onboarding';
          }
          if (!authState.needsOnboarding &&
              (path.startsWith('/welcome') || path.startsWith('/auth'))) {
            return '/home';
          }
        }

        if (authState.role?.isAdmin == true && path.startsWith('/auth')) {
          return '/welcome';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const ConsumerRegisterScreen(),
      ),
      GoRoute(
        path: '/auth/register/accountant',
        builder: (context, state) => const AccountantRegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/verify-email',
        builder: (context, state) => VerifyEmailScreen(
          email: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/accountant-pending',
        builder: (context, state) => const AccountantPendingScreen(),
      ),
      GoRoute(
        path: '/legal/privacy',
        builder: (context, state) =>
            const LegalContentScreen(type: 'privacy'),
      ),
      GoRoute(
        path: '/legal/terms',
        builder: (context, state) => const LegalContentScreen(type: 'terms'),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/home/receipts',
            builder: (context, state) => const ReceiptsPlaceholderScreen(),
          ),
          GoRoute(
            path: '/home/scan',
            builder: (context, state) => const ScanPlaceholderScreen(),
          ),
          GoRoute(
            path: '/home/insights',
            builder: (context, state) => const InsightsPlaceholderScreen(),
          ),
          GoRoute(
            path: '/home/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

bool _isPublicRoute(String path) {
  return path.startsWith('/welcome') ||
      path.startsWith('/auth') ||
      path.startsWith('/legal');
}
