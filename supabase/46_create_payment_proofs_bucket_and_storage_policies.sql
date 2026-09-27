-- 46_create_payment_proofs_bucket_and_storage_policies.sql
-- Fixes missing storage bucket and policies for manual transfer payment receipts (Vodafone Cash / InstaPay).

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('payment-proofs', 'payment-proofs', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
ON CONFLICT (id) DO UPDATE SET public = false;

DROP POLICY IF EXISTS "payment_proofs_authenticated_select" ON storage.objects;
CREATE POLICY "payment_proofs_authenticated_select" ON storage.objects
  FOR SELECT TO authenticated USING (bucket_id IN ('receipts', 'payment-proofs'));

DROP POLICY IF EXISTS "payment_proofs_authenticated_insert" ON storage.objects;
CREATE POLICY "payment_proofs_authenticated_insert" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id IN ('receipts', 'payment-proofs'));
