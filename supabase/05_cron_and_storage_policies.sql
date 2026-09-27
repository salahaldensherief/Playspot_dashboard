-- =============================================================================
-- 05_cron_and_storage_policies.sql
-- Storage Buckets RLS Hardening & Automated Maintenance Jobs (pg_cron)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Storage Buckets Policy Hardening
-- -----------------------------------------------------------------------------

-- Drop overly broad public SELECT policy if it exists
DROP POLICY IF EXISTS "Allow public select existing storage" ON storage.objects;
DROP POLICY IF EXISTS "Public select for public buckets" ON storage.objects;

-- Create dynamic SELECT policy for ALL public buckets
CREATE POLICY "Public select for public buckets"
    ON storage.objects FOR SELECT
    USING (
        bucket_id IN (
            SELECT id FROM storage.buckets WHERE public = true
        )
    );

-- Secure SELECT policy for Receipts Bucket (Lounge Owners, Booking User, Super Admin)
DROP POLICY IF EXISTS "Authorized view for receipts" ON storage.objects;
CREATE POLICY "Authorized view for receipts"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'receipts' AND (
            public.is_super_admin() OR
            owner = auth.uid() OR
            (storage.foldername(name))[1] = auth.uid()::text OR
            EXISTS (
                SELECT 1 FROM public.payouts p
                WHERE public.is_lounge_admin(p.lounge_id)
            )
        )
    );

-- Secure SELECT policy for KYC Documents (Owner & Super Admin Only)
DROP POLICY IF EXISTS "Authorized view for kyc documents" ON storage.objects;
CREATE POLICY "Authorized view for kyc documents"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'kyc-documents' AND (
            public.is_super_admin() OR
            owner = auth.uid() OR
            (storage.foldername(name))[1] = auth.uid()::text
        )
    );

-- Secure SELECT policy for Tournament Receipts & Proofs
DROP POLICY IF EXISTS "Authorized view for tournament receipts" ON storage.objects;
CREATE POLICY "Authorized view for tournament receipts"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        (bucket_id IN ('tournament-receipts', 'tournament-result-proofs')) AND (
            public.is_super_admin() OR
            owner = auth.uid() OR
            (storage.foldername(name))[1] = auth.uid()::text
        )
    );


-- -----------------------------------------------------------------------------
-- 2. Automated Scheduled Maintenance (pg_cron)
-- -----------------------------------------------------------------------------

DO $outer$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    -- 1. Cron Job: Clean notifications older than 60 days
    BEGIN
      PERFORM cron.unschedule('clean-old-notifications');
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

    PERFORM cron.schedule(
      'clean-old-notifications',
      '0 3 * * *',
      $cmd$ DELETE FROM public.notifications WHERE created_at < NOW() - INTERVAL '60 days'; $cmd$
    );

    -- 2. Cron Job: Auto-cancel stale pending bookings older than 24 hours
    BEGIN
      PERFORM cron.unschedule('clean-stale-pending-bookings');
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

    PERFORM cron.schedule(
      'clean-stale-pending-bookings',
      '0 4 * * *',
      $cmd$ UPDATE public.bookings SET status = 'cancelled', cancellation_reason = 'Auto-cancelled due to expiry' WHERE status = 'pending' AND created_at < NOW() - INTERVAL '24 hours'; $cmd$
    );
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipped pg_cron job scheduling: %', SQLERRM;
END $outer$;
