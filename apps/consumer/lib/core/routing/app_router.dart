import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

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
import '../../features/expenses/presentation/screens/duplicates_screen.dart';
import '../../features/receipts/presentation/screens/manual_entry_screen.dart';
import '../../features/receipts/presentation/screens/qr_scan_screen.dart';
import '../../features/receipts/presentation/screens/receipt_detail_screen.dart';
import '../../features/receipts/presentation/screens/receipt_review_screen.dart';
import '../../features/receipts/presentation/screens/receipt_wallet_screen.dart';
import '../../features/receipts/presentation/screens/scan_hub_screen.dart';
import '../../features/insights/presentation/screens/insights_screen.dart';
import '../../features/warranties/presentation/screens/add_return_screen.dart';
import '../../features/warranties/presentation/screens/add_warranty_screen.dart';
import '../../features/warranties/presentation/screens/return_detail_screen.dart';
import '../../features/warranties/presentation/screens/warranties_returns_hub_screen.dart';
import '../../features/warranties/presentation/screens/warranty_detail_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
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
      GoRoute(
        path: '/receipts/scan',
        builder: (context, state) => const ScanHubScreen(),
      ),
      GoRoute(
        path: '/receipts/review',
        builder: (context, state) => const ReceiptReviewScreen(),
      ),
      GoRoute(
        path: '/receipts/manual',
        builder: (context, state) => const ManualEntryScreen(),
      ),
      GoRoute(
        path: '/receipts/qr-scan',
        builder: (context, state) => const QrScanScreen(),
      ),
      GoRoute(
        path: '/receipts/duplicates',
        builder: (context, state) => const DuplicatesScreen(),
      ),
      GoRoute(
        path: '/receipts/:id',
        builder: (context, state) => ReceiptDetailScreen(
          receiptId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/warranties',
        builder: (context, state) => const WarrantiesReturnsHubScreen(),
      ),
      GoRoute(
        path: '/warranties/add/:receiptId',
        builder: (context, state) => AddWarrantyScreen(
          receiptId: state.pathParameters['receiptId']!,
        ),
      ),
      GoRoute(
        path: '/warranties/:id',
        builder: (context, state) => WarrantyDetailScreen(
          warrantyId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/returns/add/:receiptId',
        builder: (context, state) => AddReturnScreen(
          receiptId: state.pathParameters['receiptId']!,
        ),
      ),
      GoRoute(
        path: '/returns/:id',
        builder: (context, state) => ReturnDetailScreen(
          returnId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/notifications/preferences',
        builder: (context, state) => const NotificationPreferencesScreen(),
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
            builder: (context, state) => const ReceiptWalletScreen(),
          ),
          GoRoute(
            path: '/home/scan',
            builder: (context, state) => const ScanHubScreen(),
          ),
          GoRoute(
            path: '/home/insights',
            builder: (context, state) => const InsightsScreen(),
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
