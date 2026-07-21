import '../rbac/user_role.dart';

/// The three platform areas (Step 1.1). One shared codebase, three distinct
/// experiences, gated by [UserRole] — never by a merchant concept, which
/// does not exist in this app.
enum AppArea {
  consumer,
  accountant,
  admin;

  /// The area a given role is allowed to land in immediately after sign-in.
  /// Phase 3+ screens will use this to route post-login; Phase 1 only wires
  /// the decision, not the destination screens themselves.
  static AppArea forRole(UserRole role) {
    switch (role) {
      case UserRole.consumer:
        return AppArea.consumer;
      case UserRole.accountant:
      case UserRole.accountingFirmManager:
        return AppArea.accountant;
      case UserRole.superAdministrator:
      case UserRole.supportAdministrator:
        return AppArea.admin;
    }
  }

  String get label => switch (this) {
        AppArea.consumer => 'Consumer App',
        AppArea.accountant => 'Accountant Portal',
        AppArea.admin => 'Super Admin Dashboard',
      };
}
