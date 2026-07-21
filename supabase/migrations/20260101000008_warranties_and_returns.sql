-- Receipt24 · Phase 2 · Migration 08
-- Warranties, Returns and Refunds.
-- Receipt24 never contacts a merchant on the user's behalf (Step 8.2/8.3) --
-- these tables only ever record what the CONSUMER did/observed.

create table public.warranties (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null references public.receipts (id) on delete cascade,
  receipt_item_id uuid references public.receipt_items (id) on delete set null,
  consumer_user_id uuid not null references public.users (id) on delete cascade,
  warranty_start_date date,
  warranty_end_date date,
  warranty_status public.warranty_status not null default 'active',
  reminder_status public.warranty_reminder_status not null default 'none',
  claim_reference text,
  merchant_contact_details text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index warranties_consumer_idx on public.warranties (consumer_user_id);
create index warranties_receipt_idx on public.warranties (receipt_id);
create index warranties_end_date_idx on public.warranties (warranty_end_date);
create index warranties_status_idx on public.warranties (warranty_status);

create table public.returns_and_refunds (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null references public.receipts (id) on delete cascade,
  receipt_item_id uuid references public.receipt_items (id) on delete set null,
  consumer_user_id uuid not null references public.users (id) on delete cascade,
  request_type public.return_request_type not null default 'return',
  request_reason text,
  request_description text,
  supporting_file_url text,
  request_status public.return_request_status not null default 'not_started',
  refund_amount numeric(12, 2),
  merchant_response_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index returns_consumer_idx on public.returns_and_refunds (consumer_user_id);
create index returns_receipt_idx on public.returns_and_refunds (receipt_id);
create index returns_status_idx on public.returns_and_refunds (request_status);
