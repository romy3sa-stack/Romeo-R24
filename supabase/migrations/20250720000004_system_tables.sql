-- Receipt24: Warranties, returns, notifications, subscriptions, support, audit
-- Phase 2 — Step 4

CREATE TABLE public.warranties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  receipt_id UUID NOT NULL REFERENCES public.receipts(id) ON DELETE CASCADE,
  receipt_item_id UUID REFERENCES public.receipt_items(id) ON DELETE SET NULL,
  consumer_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  warranty_start_date DATE NOT NULL,
  warranty_end_date DATE NOT NULL,
  warranty_status public.warranty_status NOT NULL DEFAULT 'active',
  reminder_status public.reminder_status NOT NULL DEFAULT 'pending',
  claim_reference TEXT,
  merchant_contact_details TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.returns_and_refunds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  receipt_id UUID NOT NULL REFERENCES public.receipts(id) ON DELETE CASCADE,
  receipt_item_id UUID REFERENCES public.receipt_items(id) ON DELETE SET NULL,
  consumer_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  request_type public.return_request_type NOT NULL DEFAULT 'return',
  request_reason TEXT,
  request_description TEXT,
  supporting_file_url TEXT,
  request_status public.return_request_status NOT NULL DEFAULT 'not_started',
  refund_amount DECIMAL(12, 2),
  merchant_response_notes TEXT,
  return_deadline DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  notification_type public.notification_type NOT NULL DEFAULT 'general',
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  related_record_type TEXT,
  related_record_id UUID,
  read_status BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  accountant_id UUID REFERENCES public.accountants(id) ON DELETE CASCADE,
  plan_name TEXT NOT NULL,
  billing_cycle public.billing_cycle NOT NULL DEFAULT 'monthly',
  amount DECIMAL(12, 2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  subscription_status public.subscription_status NOT NULL DEFAULT 'active',
  start_date DATE NOT NULL,
  renewal_date DATE,
  payment_provider TEXT DEFAULT 'stripe',
  external_subscription_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT subscriptions_owner_check CHECK (
    (user_id IS NOT NULL AND accountant_id IS NULL) OR
    (user_id IS NULL AND accountant_id IS NOT NULL)
  )
);

CREATE TABLE public.support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  ticket_number TEXT NOT NULL UNIQUE,
  subject TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT,
  priority public.ticket_priority NOT NULL DEFAULT 'medium',
  ticket_status public.ticket_status NOT NULL DEFAULT 'open',
  assigned_admin_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  action_type TEXT NOT NULL,
  record_type TEXT NOT NULL,
  record_id UUID,
  previous_value JSONB,
  new_value JSONB,
  ip_address INET,
  device_information TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_warranties_consumer ON public.warranties(consumer_user_id);
CREATE INDEX idx_warranties_end_date ON public.warranties(warranty_end_date);
CREATE INDEX idx_returns_consumer ON public.returns_and_refunds(consumer_user_id);
CREATE INDEX idx_notifications_user ON public.notifications(user_id);
CREATE INDEX idx_notifications_unread ON public.notifications(user_id, read_status) WHERE read_status = FALSE;
CREATE INDEX idx_subscriptions_user ON public.subscriptions(user_id);
CREATE INDEX idx_subscriptions_accountant ON public.subscriptions(accountant_id);
CREATE INDEX idx_support_tickets_user ON public.support_tickets(user_id);
CREATE INDEX idx_support_tickets_status ON public.support_tickets(ticket_status);
CREATE INDEX idx_audit_logs_user ON public.audit_logs(user_id);
CREATE INDEX idx_audit_logs_record ON public.audit_logs(record_type, record_id);
CREATE INDEX idx_audit_logs_created ON public.audit_logs(created_at);

-- Content management tables for admin (Phase 12 prep)
CREATE TABLE public.countries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code TEXT NOT NULL UNIQUE,
  country_name TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.currencies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  currency_code TEXT NOT NULL UNIQUE,
  currency_name TEXT NOT NULL,
  symbol TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.languages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  language_code TEXT NOT NULL UNIQUE,
  language_name TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.legal_content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_type TEXT NOT NULL,
  language_code TEXT NOT NULL DEFAULT 'en',
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  version TEXT NOT NULL DEFAULT '1.0',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (content_type, language_code, version)
);

CREATE TABLE public.notification_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_key TEXT NOT NULL,
  language_code TEXT NOT NULL DEFAULT 'en',
  channel TEXT NOT NULL DEFAULT 'email',
  subject TEXT,
  body TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (template_key, language_code, channel)
);
