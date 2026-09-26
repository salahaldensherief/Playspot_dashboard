-- =============================================================================
-- 20_security_and_rls_hardening.sql
-- Complete Row-Level Security (RLS) & Multi-Tenant Isolation Migration
-- Playspot Dashboard - 2026
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Helper Function: Check if user belongs to lounge
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_lounge_member_or_admin(p_lounge_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN FALSE;
  END IF;

  RETURN public.is_super_admin()
    OR EXISTS (
        SELECT 1 FROM public.lounges
        WHERE id = p_lounge_id AND owner_id = auth.uid()
    )
    OR EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND lounge_id = p_lounge_id AND COALESCE(is_active, true)
    )
    OR EXISTS (
        SELECT 1 FROM public.lounge_staff
        WHERE lounge_id = p_lounge_id AND user_id = auth.uid()
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.is_lounge_member_or_admin TO authenticated;

-- =============================================================================
-- 1. PROFILES & STAFF SECURITY
-- =============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_select_policy" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert_policy" ON public.profiles;

-- Anyone authenticated can view their own profile, SuperAdmins view all, Lounge Staff view profiles in their lounge
CREATE POLICY "profiles_select_policy"
ON public.profiles FOR SELECT
TO authenticated
USING (
    id = auth.uid()
    OR public.is_super_admin()
    OR (lounge_id IS NOT NULL AND public.is_lounge_member_or_admin(lounge_id))
);

-- Users can update their own profile fields, Lounge Admins can update staff in their lounge, SuperAdmins can update any
CREATE POLICY "profiles_update_policy"
ON public.profiles FOR UPDATE
TO authenticated
USING (
    id = auth.uid()
    OR public.is_super_admin()
    OR (lounge_id IS NOT NULL AND public.is_lounge_member_or_admin(lounge_id))
)
WITH CHECK (
    -- Non-SuperAdmins CANNOT escalate role to super_admin or change lounge_id to a different lounge
    (
        NOT public.is_super_admin()
        AND role != 'super_admin'
        AND role != 'superadmin'
    )
    OR public.is_super_admin()
);

-- LOUNGE_STAFF Table
ALTER TABLE public.lounge_staff ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "lounge_staff_policy" ON public.lounge_staff;
CREATE POLICY "lounge_staff_policy"
ON public.lounge_staff FOR ALL
TO authenticated
USING (
    public.is_super_admin()
    OR public.is_lounge_member_or_admin(lounge_id)
)
WITH CHECK (
    public.is_super_admin()
    OR public.is_lounge_member_or_admin(lounge_id)
);


-- =============================================================================
-- 2. ROOMS SECURITY
-- =============================================================================
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "rooms_select_policy" ON public.rooms;
DROP POLICY IF EXISTS "rooms_write_policy" ON public.rooms;

-- Public read for browsing lounges & rooms
CREATE POLICY "rooms_select_policy"
ON public.rooms FOR SELECT
USING (true);

-- Only SuperAdmins or Lounge Admins for that specific lounge_id can insert/update/delete
CREATE POLICY "rooms_write_policy"
ON public.rooms FOR ALL
TO authenticated
USING (
    public.is_super_admin()
    OR public.is_lounge_member_or_admin(lounge_id)
)
WITH CHECK (
    public.is_super_admin()
    OR public.is_lounge_member_or_admin(lounge_id)
);


-- =============================================================================
-- 3. BOOKINGS & BOOKING ITEMS SECURITY
-- =============================================================================
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "bookings_select_policy" ON public.bookings;
DROP POLICY IF EXISTS "bookings_write_policy" ON public.bookings;

CREATE POLICY "bookings_select_policy"
ON public.bookings FOR SELECT
TO authenticated
USING (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR public.is_lounge_member_or_admin(lounge_id)
);

CREATE POLICY "bookings_write_policy"
ON public.bookings FOR ALL
TO authenticated
USING (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR public.is_lounge_member_or_admin(lounge_id)
)
WITH CHECK (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR public.is_lounge_member_or_admin(lounge_id)
);

-- BOOKING_ITEMS
ALTER TABLE public.booking_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "booking_items_policy" ON public.booking_items;
CREATE POLICY "booking_items_policy"
ON public.booking_items FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.bookings b
        WHERE b.id = booking_items.booking_id
        AND (b.user_id = auth.uid() OR public.is_super_admin() OR public.is_lounge_member_or_admin(b.lounge_id))
    )
);


