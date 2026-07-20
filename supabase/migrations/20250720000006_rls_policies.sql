-- Receipt24: Row-Level Security policies
-- Phase 2 — Step 6

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consumer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accountants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounting_firm_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accountant_client_access ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.merchants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receipt_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receipt_uploads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receipt_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receipt_expense_classification ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.warranties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.returns_and_refunds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.countries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.currencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.languages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.legal_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_templates ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- USERS
-- ============================================================================
CREATE POLICY "users_select_own" ON public.users
  FOR SELECT USING (id = auth.uid() OR public.is_admin());

CREATE POLICY "users_select_accountant_clients" ON public.users
  FOR SELECT USING (
    public.is_accountant() AND
    public.accountant_has_client_access(id)
  );

CREATE POLICY "users_update_own" ON public.users
  FOR UPDATE USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

CREATE POLICY "users_admin_all" ON public.users
  FOR ALL USING (public.is_super_admin());

-- ============================================================================
-- CONSUMER PROFILES
-- ============================================================================
CREATE POLICY "consumer_profiles_select_own" ON public.consumer_profiles
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY "consumer_profiles_select_accountant" ON public.consumer_profiles
  FOR SELECT USING (public.accountant_has_client_access(user_id));

CREATE POLICY "consumer_profiles_insert_own" ON public.consumer_profiles
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "consumer_profiles_update_own" ON public.consumer_profiles
  FOR UPDATE USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "consumer_profiles_admin_all" ON public.consumer_profiles
  FOR ALL USING (public.is_super_admin());

-- ============================================================================
-- ACCOUNTANTS
-- ============================================================================
CREATE POLICY "accountants_select_own" ON public.accountants
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY "accountants_update_own" ON public.accountants
  FOR UPDATE USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "accountants_insert_own" ON public.accountants
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "accountants_admin_all" ON public.accountants
  FOR ALL USING (public.is_super_admin());

-- ============================================================================
-- ACCOUNTING FIRM MEMBERS
-- ============================================================================
CREATE POLICY "firm_members_select" ON public.accounting_firm_members
  FOR SELECT USING (
    user_id = auth.uid() OR
    accountant_id IN (
      SELECT id FROM public.accountants WHERE user_id = auth.uid()
    ) OR
    public.is_admin()
  );

CREATE POLICY "firm_members_manage" ON public.accounting_firm_members
  FOR ALL USING (
    accountant_id IN (
      SELECT a.id FROM public.accountants a
      JOIN public.users u ON u.id = a.user_id
      WHERE a.user_id = auth.uid()
        AND u.role = 'accounting_firm_manager'
    ) OR public.is_super_admin()
  );

-- ============================================================================
-- ACCOUNTANT CLIENT ACCESS
-- ============================================================================
CREATE POLICY "client_access_select" ON public.accountant_client_access
  FOR SELECT USING (
    consumer_user_id = auth.uid() OR
    accountant_id = public.get_accountant_id() OR
    public.is_admin()
  );

CREATE POLICY "client_access_accountant_insert" ON public.accountant_client_access
  FOR INSERT WITH CHECK (
    accountant_id = public.get_accountant_id() AND public.is_accountant()
  );

CREATE POLICY "client_access_consumer_update" ON public.accountant_client_access
  FOR UPDATE USING (consumer_user_id = auth.uid())
  WITH CHECK (consumer_user_id = auth.uid());

CREATE POLICY "client_access_accountant_revoke" ON public.accountant_client_access
  FOR UPDATE USING (accountant_id = public.get_accountant_id());

CREATE POLICY "client_access_admin_all" ON public.accountant_client_access
  FOR ALL USING (public.is_super_admin());

-- ============================================================================
-- MERCHANTS (receipt data only — no merchant auth)
-- ============================================================================
CREATE POLICY "merchants_select" ON public.merchants
  FOR SELECT USING (
    created_by_user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.receipts r
      WHERE r.merchant_id = merchants.id
        AND (r.consumer_user_id = auth.uid() OR
             public.accountant_has_client_access(r.consumer_user_id, r.id))
    ) OR
    public.is_admin()
  );

