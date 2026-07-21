begin;

revoke execute on all functions in schema public from public, anon;

create or replace function public.current_user_role()
returns public.app_role
language sql
stable
security definer
set search_path = ''
as $$
  select role from public.users where id = (select auth.uid());
$$;

create or replace function public.is_active_user()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.users
    where id = (select auth.uid()) and account_status = 'active'
  );
$$;

create or replace function public.is_service_context()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select session_user in ('postgres', 'service_role', 'supabase_admin')
    or coalesce((select auth.role()) = 'service_role', false);
$$;

create or replace function public.is_administrator()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(public.current_user_role() in (
    'super_administrator'::public.app_role,
    'support_administrator'::public.app_role
  ), false);
$$;

create or replace function public.is_super_administrator()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(public.current_user_role() = 'super_administrator'::public.app_role, false);
$$;

create or replace function public.has_sensitive_admin_purpose()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_administrator()
    and coalesce(
      (select auth.jwt()) -> 'app_metadata' ->> 'receipt_access_purpose',
      ''
    ) in ('support', 'security', 'fraud_investigation', 'legal_compliance');
$$;

create or replace function public.represents_accountant(target_accountant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_active_user() and exists (
    select 1
    from public.accountants a
    where a.id = target_accountant_id
      and (
        a.user_id = (select auth.uid())
        or exists (
          select 1
          from public.accounting_firm_members fm
          where fm.accountant_id = a.id
            and fm.user_id = (select auth.uid())
            and fm.account_status = 'active'
        )
      )
  );
$$;

create or replace function public.accountant_can_access_consumer(target_consumer_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_active_user() and exists (
    select 1
    from public.accountant_client_access aca
    where aca.consumer_user_id = target_consumer_id
      and aca.access_status = 'approved'
      and (aca.start_date is null or aca.start_date <= current_date)
      and (aca.end_date is null or aca.end_date >= current_date)
      and aca.revoked_at is null
      and public.represents_accountant(aca.accountant_id)
  );
$$;

create or replace function public.accountant_can_access_receipt(target_receipt_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_active_user() and exists (
    select 1
    from public.receipts r
    join public.accountant_client_access aca
      on aca.consumer_user_id = r.consumer_user_id
    left join public.receipt_expense_classification rec
      on rec.receipt_id = r.id
    left join public.expense_categories ec
      on ec.id = rec.expense_category_id
    left join public.receipt_categories rc
      on rc.id = r.receipt_category_id
    where r.id = target_receipt_id
      and aca.access_status = 'approved'
      and aca.revoked_at is null
      and (aca.start_date is null or aca.start_date <= current_date)
      and (aca.end_date is null or aca.end_date >= current_date)
      and public.represents_accountant(aca.accountant_id)
      and case coalesce(aca.access_scope ->> 'type', 'all_receipts')
        when 'all_receipts' then true
        when 'business_only' then rec.expense_type in ('business', 'mixed_use')
        when 'tax_related_only' then coalesce(rc.tax_relevance, false)
          or coalesce(ec.tax_deductible, false)
          or coalesce(ec.vat_eligible, false)
        when 'selected_categories' then
          (rec.expense_category_id is not null and aca.access_scope -> 'expense_category_ids'
            ? rec.expense_category_id::text)
          or (r.receipt_category_id is not null and aca.access_scope -> 'receipt_category_ids'
            ? r.receipt_category_id::text)
        when 'date_range' then
          r.transaction_date::date >= coalesce(
            (aca.access_scope ->> 'start_date')::date,
            '-infinity'::date
          )
          and r.transaction_date::date <= coalesce(
            (aca.access_scope ->> 'end_date')::date,
            'infinity'::date
          )
        else false
      end
  );
$$;

create or replace function public.can_access_receipt(target_receipt_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.receipts r
    where r.id = target_receipt_id
      and (
        r.consumer_user_id = (select auth.uid())
        or public.accountant_can_access_receipt(r.id)
        or public.has_sensitive_admin_purpose()
      )
  );
$$;

create or replace function public.can_access_merchant(target_merchant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.merchants m
    where m.id = target_merchant_id
      and (
        m.created_by_user_id = (select auth.uid())
        or exists (
          select 1 from public.receipts r
          where r.merchant_id = m.id and public.can_access_receipt(r.id)
        )
        or public.has_sensitive_admin_purpose()
      )
  );
$$;

create or replace function public.protect_user_security_fields()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if pg_trigger_depth() > 1 or public.is_service_context() then
    return new;
  end if;
  if new.role is distinct from old.role
    and not public.is_super_administrator()
  then
    raise exception 'Only a super administrator may change roles';
  end if;
  if (new.account_status, new.email_verified, new.phone_verified)
    is distinct from
    (old.account_status, old.email_verified, old.phone_verified)
    and not public.is_administrator()
  then
    raise exception 'Only an administrator may change managed user fields';
  end if;
  return new;
end;
$$;
create trigger protect_user_security_fields
  before update on public.users
  for each row execute function public.protect_user_security_fields();

create or replace function public.protect_accountant_verification()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.is_service_context() then
    return new;
  end if;
  if new.verification_status is distinct from old.verification_status
    and not public.is_administrator()
  then
    raise exception 'Only an administrator may change accountant verification';
  end if;
  return new;
end;
$$;
create trigger protect_accountant_verification
  before update on public.accountants
  for each row execute function public.protect_accountant_verification();

create or replace function public.enforce_client_access_actor()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor_is_consumer boolean := old.consumer_user_id = (select auth.uid());
  actor_is_accountant boolean := public.represents_accountant(old.accountant_id);
begin
  if public.is_service_context() or public.is_administrator() then
    return new;
  end if;
  if actor_is_consumer then
    if new.accountant_id is distinct from old.accountant_id
      or new.consumer_user_id is distinct from old.consumer_user_id
      or new.invitation_token is distinct from old.invitation_token
    then
      raise exception 'A consumer cannot change invitation ownership';
    end if;
    if new.access_status = 'approved' and new.approved_at is null then
      new.approved_at := now();
    elsif new.access_status = 'revoked' and new.revoked_at is null then
      new.revoked_at := now();
    end if;
    return new;
  end if;
  if actor_is_accountant then
    if new.access_status not in ('pending', 'revoked')
      or new.access_scope is distinct from old.access_scope
      or new.consumer_user_id is distinct from old.consumer_user_id
      or new.accountant_id is distinct from old.accountant_id
    then
      raise exception 'An accountant cannot approve or broaden client access';
    end if;
    if new.access_status = 'revoked' and new.revoked_at is null then
      new.revoked_at := now();
    end if;
    return new;
  end if;
  raise exception 'Not authorised to change client access';
end;
$$;
create trigger enforce_client_access_actor
  before update on public.accountant_client_access
  for each row execute function public.enforce_client_access_actor();

create or replace function public.protect_support_ticket_fields()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_service_context()
    and not public.is_administrator()
    and (
      new.user_id is distinct from old.user_id
      or new.ticket_number is distinct from old.ticket_number
      or new.priority is distinct from old.priority
      or new.ticket_status is distinct from old.ticket_status
      or new.assigned_admin_id is distinct from old.assigned_admin_id
    )
  then
    raise exception 'Only an administrator may change managed ticket fields';
  end if;
  return new;
end;
$$;
create trigger protect_support_ticket_fields
  before update on public.support_tickets
  for each row execute function public.protect_support_ticket_fields();

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'users', 'consumer_profiles', 'accountants', 'accounting_firm_members',
    'accountant_client_access', 'merchants', 'receipts', 'receipt_items',
    'receipt_uploads', 'receipt_categories', 'expense_categories',
    'receipt_expense_classification', 'warranties', 'returns_and_refunds',
    'notifications', 'subscriptions', 'support_tickets', 'audit_logs',
    'duplicate_receipt_alerts'
  ]
  loop
    execute format('alter table public.%I enable row level security', table_name);
    execute format('alter table public.%I force row level security', table_name);
  end loop;
end;
$$;

create policy users_select on public.users for select to authenticated
  using (
    id = (select auth.uid())
    or public.is_administrator()
    or public.accountant_can_access_consumer(id)
  );
create policy users_update_self on public.users for update to authenticated
  using (id = (select auth.uid()) or public.is_administrator())
  with check (id = (select auth.uid()) or public.is_administrator());

create policy consumer_profiles_select on public.consumer_profiles for select to authenticated
  using (
    user_id = (select auth.uid())
    or public.accountant_can_access_consumer(user_id)
    or public.is_administrator()
  );
create policy consumer_profiles_insert on public.consumer_profiles for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy consumer_profiles_update on public.consumer_profiles for update to authenticated
  using (user_id = (select auth.uid()) or public.is_administrator())
  with check (user_id = (select auth.uid()) or public.is_administrator());

create policy accountants_select on public.accountants for select to authenticated
  using (
    user_id = (select auth.uid())
    or public.represents_accountant(id)
    or public.is_administrator()
    or exists (
      select 1 from public.accountant_client_access aca
      where aca.accountant_id = accountants.id
        and aca.consumer_user_id = (select auth.uid())
    )
  );
create policy accountants_insert on public.accountants for insert to authenticated
  with check (user_id = (select auth.uid()) and verification_status = 'pending');
create policy accountants_update on public.accountants for update to authenticated
  using (public.represents_accountant(id) or public.is_administrator())
  with check (public.represents_accountant(id) or public.is_administrator());

create policy firm_members_select on public.accounting_firm_members for select to authenticated
  using (
    user_id = (select auth.uid())
    or public.represents_accountant(accountant_id)
    or public.is_administrator()
  );
create policy firm_members_manage on public.accounting_firm_members for all to authenticated
  using (
    public.current_user_role() = 'accounting_firm_manager'
    and public.represents_accountant(accountant_id)
    or public.is_super_administrator()
  )
  with check (
    public.current_user_role() = 'accounting_firm_manager'
    and public.represents_accountant(accountant_id)
    or public.is_super_administrator()
  );

create policy client_access_select on public.accountant_client_access for select to authenticated
  using (
    consumer_user_id = (select auth.uid())
    or public.represents_accountant(accountant_id)
    or public.is_administrator()
  );
create policy client_access_invite on public.accountant_client_access for insert to authenticated
  with check (
    public.represents_accountant(accountant_id)
    and access_status = 'pending'
    and approved_at is null
    and revoked_at is null
  );
create policy client_access_update on public.accountant_client_access for update to authenticated
  using (
    consumer_user_id = (select auth.uid())
    or public.represents_accountant(accountant_id)
    or public.is_administrator()
  )
  with check (
    consumer_user_id = (select auth.uid())
    or public.represents_accountant(accountant_id)
    or public.is_administrator()
  );

create policy merchants_select on public.merchants for select to authenticated
  using (public.can_access_merchant(id));
create policy merchants_insert on public.merchants for insert to authenticated
  with check (
    created_by_user_id = (select auth.uid())
    and public.current_user_role() = 'consumer'
  );
create policy merchants_update on public.merchants for update to authenticated
  using (created_by_user_id = (select auth.uid()) or public.has_sensitive_admin_purpose())
  with check (created_by_user_id = (select auth.uid()) or public.has_sensitive_admin_purpose());

create policy receipts_select on public.receipts for select to authenticated
  using (
    consumer_user_id = (select auth.uid())
    or public.accountant_can_access_receipt(id)
    or public.has_sensitive_admin_purpose()
  );
create policy receipts_insert on public.receipts for insert to authenticated
  with check (
    consumer_user_id = (select auth.uid())
    and public.current_user_role() = 'consumer'
    and public.is_active_user()
  );
create policy receipts_update on public.receipts for update to authenticated
  using (consumer_user_id = (select auth.uid()) or public.has_sensitive_admin_purpose())
  with check (consumer_user_id = (select auth.uid()) or public.has_sensitive_admin_purpose());

create policy receipt_items_select on public.receipt_items for select to authenticated
  using (public.can_access_receipt(receipt_id));
create policy receipt_items_insert on public.receipt_items for insert to authenticated
  with check (
    exists (
      select 1 from public.receipts r
      where r.id = receipt_id and r.consumer_user_id = (select auth.uid())
    )
  );
create policy receipt_items_update on public.receipt_items for update to authenticated
  using (
    exists (
      select 1 from public.receipts r
      where r.id = receipt_id and r.consumer_user_id = (select auth.uid())
    )
    or public.has_sensitive_admin_purpose()
  )
  with check (
    exists (
      select 1 from public.receipts r
      where r.id = receipt_id and r.consumer_user_id = (select auth.uid())
    )
    or public.has_sensitive_admin_purpose()
  );

create policy receipt_uploads_select on public.receipt_uploads for select to authenticated
  using (
    user_id = (select auth.uid())
    or (linked_receipt_id is not null and public.accountant_can_access_receipt(linked_receipt_id))
    or public.has_sensitive_admin_purpose()
  );
create policy receipt_uploads_insert on public.receipt_uploads for insert to authenticated
  with check (user_id = (select auth.uid()) and public.current_user_role() = 'consumer');
create policy receipt_uploads_update on public.receipt_uploads for update to authenticated
  using (user_id = (select auth.uid()) or public.has_sensitive_admin_purpose())
  with check (user_id = (select auth.uid()) or public.has_sensitive_admin_purpose());

create policy receipt_categories_read on public.receipt_categories for select to authenticated
  using (true);
create policy receipt_categories_admin on public.receipt_categories for all to authenticated
  using (public.is_super_administrator())
  with check (public.is_super_administrator());
create policy expense_categories_read on public.expense_categories for select to authenticated
  using (true);
create policy expense_categories_admin on public.expense_categories for all to authenticated
  using (public.is_super_administrator())
  with check (public.is_super_administrator());

create policy classifications_select on public.receipt_expense_classification for select to authenticated
  using (
    consumer_user_id = (select auth.uid())
    or public.accountant_can_access_receipt(receipt_id)
    or public.has_sensitive_admin_purpose()
  );
create policy classifications_insert on public.receipt_expense_classification for insert to authenticated
  with check (
    consumer_user_id = (select auth.uid())
    or public.accountant_can_access_receipt(receipt_id)
    or public.has_sensitive_admin_purpose()
  );
create policy classifications_update on public.receipt_expense_classification for update to authenticated
  using (
    consumer_user_id = (select auth.uid())
    or public.accountant_can_access_receipt(receipt_id)
    or public.has_sensitive_admin_purpose()
  )
  with check (
    consumer_user_id = (select auth.uid())
    or public.accountant_can_access_receipt(receipt_id)
    or public.has_sensitive_admin_purpose()
  );

create policy warranties_select on public.warranties for select to authenticated
  using (
    consumer_user_id = (select auth.uid())
    or public.accountant_can_access_receipt(receipt_id)
    or public.has_sensitive_admin_purpose()
  );
create policy warranties_insert on public.warranties for insert to authenticated
  with check (consumer_user_id = (select auth.uid()));
create policy warranties_update on public.warranties for update to authenticated
  using (consumer_user_id = (select auth.uid()) or public.has_sensitive_admin_purpose())
  with check (consumer_user_id = (select auth.uid()) or public.has_sensitive_admin_purpose());

create policy returns_select on public.returns_and_refunds for select to authenticated
  using (
    consumer_user_id = (select auth.uid())
    or public.accountant_can_access_receipt(receipt_id)
    or public.has_sensitive_admin_purpose()
  );
create policy returns_insert on public.returns_and_refunds for insert to authenticated
  with check (consumer_user_id = (select auth.uid()));
create policy returns_update on public.returns_and_refunds for update to authenticated
  using (consumer_user_id = (select auth.uid()) or public.has_sensitive_admin_purpose())
  with check (consumer_user_id = (select auth.uid()) or public.has_sensitive_admin_purpose());

create policy notifications_select on public.notifications for select to authenticated
  using (user_id = (select auth.uid()) or public.is_administrator());
create policy notifications_update on public.notifications for update to authenticated
  using (user_id = (select auth.uid()) or public.is_administrator())
  with check (user_id = (select auth.uid()) or public.is_administrator());

create policy subscriptions_select on public.subscriptions for select to authenticated
  using (
    user_id = (select auth.uid())
    or (accountant_id is not null and public.represents_accountant(accountant_id))
    or public.is_administrator()
  );
create policy subscriptions_admin on public.subscriptions for all to authenticated
  using (public.is_super_administrator())
  with check (public.is_super_administrator());

create policy support_tickets_select on public.support_tickets for select to authenticated
  using (user_id = (select auth.uid()) or public.is_administrator());
create policy support_tickets_insert on public.support_tickets for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and assigned_admin_id is null
    and ticket_status = 'open'
  );
create policy support_tickets_update on public.support_tickets for update to authenticated
  using (user_id = (select auth.uid()) or public.is_administrator())
  with check (user_id = (select auth.uid()) or public.is_administrator());

create policy audit_logs_select on public.audit_logs for select to authenticated
  using (user_id = (select auth.uid()) or public.is_administrator());

create policy duplicate_alerts_select on public.duplicate_receipt_alerts for select to authenticated
  using (
    consumer_user_id = (select auth.uid())
    or public.accountant_can_access_receipt(receipt_id)
    or public.has_sensitive_admin_purpose()
  );
create policy duplicate_alerts_update on public.duplicate_receipt_alerts for update to authenticated
  using (consumer_user_id = (select auth.uid()) or public.has_sensitive_admin_purpose())
  with check (consumer_user_id = (select auth.uid()) or public.has_sensitive_admin_purpose());

revoke all on all tables in schema public from anon;
grant usage on schema public to authenticated;
grant select, insert, update on all tables in schema public to authenticated;
revoke delete on all tables in schema public from authenticated;
revoke insert, update on public.audit_logs from authenticated;
revoke insert, update on public.subscriptions from authenticated;
revoke execute on all functions in schema public from public, anon;
grant execute on function public.current_user_role() to authenticated;
grant execute on function public.is_active_user() to authenticated;
grant execute on function public.is_administrator() to authenticated;
grant execute on function public.is_super_administrator() to authenticated;
grant execute on function public.has_sensitive_admin_purpose() to authenticated;
grant execute on function public.represents_accountant(uuid) to authenticated;
grant execute on function public.accountant_can_access_consumer(uuid) to authenticated;
grant execute on function public.accountant_can_access_receipt(uuid) to authenticated;
grant execute on function public.can_access_receipt(uuid) to authenticated;
grant execute on function public.can_access_merchant(uuid) to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'receipt-files',
    'receipt-files',
    false,
    26214400,
    array['image/jpeg', 'image/png', 'image/heic', 'application/pdf']
  ),
  (
    'verification-documents',
    'verification-documents',
    false,
    15728640,
    array['image/jpeg', 'image/png', 'application/pdf']
  ),
  (
    'profile-photos',
    'profile-photos',
    false,
    5242880,
    array['image/jpeg', 'image/png', 'image/webp']
  ),
  (
    'supporting-documents',
    'supporting-documents',
    false,
    26214400,
    array['image/jpeg', 'image/png', 'image/heic', 'application/pdf']
  ),
  (
    'exports',
    'exports',
    false,
    104857600,
    array['text/csv', 'application/pdf', 'application/zip', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']
  )
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy receipt_files_read on storage.objects for select to authenticated
  using (
    bucket_id = 'receipt-files'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or (
        (storage.foldername(name))[2] is not null
        and public.accountant_can_access_receipt(((storage.foldername(name))[2])::uuid)
      )
      or public.has_sensitive_admin_purpose()
    )
  );
