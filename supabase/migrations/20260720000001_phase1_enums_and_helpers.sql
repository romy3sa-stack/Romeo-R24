-- Receipt24 Phase 1–2: enums, extensions, and shared trigger helpers
-- Merchants are data-only. No merchant auth, roles, or subscriptions.

create extension if not exists "pgcrypto";
create extension if not exists "citext";

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------

create type public.user_role as enum (
  'consumer',
  'accountant',
  'accounting_firm_manager',
  'super_administrator',
  'support_administrator'
);

create type public.account_status as enum (
  'active',
  'pending',
  'suspended',
  'deleted'
);

create type public.verification_status as enum (
  'unverified',
  'pending',
  'verified',
  'rejected'
);

create type public.access_status as enum (
  'invited',
  'pending_approval',
  'approved',
  'revoked',
  'expired',
  'rejected'
);

create type public.access_scope as enum (
  'all_receipts',
  'business_only',
  'tax_related_only',
  'selected_categories',
  'selected_date_range'
);

create type public.firm_role as enum (
  'member',
  'manager',
  'owner'
);

create type public.merchant_source as enum (
  'ocr_scan',
  'manual_entry',
  'email_import',
  'administrator',
  'external_integration'
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
  'archived',
  'soft_deleted'
);

create type public.ocr_status as enum (
  'not_started',
  'queued',
  'processing',
  'completed',
  'failed',
  'needs_review'
);

create type public.expense_type as enum (
  'personal',
  'business',
  'mixed_use'
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

create type public.subscription_status as enum (
  'trialing',
  'active',
  'past_due',
  'cancelled',
  'expired'
);

create type public.ticket_status as enum (
  'open',
  'in_progress',
  'waiting_on_user',
  'resolved',
  'closed'
);

create type public.ticket_priority as enum (
  'low',
  'medium',
  'high',
  'urgent'
);

create type public.classification_source as enum (
  'user',
  'accountant',
  'rule_engine',
  'ai_suggestion',
  'administrator'
);

create type public.reminder_status as enum (
  'none',
  'scheduled',
  'sent_30_day',
  'sent_7_day',
  'sent_expiry',
  'disabled'
);

-- ---------------------------------------------------------------------------
-- Utility: updated_at trigger
-- ---------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;
