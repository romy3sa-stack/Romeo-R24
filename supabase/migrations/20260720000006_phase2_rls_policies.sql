-- Receipt24 Phase 2: enable RLS and define policies for all tables
-- Consumers see own data; accountants see approved clients only;
-- admins access sensitive receipt data only when required for support/security/compliance.

-- ---------------------------------------------------------------------------
-- Enable RLS on every table
-- ---------------------------------------------------------------------------

alter table public.users enable row level security;
alter table public.consumer_profiles enable row level security;
alter table public.accountants enable row level security;
alter table public.accounting_firm_members enable row level security;
alter table public.accountant_client_access enable row level security;
alter table public.merchants enable row level security;
alter table public.receipt_categories enable row level security;
alter table public.expense_categories enable row level security;
alter table public.countries enable row level security;
alter table public.currencies enable row level security;
alter table public.languages enable row level security;
alter table public.legal_documents enable row level security;
alter table public.notification_templates enable row level security;
alter table public.subscription_plans enable row level security;
alter table public.receipts enable row level security;
alter table public.receipt_items enable row level security;
alter table public.receipt_uploads enable row level security;
alter table public.receipt_expense_classification enable row level security;
alter table public.warranties enable row level security;
alter table public.returns_and_refunds enable row level security;
alter table public.duplicate_receipt_alerts enable row level security;
alter table public.notifications enable row level security;
alter table public.subscriptions enable row level security;
alter table public.support_tickets enable row level security;
alter table public.audit_logs enable row level security;
alter table public.user_devices enable row level security;
alter table public.document_requests enable row level security;
alter table public.accountant_notes enable row level security;

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------

create policy users_select_own_or_admin
  on public.users for select
  using (id = auth.uid() or public.is_admin());

create policy users_update_own
  on public.users for update
  using (id = auth.uid())
  with check (id = auth.uid());

create policy users_admin_update
  on public.users for update
  using (public.is_admin())
  with check (public.is_admin());

create policy users_insert_own
  on public.users for insert
  with check (id = auth.uid());

-- ---------------------------------------------------------------------------
-- consumer_profiles
-- ---------------------------------------------------------------------------

create policy consumer_profiles_select
  on public.consumer_profiles for select
  using (
    user_id = auth.uid()
    or public.is_admin()
    or public.accountant_has_client_access(user_id)
  );

create policy consumer_profiles_mutate_own
  on public.consumer_profiles for all
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());

-- ---------------------------------------------------------------------------
-- accountants
-- ---------------------------------------------------------------------------

create policy accountants_select
  on public.accountants for select
  using (
    user_id = auth.uid()
    or public.is_admin()
    or exists (
      select 1
      from public.accountant_client_access aca
      where aca.accountant_id = accountants.id
        and aca.consumer_user_id = auth.uid()
    )
    or exists (
      select 1
      from public.accounting_firm_members afm
      where afm.accountant_id = accountants.id
        and afm.user_id = auth.uid()
    )
  );

create policy accountants_insert_own
  on public.accountants for insert
  with check (user_id = auth.uid() or public.is_admin());

create policy accountants_update
  on public.accountants for update
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());

-- ---------------------------------------------------------------------------
-- accounting_firm_members
-- ---------------------------------------------------------------------------

create policy firm_members_select
  on public.accounting_firm_members for select
  using (
    user_id = auth.uid()
    or public.is_admin()
    or accountant_id = public.current_accountant_id()
  );

create policy firm_members_admin_or_manager_mutate
  on public.accounting_firm_members for all
  using (
    public.is_admin()
    or (
      accountant_id = public.current_accountant_id()
      and exists (
        select 1 from public.users u
        where u.id = auth.uid()
          and u.role = 'accounting_firm_manager'
      )
    )
  )
  with check (
    public.is_admin()
    or accountant_id = public.current_accountant_id()
  );

-- ---------------------------------------------------------------------------
-- accountant_client_access
-- ---------------------------------------------------------------------------

create policy client_access_select
  on public.accountant_client_access for select
  using (
    consumer_user_id = auth.uid()
    or accountant_id = public.current_accountant_id()
    or public.is_admin()
  );

create policy client_access_accountant_insert
  on public.accountant_client_access for insert
  with check (
    accountant_id = public.current_accountant_id()
    or public.is_admin()
  );

