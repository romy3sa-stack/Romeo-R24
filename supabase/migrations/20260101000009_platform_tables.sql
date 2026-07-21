-- Receipt24 · Phase 2 · Migration 09
-- Notifications, Subscriptions, Support Tickets, Audit Logs.

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  notification_type public.notification_type not null,
  title text not null,
  message text not null,
  related_record_type text,
  related_record_id uuid,
  read_status boolean not null default false,
  created_at timestamptz not null default now()
);

create index notifications_user_idx on public.notifications (user_id);
create index notifications_read_status_idx on public.notifications (user_id, read_status);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users (id) on delete cascade,
  accountant_id uuid references public.accountants (id) on delete cascade,
  plan_name text not null,
  billing_cycle public.billing_cycle not null default 'monthly',
  amount numeric(12, 2) not null default 0,
  currency text references public.currencies (code),
  subscription_status public.subscription_status not null default 'trialing',
  start_date date not null default current_date,
  renewal_date date,
  payment_provider text,
  external_subscription_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint subscriptions_owner_check check (
    (user_id is not null and accountant_id is null)
    or (user_id is null and accountant_id is not null)
  )
);

comment on table public.subscriptions is 'Consumer plans use user_id; Accountant/Firm plans use accountant_id. Exactly one owner is set — never both (no merchant plans exist, Rule 5).';

create index subscriptions_user_idx on public.subscriptions (user_id);
create index subscriptions_accountant_idx on public.subscriptions (accountant_id);
create index subscriptions_status_idx on public.subscriptions (subscription_status);

create table public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  ticket_number text not null unique default ('R24-' || upper(substr(encode(gen_random_bytes(4), 'hex'), 1, 8))),
  subject text not null,
  description text,
  category text,
  priority public.support_ticket_priority not null default 'medium',
  ticket_status public.support_ticket_status not null default 'open',
  assigned_admin_id uuid references public.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index support_tickets_user_idx on public.support_tickets (user_id);
create index support_tickets_status_idx on public.support_tickets (ticket_status);
create index support_tickets_assigned_admin_idx on public.support_tickets (assigned_admin_id);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users (id) on delete set null,
  action_type text not null,
  record_type text not null,
  record_id uuid,
  previous_value jsonb,
  new_value jsonb,
  ip_address inet,
  device_information jsonb,
  created_at timestamptz not null default now()
);

comment on table public.audit_logs is 'Append-only. Written by triggers/edge functions using the service role; never writable directly by end users (Rule 14).';

create index audit_logs_user_idx on public.audit_logs (user_id);
create index audit_logs_record_idx on public.audit_logs (record_type, record_id);
create index audit_logs_created_at_idx on public.audit_logs (created_at desc);
