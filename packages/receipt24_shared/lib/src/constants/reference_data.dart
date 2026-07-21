/// Reference data for registration forms.
abstract final class ReferenceData {
  static const countries = [
    ('ZA', 'South Africa'),
    ('US', 'United States'),
    ('GB', 'United Kingdom'),
    ('CA', 'Canada'),
    ('AU', 'Australia'),
    ('DE', 'Germany'),
    ('FR', 'France'),
    ('PT', 'Portugal'),
    ('ES', 'Spain'),
    ('BR', 'Brazil'),
  ];

  static const currencies = [
    ('ZAR', 'South African Rand (R)'),
    ('USD', 'US Dollar (\$)'),
    ('GBP', 'British Pound (£)'),
    ('EUR', 'Euro (€)'),
    ('CAD', 'Canadian Dollar (C\$)'),
    ('AUD', 'Australian Dollar (A\$)'),
  ];

  static const accountantPlans = [
    ('solo_accountant', 'planSolo'),
    ('professional_firm', 'planProfessional'),
    ('enterprise_firm', 'planEnterprise'),
  ];

  static const onboardingInterests = [
    'personal_expenses',
    'business_expenses',
    'tax_prep',
    'warranty',
    'returns',
    'accountant_sharing',
  ];
}
