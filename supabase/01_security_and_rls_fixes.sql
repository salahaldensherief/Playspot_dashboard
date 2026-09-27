-- =============================================================================
-- 01_security_and_rls_fixes.sql
-- Playspot Dashboard - Security & RLS Policies Hardening Migration
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Lock down spatial_ref_sys (PostGIS Table)
-- -----------------------------------------------------------------------------
DO $$
BEGIN
  ALTER TABLE IF EXISTS public.spatial_ref_sys ENABLE ROW LEVEL SECURITY;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipped spatial_ref_sys RLS alter due to owner privileges: %', SQLERRM;
END $$;

-- -----------------------------------------------------------------------------
-- 2. RLS Policies for Tables with RLS Enabled but No Policies
-- -----------------------------------------------------------------------------

-- A. Categories (Public Read, Super Admin Write)
ALTER TABLE IF EXISTS public.categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read categories" ON public.categories;
CREATE POLICY "Public read categories"
    ON public.categories FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Admin write categories" ON public.categories;
CREATE POLICY "Admin write categories"
    ON public.categories FOR ALL
    TO authenticated
    USING (public.is_super_admin())
    WITH CHECK (public.is_super_admin());

-- B. FAQs (Public Read, Super Admin Write)
ALTER TABLE IF EXISTS public.faqs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read faqs" ON public.faqs;
CREATE POLICY "Public read faqs"
    ON public.faqs FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Admin write faqs" ON public.faqs;
CREATE POLICY "Admin write faqs"
    ON public.faqs FOR ALL
    TO authenticated
    USING (public.is_super_admin())
    WITH CHECK (public.is_super_admin());

-- C. Legal Policies (Public Read, Super Admin Write)
ALTER TABLE IF EXISTS public.legal_policies ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read legal policies" ON public.legal_policies;
CREATE POLICY "Public read legal policies"
    ON public.legal_policies FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Admin write legal policies" ON public.legal_policies;
CREATE POLICY "Admin write legal policies"
    ON public.legal_policies FOR ALL
    TO authenticated
    USING (public.is_super_admin())
    WITH CHECK (public.is_super_admin());

-- D. Tournaments (Public Read, Admin/Lounge Owner Write)
ALTER TABLE IF EXISTS public.tournaments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read tournaments" ON public.tournaments;
CREATE POLICY "Public read tournaments"
    ON public.tournaments FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Admin write tournaments" ON public.tournaments;
CREATE POLICY "Admin write tournaments"
    ON public.tournaments FOR ALL
    TO authenticated
    USING (public.is_super_admin() OR public.is_lounge_admin(lounge_id))
    WITH CHECK (public.is_super_admin() OR public.is_lounge_admin(lounge_id));

-- E. Tournament Stations (Public Read, Admin Write)
ALTER TABLE IF EXISTS public.tournament_stations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read tournament stations" ON public.tournament_stations;
CREATE POLICY "Public read tournament stations"
    ON public.tournament_stations FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Admin write tournament stations" ON public.tournament_stations;
CREATE POLICY "Admin write tournament stations"
    ON public.tournament_stations FOR ALL
    TO authenticated
    USING (public.is_super_admin())
    WITH CHECK (public.is_super_admin());

-- F. Tournament Matches (Public Read, Admin Write)
ALTER TABLE IF EXISTS public.tournament_matches ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read tournament matches" ON public.tournament_matches;
CREATE POLICY "Public read tournament matches"
    ON public.tournament_matches FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Admin write tournament matches" ON public.tournament_matches;
CREATE POLICY "Admin write tournament matches"
    ON public.tournament_matches FOR ALL
    TO authenticated
    USING (public.is_super_admin())
    WITH CHECK (public.is_super_admin());

-- G. Tournament Payment Submissions (User Read Own, Super Admin All)
ALTER TABLE IF EXISTS public.tournament_payment_submissions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "User read own tournament submissions" ON public.tournament_payment_submissions;
CREATE POLICY "User read own tournament submissions"
    ON public.tournament_payment_submissions FOR SELECT
    TO authenticated
    USING (submitted_by = auth.uid() OR public.is_super_admin());

