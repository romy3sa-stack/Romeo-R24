-- Receipt24 · Phase 2 · Migration 05
-- Accountants, Accounting Firm Members, Accountant Client Access.

create table public.accountants (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users (id) on delete cascade,
  firm_name text not null,
  professional_registration_number text,
  tax_number text,
  country text references public.countries (code),
  address text,
  phone_number text,
  verification_status public.accountant_verification_status not null default 'pending',
  verification_document_url text,
  subscription_plan text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.accountants is 'One row per registered accountant / firm principal. Account remains pending until verified by an administrator (Step 3.4).';

create index accountants_verification_status_idx on public.accountants (verification_status);

create table public.accounting_firm_members (
  id uuid primary key default gen_random_uuid(),
  accountant_id uuid not null references public.accountants (id) on delete cascade,
  user_id uuid not null references public.users (id) on delete cascade,
  firm_role public.firm_member_role not null default 'staff',
  permissions jsonb not null default '{}'::jsonb,
  account_status public.account_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (accountant_id, user_id)
);

comment on table public.accounting_firm_members is 'Staff belonging to an accounting firm (Professional Firm / Enterprise Firm plans). firm_role separates Accounting Firm Manager from regular staff.';

create index firm_members_accountant_idx on public.accounting_firm_members (accountant_id);
create index firm_members_user_idx on public.accounting_firm_members (user_id);

create table public.accountant_client_access (
  id uuid primary key default gen_random_uuid(),
  accountant_id uuid not null references public.accountants (id) on delete cascade,
  consumer_user_id uuid not null references public.users (id) on delete cascade,
  access_status public.accountant_access_status not null default 'pending',
  access_scope jsonb not null default '{"type": "all_receipts"}'::jsonb,
  start_date date,
  end_date date,
  invitation_token text unique,
  approved_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (accountant_id, consumer_user_id)
);

comment on table public.accountant_client_access is 'Consumer-approved sharing grant. access_scope.type mirrors accountant_access_scope_type; category_ids/date_range live inside the same jsonb for flexibility (Step 9.1).';

create index client_access_accountant_idx on public.accountant_client_access (accountant_id);
create index client_access_consumer_idx on public.accountant_client_access (consumer_user_id);
create index client_access_status_idx on public.accountant_client_access (access_status);
