import 'dart:async';
import 'dart:typed_data';

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
    if (user == null) return const AuthState();

    try {
      final profile = await _client
          .from('users')
          .select('role, account_status, full_name, email_verified')
          .eq('id', user.id)
          .single();

      final role = UserRole.fromString(profile['role'] as String);
      var onboardingCompleted = true;
      var fullName = profile['full_name'] as String?;

      if (role == UserRole.consumer) {
        final consumerProfile = await _client
            .from('consumer_profiles')
            .select('onboarding_completed')
            .eq('user_id', user.id)
            .maybeSingle();
        onboardingCompleted =
            consumerProfile?['onboarding_completed'] as bool? ?? false;
      }

      return AuthState(
        user: user,
        role: role,
        accountStatus: profile['account_status'] as String?,
        fullName: fullName,
        onboardingCompleted: onboardingCompleted,
        emailVerified: profile['email_verified'] as bool? ??
            user.emailConfirmedAt != null,
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
    String? subscriptionPlan,
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
        'subscription_plan': subscriptionPlan ?? 'solo_accountant',
      },
    );
  }

  Future<void> updateAccountantPlan(String userId, String plan) async {
    await _client
        .from('accountants')
        .update({'subscription_plan': plan})
        .eq('user_id', userId);
  }

  Future<String> uploadVerificationDocument({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final path = '$userId/$fileName';
    await _client.storage.from('verification-documents').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    final url =
        _client.storage.from('verification-documents').getPublicUrl(path);
    await _client
        .from('accountants')
        .update({'verification_document_url': url})
        .eq('user_id', userId);
    return url;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
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

  Future<void> resendVerificationEmail(String email) {
    return _client.auth.resend(type: OtpType.signup, email: email);
  }

  Future<void> completeOnboarding({
    required String userId,
    required List<String> interests,
  }) async {
    await _client.from('consumer_profiles').update({
      'onboarding_completed': true,
      'onboarding_interests': interests,
    }).eq('user_id', userId);
  }

  Future<Map<String, dynamic>> getHomeStats(String userId) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();

    final receipts = await _client
        .from('receipts')
        .select('total_amount, currency')
        .eq('consumer_user_id', userId)
        .gte('created_at', monthStart)
        .isFilter('soft_deleted_at', null);

    final receiptList = receipts as List;
    double total = 0;
    for (final r in receiptList) {
      total += (r['total_amount'] as num?)?.toDouble() ?? 0;
    }

    final warranties = await _client
        .from('warranties')
        .select('id')
        .eq('consumer_user_id', userId)
        .eq('warranty_status', 'active');

    final returns = await _client
        .from('returns_and_refunds')
        .select('id')
        .eq('consumer_user_id', userId)
        .neq('request_status', 'closed');

    return {
      'monthlySpending': total,
      'receiptCount': receiptList.length,
      'activeWarranties': (warranties as List).length,
      'returnDeadlines': (returns as List).length,
    };
  }
}
