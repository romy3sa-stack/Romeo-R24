-- Receipt24: Storage buckets and policies
-- Phase 2 — Step 7

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  (
    'receipt-images',
    'receipt-images',
    FALSE,
    10485760,
    ARRAY['image/jpeg', 'image/png', 'image/heic', 'image/webp']
  ),
  (
    'receipt-pdfs',
    'receipt-pdfs',
    FALSE,
    52428800,
    ARRAY['application/pdf']
  ),
  (
    'receipt-uploads',
    'receipt-uploads',
    FALSE,
    52428800,
    ARRAY['image/jpeg', 'image/png', 'image/heic', 'image/webp', 'application/pdf']
  ),
  (
    'verification-documents',
    'verification-documents',
    FALSE,
    10485760,
    ARRAY['image/jpeg', 'image/png', 'application/pdf']
  ),
  (
    'profile-photos',
    'profile-photos',
    FALSE,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp']
  ),
  (
    'warranty-documents',
    'warranty-documents',
    FALSE,
    10485760,
    ARRAY['image/jpeg', 'image/png', 'application/pdf']
  ),
  (
    'support-attachments',
    'support-attachments',
    FALSE,
    10485760,
    ARRAY['image/jpeg', 'image/png', 'application/pdf']
  )
ON CONFLICT (id) DO NOTHING;

-- Receipt images: consumer owns path {user_id}/{filename}
CREATE POLICY "receipt_images_select" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'receipt-images' AND (
      (storage.foldername(name))[1] = auth.uid()::text OR
      public.is_admin()
    )
  );

CREATE POLICY "receipt_images_insert" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'receipt-images' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "receipt_images_update" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'receipt-images' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "receipt_images_delete" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'receipt-images' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Receipt PDFs
CREATE POLICY "receipt_pdfs_select" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'receipt-pdfs' AND (
      (storage.foldername(name))[1] = auth.uid()::text OR
      public.is_admin()
    )
  );

CREATE POLICY "receipt_pdfs_insert" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'receipt-pdfs' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Receipt uploads (processing queue)
CREATE POLICY "receipt_uploads_storage_select" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'receipt-uploads' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "receipt_uploads_storage_insert" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'receipt-uploads' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Verification documents (accountants only)
CREATE POLICY "verification_docs_select" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'verification-documents' AND (
      (storage.foldername(name))[1] = auth.uid()::text OR
      public.is_admin()
    )
  );

CREATE POLICY "verification_docs_insert" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'verification-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text AND
    public.is_accountant()
  );

-- Profile photos
CREATE POLICY "profile_photos_select" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'profile-photos' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "profile_photos_insert" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'profile-photos' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "profile_photos_update" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'profile-photos' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Warranty documents
CREATE POLICY "warranty_docs_select" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'warranty-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "warranty_docs_insert" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'warranty-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Support attachments
CREATE POLICY "support_attachments_select" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'support-attachments' AND (
      (storage.foldername(name))[1] = auth.uid()::text OR
      public.is_support_admin()
    )
  );

CREATE POLICY "support_attachments_insert" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'support-attachments' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );
