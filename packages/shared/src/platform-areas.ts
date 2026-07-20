/**
 * Three platform areas. Merchants are never a platform area.
 */
export const PLATFORM_AREAS = {
  consumer: {
    id: "consumer",
    name: "Consumer App",
    hosts: ["app.receipt24.com", "www.receipt24.com"],
    allowedRoles: ["consumer"] as const,
  },
  accountant: {
    id: "accountant",
    name: "Accountant Portal",
    hosts: ["accountant.receipt24.com"],
    allowedRoles: ["accountant", "accounting_firm_manager"] as const,
  },
  admin: {
    id: "admin",
    name: "Super Admin Dashboard",
    hosts: ["admin.receipt24.com"],
    allowedRoles: ["super_administrator", "support_administrator"] as const,
  },
} as const;

export type PlatformAreaId = keyof typeof PLATFORM_AREAS;