DROP POLICY IF EXISTS "User insert own tournament submission" ON public.tournament_payment_submissions;
CREATE POLICY "User insert own tournament submission"
    ON public.tournament_payment_submissions FOR INSERT
    TO authenticated
    WITH CHECK (submitted_by = auth.uid());

DROP POLICY IF EXISTS "Admin write tournament submissions" ON public.tournament_payment_submissions;
CREATE POLICY "Admin write tournament submissions"
    ON public.tournament_payment_submissions FOR ALL
    TO authenticated
    USING (public.is_super_admin())
    WITH CHECK (public.is_super_admin());

-- H. Tournament Audit Logs (Admin Only)
ALTER TABLE IF EXISTS public.tournament_audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin read tournament audit logs" ON public.tournament_audit_logs;
CREATE POLICY "Admin read tournament audit logs"
    ON public.tournament_audit_logs FOR SELECT
    TO authenticated
    USING (public.is_super_admin());

-- I. Payouts (Lounge Owner & Admin Access)
ALTER TABLE IF EXISTS public.payouts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lounge owner read own payouts" ON public.payouts;
CREATE POLICY "Lounge owner read own payouts"
    ON public.payouts FOR SELECT
    TO authenticated
    USING (
        public.is_super_admin() OR
        public.is_lounge_admin(lounge_id)
    );

DROP POLICY IF EXISTS "Admin write payouts" ON public.payouts;
CREATE POLICY "Admin write payouts"
    ON public.payouts FOR ALL
    TO authenticated
    USING (public.is_super_admin())
    WITH CHECK (public.is_super_admin());

-- J. Payout Audit Logs (Admin & Lounge Owner Read)
ALTER TABLE IF EXISTS public.payout_audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin read payout audit logs" ON public.payout_audit_logs;
CREATE POLICY "Admin read payout audit logs"
    ON public.payout_audit_logs FOR SELECT
    TO authenticated
    USING (
        public.is_super_admin() OR
        EXISTS (
            SELECT 1 FROM public.payouts p
            WHERE p.id = payout_audit_logs.payout_id
              AND public.is_lounge_admin(p.lounge_id)
        )
    );

-- K. Private Function Backups (Super Admin Only)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'private' AND table_name = 'function_backups') THEN
    ALTER TABLE private.function_backups ENABLE ROW LEVEL SECURITY;

    EXECUTE 'DROP POLICY IF EXISTS "Super admin access backups" ON private.function_backups';
    EXECUTE 'CREATE POLICY "Super admin access backups" ON private.function_backups FOR ALL TO authenticated USING (public.is_super_admin()) WITH CHECK (public.is_super_admin())';
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- 3. Fix search_path for Functions (Object Shadowing Defense)
-- -----------------------------------------------------------------------------

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'is_super_admin') THEN
        ALTER FUNCTION public.is_super_admin() SET search_path = public, auth, pg_temp;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'is_lounge_admin') THEN
        ALTER FUNCTION public.is_lounge_admin(UUID) SET search_path = public, auth, pg_temp;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'place_canteen_order') THEN
        ALTER FUNCTION public.place_canteen_order SET search_path = public, auth, pg_temp;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_dashboard_overview') THEN
        ALTER FUNCTION public.get_dashboard_overview SET search_path = public, auth, pg_temp;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_live_bookings_with_items') THEN
        ALTER FUNCTION public.get_live_bookings_with_items SET search_path = public, auth, pg_temp;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_pending_extension_requests') THEN
        ALTER FUNCTION public.get_pending_extension_requests SET search_path = public, auth, pg_temp;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_shift_report') THEN
        ALTER FUNCTION public.get_shift_report SET search_path = public, auth, pg_temp;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_lounge_owner_dashboard_stats') THEN
        ALTER FUNCTION public.get_lounge_owner_dashboard_stats SET search_path = public, auth, pg_temp;
    END IF;
END $$;
