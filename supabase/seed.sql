-- Reference data only. Application records are deliberately not seeded.
insert into public.receipt_categories
  (category_name, category_icon, category_colour, tax_relevance)
values
  ('General', 'receipt', '#2563EB', false),
  ('Travel', 'plane', '#0D9488', true),
  ('Medical', 'heart-pulse', '#DC2626', true)
on conflict (category_name) do nothing;

insert into public.expense_categories
  (category_name, category_code, tax_deductible, vat_eligible, description)
values
  ('Groceries', 'GROCERIES', false, false, 'Food and household grocery purchases'),
  ('Fuel', 'FUEL', true, true, 'Fuel and vehicle energy costs'),
  ('Transport', 'TRANSPORT', true, true, 'Public transport and transport services'),
  ('Accommodation', 'ACCOMMODATION', true, true, 'Hotels and short-term accommodation'),
  ('Restaurants', 'RESTAURANTS', false, false, 'Meals and restaurant purchases'),
  ('Medical', 'MEDICAL', true, false, 'Medical and healthcare expenses'),
  ('Education', 'EDUCATION', true, false, 'Education and training expenses'),
  ('Office supplies', 'OFFICE_SUPPLIES', true, true, 'Office consumables and equipment'),
  ('Communication', 'COMMUNICATION', true, true, 'Telephone and internet services'),
  ('Utilities', 'UTILITIES', true, true, 'Electricity, water, and related utilities'),
  ('Entertainment', 'ENTERTAINMENT', false, false, 'Entertainment purchases'),
  ('Travel', 'TRAVEL', true, true, 'Business and personal travel costs'),
  ('Professional services', 'PROFESSIONAL_SERVICES', true, true, 'Professional fees and services'),
  ('Personal care', 'PERSONAL_CARE', false, false, 'Personal care products and services'),
  ('Clothing', 'CLOTHING', false, false, 'Clothing and footwear'),
  ('Repairs and maintenance', 'REPAIRS_MAINTENANCE', true, true, 'Repair and maintenance costs')
on conflict (category_code) do nothing;
