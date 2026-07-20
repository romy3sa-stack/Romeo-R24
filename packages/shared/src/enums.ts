export const ACCOUNT_STATUSES = [
  "active",
  "pending",
  "suspended",
  "deleted",
] as const;

export const VERIFICATION_STATUSES = [
  "unverified",
  "pending",
  "verified",
  "rejected",
] as const;

export const ACCESS_STATUSES = [
  "invited",
  "pending_approval",
  "approved",
  "revoked",
  "expired",
  "rejected",
] as const;

export const ACCESS_SCOPES = [
  "all_receipts",
  "business_only",
  "tax_related_only",
  "selected_categories",
  "selected_date_range",
] as const;

export const MERCHANT_SOURCES = [
  "ocr_scan",
  "manual_entry",
  "email_import",
  "administrator",
  "external_integration",
] as const;

export const RECEIPT_SOURCES = [
  "camera_scan",
  "image_upload",
  "pdf_upload",
  "email_import",
  "manual_entry",
  "external_integration",
] as const;

export const RECEIPT_STATUSES = [
  "draft",
  "processing",
  "needs_review",
  "confirmed",
  "archived",
  "soft_deleted",
] as const;

export const OCR_STATUSES = [
  "not_started",
  "queued",
  "processing",
  "completed",
  "failed",
  "needs_review",
] as const;

export const EXPENSE_TYPES = ["personal", "business", "mixed_use"] as const;

export const WARRANTY_STATUSES = [
  "active",
  "claim_started",
  "awaiting_response",
  "repair_in_progress",
  "replaced",
  "refunded",
  "rejected",
  "expired",
  "closed",
] as const;

export const RETURN_REQUEST_STATUSES = [
  "not_started",
  "contacted_merchant",
  "awaiting_response",
  "product_returned",
  "refund_pending",
  "refund_received",
  "exchange_completed",
  "rejected",
  "closed",
] as const;

export const SUBSCRIPTION_STATUSES = [
  "trialing",
  "active",
  "past_due",
  "cancelled",
  "expired",
] as const;

export const TICKET_STATUSES = [
  "open",
  "in_progress",
  "waiting_on_user",
  "resolved",
  "closed",
] as const;

export const FIRM_ROLES = ["member", "manager", "owner"] as const;

export type AccountStatus = (typeof ACCOUNT_STATUSES)[number];
export type VerificationStatus = (typeof VERIFICATION_STATUSES)[number];
export type AccessStatus = (typeof ACCESS_STATUSES)[number];
export type AccessScope = (typeof ACCESS_SCOPES)[number];
export type MerchantSource = (typeof MERCHANT_SOURCES)[number];
export type ReceiptSource = (typeof RECEIPT_SOURCES)[number];
export type ReceiptStatus = (typeof RECEIPT_STATUSES)[number];
export type OcrStatus = (typeof OCR_STATUSES)[number];
export type ExpenseType = (typeof EXPENSE_TYPES)[number];
export type WarrantyStatus = (typeof WARRANTY_STATUSES)[number];
export type ReturnRequestStatus = (typeof RETURN_REQUEST_STATUSES)[number];
export type SubscriptionStatus = (typeof SUBSCRIPTION_STATUSES)[number];
export type TicketStatus = (typeof TICKET_STATUSES)[number];
export type FirmRole = (typeof FIRM_ROLES)[number];