create policy client_access_update
  on public.accountant_client_access for update
  using (
    consumer_user_id = auth.uid()
    or accountant_id = public.current_accountant_id()
    or public.is_admin()
  )
  with check (
    consumer_user_id = auth.uid()
    or accountant_id = public.current_accountant_id()
    or public.is_admin()
  );

-- ---------------------------------------------------------------------------
-- merchants (data only; authenticated users can read linked merchants)
-- ---------------------------------------------------------------------------

create policy merchants_select_authenticated
  on public.merchants for select
  using (
    auth.uid() is not null
    and deleted_at is null
  );

create policy merchants_insert_authenticated
  on public.merchants for insert
  with check (
    auth.uid() is not null
    and created_by_user_id = auth.uid()
  );

create policy merchants_update_creator_or_admin
  on public.merchants for update
  using (created_by_user_id = auth.uid() or public.is_admin())
  with check (created_by_user_id = auth.uid() or public.is_admin());

-- ---------------------------------------------------------------------------
-- Reference / CMS tables
-- ---------------------------------------------------------------------------

create policy receipt_categories_read
  on public.receipt_categories for select
  using (is_active = true or public.is_admin());

create policy receipt_categories_admin_write
  on public.receipt_categories for all
  using (public.is_admin())
  with check (public.is_admin());

create policy expense_categories_read
  on public.expense_categories for select
  using (is_active = true or public.is_admin());

create policy expense_categories_admin_write
  on public.expense_categories for all
  using (public.is_admin())
  with check (public.is_admin());

create policy countries_read
  on public.countries for select
  using (is_active = true or public.is_admin());

create policy countries_admin_write
  on public.countries for all
  using (public.is_admin())
  with check (public.is_admin());

create policy currencies_read
  on public.currencies for select
  using (is_active = true or public.is_admin());

create policy currencies_admin_write
  on public.currencies for all
  using (public.is_admin())
  with check (public.is_admin());

create policy languages_read
  on public.languages for select
  using (is_active = true or public.is_admin());

create policy languages_admin_write
  on public.languages for all
  using (public.is_admin())
  with check (public.is_admin());

create policy legal_documents_read_published
  on public.legal_documents for select
  using (is_published = true or public.is_admin());

create policy legal_documents_admin_write
  on public.legal_documents for all
  using (public.is_admin())
  with check (public.is_admin());

create policy notification_templates_admin
  on public.notification_templates for all
  using (public.is_admin())
  with check (public.is_admin());

create policy subscription_plans_read
  on public.subscription_plans for select
  using (is_active = true or public.is_admin());

create policy subscription_plans_admin_write
  on public.subscription_plans for all
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- receipts
-- ---------------------------------------------------------------------------

create policy receipts_select
  on public.receipts for select
  using (
    deleted_at is null
    and (
      consumer_user_id = auth.uid()
      or public.accountant_has_client_access(consumer_user_id, id)
      or public.is_admin()
    )
  );

create policy receipts_insert_own
  on public.receipts for insert
  with check (consumer_user_id = auth.uid());

create policy receipts_update
  on public.receipts for update
  using (
    consumer_user_id = auth.uid()
    or public.accountant_has_client_access(consumer_user_id, id)
    or public.is_admin()
  )
  with check (
    consumer_user_id = auth.uid()
    or public.accountant_has_client_access(consumer_user_id, id)
    or public.is_admin()
  );

-- No hard delete policy for consumers — use soft_delete_receipt()
create policy receipts_admin_soft_ops
  on public.receipts for delete
  using (public.is_super_admin());

-- ---------------------------------------------------------------------------
-- receipt_items
-- ---------------------------------------------------------------------------

create policy receipt_items_select
  on public.receipt_items for select
  using (
    exists (
      select 1 from public.receipts r
      where r.id = receipt_items.receipt_id
        and r.deleted_at is null
        and (
          r.consumer_user_id = auth.uid()
          or public.accountant_has_client_access(r.consumer_user_id, r.id)
          or public.is_admin()
        )
    )
  );

create policy receipt_items_mutate
  on public.receipt_items for all
  using (
    exists (
      select 1 from public.receipts r
      where r.id = receipt_items.receipt_id
        and (
          r.consumer_user_id = auth.uid()
          or public.accountant_has_client_access(r.consumer_user_id, r.id)
          or public.is_admin()
        )
    )
  )
  with check (
    exists (
      select 1 from public.receipts r
      where r.id = receipt_items.receipt_id
        and (
          r.consumer_user_id = auth.uid()
          or public.accountant_has_client_access(r.consumer_user_id, r.id)
          or public.is_admin()
        )
    )
  );

