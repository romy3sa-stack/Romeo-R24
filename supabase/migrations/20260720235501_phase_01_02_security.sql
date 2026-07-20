-- RLS is default-deny. Service-role Edge Functions perform privileged workflows
-- (OCR, payment webhooks, administrator review) and must write audit logs.

create or replace function public.is_platform_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.users
    where id = auth.uid()
      and role in ('super_administrator', 'support_administrator')
      and account_status = 'active'
  );
$$;

create or replace function public.owns_receipt(target_receipt_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.receipts
    where id = target_receipt_id and consumer_user_id = auth.uid()
  );
$$;

create or replace function public.accountant_can_read_receipt(target_receipt_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.receipts r
    join public.accountant_client_access aca on aca.consumer_user_id = r.consumer_user_id
    join public.accountants a on a.id = aca.accountant_id
    join public.users accountant_user on accountant_user.id = a.user_id
    where r.id = target_receipt_id
      and accountant_user.id = auth.uid()
      and accountant_user.account_status = 'active'
      and a.verification_status = 'approved'
      and aca.access_status = 'active'
      and (aca.start_date is null or r.transaction_date >= aca.start_date)
      and (aca.end_date is null or r.transaction_date <= aca.end_date)
      and (
        aca.access_scope ->> 'type' = 'all_receipts'
        or (aca.access_scope ->> 'type' = 'business_only' and exists (
          select 1 from public.receipt_expense_classifications rec
          where rec.receipt_id = r.id and rec.expense_type in ('business', 'mixed_use')
        ))
        or (aca.access_scope ->> 'type' = 'tax_related' and exists (
          select 1 from public.receipt_expense_classifications rec
          join public.expense_categories ec on ec.id = rec.expense_category_id
          where rec.receipt_id = r.id and (ec.tax_deductible or ec.vat_eligible)
        ))
        or (aca.access_scope ->> 'type' = 'selected_categories' and r.receipt_category_id::text = any (
          coalesce(array(select jsonb_array_elements_text(aca.access_scope -> 'category_ids')), array[]::text[])
        ))
      )
  );
$$;

