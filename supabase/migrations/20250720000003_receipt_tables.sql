-- Receipt24: Receipt and upload tables
-- Phase 2 — Step 3

CREATE TABLE public.receipt_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_name TEXT NOT NULL UNIQUE,
  category_icon TEXT,
  category_colour TEXT,
  tax_relevance BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.expense_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_name TEXT NOT NULL UNIQUE,
  category_code TEXT NOT NULL UNIQUE,
  tax_deductible BOOLEAN NOT NULL DEFAULT FALSE,
  vat_eligible BOOLEAN NOT NULL DEFAULT FALSE,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.receipt_uploads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_type public.file_type NOT NULL,
  upload_source public.upload_source NOT NULL,
  ocr_status public.ocr_status NOT NULL DEFAULT 'pending',
  ocr_raw_text TEXT,
  processing_status public.processing_status NOT NULL DEFAULT 'queued',
  linked_receipt_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.receipts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  consumer_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  merchant_id UUID REFERENCES public.merchants(id) ON DELETE SET NULL,
  merchant_name_raw TEXT,
  receipt_number TEXT,
  transaction_reference TEXT,
  transaction_date DATE,
  subtotal DECIMAL(12, 2),
  tax_amount DECIMAL(12, 2),
  discount_amount DECIMAL(12, 2) DEFAULT 0,
  total_amount DECIMAL(12, 2),
  currency TEXT DEFAULT 'USD',
  payment_method public.payment_method DEFAULT 'unknown',
  receipt_source public.receipt_source NOT NULL,
  receipt_status public.receipt_status NOT NULL DEFAULT 'draft',
  receipt_file_url TEXT,
  receipt_image_url TEXT,
  receipt_category_id UUID REFERENCES public.receipt_categories(id) ON DELETE SET NULL,
  ocr_status public.ocr_status NOT NULL DEFAULT 'pending',
  ocr_confidence_score DECIMAL(5, 2),
  verification_status public.verification_status NOT NULL DEFAULT 'unverified',
  warranty_available BOOLEAN NOT NULL DEFAULT FALSE,
  return_deadline DATE,
  notes TEXT,
  is_duplicate_flagged BOOLEAN NOT NULL DEFAULT FALSE,
  duplicate_of_receipt_id UUID REFERENCES public.receipts(id) ON DELETE SET NULL,
  soft_deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.receipt_uploads
  ADD CONSTRAINT fk_receipt_uploads_linked_receipt
  FOREIGN KEY (linked_receipt_id) REFERENCES public.receipts(id) ON DELETE SET NULL;

CREATE TABLE public.receipt_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  receipt_id UUID NOT NULL REFERENCES public.receipts(id) ON DELETE CASCADE,
  item_name TEXT NOT NULL,
  item_description TEXT,
  item_category TEXT,
  quantity DECIMAL(10, 3) NOT NULL DEFAULT 1,
  unit_price DECIMAL(12, 2),
  tax_rate DECIMAL(5, 2),
  tax_amount DECIMAL(12, 2),
  discount_amount DECIMAL(12, 2) DEFAULT 0,
  total_price DECIMAL(12, 2),
  serial_number TEXT,
  warranty_period INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.receipt_expense_classification (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  receipt_id UUID NOT NULL REFERENCES public.receipts(id) ON DELETE CASCADE,
  consumer_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  expense_category_id UUID REFERENCES public.expense_categories(id) ON DELETE SET NULL,
  classification_source public.classification_source NOT NULL DEFAULT 'automatic',
  confidence_score DECIMAL(5, 2),
  user_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
  expense_type public.expense_type NOT NULL DEFAULT 'personal',
  business_percentage DECIMAL(5, 2) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (receipt_id)
);

CREATE INDEX idx_receipts_consumer ON public.receipts(consumer_user_id);
CREATE INDEX idx_receipts_merchant ON public.receipts(merchant_id);
CREATE INDEX idx_receipts_transaction_date ON public.receipts(transaction_date);
CREATE INDEX idx_receipts_status ON public.receipts(receipt_status);
CREATE INDEX idx_receipts_duplicate ON public.receipts(is_duplicate_flagged) WHERE is_duplicate_flagged = TRUE;
CREATE INDEX idx_receipt_items_receipt ON public.receipt_items(receipt_id);
CREATE INDEX idx_receipt_uploads_user ON public.receipt_uploads(user_id);
