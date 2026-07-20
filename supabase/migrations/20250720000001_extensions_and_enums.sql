-- Receipt24: Extensions and enumerated types
-- Phase 2 — Step 1

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- User roles (no merchant roles)
CREATE TYPE public.user_role AS ENUM (
  'consumer',
  'accountant',
  'accounting_firm_manager',
  'super_administrator',
  'support_administrator'
);

CREATE TYPE public.account_status AS ENUM (
  'active',
  'pending',
  'suspended',
  'deleted'
);

CREATE TYPE public.verification_status AS ENUM (
  'pending',
  'verified',
  'rejected',
  'unverified'
);

CREATE TYPE public.merchant_source AS ENUM (
  'ocr_scan',
  'manual_entry',
  'email_import',
  'administrator',
  'external_integration'
);

CREATE TYPE public.receipt_source AS ENUM (
  'camera_scan',
  'image_upload',
  'pdf_upload',
  'email_import',
  'manual_entry',
  'external_integration'
);

CREATE TYPE public.receipt_status AS ENUM (
  'draft',
  'processing',
  'pending_review',
  'confirmed',
  'archived',
  'failed'
);

CREATE TYPE public.ocr_status AS ENUM (
  'pending',
  'processing',
  'completed',
  'failed',
  'not_applicable'
);

CREATE TYPE public.expense_type AS ENUM (
  'personal',
  'business',
  'mixed_use'
);

CREATE TYPE public.access_status AS ENUM (
  'pending',
  'approved',
  'rejected',
  'revoked',
  'expired'
);

CREATE TYPE public.firm_role AS ENUM (
  'manager',
  'accountant',
  'viewer'
);

CREATE TYPE public.warranty_status AS ENUM (
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

CREATE TYPE public.return_request_status AS ENUM (
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

CREATE TYPE public.subscription_status AS ENUM (
  'active',
  'trialing',
  'past_due',
  'cancelled',
  'expired'
);

CREATE TYPE public.ticket_status AS ENUM (
  'open',
  'in_progress',
  'waiting_on_user',
  'resolved',
  'closed'
);

CREATE TYPE public.processing_status AS ENUM (
  'queued',
  'processing',
  'completed',
  'failed'
);

CREATE TYPE public.classification_source AS ENUM (
  'automatic',
  'ai_suggested',
  'user_confirmed',
  'accountant_assigned'
);

CREATE TYPE public.notification_type AS ENUM (
  'receipt_processed',
  'receipt_processing_completed',
  'receipt_processing_failed',
  'receipt_requires_review',
  'duplicate_detected',
  'warranty_expiry_reminder',
  'return_deadline_reminder',
  'accountant_invitation',
  'accountant_access_approved',
  'accountant_access_revoked',
  'subscription_renewal',
  'security_alert',
  'support_ticket_update',
  'general'
);

CREATE TYPE public.access_scope AS ENUM (
  'all_receipts',
  'business_only',
  'tax_related_only',
  'selected_categories',
  'selected_date_range'
);

CREATE TYPE public.payment_method AS ENUM (
  'cash',
  'card',
  'debit_card',
  'credit_card',
  'mobile_payment',
  'bank_transfer',
  'other',
  'unknown'
);

CREATE TYPE public.return_request_type AS ENUM (
  'return',
  'refund',
  'exchange'
);

CREATE TYPE public.reminder_status AS ENUM (
  'pending',
  'sent_30_days',
  'sent_7_days',
  'sent_on_expiry',
  'disabled'
);

CREATE TYPE public.billing_cycle AS ENUM (
  'monthly',
  'annual'
);

CREATE TYPE public.ticket_priority AS ENUM (
  'low',
  'medium',
  'high',
  'urgent'
);

CREATE TYPE public.upload_source AS ENUM (
  'camera',
  'gallery',
  'file_picker',
  'email',
  'manual'
);

CREATE TYPE public.file_type AS ENUM (
  'image_jpeg',
  'image_png',
  'image_heic',
  'application_pdf',
  'other'
);
