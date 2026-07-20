-- Receipt24 Phase 2: core identity, accountant, and reference tables

-- ---------------------------------------------------------------------------
-- Users (extends auth.users)
-- ---------------------------------------------------------------------------

create table public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  email citext not null unique,
  phone_number text,
  profile_photo_url text,
  role public.user_role not null,
  preferred_language text not null default 'en',
  country text,
  currency text not null default 'ZAR',
  timezone text not null default 'Africa/Johannesburg',
  account_status public.account_status not null default 'pending',
  email_verified boolean not null default false,
  phone_verified boolean not null default false,
  deleted_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint users_preferred_language_chk check (char_length(preferred_language) between 2 and 10),
  constraint users_currency_chk check (char_length(currency) = 3)
);

create index users_role_idx on public.users (role);
create index users_account_status_idx on public.users (account_status);
create index users_email_idx on public.users (email);

create trigger users_set_updated_at
before update on public.users
for each row execute function public.set_updated_at();

comment on table public.users is
  'Platform users only: consumers, accountants, firm managers, and administrators. No merchant users.';

-- ---------------------------------------------------------------------------
-- Consumer profiles
-- ---------------------------------------------------------------------------

create table public.consumer_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users (id) on delete cascade,
  tax_profile_enabled boolean not null default false,
  accountant_sharing_enabled boolean not null default false,
  default_expense_type public.expense_type not null default 'personal',
  notification_preferences jsonb not null default '{}'::jsonb,
  marketing_consent boolean not null default false,
  forwarding_email_local_part text unique,
  onboarding_completed boolean not null default false,
  onboarding_interests text[] not null default '{}',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create trigger consumer_profiles_set_updated_at
before update on public.consumer_profiles
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Accountants
-- ---------------------------------------------------------------------------

