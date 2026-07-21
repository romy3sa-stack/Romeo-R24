begin;

create extension if not exists pgcrypto with schema extensions;

create type public.app_role as enum (
  'consumer',
  'accountant',
  'accounting_firm_manager',
  'super_administrator',
  'support_administrator'
);
create type public.account_status as enum ('pending', 'active', 'suspended', 'closed');
create type public.verification_status as enum ('pending', 'verified', 'rejected');
create type public.access_status as enum ('pending', 'approved', 'revoked', 'expired');
create type public.ocr_status as enum ('pending', 'processing', 'completed', 'failed', 'review_required');
create type public.processing_status as enum ('queued', 'processing', 'completed', 'failed');
create type public.receipt_status as enum ('draft', 'processing', 'ready', 'archived');
create type public.expense_type as enum ('personal', 'business', 'mixed_use');
create type public.subscription_status as enum ('trialing', 'active', 'past_due', 'cancelled', 'expired');
create type public.ticket_status as enum ('open', 'in_progress', 'waiting_on_user', 'resolved', 'closed');
create type public.ticket_priority as enum ('low', 'normal', 'high', 'urgent');
create type public.return_status as enum (
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
create type public.duplicate_status as enum ('open', 'dismissed', 'confirmed');

create table public.users (
  id uuid primary key references auth.users(id) on delete restrict,
  full_name text not null check (char_length(full_name) between 1 and 200),
  email text not null,
  phone_number text,
  profile_photo_url text,
  role public.app_role not null default 'consumer',
  preferred_language text not null default 'en',
  country text,
  currency text,
  timezone text not null default 'UTC',
  account_status public.account_status not null default 'pending',
  email_verified boolean not null default false,
  phone_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint users_email_normalized check (email = lower(trim(email))),
  constraint users_language_format check (preferred_language ~ '^[a-z]{2}(-[A-Z]{2})?$'),
  constraint users_country_format check (country is null or country ~ '^[A-Z]{2}$'),
  constraint users_currency_format check (currency is null or currency ~ '^[A-Z]{3}$')
);
create unique index users_email_unique on public.users (lower(email));

create table public.consumer_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users(id) on delete restrict,
  tax_profile_enabled boolean not null default false,
  accountant_sharing_enabled boolean not null default false,
  default_expense_type public.expense_type not null default 'personal',
  notification_preferences jsonb not null default '{}'::jsonb,
  marketing_consent boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint consumer_notification_preferences_object
    check (jsonb_typeof(notification_preferences) = 'object')
);

create table public.accountants (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users(id) on delete restrict,
  firm_name text not null,
  professional_registration_number text not null,
  tax_number text,
  country text not null check (country ~ '^[A-Z]{2}$'),
  address text not null,
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
  accountant_id uuid not null references public.accountants(id) on delete restrict,
  user_id uuid not null references public.users(id) on delete restrict,
  firm_role text not null,
  permissions jsonb not null default '{}'::jsonb,
  account_status public.account_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (accountant_id, user_id),
  constraint firm_member_permissions_object check (jsonb_typeof(permissions) = 'object')
);

