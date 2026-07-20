-- Receipt24 Phase 2: notifications, subscriptions, support, audit

-- ---------------------------------------------------------------------------
-- Notifications
-- ---------------------------------------------------------------------------

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  notification_type text not null,
  title text not null,
  message text not null,
  related_record_type text,
  related_record_id uuid,
  read_status boolean not null default false,
  created_at timestamptz not null default timezone('utc', now())
);

create index notifications_user_id_idx on public.notifications (user_id);
create index notifications_unread_idx
  on public.notifications (user_id, read_status)
  where read_status = false;

-- ---------------------------------------------------------------------------
-- Subscriptions (consumer + accountant only)
-- ---------------------------------------------------------------------------

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users (id) on delete cascade,
  accountant_id uuid references public.accountants (id) on delete cascade,
  plan_name text not null,
  plan_id uuid references public.subscription_plans (id),
  billing_cycle text not null check (billing_cycle in ('monthly', 'yearly')),
  amount numeric(12, 2) not null check (amount >= 0),
  currency char(3) not null default 'ZAR',
  subscription_status public.subscription_status not null default 'trialing',
  start_date date not null default (timezone('utc', now()))::date,
  renewal_date date,
  payment_provider text,
  external_subscription_id text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint subscriptions_owner_chk
    check (user_id is not null or accountant_id is not null)
);

create index subscriptions_user_id_idx on public.subscriptions (user_id);
create index subscriptions_accountant_id_idx on public.subscriptions (accountant_id);
create index subscriptions_status_idx on public.subscriptions (subscription_status);

create trigger subscriptions_set_updated_at
before update on public.subscriptions
for each row execute function public.set_updated_at();

comment on table public.subscriptions is
  'Billing for consumers and accountants only. No merchant subscriptions.';

-- ---------------------------------------------------------------------------
-- Support tickets
-- ---------------------------------------------------------------------------

create table public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  ticket_number text not null unique,
  subject text not null,
  description text not null,
  category text,
  priority public.ticket_priority not null default 'medium',
  ticket_status public.ticket_status not null default 'open',
  assigned_admin_id uuid references public.users (id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index support_tickets_user_id_idx on public.support_tickets (user_id);
create index support_tickets_status_idx on public.support_tickets (ticket_status);
create index support_tickets_assigned_admin_idx
  on public.support_tickets (assigned_admin_id);

create trigger support_tickets_set_updated_at
before update on public.support_tickets
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Audit logs
-- ---------------------------------------------------------------------------

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users (id) on delete set null,
  action_type text not null,
  record_type text not null,
  record_id uuid,
  previous_value jsonb,
  new_value jsonb,
  ip_address inet,
  device_information text,
  created_at timestamptz not null default timezone('utc', now())
);

create index audit_logs_user_id_idx on public.audit_logs (user_id);
create index audit_logs_record_idx on public.audit_logs (record_type, record_id);
create index audit_logs_created_at_idx on public.audit_logs (created_at desc);

comment on table public.audit_logs is
  'Immutable-style audit trail for sensitive actions. Prefer insert-only access.';

-- ---------------------------------------------------------------------------
-- Connected devices (privacy / security settings foundation)
-- ---------------------------------------------------------------------------

create table public.user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  device_name text,
  device_fingerprint text,
  push_token text,
  platform text,
  last_seen_at timestamptz,
  is_trusted boolean not null default false,
  revoked_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index user_devices_user_id_idx on public.user_devices (user_id);

create trigger user_devices_set_updated_at
before update on public.user_devices
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Document requests (accountant → consumer)
-- ---------------------------------------------------------------------------

create table public.document_requests (
  id uuid primary key default gen_random_uuid(),
  accountant_id uuid not null references public.accountants (id) on delete cascade,
  consumer_user_id uuid not null references public.users (id) on delete cascade,
  receipt_id uuid references public.receipts (id) on delete set null,
  request_message text not null,
  status text not null default 'open',
  fulfilled_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index document_requests_consumer_idx
  on public.document_requests (consumer_user_id);

create trigger document_requests_set_updated_at
before update on public.document_requests
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Accountant notes on client receipts
-- ---------------------------------------------------------------------------

create table public.accountant_notes (
  id uuid primary key default gen_random_uuid(),
  accountant_id uuid not null references public.accountants (id) on delete cascade,
  consumer_user_id uuid not null references public.users (id) on delete cascade,
  receipt_id uuid references public.receipts (id) on delete cascade,
  note text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index accountant_notes_receipt_idx on public.accountant_notes (receipt_id);

create trigger accountant_notes_set_updated_at
before update on public.accountant_notes
for each row execute function public.set_updated_at();
