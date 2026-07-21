-- Receipt24 · Phase 2 · Migration 11
-- Row Level Security. Every table gets RLS enabled + explicit policies.
-- Default-deny: if no policy matches, Postgres denies the row/operation.
--
-- Legend used throughout:
--   auth.uid()                       -> the logged-in user's id (Supabase Auth)
--   is_administrator()                -> super_administrator OR support_administrator
--   accountant_has_client_access(id)  -> caller is an accountant with an
--                                        APPROVED, non-expired grant for
--                                        consumer `id` (see migration 10)

-- ---------------------------------------------------------------------------
-- Baseline schema grants (RLS still applies row-by-row on top of these).
-- ---------------------------------------------------------------------------
grant usage on schema public to anon, authenticated, service_role;
grant all on all tables in schema public to service_role;
grant all on all sequences in schema public to service_role;

grant select, insert, update, delete on
  public.users,
  public.consumer_profiles,
  public.accountants,
  public.accounting_firm_members,
  public.accountant_client_access,
  public.merchants,
  public.receipts,
  public.receipt_items,
  public.receipt_uploads,
  public.receipt_expense_classification,
  public.warranties,
  public.returns_and_refunds,
  public.notifications,
  public.subscriptions,
  public.support_tickets
to authenticated;

grant select on
  public.receipt_categories,
  public.expense_categories,
  public.languages,
  public.countries,
  public.currencies
to anon, authenticated;

grant insert, update, delete on
  public.receipt_categories,
  public.expense_categories,
  public.languages,
  public.countries,
  public.currencies
to authenticated;

grant select on public.audit_logs to authenticated;

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------
alter table public.users enable row level security;

create policy users_select_own_or_privileged on public.users
  for select to authenticated
  using (
    id = auth.uid()
    or public.is_administrator()
    or public.accountant_has_client_access(id)
  );

create policy users_insert_self on public.users
  for insert to authenticated
  with check (id = auth.uid());

create policy users_update_own_or_admin on public.users
  for update to authenticated
  using (id = auth.uid() or public.is_administrator())
  with check (id = auth.uid() or public.is_administrator());

create policy users_delete_admin_only on public.users
  for delete to authenticated
  using (public.is_super_administrator());

-- Field-level guard: only an administrator may change role/account_status,
-- even though the row-level policy above allows self-updates to other columns.
create or replace function public.prevent_self_privilege_escalation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- auth.uid() is null for service-role/backend contexts (migrations, seed
  -- jobs, trusted Edge Functions) which have no end-user JWT at all; those
  -- are allowed through. Any request carrying a JWT (real end users) must
  -- be an administrator to change role/account_status.
  if auth.uid() is not null and not public.is_administrator() then
    if new.role is distinct from old.role or new.account_status is distinct from old.account_status then
      raise exception 'Only an administrator may change role or account_status';
    end if;
  end if;
  return new;
end;
$$;

create trigger guard_users_privilege_escalation
  before update on public.users
  for each row execute function public.prevent_self_privilege_escalation();

-- ---------------------------------------------------------------------------
-- consumer_profiles
-- ---------------------------------------------------------------------------
alter table public.consumer_profiles enable row level security;

create policy consumer_profiles_owner_or_admin on public.consumer_profiles
  for all to authenticated
  using (user_id = auth.uid() or public.is_administrator())
  with check (user_id = auth.uid() or public.is_administrator());

-- ---------------------------------------------------------------------------
-- accountants
-- ---------------------------------------------------------------------------
alter table public.accountants enable row level security;

create policy accountants_select on public.accountants
  for select to authenticated
  using (
    user_id = auth.uid()
    or public.is_administrator()
    or exists (
      select 1 from public.accountant_client_access aca
      where aca.accountant_id = accountants.id and aca.consumer_user_id = auth.uid()
    )
  );

create policy accountants_insert_self on public.accountants
  for insert to authenticated
  with check (user_id = auth.uid());

