-- =============================================================================
-- 23_harden_delete_policies.sql
-- Restrict DELETE on rooms, extras, and shifts to Lounge Admins & Super Admins
-- Playspot Dashboard - 2026
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. EXTRAS (Canteen Menu Items)
-- -----------------------------------------------------------------------------
ALTER TABLE public.extras ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "extras_manage_scoped" ON public.extras;
DROP POLICY IF EXISTS "extras_staff_write_policy" ON public.extras;
DROP POLICY IF EXISTS "extras_admin_delete_policy" ON public.extras;

-- Staff/Cashier can SELECT, INSERT, UPDATE canteen items and stock
CREATE POLICY "extras_staff_write_policy"
ON public.extras FOR INSERT
TO authenticated
WITH CHECK (public._playspot_has_lounge_access(lounge_id));

CREATE POLICY "extras_staff_update_policy"
ON public.extras FOR UPDATE
TO authenticated
USING (public._playspot_has_lounge_access(lounge_id))
WITH CHECK (public._playspot_has_lounge_access(lounge_id));

-- Only Lounge Admins (Owners/Managers) or Super Admins can DELETE menu extras
CREATE POLICY "extras_admin_delete_policy"
ON public.extras FOR DELETE
TO authenticated
USING (public.is_super_admin() OR public.is_lounge_admin(lounge_id));


-- -----------------------------------------------------------------------------
-- 2. ROOMS (Playstation & Gaming Stations)
-- -----------------------------------------------------------------------------
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "rooms_manage_scoped" ON public.rooms;
DROP POLICY IF EXISTS "rooms_write_policy" ON public.rooms;
DROP POLICY IF EXISTS "rooms_select_policy" ON public.rooms;
DROP POLICY IF EXISTS "rooms_staff_insert_policy" ON public.rooms;
DROP POLICY IF EXISTS "rooms_staff_update_policy" ON public.rooms;
DROP POLICY IF EXISTS "rooms_admin_delete_policy" ON public.rooms;

CREATE POLICY "rooms_staff_insert_policy"
ON public.rooms FOR INSERT
TO authenticated
WITH CHECK (public._playspot_has_lounge_access(lounge_id));

CREATE POLICY "rooms_staff_update_policy"
ON public.rooms FOR UPDATE
TO authenticated
USING (public._playspot_has_lounge_access(lounge_id))
WITH CHECK (public._playspot_has_lounge_access(lounge_id));

-- Only Lounge Admins (Owners/Managers) or Super Admins can DELETE room records
CREATE POLICY "rooms_admin_delete_policy"
ON public.rooms FOR DELETE
TO authenticated
USING (public.is_super_admin() OR public.is_lounge_admin(lounge_id));


-- -----------------------------------------------------------------------------
-- 3. SHIFTS (Cash Register Shift History)
-- -----------------------------------------------------------------------------
ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "shifts_branch_scoped" ON public.shifts;
DROP POLICY IF EXISTS "shifts_policy" ON public.shifts;
DROP POLICY IF EXISTS "shifts_staff_insert_policy" ON public.shifts;
DROP POLICY IF EXISTS "shifts_staff_update_policy" ON public.shifts;
DROP POLICY IF EXISTS "shifts_admin_delete_policy" ON public.shifts;

CREATE POLICY "shifts_staff_insert_policy"
ON public.shifts FOR INSERT
TO authenticated
WITH CHECK (public._playspot_has_lounge_access(lounge_id));

CREATE POLICY "shifts_staff_update_policy"
ON public.shifts FOR UPDATE
TO authenticated
USING (public._playspot_has_lounge_access(lounge_id))
WITH CHECK (public._playspot_has_lounge_access(lounge_id));

-- Only Lounge Admins (Owners/Managers) or Super Admins can DELETE shift audit records
CREATE POLICY "shifts_admin_delete_policy"
ON public.shifts FOR DELETE
TO authenticated
USING (public.is_super_admin() OR public.is_lounge_admin(lounge_id));
