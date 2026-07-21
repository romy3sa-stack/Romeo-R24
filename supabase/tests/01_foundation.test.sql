begin;
create extension if not exists pgtap with schema extensions;
select plan(26);

select has_table('public', 'users', 'users table exists');
select has_table('public', 'consumer_profiles', 'consumer profiles table exists');
select has_table('public', 'accountants', 'accountants table exists');
select has_table('public', 'accountant_client_access', 'client access table exists');
select has_table('public', 'merchants', 'receipt-derived merchants table exists');
select has_table('public', 'receipts', 'receipts table exists');
select has_table('public', 'receipt_items', 'receipt items table exists');
select has_table('public', 'receipt_uploads', 'receipt uploads table exists');
select has_table('public', 'receipt_expense_classification', 'classification table exists');
select has_table('public', 'warranties', 'warranties table exists');
select has_table('public', 'returns_and_refunds', 'returns table exists');
select has_table('public', 'subscriptions', 'subscriptions table exists');
select has_table('public', 'support_tickets', 'support tickets table exists');
select has_table('public', 'audit_logs', 'audit logs table exists');
select has_table('public', 'duplicate_receipt_alerts', 'duplicate alerts table exists');

select results_eq(
  $$select enumlabel::text
    from pg_enum e
    join pg_type t on t.oid = e.enumtypid
    where t.typname = 'app_role'
    order by e.enumsortorder$$,
  $$values
    ('consumer'),
    ('accountant'),
    ('accounting_firm_manager'),
    ('super_administrator'),
    ('support_administrator')$$,
  'only supported application roles exist'
);

select is(
  (select count(*)::integer from pg_enum e join pg_type t on t.oid = e.enumtypid
   where t.typname = 'app_role' and e.enumlabel like 'merchant%'),
  0,
  'no merchant role exists'
);

select is(
  (select relrowsecurity from pg_class where oid = 'public.receipts'::regclass),
  true,
  'receipts have RLS enabled'
);
select is(
  (select relforcerowsecurity from pg_class where oid = 'public.receipts'::regclass),
  true,
  'receipts force RLS'
);
select is(
  (select relrowsecurity from pg_class where oid = 'public.accountant_client_access'::regclass),
  true,
  'client access has RLS enabled'
);

select results_eq(
  $$select public from storage.buckets
    where id in (
      'receipt-files', 'verification-documents', 'profile-photos',
      'supporting-documents', 'exports'
    )
    order by id$$,
  $$values (false), (false), (false), (false), (false)$$,
  'all application storage buckets are private'
);

select is(
  (select count(*)::integer from pg_policies where schemaname = 'public' and tablename = 'receipts'),
  3,
  'receipts expose select, insert, and update policies only'
);
select is(
  (select count(*)::integer from pg_policies where schemaname = 'public' and tablename = 'audit_logs'),
  1,
  'audit logs are read-only to authenticated clients'
);
select is(
  (select count(*)::integer from pg_trigger
   where tgrelid = 'public.receipts'::regclass and tgname = 'audit_receipts_changes'),
  1,
  'receipt changes are audited'
);
select col_is_fk(
  'public',
  'receipts',
  'consumer_user_id',
  'receipts belong to a public user'
);
select col_is_fk(
  'public',
  'merchants',
  'created_by_user_id',
  'merchant records are created by platform users'
);

select * from finish();
rollback;
