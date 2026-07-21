import 'package:equatable/equatable.dart';

import '../rbac/user_role.dart';

/// Client-side mirror of a `public.users` row (see
/// supabase/migrations/20260101000004_users_and_profiles.sql). Populated
/// after Supabase Auth sign-in by reading the user's own row — which RLS
/// always allows (`id = auth.uid()`).
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.accountStatus,
    this.phoneNumber,
    this.profilePhotoUrl,
    this.preferredLanguage = 'en',
    this.country,
    this.currency,
    this.emailVerified = false,
    this.phoneVerified = false,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String accountStatus;
  final String? phoneNumber;
  final String? profilePhotoUrl;
  final String preferredLanguage;
  final String? country;
  final String? currency;
  final bool emailVerified;
  final bool phoneVerified;

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      role: UserRole.fromDbValue(map['role'] as String),
      accountStatus: map['account_status'] as String,
      phoneNumber: map['phone_number'] as String?,
      profilePhotoUrl: map['profile_photo_url'] as String?,
      preferredLanguage: map['preferred_language'] as String? ?? 'en',
      country: map['country'] as String?,
      currency: map['currency'] as String?,
      emailVerified: map['email_verified'] as bool? ?? false,
      phoneVerified: map['phone_verified'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        role,
        accountStatus,
        phoneNumber,
        profilePhotoUrl,
        preferredLanguage,
        country,
        currency,
        emailVerified,
        phoneVerified,
      ];
}
