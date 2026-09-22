-- =============================================================================
-- 07_linter_and_perf_fixes.sql
-- Resolution for Supabase Linter Warnings, Permissive Policies & Performance
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Lock down spatial_ref_sys API Access
-- -----------------------------------------------------------------------------
REVOKE ALL ON public.spatial_ref_sys FROM anon, authenticated, PUBLIC;
GRANT SELECT ON public.spatial_ref_sys TO postgres, service_role;

-- -----------------------------------------------------------------------------
-- 2. Systemic Function Permission Hardening (Revoke EXECUTE from anon)
-- -----------------------------------------------------------------------------
-- Revoke execution from PUBLIC and anon for ALL functions in public schema
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC, anon;

-- Re-grant EXECUTE ONLY on explicitly public content getters to anon & authenticated
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_public_faqs') THEN
    GRANT EXECUTE ON FUNCTION public.get_public_faqs TO anon, authenticated;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_public_policies') THEN
    GRANT EXECUTE ON FUNCTION public.get_public_policies TO anon, authenticated;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_public_support_settings') THEN
    GRANT EXECUTE ON FUNCTION public.get_public_support_settings TO anon, authenticated;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_home_tournament') THEN
    GRANT EXECUTE ON FUNCTION public.get_home_tournament TO anon, authenticated;
  END IF;
END $$;

-- Re-grant EXECUTE on application RPCs ONLY to authenticated role
GRANT EXECUTE ON FUNCTION public.place_canteen_order TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_lounge_owner_dashboard_stats TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_dashboard_overview TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_live_bookings_with_items TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_pending_extension_requests TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_active_lounge_requests_page TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_super_admin TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_lounge_admin TO authenticated;
GRANT EXECUTE ON FUNCTION public.handle_no_show_paid_bookings TO authenticated;


-- -----------------------------------------------------------------------------
-- 3. Foreign Key Indexing (public.rooms.space_type_id)
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_rooms_space_type_id ON public.rooms(space_type_id);


-- -----------------------------------------------------------------------------
-- 4. Consolidate Multiple Permissive Policies into Single Unified Policies
-- -----------------------------------------------------------------------------

-- A. Categories Unified Policy
DROP POLICY IF EXISTS "Public read categories" ON public.categories;
DROP POLICY IF EXISTS "Admin write categories" ON public.categories;

CREATE POLICY "categories_unified_policy"
    ON public.categories FOR ALL
    TO authenticated, anon
    USING (true)
    WITH CHECK (public.is_super_admin());

-- B. FAQs Unified Policy
DROP POLICY IF EXISTS "Public read faqs" ON public.faqs;
DROP POLICY IF EXISTS "Admin write faqs" ON public.faqs;

CREATE POLICY "faqs_unified_policy"
    ON public.faqs FOR ALL
    TO authenticated, anon
    USING (true)
    WITH CHECK (public.is_super_admin());

-- C. Legal Policies Unified Policy
DROP POLICY IF EXISTS "Public read legal policies" ON public.legal_policies;
DROP POLICY IF EXISTS "Admin write legal policies" ON public.legal_policies;

CREATE POLICY "legal_policies_unified_policy"
    ON public.legal_policies FOR ALL
    TO authenticated, anon
    USING (true)
    WITH CHECK (public.is_super_admin());

-- D. Tournaments Unified Policy
DROP POLICY IF EXISTS "Public read tournaments" ON public.tournaments;
DROP POLICY IF EXISTS "Admin write tournaments" ON public.tournaments;

CREATE POLICY "tournaments_unified_policy"
    ON public.tournaments FOR ALL
    TO authenticated, anon
    USING (true)
    WITH CHECK (public.is_super_admin() OR public.is_lounge_admin(lounge_id));

-- E. Tournament Stations Unified Policy
DROP POLICY IF EXISTS "Public read tournament stations" ON public.tournament_stations;
DROP POLICY IF EXISTS "Admin write tournament stations" ON public.tournament_stations;

CREATE POLICY "tournament_stations_unified_policy"
    ON public.tournament_stations FOR ALL
    TO authenticated, anon
    USING (true)
    WITH CHECK (public.is_super_admin());

-- F. Tournament Matches Unified Policy
DROP POLICY IF EXISTS "Public read tournament matches" ON public.tournament_matches;
DROP POLICY IF EXISTS "Admin write tournament matches" ON public.tournament_matches;

CREATE POLICY "tournament_matches_unified_policy"
    ON public.tournament_matches FOR ALL
    TO authenticated, anon
    USING (true)
    WITH CHECK (public.is_super_admin());

-- G. Tournament Payment Submissions Unified Policy (Optimized auth.uid())
DROP POLICY IF EXISTS "User read own tournament submissions" ON public.tournament_payment_submissions;
DROP POLICY IF EXISTS "User insert own tournament submission" ON public.tournament_payment_submissions;
DROP POLICY IF EXISTS "Admin write tournament submissions" ON public.tournament_payment_submissions;

CREATE POLICY "tournament_submissions_unified_policy"
    ON public.tournament_payment_submissions FOR ALL
    TO authenticated
    USING (submitted_by = (SELECT auth.uid()) OR public.is_super_admin())
    WITH CHECK (submitted_by = (SELECT auth.uid()) OR public.is_super_admin());

-- H. Payouts Unified Policy
DROP POLICY IF EXISTS "Lounge owner read own payouts" ON public.payouts;
DROP POLICY IF EXISTS "Admin write payouts" ON public.payouts;

CREATE POLICY "payouts_unified_policy"
    ON public.payouts FOR ALL
    TO authenticated
    USING (public.is_super_admin() OR public.is_lounge_admin(lounge_id))
    WITH CHECK (public.is_super_admin());

-- I. Payout Audit Logs Unified Policy
DROP POLICY IF EXISTS "Admin read payout audit logs" ON public.payout_audit_logs;

CREATE POLICY "payout_audit_logs_unified_policy"
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
