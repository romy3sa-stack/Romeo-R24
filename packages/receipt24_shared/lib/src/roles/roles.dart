/// Receipt24 user roles.
/// Merchants do NOT have roles — merchant data exists only on receipts.
enum UserRole {
  consumer('consumer'),
  accountant('accountant'),
  accountingFirmManager('accounting_firm_manager'),
  superAdministrator('super_administrator'),
  supportAdministrator('support_administrator');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.consumer,
    );
  }

  bool get isAdmin =>
      this == UserRole.superAdministrator ||
      this == UserRole.supportAdministrator;

  bool get isAccountant =>
      this == UserRole.accountant ||
      this == UserRole.accountingFirmManager;

  bool get isConsumer => this == UserRole.consumer;
}

/// Application areas within the Receipt24 platform.
enum AppArea {
  consumer,
  accountant,
  admin,
}

/// Maps roles to their default application area.
AppArea appAreaForRole(UserRole role) {
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

/// Role-based permissions matrix.
class RolePermissions {
  static const Map<UserRole, Set<String>> permissions = {
    UserRole.consumer: {
      'receipts.scan',
      'receipts.upload',
      'receipts.manual_entry',
      'receipts.view_own',
      'receipts.edit_own',
      'receipts.share_accountant',
      'receipts.export',
      'expenses.categorise',
      'warranties.manage',
      'returns.manage',
      'subscriptions.manage',
      'profile.manage',
    },
    UserRole.accountant: {
      'clients.invite',
      'clients.view_approved',
      'receipts.view_client',
      'receipts.classify',
      'receipts.add_notes',
      'receipts.request_documents',
      'reports.generate',
      'reports.export',
      'profile.manage',
    },
    UserRole.accountingFirmManager: {
      'clients.invite',
      'clients.view_approved',
      'receipts.view_client',
      'receipts.classify',
      'receipts.add_notes',
      'receipts.request_documents',
      'reports.generate',
      'reports.export',
      'staff.manage',
      'profile.manage',
    },
    UserRole.superAdministrator: {
      'users.manage_consumers',
      'users.manage_accountants',
      'users.verify_accountants',
      'users.suspend',
      'categories.manage',
      'ocr.monitor',
      'subscriptions.manage',
      'support.manage',
      'audit.view',
      'duplicates.review',
      'notifications.manage',
      'languages.manage',
      'countries.manage',
      'legal.manage',
    },
    UserRole.supportAdministrator: {
      'users.view',
      'support.manage',
      'audit.view',
    },
  };

  static bool hasPermission(UserRole role, String permission) {
    return permissions[role]?.contains(permission) ?? false;
  }
}
