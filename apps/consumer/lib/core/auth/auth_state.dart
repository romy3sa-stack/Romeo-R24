import 'package:receipt24_shared/receipt24_shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication state including user profile and role.
class AuthState {
  const AuthState({
    this.user,
    this.role,
    this.accountStatus,
    this.fullName,
    this.onboardingCompleted = false,
    this.emailVerified = false,
    this.isLoading = false,
  });

  final User? user;
  final UserRole? role;
  final String? accountStatus;
  final String? fullName;
  final bool onboardingCompleted;
  final bool emailVerified;
  final bool isLoading;

  bool get isAuthenticated => user != null;

  bool get isPendingAccountant =>
      role?.isAccountant == true && accountStatus == 'pending';

  bool get needsOnboarding =>
      role == UserRole.consumer && !onboardingCompleted;

  bool get needsEmailVerification =>
      isAuthenticated && !emailVerified && role == UserRole.consumer;

  AuthState copyWith({
    User? user,
    UserRole? role,
    String? accountStatus,
    String? fullName,
    bool? onboardingCompleted,
    bool? emailVerified,
    bool? isLoading,
  }) {
    return AuthState(
      user: user ?? this.user,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      fullName: fullName ?? this.fullName,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      emailVerified: emailVerified ?? this.emailVerified,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
