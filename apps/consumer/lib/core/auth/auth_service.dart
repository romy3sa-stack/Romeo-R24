import 'dart:async';

import 'package:receipt24_shared/receipt24_shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_state.dart';

/// Supabase Auth integration with role-based profile loading.
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
    if (user == null) {
      return const AuthState();
    }

    try {
      final profile = await _client
          .from('users')
          .select('role, account_status')
          .eq('id', user.id)
          .single();

      return AuthState(
        user: user,
        role: UserRole.fromString(profile['role'] as String),
        accountStatus: profile['account_status'] as String?,
      );
    } catch (_) {
      return AuthState(user: user);
    }
  }

  Future<AuthResponse> signUpConsumer({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? country,
    String? currency,
    String? preferredLanguage,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'role': UserRole.consumer.value,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'country': country,
        'currency': currency,
        'preferred_language': preferredLanguage ?? 'en',
      },
    );
  }

  Future<AuthResponse> signUpAccountant({
    required String email,
    required String password,
    required String fullName,
    required String firmName,
    String? professionalRegistrationNumber,
    String? taxNumber,
    String? country,
    String? address,
    String? phoneNumber,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'role': UserRole.accountant.value,
        'full_name': fullName,
        'firm_name': firmName,
        'professional_registration_number': professionalRegistrationNumber,
        'tax_number': taxNumber,
        'country': country,
        'address': address,
        'phone_number': phoneNumber,
      },
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signInWithGoogle() {
    return _client.auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<void> signInWithApple() {
    return _client.auth.signInWithOAuth(OAuthProvider.apple);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> resetPassword(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }

  bool hasPermission(String permission) {
    final role = _client.auth.currentUser != null ? null : null;
    // Resolved via authStateProvider in UI layer
    return role != null;
  }
}
