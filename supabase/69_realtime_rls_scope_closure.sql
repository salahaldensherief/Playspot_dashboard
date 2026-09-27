BEGIN;

DROP POLICY IF EXISTS "Staff can view canteen orders" ON public.canteen_orders;
DROP POLICY IF EXISTS "Staff can update canteen orders" ON public.canteen_orders;

DROP POLICY IF EXISTS "Staff can view canteen order items" ON public.canteen_order_items;
DROP POLICY IF EXISTS "canteen_order_items_select_scoped" ON public.canteen_order_items;
CREATE POLICY "canteen_order_items_select_scoped"
ON public.canteen_order_items
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.canteen_orders co
    WHERE co.id = canteen_order_items.order_id
      AND (
        co.user_id = (select auth.uid())
        OR public.is_super_admin()
        OR public.is_lounge_member_or_admin(co.lounge_id)
      )
  )
);

DROP POLICY IF EXISTS "service_calls_policy" ON public.service_calls;
DROP POLICY IF EXISTS "Staff can view service calls" ON public.service_calls;
DROP POLICY IF EXISTS "Staff can update service calls" ON public.service_calls;

DROP POLICY IF EXISTS "service_calls_select_scoped" ON public.service_calls;
CREATE POLICY "service_calls_select_scoped"
ON public.service_calls
FOR SELECT TO authenticated
USING (
  user_id = (select auth.uid())
  OR public.is_super_admin()
  OR (
    lounge_id IS NOT NULL
    AND public.is_lounge_member_or_admin(lounge_id)
  )
);

COMMIT;
