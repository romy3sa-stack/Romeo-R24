import 'package:receipt24_shared/receipt24_shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthState {
  const AuthState({
    this.user,
    this.role,
    this.fullName,
  });

  final User? user;
  final UserRole? role;
  final String? fullName;

  bool get isAuthenticated => user != null;
  bool get isAdminRole => role?.isAdmin == true;
  bool get isSuperAdmin => role == UserRole.superAdministrator;
  bool get isSupportAdmin => role == UserRole.supportAdministrator;
}