create table public.accountant_client_access (
  id uuid primary key default gen_random_uuid(),
  accountant_id uuid not null references public.accountants(id) on delete restrict,
  consumer_user_id uuid not null references public.users(id) on delete restrict,
  access_status public.access_status not null default 'pending',
  access_scope jsonb not null default '{"type":"all_receipts"}'::jsonb,
  start_date date,
  end_date date,
  invitation_token uuid not null default gen_random_uuid(),
  approved_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (accountant_id, consumer_user_id),
  unique (invitation_token),
  constraint client_access_scope_object check (jsonb_typeof(access_scope) = 'object'),
  constraint client_access_dates_valid check (end_date is null or start_date is null or end_date >= start_date),
  constraint approved_access_has_timestamp check (access_status <> 'approved' or approved_at is not null),
  constraint revoked_access_has_timestamp check (access_status <> 'revoked' or revoked_at is not null)
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
  country text check (country is null or country ~ '^[A-Z]{2}$'),
  latitude numeric(9,6) check (latitude between -90 and 90),
  longitude numeric(9,6) check (longitude between -180 and 180),
  logo_url text,
  merchant_source text not null check (
    merchant_source in ('ocr_scan', 'manual_entry', 'email_import', 'administrator', 'external_integration')
  ),
  verification_status public.verification_status not null default 'pending',
  created_by_user_id uuid not null references public.users(id) on delete restrict,
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
  updated_at timestamptz not null default now(),
  constraint receipt_category_colour_format
    check (category_colour is null or category_colour ~ '^#[0-9A-Fa-f]{6}$')
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
  merchant_name_raw text not null,
  receipt_number text,
  transaction_reference text,
  transaction_date timestamptz not null,
  subtotal numeric(14,2) check (subtotal is null or subtotal >= 0),
  tax_amount numeric(14,2) check (tax_amount is null or tax_amount >= 0),
  discount_amount numeric(14,2) check (discount_amount is null or discount_amount >= 0),
  total_amount numeric(14,2) not null check (total_amount >= 0),
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  payment_method text,
  receipt_source text not null check (
    receipt_source in ('camera_scan', 'image_upload', 'pdf_upload', 'email_import', 'manual_entry', 'external_integration')
  ),
  receipt_status public.receipt_status not null default 'draft',
  receipt_file_url text,
  receipt_image_url text,
  ocr_status public.ocr_status not null default 'pending',
  ocr_confidence_score numeric(5,4) check (ocr_confidence_score between 0 and 1),
  verification_status public.verification_status not null default 'pending',
  warranty_available boolean not null default false,
  return_deadline date,
  notes text,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.receipt_items (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null references public.receipts(id) on delete restrict,
  item_name text not null,
  item_description text,
  item_category text,
  quantity numeric(12,3) not null default 1 check (quantity > 0),
  unit_price numeric(14,2) check (unit_price is null or unit_price >= 0),
  tax_rate numeric(7,4) check (tax_rate is null or tax_rate between 0 and 100),
  tax_amount numeric(14,2) check (tax_amount is null or tax_amount >= 0),
  discount_amount numeric(14,2) check (discount_amount is null or discount_amount >= 0),
  total_price numeric(14,2) not null check (total_price >= 0),
  serial_number text,
  warranty_period interval check (warranty_period is null or warranty_period >= interval '0 days'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.receipt_uploads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete restrict,
  file_url text not null,
  file_type text not null check (file_type in ('jpg', 'jpeg', 'png', 'heic', 'pdf', 'email_body')),
  upload_source text not null check (
    upload_source in ('camera_scan', 'image_upload', 'pdf_upload', 'email_import', 'manual_entry')
  ),
  ocr_status public.ocr_status not null default 'pending',
  ocr_raw_text text,
  processing_status public.processing_status not null default 'queued',
  linked_receipt_id uuid references public.receipts(id) on delete set null,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.receipt_expense_classification (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null references public.receipts(id) on delete restrict,
  consumer_user_id uuid not null references public.users(id) on delete restrict,
  expense_category_id uuid not null references public.expense_categories(id) on delete restrict,
  classification_source text not null check (classification_source in ('user', 'accountant', 'rule', 'ai', 'administrator')),
  confidence_score numeric(5,4) check (confidence_score between 0 and 1),
  user_confirmed boolean not null default false,
  expense_type public.expense_type not null default 'personal',
  business_percentage numeric(5,2) not null default 0 check (business_percentage between 0 and 100),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (receipt_id),
  constraint classification_owner_matches_receipt unique (receipt_id, consumer_user_id),
  constraint classification_percentage_matches_type check (
    (expense_type = 'personal' and business_percentage = 0)
    or (expense_type = 'business' and business_percentage = 100)
    or (expense_type = 'mixed_use' and business_percentage > 0 and business_percentage < 100)
  )
);

create table public.warranties (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null references public.receipts(id) on delete restrict,
  receipt_item_id uuid references public.receipt_items(id) on delete restrict,
  consumer_user_id uuid not null references public.users(id) on delete restrict,
  warranty_start_date date not null,
  warranty_end_date date not null,
  warranty_status public.warranty_status not null default 'active',
  reminder_status jsonb not null default '{"30_days":true,"7_days":true,"on_expiry":true}'::jsonb,
  claim_reference text,
  merchant_contact_details jsonb not null default '{}'::jsonb,
  notes text,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint warranty_dates_valid check (warranty_end_date >= warranty_start_date),
  constraint warranty_reminder_status_object check (jsonb_typeof(reminder_status) = 'object'),
  constraint warranty_merchant_contacts_object check (jsonb_typeof(merchant_contact_details) = 'object')
);

create table public.returns_and_refunds (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null references public.receipts(id) on delete restrict,
  receipt_item_id uuid references public.receipt_items(id) on delete restrict,
  consumer_user_id uuid not null references public.users(id) on delete restrict,
  request_type text not null check (request_type in ('return', 'refund', 'exchange')),
  request_reason text not null,
  request_description text,
  supporting_file_url text,
  request_status public.return_status not null default 'not_started',
  refund_amount numeric(14,2) check (refund_amount is null or refund_amount >= 0),
  merchant_response_notes text,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete restrict,
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
  user_id uuid references public.users(id) on delete restrict,
  accountant_id uuid references public.accountants(id) on delete restrict,
  plan_name text not null,
  billing_cycle text not null check (billing_cycle in ('monthly', 'annual')),
  amount numeric(14,2) not null check (amount >= 0),
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  subscription_status public.subscription_status not null default 'trialing',
  start_date date not null,
  renewal_date date,
  payment_provider text not null,
  external_subscription_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint subscription_single_owner check (num_nonnulls(user_id, accountant_id) = 1),
  unique (payment_provider, external_subscription_id)
);

create table public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete restrict,
  ticket_number text not null unique,
  subject text not null,
  description text not null,
  category text not null,
  priority public.ticket_priority not null default 'normal',
  ticket_status public.ticket_status not null default 'open',
  assigned_admin_id uuid references public.users(id) on delete restrict,
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
  device_information jsonb,
  created_at timestamptz not null default now()
);

create table public.duplicate_receipt_alerts (
  id uuid primary key default gen_random_uuid(),
  consumer_user_id uuid not null references public.users(id) on delete restrict,
  receipt_id uuid not null references public.receipts(id) on delete restrict,
  possible_duplicate_receipt_id uuid not null references public.receipts(id) on delete restrict,
  match_reasons jsonb not null default '[]'::jsonb,
  confidence_score numeric(5,4) not null check (confidence_score between 0 and 1),
  status public.duplicate_status not null default 'open',
  reviewed_by_user_id uuid references public.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint duplicate_receipts_differ check (receipt_id <> possible_duplicate_receipt_id),
  constraint duplicate_match_reasons_array check (jsonb_typeof(match_reasons) = 'array')
);

create index receipts_consumer_date_idx on public.receipts (consumer_user_id, transaction_date desc);
create index receipts_merchant_idx on public.receipts (merchant_id);
create index receipt_items_receipt_idx on public.receipt_items (receipt_id);
create index receipt_uploads_user_idx on public.receipt_uploads (user_id, created_at desc);
create index warranties_consumer_expiry_idx on public.warranties (consumer_user_id, warranty_end_date);
create index returns_consumer_idx on public.returns_and_refunds (consumer_user_id, created_at desc);
create index notifications_user_unread_idx on public.notifications (user_id, read_status, created_at desc);
create index support_tickets_user_idx on public.support_tickets (user_id, created_at desc);
create index audit_logs_record_idx on public.audit_logs (record_type, record_id, created_at desc);
create index client_access_consumer_idx on public.accountant_client_access (consumer_user_id, access_status);
create index duplicate_alerts_consumer_idx on public.duplicate_receipt_alerts (consumer_user_id, status);

alter table public.receipts
  add constraint receipts_owner_pair unique (id, consumer_user_id);
alter table public.receipt_items
  add constraint receipt_items_receipt_pair unique (id, receipt_id);
alter table public.receipt_uploads
  add constraint receipt_upload_receipt_owner
  foreign key (linked_receipt_id, user_id)
  references public.receipts(id, consumer_user_id) on delete restrict;
alter table public.receipt_expense_classification
  add constraint classification_receipt_owner
  foreign key (receipt_id, consumer_user_id)
  references public.receipts(id, consumer_user_id) on delete restrict;
alter table public.warranties
  add constraint warranties_receipt_owner
  foreign key (receipt_id, consumer_user_id)
  references public.receipts(id, consumer_user_id) on delete restrict;
alter table public.warranties
  add constraint warranties_item_receipt
  foreign key (receipt_item_id, receipt_id)
  references public.receipt_items(id, receipt_id) on delete restrict;
alter table public.returns_and_refunds
  add constraint returns_receipt_owner
  foreign key (receipt_id, consumer_user_id)
  references public.receipts(id, consumer_user_id) on delete restrict;
alter table public.returns_and_refunds
  add constraint returns_item_receipt
  foreign key (receipt_item_id, receipt_id)
  references public.receipt_items(id, receipt_id) on delete restrict;
alter table public.duplicate_receipt_alerts
  add constraint duplicate_original_owner
  foreign key (receipt_id, consumer_user_id)
  references public.receipts(id, consumer_user_id) on delete restrict;
alter table public.duplicate_receipt_alerts
  add constraint duplicate_candidate_owner
  foreign key (possible_duplicate_receipt_id, consumer_user_id)
  references public.receipts(id, consumer_user_id) on delete restrict;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'users', 'consumer_profiles', 'accountants', 'accounting_firm_members',
    'accountant_client_access', 'merchants', 'receipts', 'receipt_items',
    'receipt_uploads', 'receipt_categories', 'expense_categories',
    'receipt_expense_classification', 'warranties', 'returns_and_refunds',
    'subscriptions', 'support_tickets', 'duplicate_receipt_alerts'
  ]
  loop
    execute format(
      'create trigger set_%I_updated_at before update on public.%I
       for each row execute function public.set_updated_at()',
      table_name,
      table_name
    );
  end loop;
end;
$$;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.users (
    id,
    full_name,
    email,
    phone_number,
    preferred_language,
    country,
    currency,
    timezone,
    account_status,
    email_verified,
    phone_verified
  )
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''), 'Receipt24 user'),
    lower(new.email),
    new.phone,
    coalesce(new.raw_user_meta_data ->> 'preferred_language', 'en'),
    nullif(new.raw_user_meta_data ->> 'country', ''),
    nullif(new.raw_user_meta_data ->> 'currency', ''),
    coalesce(new.raw_user_meta_data ->> 'timezone', 'UTC'),
    case when new.email_confirmed_at is null then 'pending'::public.account_status else 'active'::public.account_status end,
    new.email_confirmed_at is not null,
    new.phone_confirmed_at is not null
  );

  insert into public.consumer_profiles (user_id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

create or replace function public.sync_auth_verification()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.users
  set
    email = lower(new.email),
    phone_number = new.phone,
    email_verified = new.email_confirmed_at is not null,
    phone_verified = new.phone_confirmed_at is not null,
    account_status = case
      when account_status = 'pending' and new.email_confirmed_at is not null then 'active'::public.account_status
      else account_status
    end
  where id = new.id;
  return new;
end;
$$;

create trigger on_auth_user_updated
  after update of email, phone, email_confirmed_at, phone_confirmed_at on auth.users
  for each row execute function public.sync_auth_verification();

comment on table public.merchants is
  'Receipt-derived merchant data only. Merchants are never authentication principals or platform users.';
comment on column public.accountant_client_access.access_scope is
  'JSON object with type all_receipts, business_only, tax_related_only, selected_categories, or date_range and corresponding values.';
comment on column public.receipts.archived_at is
  'Soft-archive marker; financial records are not exposed to client-side hard deletion.';

commit;
