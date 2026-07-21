begin;
create extension if not exists pgtap with schema extensions;
select plan(10);

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '10000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', 'owner@example.test', 'not-a-real-hash', now(),
    '{}'::jsonb, '{"full_name":"Receipt Owner"}'::jsonb, now(), now()
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', 'other@example.test', 'not-a-real-hash', now(),
    '{}'::jsonb, '{"full_name":"Other Consumer"}'::jsonb, now(), now()
  ),
  (
    '20000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', 'accountant@example.test', 'not-a-real-hash', now(),
    '{}'::jsonb, '{"full_name":"Approved Accountant"}'::jsonb, now(), now()
  ),
  (
    '30000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', 'admin@example.test', 'not-a-real-hash', now(),
    '{}'::jsonb, '{"full_name":"Support Admin"}'::jsonb, now(), now()
  );

update public.users
set role = 'accountant'
where id = '20000000-0000-0000-0000-000000000001';
update public.users
set role = 'support_administrator'
where id = '30000000-0000-0000-0000-000000000001';

insert into public.accountants (
  id, user_id, firm_name, professional_registration_number, country, address,
  verification_status
)
values (
  '21000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000001',
  'Test Accounting',
  'TEST-001',
  'ZA',
  '1 Test Street',
  'verified'
);

insert into public.receipts (
  id, consumer_user_id, merchant_name_raw, transaction_date, total_amount,
  currency, receipt_source, receipt_status, ocr_status
)
values
  (
    '40000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'Owner Shop', now(), 42.50, 'ZAR', 'manual_entry', 'ready', 'completed'
  ),
  (
    '40000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002',
    'Other Shop', now(), 99.00, 'ZAR', 'manual_entry', 'ready', 'completed'
  );

insert into public.accountant_client_access (
  id, accountant_id, consumer_user_id, access_status, access_scope, approved_at
)
values (
  '22000000-0000-0000-0000-000000000001',
  '21000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  'approved',
  '{"type":"all_receipts"}',
  now()
);

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"10000000-0000-0000-0000-000000000001","role":"authenticated","app_metadata":{}}';

select results_eq(
  'select merchant_name_raw from public.receipts order by merchant_name_raw',
  $$values ('Owner Shop'::text)$$,
  'consumer sees only their receipt'
);
select lives_ok(
  $$update public.receipts set notes = 'owner note'
    where id = '40000000-0000-0000-0000-000000000001'$$,
  'consumer can update their receipt'
);
select is(
  (select count(*)::integer from public.receipts
   where id = '40000000-0000-0000-0000-000000000002'),
  0,
  'cross-consumer receipt is hidden'
);
select throws_ok(
  $$delete from public.receipts
    where id = '40000000-0000-0000-0000-000000000001'$$,
  '42501',
  null,
  'authenticated users cannot hard-delete receipts'
);

set local request.jwt.claims =
  '{"sub":"20000000-0000-0000-0000-000000000001","role":"authenticated","app_metadata":{}}';
select results_eq(
  'select merchant_name_raw from public.receipts order by merchant_name_raw',
  $$values ('Owner Shop'::text)$$,
  'approved accountant sees only the authorised client receipt'
);
select is(
  (select count(*)::integer from public.receipts
   where id = '40000000-0000-0000-0000-000000000002'),
  0,
  'accountant cannot see an unapproved client receipt'
);

reset role;
update public.accountant_client_access
set access_status = 'revoked', revoked_at = now()
where id = '22000000-0000-0000-0000-000000000001';
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"20000000-0000-0000-0000-000000000001","role":"authenticated","app_metadata":{}}';
select is(
  (select count(*)::integer from public.receipts),
  0,
  'revoked accountant immediately loses receipt access'
);

set local request.jwt.claims =
  '{"sub":"30000000-0000-0000-0000-000000000001","role":"authenticated","app_metadata":{}}';
select is(
  (select count(*)::integer from public.receipts),
  0,
  'administrator without a purpose claim cannot read receipts'
);

set local request.jwt.claims =
  '{"sub":"30000000-0000-0000-0000-000000000001","role":"authenticated","app_metadata":{"receipt_access_purpose":"support"}}';
select is(
  (select count(*)::integer from public.receipts),
  2,
  'administrator with a support purpose claim can read receipts'
);

set local request.jwt.claims =
  '{"sub":"10000000-0000-0000-0000-000000000001","role":"authenticated","app_metadata":{}}';
select throws_ok(
  $$update public.users set role = 'super_administrator'
    where id = '10000000-0000-0000-0000-000000000001'$$,
  'P0001',
  'Only a super administrator may change roles',
  'consumer cannot escalate their role'
);

select * from finish();
rollback;
