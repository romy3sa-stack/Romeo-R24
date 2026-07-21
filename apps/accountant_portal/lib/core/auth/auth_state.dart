import 'package:receipt24_shared/receipt24_shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthState {
  const AuthState({
    this.user,
    this.role,
    this.accountStatus,
    this.fullName,
    this.firmName,
    this.isLoading = false,
  });

  final User? user;
  final UserRole? role;
  final String? accountStatus;
  final String? fullName;
  final String? firmName;
  final bool isLoading;

  bool get isAuthenticated => user != null;

  bool get isAccountantRole => role?.isAccountant == true;

  bool get isPendingAccountant =>
      isAccountantRole && accountStatus == 'pending';

  bool get isActiveAccountant =>
      isAccountantRole && accountStatus == 'active';
}
