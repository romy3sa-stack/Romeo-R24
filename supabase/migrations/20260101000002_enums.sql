-- Receipt24 · Phase 2 · Migration 02
-- Enumerated types shared across the schema.
--
-- NOTE on naming: the master spec uses a few mixed-case field names
-- (OCR_status, IP_address, VAT_eligible, ...). SQL identifiers are
-- case-insensitive, so every field/enum below is normalised to snake_case
-- (ocr_status, ip_address, vat_eligible, ...). No meaning is changed.

-- Platform-wide roles (Step 1.2). Merchant roles are intentionally absent.
create type public.user_role as enum (
  'consumer',
  'accountant',
  'accounting_firm_manager',
  'super_administrator',
  'support_administrator'
);

create type public.account_status as enum (
  'pending',
  'active',
  'suspended',
  'deleted'
);

create type public.expense_type as enum (
  'personal',
  'business',
  'mixed_use'
);

create type public.accountant_verification_status as enum (
  'pending',
  'approved',
  'rejected',
  'suspended'
);

create type public.firm_member_role as enum (
  'manager',
  'staff'
);

create type public.accountant_access_status as enum (
  'pending',
  'approved',
  'revoked',
  'expired'
);

create type public.accountant_access_scope_type as enum (
  'all_receipts',
  'business_only',
  'tax_related_only',
  'selected_categories',
  'selected_date_range'
);

create type public.merchant_source as enum (
  'ocr_scan',
  'manual_entry',
  'email_import',
  'administrator',
  'external_integration'
);

create type public.merchant_verification_status as enum (
  'unverified',
  'verified',
  'flagged'
);

create type public.receipt_source as enum (
  'camera_scan',
  'image_upload',
  'pdf_upload',
  'email_import',
  'manual_entry',
  'external_integration'
);

create type public.receipt_status as enum (
  'draft',
  'processing',
  'needs_review',
  'confirmed',
  'flagged_duplicate',
  'archived'
);

create type public.ocr_status as enum (
  'not_applicable',
  'pending',
  'processing',
  'completed',
  'failed'
);

create type public.receipt_verification_status as enum (
  'unverified',
  'verified',
  'flagged'
);

create type public.classification_source as enum (
  'rule_based',
  'ai_suggested',
  'user_manual',
  'accountant_manual'
);

create type public.warranty_status as enum (
  'active',
  'claim_started',
  'awaiting_response',
  'repair_in_progress',
  'replaced',
  'refunded',
  'rejected',
  'expired',
  'closed'
);

create type public.warranty_reminder_status as enum (
  'none',
  'thirty_day_sent',
  'seven_day_sent',
  'expiry_sent'
);

create type public.return_request_type as enum (
  'return',
  'refund',
  'exchange'
);

create type public.return_request_status as enum (
  'not_started',
  'contacted_merchant',
  'awaiting_response',
  'product_returned',
  'refund_pending',
  'refund_received',
  'exchange_completed',
  'rejected',
  'closed'
);

create type public.notification_type as enum (
  'new_receipt_processed',
  'receipt_processing_completed',
  'receipt_processing_failed',
  'receipt_requires_review',
  'duplicate_receipt_detected',
  'warranty_expiry_reminder',
  'return_deadline_reminder',
  'accountant_invitation',
  'accountant_access_approved',
  'accountant_access_revoked',
  'subscription_renewal',
  'security_alert',
  'support_ticket_update'
);

create type public.subscription_status as enum (
  'trialing',
  'active',
  'past_due',
  'canceled',
  'expired'
);

create type public.billing_cycle as enum (
  'monthly',
  'annual'
);

create type public.support_ticket_priority as enum (
  'low',
  'medium',
  'high',
  'urgent'
);

create type public.support_ticket_status as enum (
  'open',
  'in_progress',
  'waiting_on_user',
  'resolved',
  'closed'
);

create type public.upload_processing_status as enum (
  'queued',
  'processing',
  'completed',
  'failed',
  'needs_review'
);
