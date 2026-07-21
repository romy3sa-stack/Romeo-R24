/// Platform roles (Step 1.2). Mirrors the `public.user_role` Postgres enum
/// defined in supabase/migrations/20260101000002_enums.sql — keep both in
/// sync if this ever changes (Rule 22).
///
/// Deliberately absent: any Merchant role (Rules 2-6). Merchants never
/// authenticate and therefore never have a role.
enum UserRole {
  consumer,
  accountant,
  accountingFirmManager,
  superAdministrator,
  supportAdministrator;

  /// The exact string stored in `public.users.role`.
  String get dbValue => switch (this) {
        UserRole.consumer => 'consumer',
        UserRole.accountant => 'accountant',
        UserRole.accountingFirmManager => 'accounting_firm_manager',
        UserRole.superAdministrator => 'super_administrator',
        UserRole.supportAdministrator => 'support_administrator',
      };

  static UserRole fromDbValue(String value) {
    return UserRole.values.firstWhere(
      (role) => role.dbValue == value,
      orElse: () => throw ArgumentError('Unknown user_role "$value"'),
    );
  }

  bool get isAccountantFamily =>
      this == UserRole.accountant || this == UserRole.accountingFirmManager;

  bool get isAdministrator =>
      this == UserRole.superAdministrator || this == UserRole.supportAdministrator;
}
