-- Receipt24 Phase 2: RLS helper functions (after users/accountants exist)

create or replace function public.current_user_id()
returns uuid
language sql
stable
as $$
  select auth.uid();
$$;

create or replace function public.current_user_role()
returns public.user_role
language sql
stable
security definer
set search_path = public
as $$
  select role
  from public.users
  where id = auth.uid()
    and deleted_at is null;
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.users u
    where u.id = auth.uid()
      and u.role in ('super_administrator', 'support_administrator')
      and u.account_status = 'active'
      and u.deleted_at is null
  );
$$;

create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.users u
    where u.id = auth.uid()
      and u.role = 'super_administrator'
      and u.account_status = 'active'
      and u.deleted_at is null
  );
$$;

create or replace function public.is_accountant_user()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.users u
    where u.id = auth.uid()
      and u.role in ('accountant', 'accounting_firm_manager')
      and u.account_status = 'active'
      and u.deleted_at is null
  );
$$;

create or replace function public.current_accountant_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select a.id
  from public.accountants a
  where a.user_id = auth.uid()
  union
  select afm.accountant_id
  from public.accounting_firm_members afm
  where afm.user_id = auth.uid()
    and afm.account_status = 'active'
  limit 1;
$$;

-- Approved accountant access to a consumer (and optionally a receipt)
create or replace function public.accountant_has_client_access(
  p_consumer_user_id uuid,
  p_receipt_id uuid default null
)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_accountant_id uuid;
  v_access public.accountant_client_access%rowtype;
  v_receipt public.receipts%rowtype;
  v_classification public.receipt_expense_classification%rowtype;
begin
  v_accountant_id := public.current_accountant_id();
  if v_accountant_id is null then
    return false;
  end if;

  select *
  into v_access
  from public.accountant_client_access aca
  where aca.accountant_id = v_accountant_id
    and aca.consumer_user_id = p_consumer_user_id
    and aca.access_status = 'approved'
    and (aca.start_date is null or aca.start_date <= (timezone('utc', now()))::date)
    and (aca.end_date is null or aca.end_date >= (timezone('utc', now()))::date)
    and aca.revoked_at is null;

  if not found then
    return false;
  end if;

  if p_receipt_id is null then
    return true;
  end if;

  select *
  into v_receipt
  from public.receipts r
  where r.id = p_receipt_id
    and r.consumer_user_id = p_consumer_user_id
    and r.deleted_at is null;

  if not found then
    return false;
  end if;

  if v_access.access_scope = 'all_receipts' then
    return true;
  end if;

  if v_access.access_scope = 'selected_date_range' then
    return v_receipt.transaction_date is not null
      and (v_access.selected_date_start is null or v_receipt.transaction_date >= v_access.selected_date_start)
      and (v_access.selected_date_end is null or v_receipt.transaction_date <= v_access.selected_date_end);
  end if;

  select *
  into v_classification
  from public.receipt_expense_classification rec
  where rec.receipt_id = p_receipt_id;

  if v_access.access_scope = 'business_only' then
    return found and v_classification.expense_type in ('business', 'mixed_use');
  end if;

  if v_access.access_scope = 'tax_related_only' then
    return exists (
      select 1
      from public.expense_categories ec
      where ec.id = v_classification.expense_category_id
        and (ec.tax_deductible = true or ec.vat_eligible = true)
    );
  end if;

  if v_access.access_scope = 'selected_categories' then
    return found
      and v_classification.expense_category_id = any (v_access.selected_category_ids);
  end if;

  return false;
end;
$$;

comment on function public.accountant_has_client_access(uuid, uuid) is
  'Returns true only when an approved accountant may access a client and optional receipt under the chosen scope.';

-- Soft-delete helper for financial records (never hard-delete by default)
create or replace function public.soft_delete_receipt(p_receipt_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  update public.receipts
  set
    deleted_at = timezone('utc', now()),
    receipt_status = 'soft_deleted',
    updated_at = timezone('utc', now())
  where id = p_receipt_id
    and consumer_user_id = auth.uid()
    and deleted_at is null;

  insert into public.audit_logs (user_id, action_type, record_type, record_id, new_value)
  values (
    auth.uid(),
    'soft_delete',
    'receipts',
    p_receipt_id,
    jsonb_build_object('deleted_at', timezone('utc', now()))
  );
end;
$$;