create or replace function public.can_read_receipt(target_receipt_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select public.owns_receipt(target_receipt_id)
      or public.accountant_can_read_receipt(target_receipt_id);
$$;

create or replace function public.prevent_user_privilege_changes()
returns trigger language plpgsql set search_path = public as $$
begin
  if old.role <> new.role or old.account_status <> new.account_status
     or old.email_verified <> new.email_verified or old.phone_verified <> new.phone_verified then
    if coalesce(current_setting('request.jwt.claim.role', true), '') <> 'service_role' then
      raise exception 'Role, account status, and verification fields require a privileged workflow';
    end if;
  end if;
  return new;
end;
$$;
create trigger prevent_user_privilege_changes before update on public.users
for each row execute procedure public.prevent_user_privilege_changes();

alter table public.users enable row level security;
alter table public.consumer_profiles enable row level security;
alter table public.accountants enable row level security;
alter table public.accounting_firm_members enable row level security;
alter table public.merchants enable row level security;
alter table public.receipt_categories enable row level security;
alter table public.expense_categories enable row level security;
alter table public.receipts enable row level security;
alter table public.receipt_items enable row level security;
alter table public.receipt_uploads enable row level security;
alter table public.receipt_expense_classifications enable row level security;
alter table public.warranties enable row level security;
alter table public.returns_and_refunds enable row level security;
alter table public.accountant_client_access enable row level security;
alter table public.notifications enable row level security;
alter table public.subscriptions enable row level security;
alter table public.support_tickets enable row level security;
alter table public.audit_logs enable row level security;

-- Identity and own profile
create policy "users_select_self" on public.users for select using (id = auth.uid());
create policy "users_update_self_non_privileged" on public.users for update using (id = auth.uid()) with check (id = auth.uid());
create policy "consumer_profiles_owner_all" on public.consumer_profiles for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Accountant applicants control only their own application. Approval is service-role only.
create policy "accountants_select_own" on public.accountants for select using (user_id = auth.uid());
create policy "accountants_insert_own" on public.accountants for insert with check (user_id = auth.uid());
create policy "accountants_update_own" on public.accountants for update using (user_id = auth.uid()) with check (user_id = auth.uid() and verification_status = 'pending');
create policy "firm_members_select_own" on public.accounting_firm_members for select using (user_id = auth.uid());

-- Global classification vocabulary is public to authenticated users; only admins manage it.
create policy "receipt_categories_authenticated_read" on public.receipt_categories for select to authenticated using (true);
create policy "receipt_categories_admin_write" on public.receipt_categories for all using (public.is_platform_admin()) with check (public.is_platform_admin());
create policy "expense_categories_authenticated_read" on public.expense_categories for select to authenticated using (true);
create policy "expense_categories_admin_write" on public.expense_categories for all using (public.is_platform_admin()) with check (public.is_platform_admin());

-- Receipts and receipt-derived data. No delete policy: financial records require retention workflows.
create policy "receipts_consumer_read_or_shared_accountant" on public.receipts for select using (consumer_user_id = auth.uid() or public.accountant_can_read_receipt(id));
create policy "receipts_consumer_insert" on public.receipts for insert with check (consumer_user_id = auth.uid());
create policy "receipts_consumer_update" on public.receipts for update using (consumer_user_id = auth.uid()) with check (consumer_user_id = auth.uid());
create policy "receipt_items_read_authorised" on public.receipt_items for select using (public.can_read_receipt(receipt_id));
create policy "receipt_items_owner_write" on public.receipt_items for all using (public.owns_receipt(receipt_id)) with check (public.owns_receipt(receipt_id));
create policy "receipt_uploads_owner_all" on public.receipt_uploads for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "classifications_read_authorised" on public.receipt_expense_classifications for select using (public.can_read_receipt(receipt_id));
create policy "classifications_owner_write" on public.receipt_expense_classifications for all using (consumer_user_id = auth.uid()) with check (consumer_user_id = auth.uid() and public.owns_receipt(receipt_id));
create policy "warranties_read_authorised" on public.warranties for select using (public.can_read_receipt(receipt_id));
create policy "warranties_owner_write" on public.warranties for all using (consumer_user_id = auth.uid()) with check (consumer_user_id = auth.uid() and public.owns_receipt(receipt_id));
create policy "returns_read_authorised" on public.returns_and_refunds for select using (public.can_read_receipt(receipt_id));
create policy "returns_owner_write" on public.returns_and_refunds for all using (consumer_user_id = auth.uid()) with check (consumer_user_id = auth.uid() and public.owns_receipt(receipt_id));
create policy "merchants_read_when_receipt_authorised" on public.merchants for select using (
  exists (select 1 from public.receipts r where r.merchant_id = merchants.id and public.can_read_receipt(r.id))
);
create policy "merchants_consumer_insert" on public.merchants for insert with check (created_by_user_id = auth.uid());
create policy "merchants_consumer_update" on public.merchants for update using (created_by_user_id = auth.uid()) with check (created_by_user_id = auth.uid());

-- Client grants: consumers decide approvals/revocations; accountants can create invitations.
create policy "access_consumer_read" on public.accountant_client_access for select using (consumer_user_id = auth.uid());
create policy "access_accountant_read" on public.accountant_client_access for select using (
  exists (select 1 from public.accountants a where a.id = accountant_id and a.user_id = auth.uid())
);
create policy "access_accountant_invite" on public.accountant_client_access for insert with check (
  exists (select 1 from public.accountants a where a.id = accountant_id and a.user_id = auth.uid() and a.verification_status = 'approved')
);
create policy "access_consumer_update" on public.accountant_client_access for update using (consumer_user_id = auth.uid()) with check (consumer_user_id = auth.uid());

create policy "notifications_owner_read_update" on public.notifications for select using (user_id = auth.uid());
create policy "notifications_owner_mark_read" on public.notifications for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "subscriptions_owner_read" on public.subscriptions for select using (
  user_id = auth.uid() or exists (select 1 from public.accountants a where a.id = accountant_id and a.user_id = auth.uid())
);
create policy "tickets_owner_read_create" on public.support_tickets for select using (user_id = auth.uid());
create policy "tickets_owner_create" on public.support_tickets for insert with check (user_id = auth.uid());
create policy "tickets_owner_update" on public.support_tickets for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "audit_logs_self_read" on public.audit_logs for select using (user_id = auth.uid());

-- Private buckets. Object paths must begin with the authenticated user's UUID.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('receipt-files', 'receipt-files', false, 20971520, array['image/jpeg', 'image/png', 'image/heic', 'application/pdf']),
  ('accountant-verification', 'accountant-verification', false, 10485760, array['application/pdf', 'image/jpeg', 'image/png'])
on conflict (id) do nothing;

create policy "receipt_files_owner_read" on storage.objects for select using (
  bucket_id = 'receipt-files' and (storage.foldername(name))[1] = auth.uid()::text
);
create policy "receipt_files_owner_insert" on storage.objects for insert with check (
  bucket_id = 'receipt-files' and (storage.foldername(name))[1] = auth.uid()::text
);
create policy "receipt_files_owner_update" on storage.objects for update using (
  bucket_id = 'receipt-files' and (storage.foldername(name))[1] = auth.uid()::text
) with check (bucket_id = 'receipt-files' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "verification_owner_read" on storage.objects for select using (
  bucket_id = 'accountant-verification' and (storage.foldername(name))[1] = auth.uid()::text
);
create policy "verification_owner_insert" on storage.objects for insert with check (
  bucket_id = 'accountant-verification' and (storage.foldername(name))[1] = auth.uid()::text
);
