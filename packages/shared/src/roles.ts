/**
 * Receipt24 platform roles.
 * Merchant roles are intentionally excluded — merchants exist only as receipt data.
 */
export const USER_ROLES = [
  "consumer",
  "accountant",
  "accounting_firm_manager",
  "super_administrator",
  "support_administrator",
] as const;

export type UserRole = (typeof USER_ROLES)[number];

export const FORBIDDEN_MERCHANT_ROLES = [
  "merchant_owner",
  "merchant_manager",
  "merchant_cashier",
  "merchant_staff",
  "merchant_administrator",
] as const;

export const ADMIN_ROLES: UserRole[] = [
  "super_administrator",
  "support_administrator",
];

export const ACCOUNTANT_ROLES: UserRole[] = [
  "accountant",
  "accounting_firm_manager",
];

export function isAdminRole(role: UserRole): boolean {
  return ADMIN_ROLES.includes(role);
}

export function isAccountantRole(role: UserRole): boolean {
  return ACCOUNTANT_ROLES.includes(role);
}

export function isConsumerRole(role: UserRole): boolean {
  return role === "consumer";
}