-- ---------------------------------------------------------------------------
-- receipt_uploads
-- ---------------------------------------------------------------------------

create policy receipt_uploads_own
  on public.receipt_uploads for all
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());

-- ---------------------------------------------------------------------------
-- receipt_expense_classification
-- ---------------------------------------------------------------------------

create policy classification_select
  on public.receipt_expense_classification for select
  using (
    consumer_user_id = auth.uid()
    or public.accountant_has_client_access(consumer_user_id, receipt_id)
    or public.is_admin()
  );

create policy classification_mutate
  on public.receipt_expense_classification for all
  using (
    consumer_user_id = auth.uid()
    or public.accountant_has_client_access(consumer_user_id, receipt_id)
    or public.is_admin()
  )
  with check (
    consumer_user_id = auth.uid()
    or public.accountant_has_client_access(consumer_user_id, receipt_id)
    or public.is_admin()
  );

-- ---------------------------------------------------------------------------
-- warranties / returns
-- ---------------------------------------------------------------------------

create policy warranties_own_or_shared
  on public.warranties for all
  using (
    (consumer_user_id = auth.uid() or public.is_admin())
    and deleted_at is null
  )
  with check (consumer_user_id = auth.uid() or public.is_admin());

create policy returns_own_or_admin
  on public.returns_and_refunds for all
  using (
    (consumer_user_id = auth.uid() or public.is_admin())
    and deleted_at is null
  )
  with check (consumer_user_id = auth.uid() or public.is_admin());

-- ---------------------------------------------------------------------------
-- duplicate alerts
-- ---------------------------------------------------------------------------

create policy duplicate_alerts_select
  on public.duplicate_receipt_alerts for select
  using (
    consumer_user_id = auth.uid()
    or public.is_admin()
    or public.accountant_has_client_access(consumer_user_id)
  );

create policy duplicate_alerts_mutate
  on public.duplicate_receipt_alerts for all
  using (consumer_user_id = auth.uid() or public.is_admin())
  with check (consumer_user_id = auth.uid() or public.is_admin());

-- ---------------------------------------------------------------------------
-- notifications / devices / subscriptions / tickets
-- ---------------------------------------------------------------------------

create policy notifications_own
  on public.notifications for all
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());

create policy user_devices_own
  on public.user_devices for all
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());

create policy subscriptions_select
  on public.subscriptions for select
  using (
    user_id = auth.uid()
    or accountant_id = public.current_accountant_id()
    or public.is_admin()
  );

create policy subscriptions_mutate_own_or_admin
  on public.subscriptions for all
  using (
    user_id = auth.uid()
    or accountant_id = public.current_accountant_id()
    or public.is_admin()
  )
  with check (
    user_id = auth.uid()
    or accountant_id = public.current_accountant_id()
    or public.is_admin()
  );

create policy support_tickets_select
  on public.support_tickets for select
  using (user_id = auth.uid() or public.is_admin());

create policy support_tickets_insert_own
  on public.support_tickets for insert
  with check (user_id = auth.uid());

create policy support_tickets_update
  on public.support_tickets for update
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());

-- ---------------------------------------------------------------------------
-- audit_logs: insert by authenticated users; read for admins + own actions
-- ---------------------------------------------------------------------------

create policy audit_logs_insert
  on public.audit_logs for insert
  with check (user_id = auth.uid() or public.is_admin());

create policy audit_logs_select
  on public.audit_logs for select
  using (user_id = auth.uid() or public.is_admin());

-- No update/delete policies for audit_logs (immutable)

-- ---------------------------------------------------------------------------
-- document_requests / accountant_notes
-- ---------------------------------------------------------------------------

create policy document_requests_access
  on public.document_requests for all
  using (
    consumer_user_id = auth.uid()
    or accountant_id = public.current_accountant_id()
    or public.is_admin()
  )
  with check (
    consumer_user_id = auth.uid()
    or accountant_id = public.current_accountant_id()
    or public.is_admin()
  );

create policy accountant_notes_access
  on public.accountant_notes for all
  using (
    consumer_user_id = auth.uid()
    or accountant_id = public.current_accountant_id()
    or public.is_admin()
  )
  with check (
    accountant_id = public.current_accountant_id()
    or public.is_admin()
  );
