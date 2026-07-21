begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
grant usage on schema extensions to authenticated;
grant execute on all functions in schema extensions to authenticated;
grant usage on schema extensions to anon;
grant execute on all functions in schema extensions to anon;
select plan(6);

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  (
    '11000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', 'storage-owner@example.test', 'not-a-real-hash', now(),
    '{}'::jsonb, '{"full_name":"Storage Owner"}'::jsonb, now(), now()
  ),
  (
    '11000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', 'storage-other@example.test', 'not-a-real-hash', now(),
    '{}'::jsonb, '{"full_name":"Storage Other"}'::jsonb, now(), now()
  ),
  (
    '21000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', 'storage-accountant@example.test', 'not-a-real-hash', now(),
    '{}'::jsonb, '{"full_name":"Storage Accountant"}'::jsonb, now(), now()
  );

update public.users
set role = 'accountant'
where id = '21000000-0000-0000-0000-000000000002';

insert into public.accountants (
  id, user_id, firm_name, professional_registration_number, country, address,
  verification_status
)
values (
  '21100000-0000-0000-0000-000000000002',
  '21000000-0000-0000-0000-000000000002',
  'Storage Accounting',
  'STORAGE-001',
  'ZA',
  '2 Test Street',
  'verified'
);

insert into public.receipts (
  id, consumer_user_id, merchant_name_raw, transaction_date, total_amount,
  currency, receipt_source, receipt_status, ocr_status
)
values
  (
    '41000000-0000-0000-0000-000000000001',
    '11000000-0000-0000-0000-000000000001',
    'Storage Owner Shop', now(), 50, 'ZAR', 'image_upload', 'ready', 'completed'
  ),
  (
    '41000000-0000-0000-0000-000000000002',
    '11000000-0000-0000-0000-000000000002',
    'Storage Other Shop', now(), 60, 'ZAR', 'image_upload', 'ready', 'completed'
  );

insert into public.accountant_client_access (
  id, accountant_id, consumer_user_id, access_status, access_scope, approved_at
)
values (
  '22100000-0000-0000-0000-000000000002',
  '21100000-0000-0000-0000-000000000002',
  '11000000-0000-0000-0000-000000000001',
  'approved',
  '{"type":"all_receipts"}',
  now()
);

insert into storage.objects (bucket_id, name)
values
  (
    'receipt-files',
    '11000000-0000-0000-0000-000000000001/41000000-0000-0000-0000-000000000001/owner.jpg'
  ),
  (
    'receipt-files',
    '11000000-0000-0000-0000-000000000002/41000000-0000-0000-0000-000000000002/other.jpg'
  );

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"11000000-0000-0000-0000-000000000001","role":"authenticated","app_metadata":{}}';
select is(
  (select count(*)::integer from storage.objects where bucket_id = 'receipt-files'),
  1,
  'consumer reads only their receipt object'
);
select throws_ok(
  $$insert into storage.objects (bucket_id, name)
    values (
      'receipt-files',
      '11000000-0000-0000-0000-000000000002/41000000-0000-0000-0000-000000000002/stolen.jpg'
    )$$,
  '42501',
  null,
  'consumer cannot upload into another user folder'
);

set local request.jwt.claims =
  '{"sub":"21000000-0000-0000-0000-000000000002","role":"authenticated","app_metadata":{}}';
select results_eq(
  $$select name from storage.objects where bucket_id = 'receipt-files'$$,
  $$values (
    '11000000-0000-0000-0000-000000000001/41000000-0000-0000-0000-000000000001/owner.jpg'::text
  )$$,
  'accountant reads the approved receipt object'
);

reset role;
update public.accountant_client_access
set access_status = 'revoked', revoked_at = now()
where id = '22100000-0000-0000-0000-000000000002';
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"21000000-0000-0000-0000-000000000002","role":"authenticated","app_metadata":{}}';
select is(
  (select count(*)::integer from storage.objects where bucket_id = 'receipt-files'),
  0,
  'revocation removes receipt object access'
);

set local request.jwt.claims =
  '{"sub":"11000000-0000-0000-0000-000000000002","role":"authenticated","app_metadata":{}}';
select is(
  (select count(*)::integer from storage.objects where bucket_id = 'receipt-files'),
  1,
  'second consumer still reads only their object'
);

reset role;
set local role anon;
select throws_ok(
  $$select * from storage.objects$$,
  '42501',
  null,
  'anonymous users cannot read private storage objects'
);

reset role;
select * from finish();
rollback;
