-- =============================================================================
-- RLS SCENARIO TESTS — run after scripts/db_apply_local.sh.
-- Uses test.login(<uuid>) / test.logout() from 00_local_supabase_stubs.sql to
-- impersonate different users under the `authenticated` Postgres role, the
-- same way PostgREST impersonates the caller in real Supabase.
--
-- Every assertion prints PASS/FAIL. A summary line is printed at the end.
-- =============================================================================

set client_min_messages to notice;

-- Plain PL/pgSQL does not support nested procedure declarations inside a DO
-- block, so the PASS/FAIL helper lives in pg_temp (this session only) and is
-- called from the DO block below.
create or replace function pg_temp.check_(label text, condition boolean)
returns boolean
language plpgsql
as $fn$
begin
  if condition then
    raise notice 'PASS - %', label;
  else
    raise notice 'FAIL - %', label;
  end if;
  return condition;
end;
$fn$;

do $$
declare
  fail_count int := 0;

  consumer_a_id uuid := '00000000-0000-0000-0000-000000000001';
  consumer_b_id uuid := '00000000-0000-0000-0000-000000000002';
  accountant_x_user_id uuid := '00000000-0000-0000-0000-000000000003';
  accountant_y_user_id uuid := '00000000-0000-0000-0000-000000000004';
  admin_id uuid := '00000000-0000-0000-0000-000000000005';
  support_admin_id uuid := '00000000-0000-0000-0000-000000000006';

  accountant_x_id uuid;
  accountant_y_id uuid;
  receipt_a1_id uuid;
  receipt_a2_id uuid;
  access_grant_id uuid;

  v_count int;
  v_ok boolean;
  v_error text;
