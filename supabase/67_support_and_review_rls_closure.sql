BEGIN;

DROP POLICY IF EXISTS "Users can create their own support tickets"
ON public.support_tickets;

DROP POLICY IF EXISTS support_tickets_select_scope
ON public.support_tickets;

CREATE POLICY support_tickets_select_scope
ON public.support_tickets
FOR SELECT
TO authenticated
USING (
  user_id = (select auth.uid())
  OR public.is_super_admin()
);

DROP POLICY IF EXISTS "Users can insert review"
ON public.lounge_reviews;

DROP POLICY IF EXISTS lounge_reviews_insert
ON public.lounge_reviews;

DROP POLICY IF EXISTS lounge_reviews_update
ON public.lounge_reviews;

COMMIT;
