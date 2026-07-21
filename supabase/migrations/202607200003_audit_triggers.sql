begin;

create or replace function public.write_audit_log()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  old_row jsonb;
  new_row jsonb;
  target_id uuid;
begin
  old_row := case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) else null end;
  new_row := case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) else null end;
  target_id := coalesce((new_row ->> 'id')::uuid, (old_row ->> 'id')::uuid);

  insert into public.audit_logs (
    user_id,
    action_type,
    record_type,
    record_id,
    previous_value,
    new_value
  )
  values (
    (select auth.uid()),
    lower(tg_op),
    tg_table_name,
    target_id,
    old_row,
    new_row
  );

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'users',
    'accountants',
    'accounting_firm_members',
    'accountant_client_access',
    'receipts',
    'receipt_expense_classification',
    'subscriptions',
    'support_tickets',
    'duplicate_receipt_alerts'
  ]
  loop
    execute format(
      'create trigger audit_%I_changes
       after insert or update or delete on public.%I
       for each row execute function public.write_audit_log()',
      table_name,
      table_name
    );
  end loop;
end;
$$;

revoke execute on function public.write_audit_log() from public, anon, authenticated;

commit;
