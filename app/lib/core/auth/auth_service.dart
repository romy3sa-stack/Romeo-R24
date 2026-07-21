import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_bootstrap.dart';
import 'app_user.dart';

/// Authentication architecture (Phase 3 backbone).
///
/// Registration/login itself belongs to Phase 3 (not built yet — Phase 1
/// only wires the *architecture*). This service exposes the primitives every
/// later phase will build screens on top of:
///
///   - Supabase Auth handles password hashing, email verification, OAuth
///     (Google/Apple), MFA, session refresh and rate limiting server-side.
///   - `public.handle_new_auth_user()` (SQL trigger) mirrors every new
///     `auth.users` row into `public.users` with role='consumer' by default;
///     administrator roles can never be granted from client metadata.
///   - RLS then scopes everything the signed-in user can see/do.
class AuthService {
  AuthService({SupabaseClient? client}) : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;

  bool get isSignedIn => currentSession != null;

  /// Consumer registration (Step 3.2). `role` metadata defaults server-side
  /// to 'consumer' regardless of what is passed here if omitted; admin roles
  /// are always rejected server-side even if requested.
  Future<AuthResponse> signUpConsumer({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? country,
    String? currency,
    String preferredLanguage = 'en',
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'role': 'consumer',
        'full_name': fullName,
        'phone_number': phoneNumber,
        'country': country,
        'currency': currency,
        'preferred_language': preferredLanguage,
      },
    );
  }

  /// Accountant registration (Step 3.4). Resulting account is created with
  /// account_status='pending' until an administrator approves it — enforced
  /// server-side in `handle_new_auth_user()`, not trusted from the client.
  Future<AuthResponse> signUpAccountant({
    required String email,
    required String password,
    required String fullName,
    required String firmName,
    String? phoneNumber,
    String? country,
    String preferredLanguage = 'en',
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'role': 'accountant',
        'full_name': fullName,
        'firm_name': firmName,
        'phone_number': phoneNumber,
        'country': country,
        'preferred_language': preferredLanguage,
      },
    );
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<bool> signInWithGoogle() {
    return _client.auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<bool> signInWithApple() {
    return _client.auth.signInWithOAuth(OAuthProvider.apple);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Loads the caller's own `public.users` row. RLS guarantees this only
  /// ever returns the signed-in user's own record (or nothing).
  Future<AppUser?> fetchCurrentAppUser() async {
    final userId = currentSession?.user.id;
    if (userId == null) return null;

    final row = await _client.from('users').select().eq('id', userId).maybeSingle();
    if (row == null) return null;
    return AppUser.fromMap(row);
  }
}
