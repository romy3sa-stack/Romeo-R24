import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../auth/auth_providers.dart';
import '../auth/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/shell/presentation/screens/admin_shell.dart';

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

      if (!authState.isAdminRole) {
        return path == '/wrong-role' ? null : '/wrong-role';
      }

      if (path == '/audit' && !authState.isSuperAdmin) {
        return '/dashboard';
      }

      if (isLogin || path == '/wrong-role') {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/wrong-role', builder: (_, __) => const WrongRoleScreen()),
      ShellRoute(
        builder: (_, __, child) => AdminShell(child: child),
        routes: [
          GoRoute(
              path: '/dashboard',
              builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/users', builder: (_, __) => const UsersScreen()),
          GoRoute(
              path: '/accountants',
              builder: (_, __) => const AccountantsScreen()),
          GoRoute(
              path: '/support',
              builder: (_, __) => const SupportScreen()),
          GoRoute(path: '/audit', builder: (_, __) => const AuditScreen()),
          GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
});
