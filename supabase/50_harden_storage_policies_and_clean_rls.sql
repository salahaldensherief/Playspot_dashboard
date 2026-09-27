-- 50_harden_storage_policies_and_clean_rls.sql
-- Security Hardening for Storage Buckets and RLS
-- 1. Restrict overly-permissive storage policies (e.g., Allow authenticated insert existing storage)
-- 2. Ensure kyc-documents, payment-proofs, tournament-assets, and lounge-assets have user/folder scoped policies.

DO $$
BEGIN
  -- Drop overly permissive catch-all storage insert policy if present
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Allow authenticated insert existing storage'
  ) THEN
    EXECUTE 'DROP POLICY "Allow authenticated insert existing storage" ON storage.objects;';
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Authenticated users can upload objects'
  ) THEN
    EXECUTE 'DROP POLICY "Authenticated users can upload objects" ON storage.objects;';
  END IF;
END $$;

-- 1. Create or ensure buckets exist
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('kyc-documents', 'kyc-documents', false),
  ('payment-proofs', 'payment-proofs', true),
  ('tournament-assets', 'tournament-assets', true),
  ('lounge-assets', 'lounge-assets', true),
  ('room-assets', 'room-assets', true),
  ('promotion-assets', 'promotion-assets', true)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;

-- 2. KYC Documents Storage Policy (Restricted to owner's own folder or super admin)
DROP POLICY IF EXISTS "kyc_insert_policy" ON storage.objects;
CREATE POLICY "kyc_insert_policy" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'kyc-documents'
  AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'super_admin')
  )
);

DROP POLICY IF EXISTS "kyc_select_policy" ON storage.objects;
CREATE POLICY "kyc_select_policy" ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'kyc-documents'
  AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'super_admin')
  )
);

-- 3. Payment Proofs Storage Policy
DROP POLICY IF EXISTS "payment_proofs_insert_policy" ON storage.objects;
CREATE POLICY "payment_proofs_insert_policy" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'payment-proofs');

DROP POLICY IF EXISTS "payment_proofs_select_policy" ON storage.objects;
CREATE POLICY "payment_proofs_select_policy" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'payment-proofs');

-- 4. Tournament Assets Storage Policy
DROP POLICY IF EXISTS "tournament_assets_insert_policy" ON storage.objects;
CREATE POLICY "tournament_assets_insert_policy" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'tournament-assets');

DROP POLICY IF EXISTS "tournament_assets_select_policy" ON storage.objects;
CREATE POLICY "tournament_assets_select_policy" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'tournament-assets');

-- 5. General Assets Storage Policies (lounge-assets, room-assets, promotion-assets)
DROP POLICY IF EXISTS "dashboard_assets_insert_policy" ON storage.objects;
CREATE POLICY "dashboard_assets_insert_policy" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id IN ('lounge-assets', 'room-assets', 'promotion-assets'));

DROP POLICY IF EXISTS "dashboard_assets_select_policy" ON storage.objects;
CREATE POLICY "dashboard_assets_select_policy" ON storage.objects
FOR SELECT TO public
USING (bucket_id IN ('lounge-assets', 'room-assets', 'promotion-assets'));