create table public.accountants (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users (id) on delete cascade,
  firm_name text not null,
  professional_registration_number text,
  tax_number text,
  country text not null,
  address text,
  phone_number text,
  verification_status public.verification_status not null default 'pending',
  verification_document_url text,
  subscription_plan text,
  verified_at timestamptz,
  verified_by_admin_id uuid references public.users (id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index accountants_verification_status_idx
  on public.accountants (verification_status);

create trigger accountants_set_updated_at
before update on public.accountants
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Accounting firm members
-- ---------------------------------------------------------------------------

create table public.accounting_firm_members (
  id uuid primary key default gen_random_uuid(),
  accountant_id uuid not null references public.accountants (id) on delete cascade,
  user_id uuid not null references public.users (id) on delete cascade,
  firm_role public.firm_role not null default 'member',
  permissions jsonb not null default '{}'::jsonb,
  account_status public.account_status not null default 'pending',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint accounting_firm_members_unique unique (accountant_id, user_id)
);

create index accounting_firm_members_user_id_idx
  on public.accounting_firm_members (user_id);

create trigger accounting_firm_members_set_updated_at
before update on public.accounting_firm_members
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Accountant client access
-- ---------------------------------------------------------------------------

create table public.accountant_client_access (
  id uuid primary key default gen_random_uuid(),
  accountant_id uuid not null references public.accountants (id) on delete cascade,
  consumer_user_id uuid not null references public.users (id) on delete cascade,
  access_status public.access_status not null default 'invited',
  access_scope public.access_scope not null default 'all_receipts',
  selected_category_ids uuid[] not null default '{}',
  selected_date_start date,
  selected_date_end date,
  start_date date,
  end_date date,
  invitation_token text unique,
  invitation_email citext,
  invitation_phone text,
  approved_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint accountant_client_access_unique
    unique (accountant_id, consumer_user_id)
);

create index accountant_client_access_consumer_idx
  on public.accountant_client_access (consumer_user_id);

create index accountant_client_access_status_idx
  on public.accountant_client_access (access_status);

create trigger accountant_client_access_set_updated_at
before update on public.accountant_client_access
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Merchants (receipt data only — no auth, no subscriptions, no dashboards)
-- ---------------------------------------------------------------------------

create table public.merchants (
  id uuid primary key default gen_random_uuid(),
  merchant_name text not null,
  trading_name text,
  business_category text,
  tax_number text,
  email citext,
  phone_number text,
  website text,
  address text,
  city text,
  province_or_state text,
  postal_code text,
  country text,
  latitude numeric(10, 7),
  longitude numeric(10, 7),
  logo_url text,
  merchant_source public.merchant_source not null default 'manual_entry',
  verification_status public.verification_status not null default 'unverified',
  created_by_user_id uuid references public.users (id),
  deleted_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index merchants_name_idx on public.merchants (merchant_name);
create index merchants_tax_number_idx on public.merchants (tax_number);

create trigger merchants_set_updated_at
before update on public.merchants
for each row execute function public.set_updated_at();

comment on table public.merchants is
  'Merchant details extracted from receipts only. Merchants never authenticate or subscribe.';

-- ---------------------------------------------------------------------------
-- Receipt / expense reference data
-- ---------------------------------------------------------------------------

create table public.receipt_categories (
  id uuid primary key default gen_random_uuid(),
  category_name text not null unique,
  category_icon text,
  category_colour text,
  tax_relevance boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create trigger receipt_categories_set_updated_at
before update on public.receipt_categories
for each row execute function public.set_updated_at();

create table public.expense_categories (
  id uuid primary key default gen_random_uuid(),
  category_name text not null unique,
  category_code text not null unique,
  tax_deductible boolean not null default false,
  vat_eligible boolean not null default false,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create trigger expense_categories_set_updated_at
before update on public.expense_categories
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Platform reference: countries, currencies, languages, legal content
-- ---------------------------------------------------------------------------

create table public.countries (
  id uuid primary key default gen_random_uuid(),
  country_code char(2) not null unique,
  country_name text not null unique,
  phone_code text,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create trigger countries_set_updated_at
before update on public.countries
for each row execute function public.set_updated_at();

create table public.currencies (
  id uuid primary key default gen_random_uuid(),
  currency_code char(3) not null unique,
  currency_name text not null,
  symbol text,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create trigger currencies_set_updated_at
before update on public.currencies
for each row execute function public.set_updated_at();

create table public.languages (
  id uuid primary key default gen_random_uuid(),
  language_code text not null unique,
  language_name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create trigger languages_set_updated_at
before update on public.languages
for each row execute function public.set_updated_at();

create table public.legal_documents (
  id uuid primary key default gen_random_uuid(),
  document_type text not null,
  language_code text not null default 'en',
  title text not null,
  content_markdown text not null,
  version text not null,
  is_published boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint legal_documents_type_version_lang unique (document_type, version, language_code)
);

create trigger legal_documents_set_updated_at
before update on public.legal_documents
for each row execute function public.set_updated_at();

create table public.notification_templates (
  id uuid primary key default gen_random_uuid(),
  template_key text not null,
  channel text not null,
  language_code text not null default 'en',
  subject text,
  body text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint notification_templates_unique
    unique (template_key, channel, language_code)
);

create trigger notification_templates_set_updated_at
before update on public.notification_templates
for each row execute function public.set_updated_at();

create table public.subscription_plans (
  id uuid primary key default gen_random_uuid(),
  plan_code text not null unique,
  plan_name text not null,
  audience text not null check (audience in ('consumer', 'accountant')),
  billing_cycle text not null check (billing_cycle in ('monthly', 'yearly')),
  amount numeric(12, 2) not null check (amount >= 0),
  currency char(3) not null default 'ZAR',
  features jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint subscription_plans_no_merchant_audience
    check (audience in ('consumer', 'accountant'))
);

create trigger subscription_plans_set_updated_at
before update on public.subscription_plans
for each row execute function public.set_updated_at();

comment on table public.subscription_plans is
  'Consumer and accountant plans only. Merchant plans are forbidden.';
