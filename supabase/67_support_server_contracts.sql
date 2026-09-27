BEGIN;

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

DROP POLICY IF EXISTS support_tickets_update_super_admin
ON public.support_tickets;

CREATE POLICY support_tickets_update_super_admin
ON public.support_tickets
FOR UPDATE
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

DROP POLICY IF EXISTS support_settings_write_super_admin
ON public.support_settings;

CREATE POLICY support_settings_write_super_admin
ON public.support_settings
FOR ALL
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

COMMIT;
