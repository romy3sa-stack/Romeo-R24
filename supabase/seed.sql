-- Receipt24 · Reference/seed data.
-- Safe to re-run: every insert is idempotent via ON CONFLICT.
-- This is DATA, not schema — never edit migrations to add rows like these.

-- Languages (Phase 14 initial set)
insert into public.languages (code, name, native_name) values
  ('en', 'English', 'English'),
  ('fr', 'French', 'Français'),
  ('pt', 'Portuguese', 'Português'),
  ('es', 'Spanish', 'Español'),
  ('af', 'Afrikaans', 'Afrikaans'),
  ('zu', 'isiZulu', 'isiZulu')
on conflict (code) do nothing;

-- Currencies (initial working set; admins can add more via Phase 12)
insert into public.currencies (code, name, symbol, decimal_digits) values
  ('ZAR', 'South African Rand', 'R', 2),
  ('USD', 'US Dollar', '$', 2),
  ('EUR', 'Euro', '€', 2),
  ('GBP', 'British Pound', '£', 2),
  ('NGN', 'Nigerian Naira', '₦', 2),
  ('KES', 'Kenyan Shilling', 'KSh', 2),
  ('GHS', 'Ghanaian Cedi', 'GH₵', 2),
  ('MZN', 'Mozambican Metical', 'MT', 2),
  ('BRL', 'Brazilian Real', 'R$', 2)
on conflict (code) do nothing;

-- Countries (initial working set)
insert into public.countries (code, name, default_currency_code, phone_dial_code) values
  ('ZA', 'South Africa', 'ZAR', '+27'),
  ('NG', 'Nigeria', 'NGN', '+234'),
  ('KE', 'Kenya', 'KES', '+254'),
  ('GH', 'Ghana', 'GHS', '+233'),
  ('MZ', 'Mozambique', 'MZN', '+258'),
  ('PT', 'Portugal', 'EUR', '+351'),
  ('BR', 'Brazil', 'BRL', '+55'),
  ('GB', 'United Kingdom', 'GBP', '+44'),
  ('US', 'United States', 'USD', '+1')
on conflict (code) do nothing;

-- Receipt Categories (Step 6.1 examples used as receipt-level tags)
insert into public.receipt_categories (category_name, category_icon, category_colour, tax_relevance) values
  ('Groceries', 'shopping-cart', '#2ECC71', false),
  ('Fuel', 'gas-pump', '#F39C12', true),
  ('Transport', 'car', '#3498DB', true),
  ('Accommodation', 'bed', '#8E44AD', true),
  ('Restaurants', 'utensils', '#E67E22', false),
  ('Medical', 'heartbeat', '#E74C3C', true),
  ('Education', 'graduation-cap', '#1ABC9C', true),
  ('Office Supplies', 'briefcase', '#34495E', true),
  ('Communication', 'phone', '#2980B9', true),
  ('Utilities', 'bolt', '#F1C40F', true),
  ('Entertainment', 'film', '#9B59B6', false),
  ('Travel', 'plane', '#16A085', true),
  ('Professional Services', 'user-tie', '#2C3E50', true),
  ('Personal Care', 'spa', '#EC407A', false),
  ('Clothing', 'tshirt', '#D35400', false),
  ('Repairs and Maintenance', 'tools', '#7F8C8D', true)
on conflict (category_name) do nothing;

-- Expense Categories (Step 6.1)
insert into public.expense_categories (category_name, category_code, tax_deductible, vat_eligible, description) values
  ('Groceries', 'GROCERIES', false, true, 'Everyday food and household supplies.'),
  ('Fuel', 'FUEL', true, true, 'Vehicle fuel purchases.'),
  ('Transport', 'TRANSPORT', true, true, 'Public transport, ride-hailing, parking.'),
  ('Accommodation', 'ACCOMMODATION', true, true, 'Hotels and lodging.'),
  ('Restaurants', 'RESTAURANTS', false, true, 'Dining out.'),
  ('Medical', 'MEDICAL', true, false, 'Medical and healthcare expenses.'),
  ('Education', 'EDUCATION', true, false, 'Courses, tuition, training material.'),
  ('Office Supplies', 'OFFICE_SUPPLIES', true, true, 'Stationery and office consumables.'),
  ('Communication', 'COMMUNICATION', true, true, 'Mobile, internet, and telephony.'),
  ('Utilities', 'UTILITIES', true, true, 'Electricity, water, and other utilities.'),
  ('Entertainment', 'ENTERTAINMENT', false, true, 'Leisure and entertainment.'),
  ('Travel', 'TRAVEL', true, true, 'Flights, car hire, and travel expenses.'),
  ('Professional Services', 'PROFESSIONAL_SERVICES', true, true, 'Legal, accounting, and consulting fees.'),
  ('Personal Care', 'PERSONAL_CARE', false, true, 'Grooming and personal care.'),
  ('Clothing', 'CLOTHING', false, true, 'Apparel and footwear.'),
  ('Repairs and Maintenance', 'REPAIRS_MAINTENANCE', true, true, 'Repairs, servicing, and upkeep.')
on conflict (category_name) do nothing;
