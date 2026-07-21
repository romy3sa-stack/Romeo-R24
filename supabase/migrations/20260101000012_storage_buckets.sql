-- Receipt24 · Phase 2 · Migration 12
-- Storage buckets + storage.objects RLS policies.
--
-- Convention: every object is stored under a first-level folder equal to the
-- owning user's auth.uid(), e.g. `receipts/<user_id>/<receipt_id>/original.jpg`.
-- This lets a single simple policy (`(storage.foldername(name))[1] = auth.uid()`)
-- protect every private bucket without per-row lookups.
--
-- All URLs referenced by Phase 2 tables (receipt_file_url, receipt_image_url,
-- profile_photo_url, verification_document_url, logo_url, supporting_file_url)
-- are Supabase Storage **paths**, resolved to short-lived signed URLs by the
-- backend at read time (Rule 11 / Phase 13 "Signed storage URLs") — never
-- public, permanent URLs for private buckets.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('receipts', 'receipts', false, 52428800,
    array['image/jpeg', 'image/png', 'image/heic', 'application/pdf']),
  ('avatars', 'avatars', false, 5242880,
    array['image/jpeg', 'image/png', 'image/webp']),
  ('accountant-verification-docs', 'accountant-verification-docs', false, 20971520,
    array['image/jpeg', 'image/png', 'application/pdf']),
  ('warranty-documents', 'warranty-documents', false, 20971520,
    array['image/jpeg', 'image/png', 'application/pdf']),
  ('return-evidence', 'return-evidence', false, 20971520,
    array['image/jpeg', 'image/png', 'application/pdf']),
  ('merchant-logos', 'merchant-logos', true, 2097152,
    array['image/jpeg', 'image/png', 'image/svg+xml', 'image/webp'])
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- receipts (private: owner + admin; accountants read via signed URL issued
-- by an Edge Function after accountant_has_client_access() passes — kept out
-- of storage RLS to avoid leaking the consumer_user_id -> receipt mapping
-- into the storage layer).
-- ---------------------------------------------------------------------------
create policy receipts_bucket_owner_rw on storage.objects
  for all to authenticated
  using (
    bucket_id = 'receipts'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.is_administrator())
  )
  with check (
    bucket_id = 'receipts'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.is_administrator())
  );

-- ---------------------------------------------------------------------------
-- avatars (private-by-default; owner + admin only)
-- ---------------------------------------------------------------------------
create policy avatars_owner_rw on storage.objects
  for all to authenticated
  using (
    bucket_id = 'avatars'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.is_administrator())
  )
  with check (
    bucket_id = 'avatars'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.is_administrator())
  );

-- ---------------------------------------------------------------------------
-- accountant-verification-docs (highly sensitive; accountant owner + admin)
-- ---------------------------------------------------------------------------
create policy verification_docs_owner_rw on storage.objects
  for all to authenticated
  using (
    bucket_id = 'accountant-verification-docs'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.is_administrator())
  )
  with check (
    bucket_id = 'accountant-verification-docs'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.is_administrator())
  );

-- ---------------------------------------------------------------------------
-- warranty-documents / return-evidence (consumer-private; admin visible)
-- ---------------------------------------------------------------------------
create policy warranty_docs_owner_rw on storage.objects
  for all to authenticated
  using (
    bucket_id = 'warranty-documents'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.is_administrator())
  )
  with check (
    bucket_id = 'warranty-documents'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.is_administrator())
  );

create policy return_evidence_owner_rw on storage.objects
  for all to authenticated
  using (
    bucket_id = 'return-evidence'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.is_administrator())
  )
  with check (
    bucket_id = 'return-evidence'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.is_administrator())
  );

-- ---------------------------------------------------------------------------
-- merchant-logos (public bucket: merchants have no login, so anyone
-- authenticated may contribute/read a logo; admins can always correct it)
-- ---------------------------------------------------------------------------
create policy merchant_logos_public_read on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'merchant-logos');

create policy merchant_logos_authenticated_write on storage.objects
  for insert to authenticated
  with check (bucket_id = 'merchant-logos');

create policy merchant_logos_admin_manage on storage.objects
  for update to authenticated
  using (bucket_id = 'merchant-logos' and public.is_administrator())
  with check (bucket_id = 'merchant-logos' and public.is_administrator());

create policy merchant_logos_admin_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'merchant-logos' and public.is_administrator());