create policy accountants_update_own_or_admin on public.accountants
  for update to authenticated
  using (user_id = auth.uid() or public.is_administrator())
  with check (user_id = auth.uid() or public.is_administrator());

create policy accountants_delete_admin_only on public.accountants
  for delete to authenticated
  using (public.is_super_administrator());

create or replace function public.prevent_self_verification_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null and not public.is_administrator() then
    if new.verification_status is distinct from old.verification_status then
      raise exception 'Only an administrator may change accountant verification_status';
    end if;
  end if;
  return new;
end;
$$;

create trigger guard_accountant_verification
  before update on public.accountants
  for each row execute function public.prevent_self_verification_change();

-- ---------------------------------------------------------------------------
-- accounting_firm_members
-- ---------------------------------------------------------------------------
alter table public.accounting_firm_members enable row level security;

create policy firm_members_select on public.accounting_firm_members
  for select to authenticated
  using (
    user_id = auth.uid()
    or accountant_id = public.current_accountant_id()
    or public.is_administrator()
  );

create policy firm_members_manage on public.accounting_firm_members
  for all to authenticated
  using (accountant_id = public.current_accountant_id() or public.is_administrator())
  with check (accountant_id = public.current_accountant_id() or public.is_administrator());

-- ---------------------------------------------------------------------------
-- accountant_client_access
-- ---------------------------------------------------------------------------
alter table public.accountant_client_access enable row level security;

create policy client_access_select on public.accountant_client_access
  for select to authenticated
  using (
    consumer_user_id = auth.uid()
    or accountant_id = public.current_accountant_id()
    or public.is_administrator()
  );

create policy client_access_insert on public.accountant_client_access
  for insert to authenticated
  with check (
    consumer_user_id = auth.uid()
    or accountant_id = public.current_accountant_id()
  );

-- Consumers may change status/scope on their own grants (approve/revoke);
-- accountants may only touch grants they own, and may never approve
-- themselves (approval is a consumer-only action, enforced below).
create policy client_access_update on public.accountant_client_access
  for update to authenticated
  using (
    consumer_user_id = auth.uid()
    or accountant_id = public.current_accountant_id()
    or public.is_administrator()
  )
  with check (
    consumer_user_id = auth.uid()
    or accountant_id = public.current_accountant_id()
    or public.is_administrator()
  );

create policy client_access_delete on public.accountant_client_access
  for delete to authenticated
  using (consumer_user_id = auth.uid() or public.is_administrator());

create or replace function public.prevent_accountant_self_approval()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null
     and new.access_status is distinct from old.access_status
     and new.access_status = 'approved'
     and auth.uid() is distinct from new.consumer_user_id
     and not public.is_administrator() then
    raise exception 'Only the consumer may approve accountant access';
  end if;
  return new;
end;
$$;

create trigger guard_client_access_approval
  before update on public.accountant_client_access
  for each row execute function public.prevent_accountant_self_approval();

-- ---------------------------------------------------------------------------
-- merchants (data-only; see Rule 2-6, merchants never authenticate)
-- ---------------------------------------------------------------------------
alter table public.merchants enable row level security;

create policy merchants_select_any_authenticated on public.merchants
  for select to authenticated
  using (true);

create policy merchants_insert_authenticated on public.merchants
  for insert to authenticated
  with check (created_by_user_id = auth.uid() or created_by_user_id is null or public.is_administrator());

create policy merchants_update_creator_or_admin on public.merchants
  for update to authenticated
  using (created_by_user_id = auth.uid() or public.is_administrator())
  with check (created_by_user_id = auth.uid() or public.is_administrator());

create policy merchants_delete_admin_only on public.merchants
  for delete to authenticated
  using (public.is_administrator());

-- ---------------------------------------------------------------------------
-- receipts
-- ---------------------------------------------------------------------------
alter table public.receipts enable row level security;

create policy receipts_select on public.receipts
  for select to authenticated
  using (
    consumer_user_id = auth.uid()
    or public.accountant_has_client_access(consumer_user_id)
    or public.is_administrator()
  );

