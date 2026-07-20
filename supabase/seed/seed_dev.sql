-- Receipt24: Development seed data
-- Run only in development/testing environments

-- Languages
INSERT INTO public.languages (language_code, language_name) VALUES
  ('en', 'English'),
  ('fr', 'French'),
  ('pt', 'Portuguese'),
  ('es', 'Spanish'),
  ('af', 'Afrikaans'),
  ('zu', 'isiZulu')
ON CONFLICT (language_code) DO NOTHING;

-- Countries (sample)
INSERT INTO public.countries (country_code, country_name) VALUES
  ('ZA', 'South Africa'),
  ('US', 'United States'),
  ('GB', 'United Kingdom'),
  ('CA', 'Canada'),
  ('AU', 'Australia'),
  ('DE', 'Germany'),
  ('FR', 'France')
ON CONFLICT (country_code) DO NOTHING;

-- Currencies
INSERT INTO public.currencies (currency_code, currency_name, symbol) VALUES
  ('ZAR', 'South African Rand', 'R'),
  ('USD', 'US Dollar', '$'),
  ('GBP', 'British Pound', '£'),
  ('EUR', 'Euro', '€'),
  ('CAD', 'Canadian Dollar', 'C$'),
  ('AUD', 'Australian Dollar', 'A$')
ON CONFLICT (currency_code) DO NOTHING;

-- Receipt categories
INSERT INTO public.receipt_categories (category_name, category_icon, category_colour, tax_relevance) VALUES
  ('Groceries', 'shopping_cart', '#4CAF50', FALSE),
  ('Fuel', 'local_gas_station', '#FF9800', TRUE),
  ('Transport', 'directions_car', '#2196F3', TRUE),
  ('Accommodation', 'hotel', '#9C27B0', TRUE),
  ('Restaurants', 'restaurant', '#E91E63', FALSE),
  ('Medical', 'medical_services', '#F44336', TRUE),
  ('Education', 'school', '#3F51B5', TRUE),
  ('Office Supplies', 'inventory', '#607D8B', TRUE),
  ('Communication', 'phone', '#00BCD4', TRUE),
  ('Utilities', 'bolt', '#795548', TRUE),
  ('Entertainment', 'movie', '#FF5722', FALSE),
  ('Travel', 'flight', '#009688', TRUE),
  ('Professional Services', 'work', '#673AB7', TRUE),
  ('Personal Care', 'spa', '#E040FB', FALSE),
  ('Clothing', 'checkroom', '#8BC34A', FALSE),
  ('Repairs and Maintenance', 'build', '#FFC107', TRUE)
ON CONFLICT (category_name) DO NOTHING;

-- Expense categories
INSERT INTO public.expense_categories (category_name, category_code, tax_deductible, vat_eligible, description) VALUES
  ('Groceries', 'GROC', FALSE, TRUE, 'Food and household groceries'),
  ('Fuel', 'FUEL', TRUE, TRUE, 'Vehicle fuel expenses'),
  ('Transport', 'TRAN', TRUE, TRUE, 'Public and private transport'),
  ('Accommodation', 'ACCM', TRUE, TRUE, 'Hotels and lodging'),
  ('Restaurants', 'REST', FALSE, TRUE, 'Dining and restaurants'),
  ('Medical', 'MEDI', TRUE, FALSE, 'Medical and health expenses'),
  ('Education', 'EDUC', TRUE, FALSE, 'Education and training'),
  ('Office Supplies', 'OFFC', TRUE, TRUE, 'Office and stationery supplies'),
  ('Communication', 'COMM', TRUE, TRUE, 'Phone and internet'),
  ('Utilities', 'UTIL', TRUE, TRUE, 'Electricity, water, gas'),
  ('Entertainment', 'ENTR', FALSE, TRUE, 'Entertainment and leisure'),
  ('Travel', 'TRVL', TRUE, TRUE, 'Business and personal travel'),
  ('Professional Services', 'PROF', TRUE, TRUE, 'Legal, accounting, consulting'),
  ('Personal Care', 'PCAR', FALSE, TRUE, 'Personal grooming and care'),
  ('Clothing', 'CLTH', FALSE, TRUE, 'Clothing and apparel'),
  ('Repairs and Maintenance', 'REPR', TRUE, TRUE, 'Repairs and maintenance')
ON CONFLICT (category_name) DO NOTHING;

-- Legal content placeholders
INSERT INTO public.legal_content (content_type, language_code, title, body, version) VALUES
  ('terms_and_conditions', 'en', 'Terms and Conditions', 'Receipt24 Terms and Conditions — placeholder content for development.', '1.0'),
  ('privacy_policy', 'en', 'Privacy Policy', 'Receipt24 Privacy Policy — placeholder content for development.', '1.0')
ON CONFLICT (content_type, language_code, version) DO NOTHING;
