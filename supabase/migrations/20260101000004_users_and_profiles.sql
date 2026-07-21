-- Receipt24 · Phase 2 · Migration 04
-- Users + Consumer Profiles.

create table public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  email citext not null unique,
  phone_number text,
  profile_photo_url text,
  role public.user_role not null default 'consumer',
  preferred_language text references public.languages (code) default 'en',
  country text references public.countries (code),
  currency text references public.currencies (code),
  timezone text default 'UTC',
  account_status public.account_status not null default 'pending',
  email_verified boolean not null default false,
  phone_verified boolean not null default false,
  deleted_at timestamptz,               -- soft delete (Rule 17); never hard-delete financial identities
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.users is 'Every platform user: consumers, accountants, firm managers and admins. Mirrors auth.users 1:1. No merchant users exist here.';
comment on column public.users.deleted_at is 'Soft-delete marker used by "Delete my account" (Phase 13). Financial records are retained per Rule 16 even after this is set.';

create index users_role_idx on public.users (role);
create index users_account_status_idx on public.users (account_status);

create table public.consumer_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users (id) on delete cascade,
  tax_profile_enabled boolean not null default false,
  accountant_sharing_enabled boolean not null default false,
  default_expense_type public.expense_type not null default 'personal',
  notification_preferences jsonb not null default '{
    "push_enabled": true,
    "email_enabled": true,
    "sms_enabled": false
  }'::jsonb,
  marketing_consent boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.consumer_profiles is 'Consumer-only settings extending public.users. One row per consumer user_id.';