create policy receipts_insert_owner on public.receipts
  for insert to authenticated
  with check (consumer_user_id = auth.uid());

create policy receipts_update on public.receipts
  for update to authenticated
  using (
    consumer_user_id = auth.uid()
    or public.accountant_has_client_access(consumer_user_id)
    or public.is_administrator()
  )
  with check (
    consumer_user_id = auth.uid()
    or public.accountant_has_client_access(consumer_user_id)
    or public.is_administrator()
  );

create policy receipts_delete_owner_or_admin on public.receipts
  for delete to authenticated
  using (consumer_user_id = auth.uid() or public.is_super_administrator());

-- ---------------------------------------------------------------------------
-- receipt_items (inherits access from parent receipt)
-- ---------------------------------------------------------------------------
alter table public.receipt_items enable row level security;

create policy receipt_items_select on public.receipt_items
  for select to authenticated
  using (
    exists (
      select 1 from public.receipts r
      where r.id = receipt_items.receipt_id
        and (
          r.consumer_user_id = auth.uid()
          or public.accountant_has_client_access(r.consumer_user_id)
          or public.is_administrator()
        )
    )
  );

create policy receipt_items_manage on public.receipt_items
  for all to authenticated
  using (
    exists (
      select 1 from public.receipts r
      where r.id = receipt_items.receipt_id
        and (r.consumer_user_id = auth.uid() or public.is_administrator())
    )
  )
  with check (
    exists (
      select 1 from public.receipts r
      where r.id = receipt_items.receipt_id
        and (r.consumer_user_id = auth.uid() or public.is_administrator())
    )
  );

-- ---------------------------------------------------------------------------
-- receipt_uploads (raw inbox — owner + admin only, never accountants)
-- ---------------------------------------------------------------------------
alter table public.receipt_uploads enable row level security;

create policy receipt_uploads_owner_or_admin on public.receipt_uploads
  for all to authenticated
  using (user_id = auth.uid() or public.is_administrator())
  with check (user_id = auth.uid() or public.is_administrator());

-- ---------------------------------------------------------------------------
-- receipt_categories / expense_categories (public reference data)
-- ---------------------------------------------------------------------------
alter table public.receipt_categories enable row level security;
alter table public.expense_categories enable row level security;

create policy receipt_categories_read_all on public.receipt_categories
  for select to anon, authenticated using (true);
create policy receipt_categories_admin_write on public.receipt_categories
  for all to authenticated
  using (public.is_administrator()) with check (public.is_administrator());

create policy expense_categories_read_all on public.expense_categories
  for select to anon, authenticated using (true);
create policy expense_categories_admin_write on public.expense_categories
  for all to authenticated
  using (public.is_administrator()) with check (public.is_administrator());

-- ---------------------------------------------------------------------------
-- receipt_expense_classification
-- ---------------------------------------------------------------------------
alter table public.receipt_expense_classification enable row level security;

create policy expense_classification_select on public.receipt_expense_classification
  for select to authenticated
  using (
    consumer_user_id = auth.uid()
    or public.accountant_has_client_access(consumer_user_id)
    or public.is_administrator()
  );

create policy expense_classification_manage on public.receipt_expense_classification
  for all to authenticated
  using (
    consumer_user_id = auth.uid()
    or public.accountant_has_client_access(consumer_user_id)
    or public.is_administrator()
  )
  with check (
    consumer_user_id = auth.uid()
    or public.accountant_has_client_access(consumer_user_id)
    or public.is_administrator()
  );

-- ---------------------------------------------------------------------------
-- warranties (consumer-private; accountants are out of scope per spec)
-- ---------------------------------------------------------------------------
alter table public.warranties enable row level security;

create policy warranties_owner_or_admin on public.warranties
  for all to authenticated
  using (consumer_user_id = auth.uid() or public.is_administrator())
  with check (consumer_user_id = auth.uid() or public.is_administrator());

