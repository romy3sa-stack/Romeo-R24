-- Receipt24 platform foundation: application-owned data only.
-- Identity credentials remain exclusively in auth.users.

create extension if not exists pgcrypto;

create type public.user_role as enum (
  'consumer',
  'accountant',
  'accounting_firm_manager',
  'super_administrator',
  'support_administrator'
);
create type public.account_status as enum ('pending', 'active', 'suspended', 'deleted');
create type public.verification_status as enum ('pending', 'approved', 'rejected', 'expired');
create type public.receipt_source as enum ('camera_scan', 'image_upload', 'pdf_upload', 'email_import', 'manual_entry', 'external_integration');
create type public.ocr_status as enum ('not_started', 'processing', 'completed', 'failed', 'needs_review');
create type public.receipt_status as enum ('draft', 'confirmed', 'archived', 'deleted');
create type public.expense_type as enum ('personal', 'business', 'mixed_use');
create type public.access_status as enum ('pending', 'active', 'revoked', 'expired', 'declined');
create type public.warranty_status as enum ('active', 'claim_started', 'awaiting_response', 'repair_in_progress', 'replaced', 'refunded', 'rejected', 'expired', 'closed');
create type public.return_status as enum ('not_started', 'contacted_merchant', 'awaiting_response', 'product_returned', 'refund_pending', 'refund_received', 'exchange_completed', 'rejected', 'closed');
create type public.ticket_status as enum ('open', 'in_progress', 'waiting_on_user', 'resolved', 'closed');

create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null check (char_length(trim(full_name)) between 1 and 200),
  email text not null unique check (email = lower(email)),
  phone_number text,
  profile_photo_url text,
  role public.user_role not null default 'consumer',
  preferred_language text not null default 'en',
  country text not null default 'ZA' check (char_length(country) = 2),
  currency text not null default 'ZAR' check (char_length(currency) = 3),
  timezone text not null default 'Africa/Johannesburg',
  account_status public.account_status not null default 'pending',
  email_verified boolean not null default false,
  phone_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.consumer_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users(id) on delete cascade,
  tax_profile_enabled boolean not null default false,
  accountant_sharing_enabled boolean not null default false,
  default_expense_type public.expense_type not null default 'personal',
  notification_preferences jsonb not null default '{}'::jsonb,
  marketing_consent boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.accountants (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users(id) on delete cascade,
  firm_name text not null,
  professional_registration_number text not null,
  tax_number text,
  country text not null check (char_length(country) = 2),
  address text,
  phone_number text,
  verification_status public.verification_status not null default 'pending',
  verification_document_url text,
  subscription_plan text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (country, professional_registration_number)
);

