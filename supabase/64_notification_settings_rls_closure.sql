BEGIN;

ALTER POLICY "Users can insert own notification settings"
ON public.notification_settings
TO authenticated
WITH CHECK ((select auth.uid()) = user_id);

ALTER POLICY "Users can update own notification settings"
ON public.notification_settings
TO authenticated
USING ((select auth.uid()) = user_id)
WITH CHECK ((select auth.uid()) = user_id);

ALTER POLICY "Users can view own notification settings"
ON public.notification_settings
TO authenticated
USING ((select auth.uid()) = user_id);

COMMIT;