-- ---------------------------------------------------------------------------
-- returns_and_refunds (consumer-private; accountants are out of scope)
-- ---------------------------------------------------------------------------
alter table public.returns_and_refunds enable row level security;

create policy returns_owner_or_admin on public.returns_and_refunds
  for all to authenticated
  using (consumer_user_id = auth.uid() or public.is_administrator())
  with check (consumer_user_id = auth.uid() or public.is_administrator());

-- ---------------------------------------------------------------------------
-- notifications
-- ---------------------------------------------------------------------------
alter table public.notifications enable row level security;

create policy notifications_select_own on public.notifications
  for select to authenticated
  using (user_id = auth.uid() or public.is_administrator());

create policy notifications_insert_admin_or_system on public.notifications
  for insert to authenticated
  with check (public.is_administrator());

create policy notifications_update_own_read_status on public.notifications
  for update to authenticated
  using (user_id = auth.uid() or public.is_administrator())
  with check (user_id = auth.uid() or public.is_administrator());

create policy notifications_delete_own_or_admin on public.notifications
  for delete to authenticated
  using (user_id = auth.uid() or public.is_administrator());

-- ---------------------------------------------------------------------------
-- subscriptions
-- ---------------------------------------------------------------------------
alter table public.subscriptions enable row level security;

create policy subscriptions_select on public.subscriptions
  for select to authenticated
  using (
    user_id = auth.uid()
    or accountant_id = public.current_accountant_id()
    or public.is_administrator()
  );

create policy subscriptions_manage on public.subscriptions
  for all to authenticated
  using (
    user_id = auth.uid()
    or accountant_id = public.current_accountant_id()
    or public.is_administrator()
  )
  with check (
    user_id = auth.uid()
    or accountant_id = public.current_accountant_id()
    or public.is_administrator()
  );

-- ---------------------------------------------------------------------------
-- support_tickets
-- ---------------------------------------------------------------------------
alter table public.support_tickets enable row level security;

create policy support_tickets_select on public.support_tickets
  for select to authenticated
  using (
    user_id = auth.uid()
    or assigned_admin_id = auth.uid()
    or public.is_administrator()
  );

create policy support_tickets_insert_own on public.support_tickets
  for insert to authenticated
  with check (user_id = auth.uid());

create policy support_tickets_update on public.support_tickets
  for update to authenticated
  using (user_id = auth.uid() or public.is_administrator())
  with check (user_id = auth.uid() or public.is_administrator());

create policy support_tickets_delete_admin_only on public.support_tickets
  for delete to authenticated
  using (public.is_administrator());

-- ---------------------------------------------------------------------------
-- audit_logs (read-only to admins; writes only via SECURITY DEFINER trigger)
-- ---------------------------------------------------------------------------
alter table public.audit_logs enable row level security;

create policy audit_logs_admin_read_only on public.audit_logs
  for select to authenticated
  using (public.is_administrator());
-- Intentionally no insert/update/delete policy for `authenticated`/`anon`:
-- rows are written exclusively by public.write_audit_log(), a SECURITY
-- DEFINER function owned by the table owner, which bypasses RLS.

-- ---------------------------------------------------------------------------
-- Lookup tables (languages / countries / currencies)
-- ---------------------------------------------------------------------------
alter table public.languages enable row level security;
alter table public.countries enable row level security;
alter table public.currencies enable row level security;

create policy languages_read_all on public.languages for select to anon, authenticated using (true);
create policy languages_admin_write on public.languages for all to authenticated
  using (public.is_administrator()) with check (public.is_administrator());

create policy countries_read_all on public.countries for select to anon, authenticated using (true);
create policy countries_admin_write on public.countries for all to authenticated
  using (public.is_administrator()) with check (public.is_administrator());

create policy currencies_read_all on public.currencies for select to anon, authenticated using (true);
create policy currencies_admin_write on public.currencies for all to authenticated
  using (public.is_administrator()) with check (public.is_administrator());