create policy receipt_files_insert on storage.objects for insert to authenticated
  with check (
    bucket_id = 'receipt-files'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and public.current_user_role() = 'consumer'
  );
create policy receipt_files_update on storage.objects for update to authenticated
  using (
    bucket_id = 'receipt-files'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'receipt-files'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy verification_documents_read on storage.objects for select to authenticated
  using (
    bucket_id = 'verification-documents'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or public.is_administrator()
    )
  );
create policy verification_documents_insert on storage.objects for insert to authenticated
  with check (
    bucket_id = 'verification-documents'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and public.current_user_role() in ('accountant', 'accounting_firm_manager')
  );
create policy verification_documents_update on storage.objects for update to authenticated
  using (
    bucket_id = 'verification-documents'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'verification-documents'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy profile_photos_read on storage.objects for select to authenticated
  using (
    bucket_id = 'profile-photos'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or public.is_administrator()
      or public.accountant_can_access_consumer(((storage.foldername(name))[1])::uuid)
    )
  );
create policy profile_photos_insert on storage.objects for insert to authenticated
  with check (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy profile_photos_update on storage.objects for update to authenticated
  using (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy supporting_documents_read on storage.objects for select to authenticated
  using (
    bucket_id = 'supporting-documents'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or (
        (storage.foldername(name))[2] is not null
        and public.accountant_can_access_receipt(((storage.foldername(name))[2])::uuid)
      )
      or public.has_sensitive_admin_purpose()
    )
  );
create policy supporting_documents_insert on storage.objects for insert to authenticated
  with check (
    bucket_id = 'supporting-documents'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy supporting_documents_update on storage.objects for update to authenticated
  using (
    bucket_id = 'supporting-documents'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'supporting-documents'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy exports_read on storage.objects for select to authenticated
  using (
    bucket_id = 'exports'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

comment on function public.has_sensitive_admin_purpose() is
  'Requires an administrator role and a server-issued JWT app_metadata.receipt_access_purpose claim.';
comment on policy receipt_files_read on storage.objects is
  'Receipt object paths must be consumer_uuid/receipt_uuid/file_name.';

commit;
