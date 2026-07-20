-- Receipt24 Phase 2: storage buckets, storage RLS, auth profile bootstrap

-- ---------------------------------------------------------------------------
-- Storage buckets
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'receipt-images',
    'receipt-images',
    false,
    15728640,
    array['image/jpeg', 'image/png', 'image/heic', 'image/heif', 'image/webp']
  ),
  (
    'receipt-pdfs',
    'receipt-pdfs',
    false,
    26214400,
    array['application/pdf']
  ),
  (
    'verification-documents',
    'verification-documents',
    false,
    20971520,
    array['application/pdf', 'image/jpeg', 'image/png']
  ),
  (
    'profile-photos',
    'profile-photos',
    false,
    5242880,
    array['image/jpeg', 'image/png', 'image/webp']
  ),
  (
    'support-attachments',
    'support-attachments',
    false,
    20971520,
    array['application/pdf', 'image/jpeg', 'image/png', 'image/webp']
  ),
  (
    'warranty-documents',
    'warranty-documents',
    false,
    20971520,
    array['application/pdf', 'image/jpeg', 'image/png', 'image/webp']
  )
on conflict (id) do nothing;

-- Path convention: {user_id}/{yyyy}/{mm}/{filename}
-- Admins may access all objects; users access only their folder prefix.

create policy storage_receipt_images_select
  on storage.objects for select
  using (
    bucket_id = 'receipt-images'
    and (
      public.is_admin()
      or (storage.foldername(name))[1] = auth.uid()::text
    )
  );

create policy storage_receipt_images_insert
  on storage.objects for insert
  with check (
    bucket_id = 'receipt-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy storage_receipt_images_update
  on storage.objects for update
  using (
    bucket_id = 'receipt-images'
    and (
      public.is_admin()
      or (storage.foldername(name))[1] = auth.uid()::text
    )
  );

create policy storage_receipt_images_delete
  on storage.objects for delete
  using (
    bucket_id = 'receipt-images'
    and (
      public.is_admin()
      or (storage.foldername(name))[1] = auth.uid()::text
    )
  );

create policy storage_receipt_pdfs_select
  on storage.objects for select
  using (
    bucket_id = 'receipt-pdfs'
    and (
      public.is_admin()
      or (storage.foldername(name))[1] = auth.uid()::text
    )
  );

create policy storage_receipt_pdfs_insert
  on storage.objects for insert
  with check (
    bucket_id = 'receipt-pdfs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy storage_receipt_pdfs_update
  on storage.objects for update
  using (
    bucket_id = 'receipt-pdfs'
    and (
      public.is_admin()
      or (storage.foldername(name))[1] = auth.uid()::text
    )
  );

create policy storage_receipt_pdfs_delete
  on storage.objects for delete
  using (
    bucket_id = 'receipt-pdfs'
    and (
      public.is_admin()
      or (storage.foldername(name))[1] = auth.uid()::text
    )
  );

create policy storage_verification_docs_select
  on storage.objects for select
  using (
    bucket_id = 'verification-documents'
    and (
      public.is_admin()
      or (storage.foldername(name))[1] = auth.uid()::text
    )
  );

create policy storage_verification_docs_insert
  on storage.objects for insert
  with check (
    bucket_id = 'verification-documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy storage_profile_photos_select
  on storage.objects for select
  using (
    bucket_id = 'profile-photos'
    and (
      public.is_admin()
      or (storage.foldername(name))[1] = auth.uid()::text
    )
  );

create policy storage_profile_photos_insert
  on storage.objects for insert
  with check (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy storage_profile_photos_update
  on storage.objects for update
  using (
    bucket_id = 'profile-photos'
    and (
      public.is_admin()
      or (storage.foldername(name))[1] = auth.uid()::text
    )
  );

create policy storage_support_attachments_all
  on storage.objects for all
  using (
    bucket_id = 'support-attachments'
    and (
      public.is_admin()
      or (storage.foldername(name))[1] = auth.uid()::text
    )
  )
  with check (
    bucket_id = 'support-attachments'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy storage_warranty_documents_all
  on storage.objects for all
  using (
    bucket_id = 'warranty-documents'
    and (
      public.is_admin()
      or (storage.foldername(name))[1] = auth.uid()::text
    )
  )
  with check (
    bucket_id = 'warranty-documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ---------------------------------------------------------------------------
-- Auth bootstrap: create public.users row from auth.users metadata
-- ---------------------------------------------------------------------------

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role public.user_role;
  v_full_name text;
begin
  v_role := coalesce(
    nullif(new.raw_user_meta_data ->> 'role', '')::public.user_role,
    'consumer'
  );

  -- Hard block merchant roles even if someone injects metadata
  if v_role::text like 'merchant%' then
    raise exception 'Merchant roles are not permitted on Receipt24';
  end if;

  v_full_name := coalesce(
    nullif(new.raw_user_meta_data ->> 'full_name', ''),
    split_part(new.email, '@', 1)
  );

  insert into public.users (
    id,
    full_name,
    email,
    phone_number,
    role,
    preferred_language,
    country,
    currency,
    timezone,
    account_status,
    email_verified
  ) values (
    new.id,
    v_full_name,
    new.email,
    new.raw_user_meta_data ->> 'phone_number',
    v_role,
    coalesce(new.raw_user_meta_data ->> 'preferred_language', 'en'),
    new.raw_user_meta_data ->> 'country',
    coalesce(new.raw_user_meta_data ->> 'currency', 'ZAR'),
    coalesce(new.raw_user_meta_data ->> 'timezone', 'Africa/Johannesburg'),
    case
      when v_role in ('accountant', 'accounting_firm_manager') then 'pending'::public.account_status
      when v_role in ('super_administrator', 'support_administrator') then 'pending'::public.account_status
      else 'active'::public.account_status
    end,
    coalesce(new.email_confirmed_at is not null, false)
  );

  if v_role = 'consumer' then
    insert into public.consumer_profiles (user_id, forwarding_email_local_part)
    values (
      new.id,
      lower(regexp_replace(split_part(new.email, '@', 1), '[^a-z0-9._-]', '', 'g'))
        || '.' || substr(replace(new.id::text, '-', ''), 1, 8)
    );
  end if;

  insert into public.audit_logs (user_id, action_type, record_type, record_id, new_value)
  values (
    new.id,
    'user_registered',
    'users',
    new.id,
    jsonb_build_object('role', v_role, 'email', new.email)
  );

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

create or replace function public.sync_email_verified()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.email_confirmed_at is distinct from old.email_confirmed_at then
    update public.users
    set email_verified = new.email_confirmed_at is not null,
        updated_at = timezone('utc', now())
    where id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists on_auth_user_email_verified on auth.users;
create trigger on_auth_user_email_verified
  after update of email_confirmed_at on auth.users
  for each row execute function public.sync_email_verified();
