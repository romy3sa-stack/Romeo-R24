-- Receipt24 · Phase 2 · Migration 07
-- Receipt Items, Receipt Uploads, Receipt Expense Classification.

create table public.receipt_items (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null references public.receipts (id) on delete cascade,
  item_name text not null,
  item_description text,
  item_category text,
  quantity numeric(10, 2) not null default 1,
  unit_price numeric(12, 2),
  tax_rate numeric(5, 2),
  tax_amount numeric(12, 2),
  discount_amount numeric(12, 2),
  total_price numeric(12, 2),
  serial_number text,
  warranty_period text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index receipt_items_receipt_idx on public.receipt_items (receipt_id);

create table public.receipt_uploads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  file_url text not null,
  file_type text,
  upload_source public.receipt_source not null,
  ocr_status public.ocr_status not null default 'pending',
  ocr_raw_text text,
  processing_status public.upload_processing_status not null default 'queued',
  linked_receipt_id uuid references public.receipts (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.receipt_uploads is 'Raw inbox for every scan/upload/email-import before (and while) it is turned into a structured public.receipts row.';

create index receipt_uploads_user_idx on public.receipt_uploads (user_id);
create index receipt_uploads_processing_status_idx on public.receipt_uploads (processing_status);
create index receipt_uploads_linked_receipt_idx on public.receipt_uploads (linked_receipt_id);

create table public.receipt_expense_classification (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null references public.receipts (id) on delete cascade,
  consumer_user_id uuid not null references public.users (id) on delete cascade,
  expense_category_id uuid references public.expense_categories (id),
  classification_source public.classification_source not null default 'rule_based',
  confidence_score numeric(5, 2),
  user_confirmed boolean not null default false,
  expense_type public.expense_type not null default 'personal',
  business_percentage numeric(5, 2) check (business_percentage is null or (business_percentage between 0 and 100)),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (receipt_id)
);

comment on table public.receipt_expense_classification is 'One active classification per receipt (Step 6.2/6.3). Accountants may also write here when access is approved.';

create index expense_classification_consumer_idx on public.receipt_expense_classification (consumer_user_id);
create index expense_classification_category_idx on public.receipt_expense_classification (expense_category_id);
