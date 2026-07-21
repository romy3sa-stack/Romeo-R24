-- Receipt24 · Phase 2 · Migration 06
-- Merchants (receipt-data-only, never an authenticated actor) + Receipts.

create table public.merchants (
  id uuid primary key default gen_random_uuid(),
  merchant_name text not null,
  trading_name text,
  business_category text,
  tax_number text,
  email text,
  phone_number text,
  website text,
  address text,
  city text,
  province_or_state text,
  postal_code text,
  country text references public.countries (code),
  latitude numeric(9, 6),
  longitude numeric(9, 6),
  logo_url text,
  merchant_source public.merchant_source not null default 'ocr_scan',
  verification_status public.merchant_verification_status not null default 'unverified',
  created_by_user_id uuid references public.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.merchants is
  'Merchant DATA ONLY, extracted from receipts. Merchants never authenticate, '
  'never own a subscription, never receive a dashboard, and never hold '
  'permissions of any kind (Rules 2-6). This row exists purely so multiple '
  'receipts can be linked to "the same shop".';

create index merchants_name_trgm_idx on public.merchants using gin (merchant_name gin_trgm_ops);
create index merchants_country_idx on public.merchants (country);
create index merchants_verification_status_idx on public.merchants (verification_status);

create table public.receipts (
  id uuid primary key default gen_random_uuid(),
  consumer_user_id uuid not null references public.users (id) on delete cascade,
  merchant_id uuid references public.merchants (id) on delete set null,
  merchant_name_raw text,
  receipt_number text,
  transaction_reference text,
  transaction_date date,
  subtotal numeric(12, 2),
  tax_amount numeric(12, 2),
  discount_amount numeric(12, 2),
  total_amount numeric(12, 2),
  currency text references public.currencies (code),
  payment_method text,
  receipt_source public.receipt_source not null default 'manual_entry',
  receipt_status public.receipt_status not null default 'draft',
  receipt_file_url text,
  receipt_image_url text,
  ocr_status public.ocr_status not null default 'not_applicable',
  ocr_confidence_score numeric(5, 2),
  verification_status public.receipt_verification_status not null default 'unverified',
  warranty_available boolean not null default false,
  return_deadline date,
  notes text,
  deleted_at timestamptz,               -- soft delete (Rule 17 / Rule 16)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.receipts is 'The core financial record. Never hard-deleted (Rule 16) — deleted_at is a soft-delete marker only.';

create index receipts_consumer_idx on public.receipts (consumer_user_id);
create index receipts_merchant_idx on public.receipts (merchant_id);
create index receipts_transaction_date_idx on public.receipts (transaction_date);
create index receipts_status_idx on public.receipts (receipt_status);
create index receipts_ocr_status_idx on public.receipts (ocr_status);
-- Supports duplicate detection (Step 6.4): same consumer + merchant + amount + date.
create index receipts_dup_candidate_idx
  on public.receipts (consumer_user_id, merchant_id, total_amount, transaction_date);