begin
  -------------------------------------------------------------------------
  -- Fixtures (as service_role / postgres, bypassing RLS)
  -------------------------------------------------------------------------
  insert into auth.users (id, email, email_confirmed_at, raw_user_meta_data) values
    (consumer_a_id, 'consumer.a@example.com', now(), '{"full_name":"Consumer A","role":"consumer"}'),
    (consumer_b_id, 'consumer.b@example.com', now(), '{"full_name":"Consumer B","role":"consumer"}'),
    (accountant_x_user_id, 'accountant.x@example.com', now(), '{"full_name":"Accountant X","role":"accountant","firm_name":"X & Co"}'),
    (accountant_y_user_id, 'accountant.y@example.com', now(), '{"full_name":"Accountant Y","role":"accountant","firm_name":"Y & Co"}'),
    (admin_id, 'super.admin@example.com', now(), '{"full_name":"Super Admin","role":"super_administrator"}'),
    (support_admin_id, 'support.admin@example.com', now(), '{"full_name":"Support Admin","role":"support_administrator"}')
  on conflict (id) do nothing;

  -- Trigger public.handle_new_auth_user() blocks self-elevation to admin
  -- roles, so admin rows must be promoted explicitly here (as postgres,
  -- simulating a trusted, out-of-band admin-provisioning process).
  update public.users set role = 'super_administrator', account_status = 'active' where id = admin_id;
  update public.users set role = 'support_administrator', account_status = 'active' where id = support_admin_id;
  update public.accountants set verification_status = 'approved' where user_id in (accountant_x_user_id, accountant_y_user_id);

  select id into accountant_x_id from public.accountants where user_id = accountant_x_user_id;
  select id into accountant_y_id from public.accountants where user_id = accountant_y_user_id;

  if not pg_temp.check_('fixture: 6 users synced into public.users via trigger',
    (select count(*) from public.users where id in (consumer_a_id, consumer_b_id, accountant_x_user_id, accountant_y_user_id, admin_id, support_admin_id)) = 6)
  then fail_count := fail_count + 1; end if;

  if not pg_temp.check_('fixture: accountant rows auto-created via trigger', accountant_x_id is not null and accountant_y_id is not null)
  then fail_count := fail_count + 1; end if;

  -------------------------------------------------------------------------
  -- Consumer A creates two receipts (as itself)
  -------------------------------------------------------------------------
  perform test.login(consumer_a_id);
  set local role authenticated;

  insert into public.receipts (id, consumer_user_id, merchant_name_raw, total_amount, currency, receipt_source)
  values (gen_random_uuid(), consumer_a_id, 'Test Grocer', 150.00, 'ZAR', 'manual_entry')
  returning id into receipt_a1_id;

  insert into public.receipts (id, consumer_user_id, merchant_name_raw, total_amount, currency, receipt_source)
  values (gen_random_uuid(), consumer_a_id, 'Test Fuel Stop', 400.00, 'ZAR', 'camera_scan')
  returning id into receipt_a2_id;

  select count(*) into v_count from public.receipts where consumer_user_id = consumer_a_id;
  if not pg_temp.check_('consumer A can insert their own receipts', v_count = 2)
  then fail_count := fail_count + 1; end if;

  reset role;
  perform test.logout();

  -------------------------------------------------------------------------
  -- Scenario 1: Consumer B must NOT see Consumer A's receipts.
  -------------------------------------------------------------------------
  perform test.login(consumer_b_id);
  set local role authenticated;

  select count(*) into v_count from public.receipts where consumer_user_id = consumer_a_id;
  if not pg_temp.check_('SCENARIO 1: cross-consumer receipt access is blocked (0 rows visible)', v_count = 0)
  then fail_count := fail_count + 1; end if;

  select count(*) into v_count from public.receipts;
  if not pg_temp.check_('SCENARIO 1: consumer B sees zero receipts total (none of their own yet)', v_count = 0)
  then fail_count := fail_count + 1; end if;

  v_error := null;
  begin
    insert into public.receipts (consumer_user_id, merchant_name_raw, total_amount)
    values (consumer_a_id, 'Hijacked receipt', 999);
  exception when others then
    get stacked diagnostics v_error = message_text;
  end;
  if not pg_temp.check_('SCENARIO 1: consumer B cannot insert a receipt for consumer A', v_error is not null)
  then fail_count := fail_count + 1; end if;

  reset role;
  perform test.logout();

  -------------------------------------------------------------------------
  -- Scenario 2: Accountant X has NO access to Consumer A yet -> blocked.
  -------------------------------------------------------------------------
  perform test.login(accountant_x_user_id);
  set local role authenticated;

  select count(*) into v_count from public.receipts where consumer_user_id = consumer_a_id;
  if not pg_temp.check_('SCENARIO 2: accountant with no grant sees 0 of consumer A receipts', v_count = 0)
  then fail_count := fail_count + 1; end if;

  reset role;
  perform test.logout();

  -------------------------------------------------------------------------
  -- Scenario 3: Consumer A invites Accountant X; access is PENDING -> still blocked.
  -------------------------------------------------------------------------
  perform test.login(consumer_a_id);
  set local role authenticated;

  insert into public.accountant_client_access (id, accountant_id, consumer_user_id, access_status, access_scope)
  values (gen_random_uuid(), accountant_x_id, consumer_a_id, 'pending', '{"type":"all_receipts"}')
  returning id into access_grant_id;

  reset role;
  perform test.logout();

  perform test.login(accountant_x_user_id);
  set local role authenticated;

  select count(*) into v_count from public.receipts where consumer_user_id = consumer_a_id;
  if not pg_temp.check_('SCENARIO 3: PENDING accountant access still blocks receipt visibility', v_count = 0)
  then fail_count := fail_count + 1; end if;

  v_error := null;
  begin
    update public.accountant_client_access set access_status = 'approved' where id = access_grant_id;
  exception when others then
    get stacked diagnostics v_error = message_text;
  end;
  if not pg_temp.check_('SCENARIO 3: accountant cannot self-approve access grant', v_error is not null)
  then fail_count := fail_count + 1; end if;

  reset role;
  perform test.logout();

  -------------------------------------------------------------------------
  -- Scenario 4: Consumer A approves the grant -> accountant X can now read.
  -------------------------------------------------------------------------
  perform test.login(consumer_a_id);
  set local role authenticated;

  update public.accountant_client_access
  set access_status = 'approved', approved_at = now()
  where id = access_grant_id;

  reset role;
  perform test.logout();

  perform test.login(accountant_x_user_id);
  set local role authenticated;

  select count(*) into v_count from public.receipts where consumer_user_id = consumer_a_id;
  if not pg_temp.check_('SCENARIO 4: APPROVED accountant access grants read of both receipts', v_count = 2)
  then fail_count := fail_count + 1; end if;

  select count(*) into v_count from public.receipts where consumer_user_id = consumer_b_id;
  if not pg_temp.check_('SCENARIO 4: approved access to A does not leak into B''s receipts', v_count = 0)
  then fail_count := fail_count + 1; end if;

  update public.receipts set notes = 'Reviewed by accountant X' where id = receipt_a1_id;
  select count(*) into v_count from public.receipts where id = receipt_a1_id and notes = 'Reviewed by accountant X';
  if not pg_temp.check_('SCENARIO 4: approved accountant can update an accessible receipt', v_count = 1)
  then fail_count := fail_count + 1; end if;

  reset role;
  perform test.logout();
  perform test.login(accountant_y_user_id);
  set local role authenticated;

  select count(*) into v_count from public.receipts where consumer_user_id = consumer_a_id;
  if not pg_temp.check_('SCENARIO 4: uninvolved accountant Y still has 0 access to consumer A', v_count = 0)
  then fail_count := fail_count + 1; end if;

  reset role;
  perform test.logout();

  -------------------------------------------------------------------------
  -- Scenario 5: Consumer A revokes access -> accountant X loses visibility.
  -------------------------------------------------------------------------
  perform test.login(consumer_a_id);
  set local role authenticated;

  update public.accountant_client_access
  set access_status = 'revoked', revoked_at = now()
  where id = access_grant_id;

  reset role;
  perform test.logout();

  perform test.login(accountant_x_user_id);
  set local role authenticated;

  select count(*) into v_count from public.receipts where consumer_user_id = consumer_a_id;
  if not pg_temp.check_('SCENARIO 5: revoked accountant access removes visibility again', v_count = 0)
  then fail_count := fail_count + 1; end if;

  reset role;
  perform test.logout();

  -------------------------------------------------------------------------
  -- Scenario 6: Role / account_status escalation attempts are blocked.
  -------------------------------------------------------------------------
  perform test.login(consumer_a_id);
  set local role authenticated;

  v_error := null;
  begin
    update public.users set role = 'super_administrator' where id = consumer_a_id;
  exception when others then
    get stacked diagnostics v_error = message_text;
  end;
  if not pg_temp.check_('SCENARIO 6: consumer cannot self-promote to super_administrator', v_error is not null)
  then fail_count := fail_count + 1; end if;

  -- consumer B's row does not match the users_update_own_or_admin USING
  -- clause at all (id <> auth.uid()), so the UPDATE silently affects 0 rows
  -- rather than raising — confirm no row was changed instead of expecting
  -- an exception. (consumer B starts out 'active'; attempt to flip it to
  -- 'suspended' so a successful-but-unwanted update would be observable.)
  update public.users set account_status = 'suspended' where id = consumer_b_id;

  reset role;
  perform test.logout();

  select (account_status = 'active') into v_ok from public.users where id = consumer_b_id;
  if not pg_temp.check_('SCENARIO 6: consumer A cannot suspend consumer B (row is RLS-invisible for update)', v_ok)
  then fail_count := fail_count + 1; end if;

  perform test.login(consumer_a_id);
  set local role authenticated;

  reset role;
  perform test.logout();

  -------------------------------------------------------------------------
  -- Scenario 7: Administrators can see everything; non-admins cannot see audit_logs.
  -------------------------------------------------------------------------
  perform test.login(admin_id);
  set local role authenticated;

  select count(*) into v_count from public.receipts;
  if not pg_temp.check_('SCENARIO 7: super_administrator can see all receipts across consumers', v_count >= 2)
  then fail_count := fail_count + 1; end if;

  select count(*) into v_count from public.audit_logs;
  if not pg_temp.check_('SCENARIO 7: super_administrator can read audit_logs', v_count > 0)
  then fail_count := fail_count + 1; end if;

  reset role;
  perform test.logout();

  perform test.login(consumer_a_id);
  set local role authenticated;

  select count(*) into v_count from public.audit_logs;
  if not pg_temp.check_('SCENARIO 7: consumer cannot read audit_logs (sees 0 rows)', v_count = 0)
  then fail_count := fail_count + 1; end if;

  v_error := null;
  begin
    insert into public.audit_logs (user_id, action_type, record_type, record_id)
    values (consumer_a_id, 'update', 'receipts', receipt_a1_id);
  exception when others then
    get stacked diagnostics v_error = message_text;
  end;
  if not pg_temp.check_('SCENARIO 7: consumer cannot write directly to audit_logs', v_error is not null)
  then fail_count := fail_count + 1; end if;

  reset role;
  perform test.logout();

  -------------------------------------------------------------------------
  -- Scenario 8: support_administrator has the same read access as super_administrator.
  -------------------------------------------------------------------------
  perform test.login(support_admin_id);
  set local role authenticated;

  select count(*) into v_count from public.receipts;
  if not pg_temp.check_('SCENARIO 8: support_administrator can see all receipts (support/fraud use case)', v_count >= 2)
  then fail_count := fail_count + 1; end if;

  reset role;
  perform test.logout();

  -------------------------------------------------------------------------
  -- Scenario 9: anon (unauthenticated) cannot read receipts, but can read
  -- public reference data (categories/languages/countries/currencies).
  -------------------------------------------------------------------------
  set local role anon;

  -- `anon` has no GRANT at all on public.receipts (private table, granted
  -- only to `authenticated`), so this fails closed at the privilege-grant
  -- layer before RLS is even evaluated — an even stronger guarantee than a
  -- 0-row RLS result. Either outcome (permission denied, or 0 rows) is a
  -- pass for "anonymous cannot read receipts".
  v_error := null;
  begin
    select count(*) into v_count from public.receipts;
  exception when insufficient_privilege then
    v_error := 'insufficient_privilege';
    v_count := 0;
  end;
  if not pg_temp.check_('SCENARIO 9: anonymous role cannot read any receipts', v_count = 0)
  then fail_count := fail_count + 1; end if;

  select count(*) into v_count from public.receipt_categories;
  if not pg_temp.check_('SCENARIO 9: anonymous role CAN read public receipt_categories reference data', v_count > 0)
  then fail_count := fail_count + 1; end if;

  reset role;

  -------------------------------------------------------------------------
  -- Scenario 10: merchants are directory data readable by any authenticated
  -- user, but a merchant record cannot be verified by a non-creator/non-admin.
  -------------------------------------------------------------------------
  perform test.login(consumer_a_id);
  set local role authenticated;

  insert into public.merchants (merchant_name, merchant_source, created_by_user_id)
  values ('Test Grocer Ltd', 'ocr_scan', consumer_a_id);

  select count(*) into v_count from public.merchants where merchant_name = 'Test Grocer Ltd';
  if not pg_temp.check_('SCENARIO 10: consumer can create a merchant record from OCR', v_count = 1)
  then fail_count := fail_count + 1; end if;

  reset role;
  perform test.logout();

  perform test.login(accountant_x_user_id);
  set local role authenticated;

  select count(*) into v_count from public.merchants where merchant_name = 'Test Grocer Ltd';
  if not pg_temp.check_('SCENARIO 10: any authenticated user can read merchant directory data', v_count = 1)
  then fail_count := fail_count + 1; end if;

  update public.merchants set verification_status = 'verified' where merchant_name = 'Test Grocer Ltd';

  reset role;
  perform test.logout();

  select (verification_status = 'unverified') into v_ok
  from public.merchants where merchant_name = 'Test Grocer Ltd';
  if not pg_temp.check_('SCENARIO 10: non-creator accountant cannot verify a merchant record', v_ok)
  then fail_count := fail_count + 1; end if;

  -------------------------------------------------------------------------
  raise notice '=====================================================';
  if fail_count = 0 then
    raise notice 'ALL RLS SCENARIO TESTS PASSED';
  else
    raise exception '% RLS SCENARIO TEST(S) FAILED', fail_count;
  end if;
end;
$$;
