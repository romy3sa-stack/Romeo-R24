-- Receipt24 development seed: reference data only (no production secrets)

insert into public.languages (language_code, language_name) values
  ('en', 'English'),
  ('fr', 'French'),
  ('pt', 'Portuguese'),
  ('es', 'Spanish'),
  ('af', 'Afrikaans'),
  ('zu', 'isiZulu')
on conflict (language_code) do nothing;

insert into public.currencies (currency_code, currency_name, symbol) values
  ('ZAR', 'South African Rand', 'R'),
  ('USD', 'US Dollar', '$'),
  ('EUR', 'Euro', '€'),
  ('GBP', 'British Pound', '£'),
  ('NGN', 'Nigerian Naira', '₦'),
  ('KES', 'Kenyan Shilling', 'KSh'),
  ('GHS', 'Ghanaian Cedi', 'GH₵')
on conflict (currency_code) do nothing;

insert into public.countries (country_code, country_name, phone_code) values
  ('ZA', 'South Africa', '+27'),
  ('NG', 'Nigeria', '+234'),
  ('KE', 'Kenya', '+254'),
  ('GH', 'Ghana', '+233'),
  ('US', 'United States', '+1'),
  ('GB', 'United Kingdom', '+44'),
  ('FR', 'France', '+33'),
  ('PT', 'Portugal', '+351'),
  ('ES', 'Spain', '+34')
on conflict (country_code) do nothing;

insert into public.expense_categories (
  category_name, category_code, tax_deductible, vat_eligible, description
) values
  ('Groceries', 'GROCERIES', false, true, 'Food and household groceries'),
  ('Fuel', 'FUEL', true, true, 'Vehicle fuel'),
  ('Transport', 'TRANSPORT', true, true, 'Public and private transport'),
  ('Accommodation', 'ACCOMMODATION', true, true, 'Hotels and lodging'),
  ('Restaurants', 'RESTAURANTS', false, true, 'Dining and takeaway'),
  ('Medical', 'MEDICAL', true, false, 'Healthcare and medical expenses'),
  ('Education', 'EDUCATION', true, false, 'Tuition and learning materials'),
  ('Office supplies', 'OFFICE_SUPPLIES', true, true, 'Stationery and office goods'),
  ('Communication', 'COMMUNICATION', true, true, 'Phone and internet'),
  ('Utilities', 'UTILITIES', true, true, 'Electricity, water, gas'),
  ('Entertainment', 'ENTERTAINMENT', false, true, 'Leisure and entertainment'),
  ('Travel', 'TRAVEL', true, true, 'Travel-related spend'),
  ('Professional services', 'PROFESSIONAL_SERVICES', true, true, 'Consulting and professional fees'),
  ('Personal care', 'PERSONAL_CARE', false, true, 'Personal care products and services'),
  ('Clothing', 'CLOTHING', false, true, 'Apparel and footwear'),
  ('Repairs and maintenance', 'REPAIRS_MAINTENANCE', true, true, 'Repairs and maintenance')
on conflict (category_code) do nothing;

insert into public.receipt_categories (
  category_name, category_icon, category_colour, tax_relevance
) values
  ('Shopping', 'shopping_bag', '#0EA5E9', false),
  ('Food', 'restaurant', '#22C55E', false),
  ('Travel', 'flight', '#0284C7', true),
  ('Health', 'medical_services', '#EF4444', true),
  ('Home', 'home', '#F59E0B', false),
  ('Business', 'briefcase', '#0B1B48', true),
  ('Other', 'receipt_long', '#5B6B86', false)
on conflict (category_name) do nothing;

insert into public.subscription_plans (
  plan_code, plan_name, audience, billing_cycle, amount, currency, features
) values
  (
    'consumer_free',
    'Free Consumer',
    'consumer',
    'monthly',
    0,
    'ZAR',
    '{"ocr_scans_per_month": 10, "pdf": false, "email_import": false, "insights": false, "accountant_sharing": false}'::jsonb
  ),
  (
    'consumer_premium_monthly',
    'Premium Consumer',
    'consumer',
    'monthly',
    99,
    'ZAR',
    '{"ocr_scans_per_month": null, "pdf": true, "email_import": true, "insights": true, "accountant_sharing": true}'::jsonb
  ),
  (
    'accountant_solo_monthly',
    'Solo Accountant',
    'accountant',
    'monthly',
    299,
    'ZAR',
    '{"max_clients": 25, "max_staff": 1, "exports": ["csv", "excel", "pdf"]}'::jsonb
  ),
  (
    'accountant_professional_monthly',
    'Professional Firm',
    'accountant',
    'monthly',
    799,
    'ZAR',
    '{"max_clients": 150, "max_staff": 10, "exports": ["csv", "excel", "pdf", "zip"]}'::jsonb
  ),
  (
    'accountant_enterprise_monthly',
    'Enterprise Firm',
    'accountant',
    'monthly',
    1999,
    'ZAR',
    '{"max_clients": null, "max_staff": null, "exports": ["csv", "excel", "pdf", "zip"]}'::jsonb
  )
on conflict (plan_code) do nothing;

insert into public.legal_documents (
  document_type, language_code, title, content_markdown, version, is_published, published_at
) values
  (
    'terms',
    'en',
    'Terms and Conditions',
    'Draft Terms and Conditions for Receipt24. Not legal advice. Subject to legal review.',
    '0.1.0',
    true,
    timezone('utc', now())
  ),
  (
    'privacy',
    'en',
    'Privacy Policy',
    'Draft Privacy Policy for Receipt24. Designed around POPIA and GDPR principles. Not a compliance claim.',
    '0.1.0',
    true,
    timezone('utc', now())
  )
on conflict (document_type, version, language_code) do nothing;
