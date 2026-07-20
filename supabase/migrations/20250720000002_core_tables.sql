-- Receipt24: Core user and profile tables
-- Phase 2 — Step 2

CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone_number TEXT,
  profile_photo_url TEXT,
  role public.user_role NOT NULL DEFAULT 'consumer',
  preferred_language TEXT NOT NULL DEFAULT 'en',
  country TEXT,
  currency TEXT DEFAULT 'USD',
  timezone TEXT DEFAULT 'UTC',
  account_status public.account_status NOT NULL DEFAULT 'active',
  email_verified BOOLEAN NOT NULL DEFAULT FALSE,
  phone_verified BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.consumer_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  tax_profile_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  accountant_sharing_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  default_expense_type public.expense_type NOT NULL DEFAULT 'personal',
  notification_preferences JSONB NOT NULL DEFAULT '{
    "push": true,
    "email": true,
    "sms": false,
    "warranty_reminders": true,
    "return_reminders": true,
    "marketing": false
  }'::jsonb,
  marketing_consent BOOLEAN NOT NULL DEFAULT FALSE,
  email_forwarding_address TEXT UNIQUE,
  onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE,
  onboarding_interests TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.accountants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  firm_name TEXT NOT NULL,
  professional_registration_number TEXT,
  tax_number TEXT,
  country TEXT,
  address TEXT,
  phone_number TEXT,
  verification_status public.verification_status NOT NULL DEFAULT 'pending',
  verification_document_url TEXT,
  subscription_plan TEXT DEFAULT 'solo_accountant',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.accounting_firm_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  accountant_id UUID NOT NULL REFERENCES public.accountants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  firm_role public.firm_role NOT NULL DEFAULT 'accountant',
  permissions JSONB NOT NULL DEFAULT '{
    "view_receipts": true,
    "classify_expenses": true,
    "add_notes": true,
    "request_documents": true,
    "export_reports": true,
    "invite_clients": false,
    "manage_staff": false
  }'::jsonb,
  account_status public.account_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (accountant_id, user_id)
);

CREATE TABLE public.accountant_client_access (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  accountant_id UUID NOT NULL REFERENCES public.accountants(id) ON DELETE CASCADE,
  consumer_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  access_status public.access_status NOT NULL DEFAULT 'pending',
  access_scope public.access_scope NOT NULL DEFAULT 'all_receipts',
  scope_config JSONB DEFAULT '{}'::jsonb,
  start_date DATE,
  end_date DATE,
  invitation_token TEXT UNIQUE,
  invitation_email TEXT,
  invitation_phone TEXT,
  approved_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (accountant_id, consumer_user_id)
);

-- Merchants: receipt data only — no user accounts or authentication
CREATE TABLE public.merchants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  merchant_name TEXT NOT NULL,
  trading_name TEXT,
  business_category TEXT,
  tax_number TEXT,
  email TEXT,
  phone_number TEXT,
  website TEXT,
  address TEXT,
  city TEXT,
  province_or_state TEXT,
  postal_code TEXT,
  country TEXT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  logo_url TEXT,
  merchant_source public.merchant_source NOT NULL DEFAULT 'ocr_scan',
  verification_status public.verification_status NOT NULL DEFAULT 'unverified',
  created_by_user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_merchants_name ON public.merchants(merchant_name);
CREATE INDEX idx_merchants_created_by ON public.merchants(created_by_user_id);
