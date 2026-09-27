-- 43_add_shifts_select_rls_policy.sql
-- Fixes: Adds missing SELECT RLS policy for public.shifts table so authenticated lounge staff and cashiers can read active shifts.

DROP POLICY IF EXISTS "shifts_authenticated_select_scoped" ON public.shifts;
CREATE POLICY "shifts_authenticated_select_scoped" ON public.shifts
  FOR SELECT
  TO authenticated
  USING (_playspot_has_lounge_access(lounge_id) OR is_super_admin() OR private.can_operate_playspot_lounge(lounge_id));