CREATE POLICY "merchants_insert" ON public.merchants
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND
    (public.is_consumer() OR public.is_accountant() OR public.is_admin())
  );

CREATE POLICY "merchants_update_own" ON public.merchants
  FOR UPDATE USING (created_by_user_id = auth.uid() OR public.is_admin());

CREATE POLICY "merchants_admin_all" ON public.merchants
  FOR ALL USING (public.is_super_admin());

-- ============================================================================
-- RECEIPTS
-- ============================================================================
CREATE POLICY "receipts_select_own" ON public.receipts
  FOR SELECT USING (
    (consumer_user_id = auth.uid() AND soft_deleted_at IS NULL) OR
    public.accountant_has_client_access(consumer_user_id, id) OR
    public.is_admin()
  );

CREATE POLICY "receipts_insert_own" ON public.receipts
  FOR INSERT WITH CHECK (consumer_user_id = auth.uid());

CREATE POLICY "receipts_update_own" ON public.receipts
  FOR UPDATE USING (consumer_user_id = auth.uid())
  WITH CHECK (consumer_user_id = auth.uid());

CREATE POLICY "receipts_update_accountant" ON public.receipts
  FOR UPDATE USING (public.accountant_has_client_access(consumer_user_id, id));

CREATE POLICY "receipts_admin_all" ON public.receipts
  FOR ALL USING (public.is_super_admin());

-- ============================================================================
-- RECEIPT ITEMS
-- ============================================================================
CREATE POLICY "receipt_items_select" ON public.receipt_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.receipts r
      WHERE r.id = receipt_items.receipt_id
        AND (
          (r.consumer_user_id = auth.uid() AND r.soft_deleted_at IS NULL) OR
          public.accountant_has_client_access(r.consumer_user_id, r.id) OR
          public.is_admin()
        )
    )
  );

CREATE POLICY "receipt_items_insert" ON public.receipt_items
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.receipts r
      WHERE r.id = receipt_items.receipt_id AND r.consumer_user_id = auth.uid()
    )
  );

CREATE POLICY "receipt_items_update" ON public.receipt_items
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.receipts r
      WHERE r.id = receipt_items.receipt_id
        AND (r.consumer_user_id = auth.uid() OR
             public.accountant_has_client_access(r.consumer_user_id, r.id))
    )
  );

CREATE POLICY "receipt_items_delete" ON public.receipt_items
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.receipts r
      WHERE r.id = receipt_items.receipt_id AND r.consumer_user_id = auth.uid()
    )
  );

-- ============================================================================
-- RECEIPT UPLOADS
-- ============================================================================
CREATE POLICY "receipt_uploads_select_own" ON public.receipt_uploads
  FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY "receipt_uploads_insert_own" ON public.receipt_uploads
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "receipt_uploads_update_own" ON public.receipt_uploads
  FOR UPDATE USING (user_id = auth.uid());

-- ============================================================================
-- CATEGORIES (readable by all authenticated users, managed by admins)
-- ============================================================================
CREATE POLICY "receipt_categories_select" ON public.receipt_categories
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "receipt_categories_admin" ON public.receipt_categories
  FOR ALL USING (public.is_super_admin());

CREATE POLICY "expense_categories_select" ON public.expense_categories
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "expense_categories_admin" ON public.expense_categories
  FOR ALL USING (public.is_super_admin());

-- ============================================================================
-- RECEIPT EXPENSE CLASSIFICATION
-- ============================================================================
CREATE POLICY "expense_classification_select" ON public.receipt_expense_classification
  FOR SELECT USING (
    consumer_user_id = auth.uid() OR
    public.accountant_has_client_access(consumer_user_id, receipt_id) OR
    public.is_admin()
  );

CREATE POLICY "expense_classification_insert" ON public.receipt_expense_classification
  FOR INSERT WITH CHECK (
    consumer_user_id = auth.uid() OR
    public.accountant_has_client_access(consumer_user_id, receipt_id)
  );

CREATE POLICY "expense_classification_update" ON public.receipt_expense_classification
  FOR UPDATE USING (
    consumer_user_id = auth.uid() OR
    public.accountant_has_client_access(consumer_user_id, receipt_id)
  );

