-- =============================================================================
-- 22_policy_cleanup_and_function_hardening.sql
-- Cleanup duplicate policies & harden is_lounge_member_or_admin for null & inactive
-- Playspot Dashboard - 2026
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. CLEANUP DUPLICATE POLICIES
-- -----------------------------------------------------------------------------

-- Lounges table cleanup
DROP POLICY IF EXISTS "lounges_delete_owner_or_admin" ON public.lounges;
DROP POLICY IF EXISTS "lounges_insert_owner_or_admin" ON public.lounges;
DROP POLICY IF EXISTS "lounges_update_scoped" ON public.lounges;

-- Payouts table cleanup
DROP POLICY IF EXISTS "payouts_read_policy" ON public.payouts;

-- Tournaments table cleanup
DROP POLICY IF EXISTS "tournaments_read_policy" ON public.tournaments;


-- -----------------------------------------------------------------------------
-- 2. HARDEN is_lounge_member_or_admin WITH NULL CHECK & IS_ACTIVE CHECK
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_lounge_member_or_admin(p_lounge_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
BEGIN
  IF auth.uid() IS NULL OR p_lounge_id IS NULL THEN
    RETURN FALSE;
  END IF;

  RETURN public.is_super_admin()
    OR EXISTS (
        SELECT 1 FROM public.lounges
        WHERE id = p_lounge_id AND owner_id = auth.uid()
    )
    OR EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND lounge_id = p_lounge_id AND COALESCE(is_active, true) = true
    )
    OR EXISTS (
        SELECT 1 FROM public.lounge_staff ls
        JOIN public.profiles p ON p.id = ls.user_id
        WHERE ls.lounge_id = p_lounge_id AND ls.user_id = auth.uid() AND COALESCE(p.is_active, true) = true
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.is_lounge_member_or_admin TO authenticated;
