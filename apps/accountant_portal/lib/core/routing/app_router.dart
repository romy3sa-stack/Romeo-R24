import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../auth/auth_providers.dart';
import '../auth/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/clients/presentation/screens/clients_screen.dart';
import '../../features/receipts/presentation/screens/receipt_screens.dart';
import '../../features/shell/presentation/screens/portal_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final authState = authAsync.valueOrNull ?? const AuthState();

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final path = state.matchedLocation;
      final isLogin = path == '/login';

      if (!authState.isAuthenticated) {
        return isLogin ? null : '/login';
      }

      if (!authState.isAccountantRole) {
        return path == '/wrong-role' ? null : '/wrong-role';
      }

      if (authState.isPendingAccountant) {
        return path == '/pending' ? null : '/pending';
      }

      if (!authState.isActiveAccountant) {
        return path == '/pending' ? null : '/pending';
      }

      if (isLogin || path == '/pending' || path == '/wrong-role') {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/pending',
        builder: (context, state) => const PendingScreen(),
      ),
      GoRoute(
        path: '/wrong-role',
        builder: (context, state) => const WrongRoleScreen(),
      ),
      GoRoute(
        path: '/clients/invite',
        builder: (context, state) => const InviteClientScreen(),
      ),
      GoRoute(
        path: '/clients/:clientId/receipts/:receiptId',
        builder: (context, state) => AccountantReceiptDetailScreen(
          clientId: state.pathParameters['clientId']!,
          receiptId: state.pathParameters['receiptId']!,
        ),
      ),
      GoRoute(
        path: '/clients/:clientId/receipts',
        builder: (context, state) => ClientReceiptsScreen(
          clientId: state.pathParameters['clientId']!,
        ),
      ),
      GoRoute(
        path: '/clients/:clientId',
        builder: (context, state) => ClientDetailScreen(
          clientId: state.pathParameters['clientId']!,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => PortalShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/clients',
            builder: (context, state) => const ClientsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
