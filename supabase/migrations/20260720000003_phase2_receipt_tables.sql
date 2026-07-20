-- Receipt24 Phase 2: receipts, items, uploads, expenses, warranties, returns

-- ---------------------------------------------------------------------------
-- Receipts
-- ---------------------------------------------------------------------------

create table public.receipts (
  id uuid primary key default gen_random_uuid(),
  consumer_user_id uuid not null references public.users (id) on delete cascade,
  merchant_id uuid references public.merchants (id),
  merchant_name_raw text,
  receipt_number text,
  transaction_reference text,
  transaction_date date,
  subtotal numeric(14, 2),
  tax_amount numeric(14, 2),
  discount_amount numeric(14, 2),
  total_amount numeric(14, 2),
  currency char(3) not null default 'ZAR',
  payment_method text,
  receipt_source public.receipt_source not null,
  receipt_status public.receipt_status not null default 'draft',
  receipt_file_url text,
  receipt_image_url text,
  ocr_status public.ocr_status not null default 'not_started',
  ocr_confidence_score numeric(5, 2),
  verification_status public.verification_status not null default 'unverified',
  warranty_available boolean not null default false,
  return_deadline date,
  receipt_category_id uuid references public.receipt_categories (id),
  notes text,
  is_duplicate_suspected boolean not null default false,
  duplicate_of_receipt_id uuid references public.receipts (id),
  deleted_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint receipts_ocr_confidence_chk
    check (ocr_confidence_score is null or (ocr_confidence_score >= 0 and ocr_confidence_score <= 100)),
  constraint receipts_currency_chk check (char_length(currency) = 3)
);

create index receipts_consumer_user_id_idx on public.receipts (consumer_user_id);
create index receipts_merchant_id_idx on public.receipts (merchant_id);
create index receipts_transaction_date_idx on public.receipts (transaction_date);
create index receipts_status_idx on public.receipts (receipt_status);
create index receipts_ocr_status_idx on public.receipts (ocr_status);
create index receipts_duplicate_flag_idx on public.receipts (is_duplicate_suspected)
  where is_duplicate_suspected = true;

create trigger receipts_set_updated_at
before update on public.receipts
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Receipt items
-- ---------------------------------------------------------------------------

create table public.receipt_items (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null references public.receipts (id) on delete cascade,
  item_name text not null,
  item_description text,
  item_category text,
  quantity numeric(12, 3) not null default 1,
  unit_price numeric(14, 2),
  tax_rate numeric(7, 4),
  tax_amount numeric(14, 2),
  discount_amount numeric(14, 2),
  total_price numeric(14, 2),
  serial_number text,
  warranty_period text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index receipt_items_receipt_id_idx on public.receipt_items (receipt_id);

create trigger receipt_items_set_updated_at
before update on public.receipt_items
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Receipt uploads
-- ---------------------------------------------------------------------------

create table public.receipt_uploads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  file_url text not null,
  file_type text not null,
  upload_source public.receipt_source not null,
  ocr_status public.ocr_status not null default 'not_started',
  ocr_raw_text text,
  processing_status text not null default 'pending',
  linked_receipt_id uuid references public.receipts (id),
  page_count integer not null default 1,
  error_message text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index receipt_uploads_user_id_idx on public.receipt_uploads (user_id);
create index receipt_uploads_ocr_status_idx on public.receipt_uploads (ocr_status);

create trigger receipt_uploads_set_updated_at
before update on public.receipt_uploads
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Expense classification
-- ---------------------------------------------------------------------------

create table public.receipt_expense_classification (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null references public.receipts (id) on delete cascade,
  consumer_user_id uuid not null references public.users (id) on delete cascade,
  expense_category_id uuid references public.expense_categories (id),
  classification_source public.classification_source not null default 'user',
  confidence_score numeric(5, 2),
  user_confirmed boolean not null default false,
  expense_type public.expense_type not null default 'personal',
  business_percentage numeric(5, 2),
  suggestion_reason text,
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint receipt_expense_classification_unique unique (receipt_id),
  constraint receipt_expense_business_pct_chk
    check (
      business_percentage is null
      or (business_percentage >= 0 and business_percentage <= 100)
    ),
  constraint receipt_expense_mixed_use_chk
    check (
      expense_type <> 'mixed_use'
      or business_percentage is not null
    )
);

create index receipt_expense_classification_consumer_idx
  on public.receipt_expense_classification (consumer_user_id);

create trigger receipt_expense_classification_set_updated_at
before update on public.receipt_expense_classification
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Warranties
-- ---------------------------------------------------------------------------

create table public.warranties (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null references public.receipts (id) on delete cascade,
  receipt_item_id uuid references public.receipt_items (id) on delete set null,
  consumer_user_id uuid not null references public.users (id) on delete cascade,
  warranty_start_date date,
  warranty_end_date date,
  warranty_status public.warranty_status not null default 'active',
  reminder_status public.reminder_status not null default 'scheduled',
  claim_reference text,
  claim_date date,
  product_problem text,
  merchant_contacted boolean not null default false,
  merchant_contact_details text,
  supporting_file_urls text[] not null default '{}',
  merchant_response text,
  final_resolution text,
  notes text,
  deleted_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index warranties_consumer_user_id_idx on public.warranties (consumer_user_id);
create index warranties_end_date_idx on public.warranties (warranty_end_date);
create index warranties_status_idx on public.warranties (warranty_status);

create trigger warranties_set_updated_at
before update on public.warranties
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Returns and refunds
-- ---------------------------------------------------------------------------

create table public.returns_and_refunds (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null references public.receipts (id) on delete cascade,
  receipt_item_id uuid references public.receipt_items (id) on delete set null,
  consumer_user_id uuid not null references public.users (id) on delete cascade,
  request_type text not null default 'return',
  request_reason text,
  request_description text,
  supporting_file_url text,
  request_status public.return_request_status not null default 'not_started',
  return_deadline date,
  merchant_return_policy text,
  merchant_contacted_at date,
  refund_amount_expected numeric(14, 2),
  refund_amount numeric(14, 2),
  exchange_details text,
  merchant_response_notes text,
  deleted_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index returns_and_refunds_consumer_idx
  on public.returns_and_refunds (consumer_user_id);
create index returns_and_refunds_status_idx
  on public.returns_and_refunds (request_status);

create trigger returns_and_refunds_set_updated_at
before update on public.returns_and_refunds
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Duplicate receipt alerts (never auto-delete)
-- ---------------------------------------------------------------------------

create table public.duplicate_receipt_alerts (
  id uuid primary key default gen_random_uuid(),
  consumer_user_id uuid not null references public.users (id) on delete cascade,
  primary_receipt_id uuid not null references public.receipts (id) on delete cascade,
  duplicate_receipt_id uuid not null references public.receipts (id) on delete cascade,
  match_score numeric(5, 2),
  match_reasons text[] not null default '{}',
  review_status text not null default 'pending',
  reviewed_by uuid references public.users (id),
  reviewed_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint duplicate_receipt_alerts_pair_unique
    unique (primary_receipt_id, duplicate_receipt_id),
  constraint duplicate_receipt_alerts_not_self
    check (primary_receipt_id <> duplicate_receipt_id)
);

create trigger duplicate_receipt_alerts_set_updated_at
before update on public.duplicate_receipt_alerts
for each row execute function public.set_updated_at();
