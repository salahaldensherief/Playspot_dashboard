-- Migration 14: Fix Bookings Insert RLS Policy & Lounge Member Check
-- Date: 2026-09-23

CREATE OR REPLACE FUNCTION private.is_lounge_member(p_lounge_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT auth.uid() IS NOT NULL
    AND p_lounge_id IS NOT NULL
    AND (
      EXISTS (
        SELECT 1 FROM public.lounges AS l
        WHERE l.id = p_lounge_id AND l.owner_id = auth.uid()
      )
      OR EXISTS (
        SELECT 1 FROM public.profiles AS p
        WHERE p.id = auth.uid()
          AND (p.lounge_id = p_lounge_id OR p.role = 'super_admin')
          AND COALESCE(p.is_active, true)
          AND p.role IN ('owner','lounge_owner','lounge_admin','admin','manager','cashier','staff','super_admin')
      )
      OR EXISTS (
        SELECT 1
        FROM public.lounge_staff AS ls
        JOIN public.profiles AS p ON p.id = ls.user_id
        WHERE ls.user_id = auth.uid()
          AND ls.lounge_id = p_lounge_id
          AND COALESCE(p.is_active, true)
      )
    );
$$;

DROP POLICY IF EXISTS bookings_insert_owner ON public.bookings;
DROP POLICY IF EXISTS bookings_insert_scoped ON public.bookings;

CREATE POLICY bookings_insert_scoped ON public.bookings
FOR INSERT WITH CHECK (
  lounge_id IS NOT NULL
  AND (
    user_id = auth.uid()
    OR private.is_lounge_member(lounge_id)
    OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'super_admin')
  )
);