-- ============================================================================
-- WARRANTIES
-- ============================================================================
CREATE POLICY "warranties_select" ON public.warranties
  FOR SELECT USING (
    consumer_user_id = auth.uid() OR
    public.accountant_has_client_access(consumer_user_id) OR
    public.is_admin()
  );

CREATE POLICY "warranties_insert" ON public.warranties
  FOR INSERT WITH CHECK (consumer_user_id = auth.uid());

CREATE POLICY "warranties_update" ON public.warranties
  FOR UPDATE USING (consumer_user_id = auth.uid());

-- ============================================================================
-- RETURNS AND REFUNDS
-- ============================================================================
CREATE POLICY "returns_select" ON public.returns_and_refunds
  FOR SELECT USING (
    consumer_user_id = auth.uid() OR
    public.accountant_has_client_access(consumer_user_id) OR
    public.is_admin()
  );

CREATE POLICY "returns_insert" ON public.returns_and_refunds
  FOR INSERT WITH CHECK (consumer_user_id = auth.uid());

CREATE POLICY "returns_update" ON public.returns_and_refunds
  FOR UPDATE USING (consumer_user_id = auth.uid());

-- ============================================================================
-- NOTIFICATIONS
-- ============================================================================
CREATE POLICY "notifications_select_own" ON public.notifications
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "notifications_update_own" ON public.notifications
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "notifications_insert_system" ON public.notifications
  FOR INSERT WITH CHECK (public.is_admin() OR auth.uid() = user_id);

-- ============================================================================
-- SUBSCRIPTIONS
-- ============================================================================
CREATE POLICY "subscriptions_select_own" ON public.subscriptions
  FOR SELECT USING (
    user_id = auth.uid() OR
    accountant_id = public.get_accountant_id() OR
    public.is_admin()
  );

CREATE POLICY "subscriptions_admin" ON public.subscriptions
  FOR ALL USING (public.is_super_admin());

-- ============================================================================
-- SUPPORT TICKETS
-- ============================================================================
CREATE POLICY "support_tickets_select" ON public.support_tickets
  FOR SELECT USING (user_id = auth.uid() OR public.is_support_admin());

CREATE POLICY "support_tickets_insert" ON public.support_tickets
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "support_tickets_update_user" ON public.support_tickets
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "support_tickets_admin" ON public.support_tickets
  FOR ALL USING (public.is_support_admin());

-- ============================================================================
-- AUDIT LOGS (admins only; users can see own actions)
-- ============================================================================
CREATE POLICY "audit_logs_select_own" ON public.audit_logs
  FOR SELECT USING (user_id = auth.uid() OR public.is_super_admin());

CREATE POLICY "audit_logs_insert" ON public.audit_logs
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- ============================================================================
-- CONTENT MANAGEMENT (public read, admin write)
-- ============================================================================
CREATE POLICY "countries_select" ON public.countries
  FOR SELECT USING (is_active = TRUE OR public.is_admin());

CREATE POLICY "countries_admin" ON public.countries
  FOR ALL USING (public.is_super_admin());

CREATE POLICY "currencies_select" ON public.currencies
  FOR SELECT USING (is_active = TRUE OR public.is_admin());

CREATE POLICY "currencies_admin" ON public.currencies
  FOR ALL USING (public.is_super_admin());

CREATE POLICY "languages_select" ON public.languages
  FOR SELECT USING (is_active = TRUE OR public.is_admin());

CREATE POLICY "languages_admin" ON public.languages
  FOR ALL USING (public.is_super_admin());

CREATE POLICY "legal_content_select" ON public.legal_content
  FOR SELECT USING (is_active = TRUE OR public.is_admin());

CREATE POLICY "legal_content_admin" ON public.legal_content
  FOR ALL USING (public.is_super_admin());

CREATE POLICY "notification_templates_admin" ON public.notification_templates
  FOR ALL USING (public.is_super_admin());

CREATE POLICY "notification_templates_select" ON public.notification_templates
  FOR SELECT USING (public.is_admin());
