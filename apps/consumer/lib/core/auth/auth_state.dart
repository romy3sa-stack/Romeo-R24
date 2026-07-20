import 'package:receipt24_shared/receipt24_shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication state including user profile and role.
class AuthState {
  const AuthState({
    this.user,
    this.role,
    this.accountStatus,
    this.isLoading = false,
  });

  final User? user;
  final UserRole? role;
  final String? accountStatus;
  final bool isLoading;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    UserRole? role,
    String? accountStatus,
    bool? isLoading,
  }) {
    return AuthState(
      user: user ?? this.user,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