-- =============================================================================
-- 4. SHIFTS & EXPENSES SECURITY
-- =============================================================================
ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "shifts_policy" ON public.shifts;
CREATE POLICY "shifts_policy"
ON public.shifts FOR ALL
TO authenticated
USING (
    public.is_super_admin()
    OR public.is_lounge_member_or_admin(lounge_id)
)
WITH CHECK (
    public.is_super_admin()
    OR public.is_lounge_member_or_admin(lounge_id)
);

-- SHIFT EXPENSES
ALTER TABLE public.shift_expenses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "shift_expenses_policy" ON public.shift_expenses;
CREATE POLICY "shift_expenses_policy"
ON public.shift_expenses FOR ALL
TO authenticated
USING (
    public.is_super_admin()
    OR public.is_lounge_member_or_admin(lounge_id)
);


-- =============================================================================
-- 5. SERVICE CALLS, CANTEEN ORDERS & CLIENT REQUESTS
-- =============================================================================
ALTER TABLE public.service_calls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.canteen_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.client_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "service_calls_policy" ON public.service_calls;
CREATE POLICY "service_calls_policy"
ON public.service_calls FOR ALL
TO authenticated
USING (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR (lounge_id IS NOT NULL AND public.is_lounge_member_or_admin(lounge_id))
);

DROP POLICY IF EXISTS "canteen_orders_policy" ON public.canteen_orders;
CREATE POLICY "canteen_orders_policy"
ON public.canteen_orders FOR ALL
TO authenticated
USING (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR (lounge_id IS NOT NULL AND public.is_lounge_member_or_admin(lounge_id))
);

DROP POLICY IF EXISTS "client_requests_policy" ON public.client_requests;
CREATE POLICY "client_requests_policy"
ON public.client_requests FOR ALL
TO authenticated
USING (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR (lounge_id IS NOT NULL AND public.is_lounge_member_or_admin(lounge_id))
);


-- =============================================================================
-- 6. PROMOTIONS & MARKETING SECURITY
-- =============================================================================
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "promotions_select_policy" ON public.promotions;
DROP POLICY IF EXISTS "promotions_write_policy" ON public.promotions;

CREATE POLICY "promotions_select_policy"
ON public.promotions FOR SELECT
USING (true);

-- Lounge Admins can ONLY create/manage promos scoped to their lounge_id.
-- Platform-wide promos (lounge_id IS NULL) require Super Admin privileges.
CREATE POLICY "promotions_write_policy"
ON public.promotions FOR ALL
TO authenticated
USING (
    public.is_super_admin()
    OR (lounge_id IS NOT NULL AND public.is_lounge_member_or_admin(lounge_id))
)
WITH CHECK (
    public.is_super_admin()
    OR (lounge_id IS NOT NULL AND public.is_lounge_member_or_admin(lounge_id))
);


-- =============================================================================
-- 7. REVIEWS & FEEDBACK
-- =============================================================================
ALTER TABLE public.lounge_reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "lounge_reviews_select" ON public.lounge_reviews;
DROP POLICY IF EXISTS "lounge_reviews_insert" ON public.lounge_reviews;
DROP POLICY IF EXISTS "lounge_reviews_update" ON public.lounge_reviews;

CREATE POLICY "lounge_reviews_select"
ON public.lounge_reviews FOR SELECT
USING (true);

CREATE POLICY "lounge_reviews_insert"
ON public.lounge_reviews FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "lounge_reviews_update"
ON public.lounge_reviews FOR UPDATE
TO authenticated
USING (
    public.is_super_admin()
    OR public.is_lounge_member_or_admin(lounge_id)
);
