BEGIN;

UPDATE storage.buckets
SET public = false,
    file_size_limit = COALESCE(file_size_limit, 10485760),
    allowed_mime_types = COALESCE(
      allowed_mime_types,
      ARRAY['image/jpeg','image/png','image/webp','application/pdf']
    )
WHERE id IN ('kyc-documents','payment-proofs','receipts','tournament-receipts','tournament-result-proofs');

DROP POLICY IF EXISTS "Allow authenticated insert existing storage" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated update existing storage" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated delete existing storage" ON storage.objects;
DROP POLICY IF EXISTS "payment_proofs_authenticated_select" ON storage.objects;
DROP POLICY IF EXISTS "payment_proofs_authenticated_insert" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload tournament result proofs" ON storage.objects;
DROP POLICY IF EXISTS "Authorized view for receipts" ON storage.objects;
DROP POLICY IF EXISTS "Authorized view for tournament receipts" ON storage.objects;

DROP POLICY IF EXISTS "Authenticated public asset insert" ON storage.objects;
CREATE POLICY "Authenticated public asset insert"
ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id IN (
    'avatars','extra-assets','lounge-assets','room-assets',
    'promotion-assets','tournament-assets','lounges','products'
  )
);

DROP POLICY IF EXISTS "Authenticated public asset update" ON storage.objects;
CREATE POLICY "Authenticated public asset update"
ON storage.objects
FOR UPDATE TO authenticated
USING (
  bucket_id IN (
    'avatars','extra-assets','lounge-assets','room-assets',
    'promotion-assets','tournament-assets','lounges','products'
  )
  AND owner = (select auth.uid())
)
WITH CHECK (
  bucket_id IN (
    'avatars','extra-assets','lounge-assets','room-assets',
    'promotion-assets','tournament-assets','lounges','products'
  )
  AND owner = (select auth.uid())
);

DROP POLICY IF EXISTS "Authenticated public asset delete" ON storage.objects;
CREATE POLICY "Authenticated public asset delete"
ON storage.objects
FOR DELETE TO authenticated
USING (
  bucket_id IN (
    'avatars','extra-assets','lounge-assets','room-assets',
    'promotion-assets','tournament-assets','lounges','products'
  )
  AND owner = (select auth.uid())
);

DROP POLICY IF EXISTS "Payment proof owner insert" ON storage.objects;
CREATE POLICY "Payment proof owner insert"
ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'payment-proofs'
  AND (storage.foldername(name))[1] = (select auth.uid())::text
  AND EXISTS (
    SELECT 1
    FROM public.bookings b
    WHERE b.id::text = (storage.foldername(name))[2]
      AND b.user_id = (select auth.uid())
  )
);

DROP POLICY IF EXISTS "Payment proof authorized select" ON storage.objects;
CREATE POLICY "Payment proof authorized select"
ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'payment-proofs'
  AND (
    (storage.foldername(name))[1] = (select auth.uid())::text
    OR public.is_super_admin()
    OR EXISTS (
      SELECT 1
      FROM public.bookings b
      WHERE b.id::text = (storage.foldername(name))[2]
        AND (
          b.user_id = (select auth.uid())
          OR public.is_lounge_member_or_admin(b.lounge_id)
        )
    )
  )
);

DROP POLICY IF EXISTS "Payment proof owner update" ON storage.objects;
CREATE POLICY "Payment proof owner update"
ON storage.objects
FOR UPDATE TO authenticated
USING (
  bucket_id = 'payment-proofs'
  AND (storage.foldername(name))[1] = (select auth.uid())::text
)
WITH CHECK (
  bucket_id = 'payment-proofs'
  AND (storage.foldername(name))[1] = (select auth.uid())::text
);

DROP POLICY IF EXISTS "Payment proof owner delete" ON storage.objects;
CREATE POLICY "Payment proof owner delete"
ON storage.objects
FOR DELETE TO authenticated
USING (
  bucket_id = 'payment-proofs'
  AND (storage.foldername(name))[1] = (select auth.uid())::text
);

DROP POLICY IF EXISTS "Legacy receipt authorized select" ON storage.objects;
CREATE POLICY "Legacy receipt authorized select"
ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'receipts'
  AND (
    owner = (select auth.uid())
    OR (storage.foldername(name))[1] = (select auth.uid())::text
    OR public.is_super_admin()
    OR EXISTS (
      SELECT 1
      FROM public.bookings b
      WHERE b.id::text = (storage.foldername(name))[2]
        AND public.is_lounge_member_or_admin(b.lounge_id)
    )
  )
);

DROP POLICY IF EXISTS "Tournament sensitive files authorized select" ON storage.objects;
CREATE POLICY "Tournament sensitive files authorized select"
ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id IN ('tournament-receipts','tournament-result-proofs')
  AND (
    owner = (select auth.uid())
    OR public.is_super_admin()
    OR EXISTS (
      SELECT 1
      FROM public.tournaments t
      WHERE t.id::text = (storage.foldername(name))[1]
        AND (
          t.created_by = (select auth.uid())
          OR public.is_lounge_member_or_admin(t.lounge_id)
        )
    )
  )
);

COMMIT;
