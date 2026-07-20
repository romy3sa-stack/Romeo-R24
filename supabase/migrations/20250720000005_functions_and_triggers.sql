-- Receipt24: Helper functions, triggers, and auth integration
-- Phase 2 — Step 5

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers to all tables with updated_at column
DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN
    SELECT unnest(ARRAY[
      'users', 'consumer_profiles', 'accountants', 'accounting_firm_members',
      'accountant_client_access', 'merchants', 'receipts', 'receipt_items',
      'receipt_uploads', 'receipt_categories', 'expense_categories',
      'receipt_expense_classification', 'warranties', 'returns_and_refunds',
      'subscriptions', 'support_tickets', 'countries', 'currencies',
      'languages', 'legal_content', 'notification_templates'
    ])
  LOOP
    EXECUTE format(
      'CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.%I
       FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at()',
      t
    );
  END LOOP;
END;
$$;

-- Role helper functions for RLS
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS public.user_role AS $$
  SELECT role FROM public.users WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid()
      AND role = 'super_administrator'
      AND account_status = 'active'
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_support_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid()
      AND role IN ('super_administrator', 'support_administrator')
      AND account_status = 'active'
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT public.is_support_admin();
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_accountant()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid()
      AND role IN ('accountant', 'accounting_firm_manager')
      AND account_status = 'active'
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_consumer()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid()
      AND role = 'consumer'
      AND account_status = 'active'
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.get_accountant_id()
RETURNS UUID AS $$
  SELECT a.id FROM public.accountants a
  WHERE a.user_id = auth.uid()
  LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

-- Check if accountant has approved access to a consumer's data
CREATE OR REPLACE FUNCTION public.accountant_has_client_access(
  p_consumer_user_id UUID,
  p_receipt_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_accountant_id UUID;
  v_access RECORD;
BEGIN
  IF NOT public.is_accountant() THEN
    RETURN FALSE;
  END IF;

  v_accountant_id := public.get_accountant_id();
  IF v_accountant_id IS NULL THEN
    -- Check firm membership
    SELECT afm.accountant_id INTO v_accountant_id
    FROM public.accounting_firm_members afm
    WHERE afm.user_id = auth.uid()
      AND afm.account_status = 'active'
    LIMIT 1;
  END IF;

  IF v_accountant_id IS NULL THEN
    RETURN FALSE;
  END IF;

  SELECT * INTO v_access
  FROM public.accountant_client_access aca
  WHERE aca.accountant_id = v_accountant_id
    AND aca.consumer_user_id = p_consumer_user_id
    AND aca.access_status = 'approved'
    AND (aca.end_date IS NULL OR aca.end_date >= CURRENT_DATE)
    AND (aca.start_date IS NULL OR aca.start_date <= CURRENT_DATE);

  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;

  -- Scope checks when receipt is provided
  IF p_receipt_id IS NOT NULL THEN
    IF v_access.access_scope = 'business_only' THEN
      RETURN EXISTS (
        SELECT 1 FROM public.receipt_expense_classification rec
        WHERE rec.receipt_id = p_receipt_id
          AND rec.expense_type IN ('business', 'mixed_use')
      );
    ELSIF v_access.access_scope = 'tax_related_only' THEN
      RETURN EXISTS (
        SELECT 1 FROM public.receipt_expense_classification rec
        JOIN public.expense_categories ec ON ec.id = rec.expense_category_id
        WHERE rec.receipt_id = p_receipt_id
          AND (ec.tax_deductible = TRUE OR ec.vat_eligible = TRUE)
      );
    END IF;
  END IF;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- Audit log helper
CREATE OR REPLACE FUNCTION public.log_audit_event(
  p_action_type TEXT,
  p_record_type TEXT,
  p_record_id UUID,
  p_previous_value JSONB DEFAULT NULL,
  p_new_value JSONB DEFAULT NULL,
  p_ip_address INET DEFAULT NULL,
  p_device_information TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO public.audit_logs (
    user_id, action_type, record_type, record_id,
    previous_value, new_value, ip_address, device_information
  ) VALUES (
    auth.uid(), p_action_type, p_record_type, p_record_id,
    p_previous_value, p_new_value, p_ip_address, p_device_information
  )
  RETURNING id INTO v_log_id;
  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Generate unique email forwarding address for consumers
CREATE OR REPLACE FUNCTION public.generate_email_forwarding_address(p_user_id UUID)
RETURNS TEXT AS $$
DECLARE
  v_username TEXT;
  v_address TEXT;
BEGIN
  v_username := LOWER(REPLACE(SPLIT_PART(
    (SELECT email FROM public.users WHERE id = p_user_id), '@', 1
  ), '.', ''));
  v_address := v_username || '@receipts.receipt24.com';
  RETURN v_address;
END;
$$ LANGUAGE plpgsql STABLE;

-- Handle new user signup: create public.users row and role-specific profile
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_role public.user_role;
  v_full_name TEXT;
BEGIN
  v_role := COALESCE(
    (NEW.raw_user_meta_data->>'role')::public.user_role,
    'consumer'
  );
  v_full_name := COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    SPLIT_PART(NEW.email, '@', 1)
  );

  INSERT INTO public.users (
    id, full_name, email, phone_number, role,
    preferred_language, country, currency, email_verified
  ) VALUES (
    NEW.id,
    v_full_name,
    NEW.email,
    NEW.raw_user_meta_data->>'phone_number',
    v_role,
    COALESCE(NEW.raw_user_meta_data->>'preferred_language', 'en'),
    NEW.raw_user_meta_data->>'country',
    COALESCE(NEW.raw_user_meta_data->>'currency', 'USD'),
    COALESCE(NEW.email_confirmed_at IS NOT NULL, FALSE)
  );

  IF v_role = 'consumer' THEN
    INSERT INTO public.consumer_profiles (user_id, email_forwarding_address)
    VALUES (NEW.id, public.generate_email_forwarding_address(NEW.id));
  ELSIF v_role IN ('accountant', 'accounting_firm_manager') THEN
    INSERT INTO public.accountants (
      user_id, firm_name, professional_registration_number,
      tax_number, country, address, phone_number
    ) VALUES (
      NEW.id,
      COALESCE(NEW.raw_user_meta_data->>'firm_name', 'Pending Firm'),
      NEW.raw_user_meta_data->>'professional_registration_number',
      NEW.raw_user_meta_data->>'tax_number',
      NEW.raw_user_meta_data->>'country',
      NEW.raw_user_meta_data->>'address',
      NEW.raw_user_meta_data->>'phone_number'
    );
    -- Accountant accounts start as pending until admin verification
    UPDATE public.users SET account_status = 'pending' WHERE id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Generate support ticket numbers
CREATE OR REPLACE FUNCTION public.generate_ticket_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.ticket_number IS NULL OR NEW.ticket_number = '' THEN
    NEW.ticket_number := 'TKT-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' ||
      LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_ticket_number
  BEFORE INSERT ON public.support_tickets
  FOR EACH ROW EXECUTE FUNCTION public.generate_ticket_number();
