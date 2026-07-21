import 'dart:async';

import 'package:receipt24_shared/receipt24_shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_state.dart';

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges async* {
    yield await _buildAuthState(_client.auth.currentUser);

    await for (final event in _client.auth.onAuthStateChange) {
      yield await _buildAuthState(event.session?.user);
    }
  }

  Future<AuthState> _buildAuthState(User? user) async {
    if (user == null) return const AuthState();

    try {
      final profile = await _client
          .from('users')
          .select('role, account_status, full_name')
          .eq('id', user.id)
          .single();

      final role = UserRole.fromString(profile['role'] as String);
      String? firmName;

      if (role.isAccountant) {
        final accountant = await _client
            .from('accountants')
            .select('firm_name')
            .eq('user_id', user.id)
            .maybeSingle();
        firmName = accountant?['firm_name'] as String?;
      }

      return AuthState(
        user: user,
        role: role,
        accountStatus: profile['account_status'] as String?,
        fullName: profile['full_name'] as String?,
        firmName: firmName,
      );
    } catch (_) {
      return AuthState(user: user);
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();
}
