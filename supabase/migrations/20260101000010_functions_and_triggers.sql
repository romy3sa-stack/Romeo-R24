-- Receipt24 · Phase 2 · Migration 10
-- Shared functions and triggers: updated_at maintenance, auth.users sync,
-- RBAC helpers used by RLS policies, and a generic audit-log writer.

-- ---------------------------------------------------------------------------
-- 1. updated_at maintenance
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
declare
  t text;
begin
  for t in
    select table_name from information_schema.columns
    where table_schema = 'public' and column_name = 'updated_at'
  loop
    execute format(
      'create trigger set_updated_at before update on public.%I
       for each row execute function public.set_updated_at();',
      t
    );
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- 2. auth.users -> public.users sync (Phase 3 registration architecture)
-- ---------------------------------------------------------------------------
-- Runs as SECURITY DEFINER because the invoking role during signup is
-- `supabase_auth_admin`, which has no privileges on public.users.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  requested_role public.user_role;
begin
  begin
    requested_role := coalesce(new.raw_user_meta_data ->> 'role', 'consumer')::public.user_role;
  exception when invalid_text_representation then
    requested_role := 'consumer';
  end;

  -- Never let client-supplied metadata self-elevate to an administrator role.
  if requested_role in ('super_administrator', 'support_administrator') then
    requested_role := 'consumer';
  end if;

  insert into public.users (
    id, full_name, email, phone_number, role,
    preferred_language, country, currency,
    account_status, email_verified
  )
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
    new.email,
    new.raw_user_meta_data ->> 'phone_number',
    requested_role,
    coalesce(new.raw_user_meta_data ->> 'preferred_language', 'en'),
    new.raw_user_meta_data ->> 'country',
    new.raw_user_meta_data ->> 'currency',
    (case when requested_role = 'accountant' then 'pending' else 'active' end)::public.account_status,
    new.email_confirmed_at is not null
  );

  if requested_role = 'consumer' then
    insert into public.consumer_profiles (user_id) values (new.id);
  end if;

  if requested_role = 'accountant' then
    insert into public.accountants (user_id, firm_name)
    values (new.id, coalesce(new.raw_user_meta_data ->> 'firm_name', 'Unnamed Firm'));
  end if;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- Keep public.users.email_verified in sync with Supabase Auth confirmation.
create or replace function public.handle_auth_user_confirmed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.email_confirmed_at is not null and old.email_confirmed_at is null then
    update public.users set email_verified = true where id = new.id;
  end if;
  return new;
end;
$$;

create trigger on_auth_user_confirmed
  after update on auth.users
  for each row execute function public.handle_auth_user_confirmed();

-- ---------------------------------------------------------------------------
-- 3. RBAC helper functions (used heavily by RLS policies in migration 11)
-- ---------------------------------------------------------------------------
create or replace function public.current_user_role()
returns public.user_role
language sql
stable
security definer
set search_path = public
as $$
  select role from public.users where id = auth.uid();
$$;

create or replace function public.is_super_administrator()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select role = 'super_administrator' from public.users where id = auth.uid()), false);
$$;

create or replace function public.is_support_administrator()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select role = 'support_administrator' from public.users where id = auth.uid()), false);
$$;

create or replace function public.is_administrator()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select role in ('super_administrator', 'support_administrator') from public.users where id = auth.uid()),
    false
  );
$$;

create or replace function public.is_accountant_role()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select role in ('accountant', 'accounting_firm_manager') from public.users where id = auth.uid()),
    false
  );
$$;

-- Resolves the accountants.id row owned by the current auth user, if any.
create or replace function public.current_accountant_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select id from public.accountants where user_id = auth.uid();
$$;

-- True when the calling accountant currently has an APPROVED, non-expired
-- sharing grant for the given consumer (Step 9.1 / Phase 2 RLS requirement).
create or replace function public.accountant_has_client_access(target_consumer_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.accountant_client_access aca
    join public.accountants a on a.id = aca.accountant_id
    where a.user_id = auth.uid()
      and aca.consumer_user_id = target_consumer_id
      and aca.access_status = 'approved'
      and (aca.end_date is null or aca.end_date >= current_date)
  );
$$;

comment on function public.accountant_has_client_access is
  'Central RLS gate for every accountant-facing policy. access_scope (category/date filters) is enforced additionally in the application layer / views in later phases; this function only enforces the row-level "may this accountant see this consumer at all" boundary.';

-- ---------------------------------------------------------------------------
-- 4. Generic audit-log writer (Rule 14)
-- ---------------------------------------------------------------------------
create or replace function public.write_audit_log()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  action text;
begin
  if tg_op = 'INSERT' then
    action := 'create';
  elsif tg_op = 'UPDATE' then
    action := 'update';
  elsif tg_op = 'DELETE' then
    action := 'delete';
  end if;

  insert into public.audit_logs (user_id, action_type, record_type, record_id, previous_value, new_value)
  values (
    auth.uid(),
    action,
    tg_table_name,
    coalesce((case when tg_op = 'DELETE' then old.id else new.id end), null),
    case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) else null end,
    case when tg_op in ('UPDATE', 'INSERT') then to_jsonb(new) else null end
  );

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

comment on function public.write_audit_log is
  'Generic before/after logger. Attached only to tables where changes are legally/operationally sensitive (see migration 11 for the exact list) to avoid flooding audit_logs with routine reads.';

create trigger audit_accountants
  after insert or update or delete on public.accountants
  for each row execute function public.write_audit_log();

create trigger audit_accountant_client_access
  after insert or update or delete on public.accountant_client_access
  for each row execute function public.write_audit_log();

create trigger audit_users_account_status
  after update of account_status, role on public.users
  for each row execute function public.write_audit_log();

create trigger audit_receipt_expense_classification
  after insert or update or delete on public.receipt_expense_classification
  for each row execute function public.write_audit_log();

create trigger audit_subscriptions
  after insert or update or delete on public.subscriptions
  for each row execute function public.write_audit_log();