create table public.accounting_firm_members (
  id uuid primary key default gen_random_uuid(),
  accountant_id uuid not null references public.accountants(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  firm_role text not null,
  permissions jsonb not null default '{}'::jsonb,
  account_status public.account_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (accountant_id, user_id)
);

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
  country text check (country is null or char_length(country) = 2),
  latitude numeric(9,6),
  longitude numeric(9,6),
  logo_url text,
  merchant_source public.receipt_source not null,
  verification_status public.verification_status not null default 'pending',
  created_by_user_id uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.receipt_categories (
  id uuid primary key default gen_random_uuid(),
  category_name text not null unique,
  category_icon text,
  category_colour text,
  tax_relevance boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.expense_categories (
  id uuid primary key default gen_random_uuid(),
  category_name text not null unique,
  category_code text not null unique,
  tax_deductible boolean not null default false,
  vat_eligible boolean not null default false,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.receipts (
  id uuid primary key default gen_random_uuid(),
  consumer_user_id uuid not null references public.users(id) on delete restrict,
  merchant_id uuid references public.merchants(id) on delete set null,
  receipt_category_id uuid references public.receipt_categories(id) on delete set null,
  merchant_name_raw text,
  receipt_number text,
  transaction_reference text,
  transaction_date date not null,
  subtotal numeric(14,2) check (subtotal is null or subtotal >= 0),
  tax_amount numeric(14,2) not null default 0 check (tax_amount >= 0),
  discount_amount numeric(14,2) not null default 0 check (discount_amount >= 0),
  total_amount numeric(14,2) not null check (total_amount >= 0),
  currency text not null check (char_length(currency) = 3),
  payment_method text,
  receipt_source public.receipt_source not null,
  receipt_status public.receipt_status not null default 'draft',
  receipt_file_url text,
  receipt_image_url text,
  ocr_status public.ocr_status not null default 'not_started',
  ocr_confidence_score numeric(5,2) check (ocr_confidence_score between 0 and 100),
  verification_status public.verification_status not null default 'pending',
  warranty_available boolean not null default false,
  return_deadline date,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index receipts_consumer_date_idx on public.receipts (consumer_user_id, transaction_date desc);
create index receipts_merchant_idx on public.receipts (merchant_id);

create table public.receipt_items (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null references public.receipts(id) on delete cascade,
  item_name text not null,
  item_description text,
  item_category text,
  quantity numeric(12,3) not null default 1 check (quantity > 0),
  unit_price numeric(14,2) check (unit_price is null or unit_price >= 0),
  tax_rate numeric(5,2) check (tax_rate is null or tax_rate >= 0),
  tax_amount numeric(14,2) not null default 0 check (tax_amount >= 0),
  discount_amount numeric(14,2) not null default 0 check (discount_amount >= 0),
  total_price numeric(14,2) not null check (total_price >= 0),
  serial_number text,
  warranty_period interval,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.receipt_uploads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  file_url text not null,
  file_type text not null,
  upload_source public.receipt_source not null,
  ocr_status public.ocr_status not null default 'not_started',
  ocr_raw_text text,
  processing_status public.ocr_status not null default 'not_started',
  linked_receipt_id uuid references public.receipts(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.receipt_expense_classifications (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null unique references public.receipts(id) on delete cascade,
  consumer_user_id uuid not null references public.users(id) on delete restrict,
  expense_category_id uuid references public.expense_categories(id) on delete set null,
  classification_source text not null,
  confidence_score numeric(5,2) check (confidence_score between 0 and 100),
  user_confirmed boolean not null default false,
  expense_type public.expense_type not null default 'personal',
  business_percentage numeric(5,2) not null default 0 check (business_percentage between 0 and 100),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((expense_type = 'mixed_use' and business_percentage between 1 and 99.99)
    or (expense_type = 'business' and business_percentage = 100)
    or (expense_type = 'personal' and business_percentage = 0))
);

create table public.warranties (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null references public.receipts(id) on delete cascade,
  receipt_item_id uuid references public.receipt_items(id) on delete set null,
  consumer_user_id uuid not null references public.users(id) on delete restrict,
  warranty_start_date date not null,
  warranty_end_date date not null,
  warranty_status public.warranty_status not null default 'active',
  reminder_status jsonb not null default '{}'::jsonb,
  claim_reference text,
  merchant_contact_details jsonb not null default '{}'::jsonb,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (warranty_end_date >= warranty_start_date)
);

create table public.returns_and_refunds (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null references public.receipts(id) on delete cascade,
  receipt_item_id uuid references public.receipt_items(id) on delete set null,
  consumer_user_id uuid not null references public.users(id) on delete restrict,
  request_type text not null,
  request_reason text,
  request_description text,
  supporting_file_url text,
  request_status public.return_status not null default 'not_started',
  refund_amount numeric(14,2) check (refund_amount is null or refund_amount >= 0),
  merchant_response_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.accountant_client_access (
  id uuid primary key default gen_random_uuid(),
  accountant_id uuid not null references public.accountants(id) on delete cascade,
  consumer_user_id uuid not null references public.users(id) on delete cascade,
  access_status public.access_status not null default 'pending',
  access_scope jsonb not null default '{"type":"all_receipts"}'::jsonb,
  start_date date,
  end_date date,
  invitation_token uuid not null default gen_random_uuid() unique,
  approved_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (accountant_id, consumer_user_id),
  check (end_date is null or start_date is null or end_date >= start_date)
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  notification_type text not null,
  title text not null,
  message text not null,
  related_record_type text,
  related_record_id uuid,
  read_status boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade,
  accountant_id uuid references public.accountants(id) on delete cascade,
  plan_name text not null,
  billing_cycle text not null,
  amount numeric(14,2) not null check (amount >= 0),
  currency text not null check (char_length(currency) = 3),
  subscription_status text not null,
  start_date date not null,
  renewal_date date,
  payment_provider text not null,
  external_subscription_id text unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (num_nonnulls(user_id, accountant_id) = 1)
);

create table public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete restrict,
  ticket_number text not null unique,
  subject text not null,
  description text not null,
  category text not null,
  priority text not null default 'normal',
  ticket_status public.ticket_status not null default 'open',
  assigned_admin_id uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete set null,
  action_type text not null,
  record_type text not null,
  record_id uuid,
  previous_value jsonb,
  new_value jsonb,
  ip_address inet,
  device_information jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = public as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.users (id, full_name, email, role, account_status, email_verified)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
    lower(new.email),
    'consumer',
    case when new.email_confirmed_at is null then 'pending' else 'active' end,
    new.email_confirmed_at is not null
  );
  insert into public.consumer_profiles (user_id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_auth_user();

do $$
declare target_table text;
begin
  foreach target_table in array array[
    'users', 'consumer_profiles', 'accountants', 'accounting_firm_members', 'merchants',
    'receipt_categories', 'expense_categories', 'receipts', 'receipt_items', 'receipt_uploads',
    'receipt_expense_classifications', 'warranties', 'returns_and_refunds',
    'accountant_client_access', 'subscriptions', 'support_tickets'
  ]
  loop
    execute format(
      'create trigger %I before update on public.%I for each row execute procedure public.set_updated_at()',
      'set_' || target_table || '_updated_at',
      target_table
    );
  end loop;
end $$;
