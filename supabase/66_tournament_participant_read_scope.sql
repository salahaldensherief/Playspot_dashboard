BEGIN;

DROP POLICY IF EXISTS tournament_participants_select_scope
ON public.tournament_participants;

CREATE POLICY tournament_participants_select_scope
ON public.tournament_participants
FOR SELECT
TO authenticated
USING (
  user_id = (select auth.uid())
  OR public.is_super_admin()
  OR EXISTS (
    SELECT 1
    FROM public.tournaments t
    WHERE t.id = tournament_participants.tournament_id
      AND public.is_lounge_member_or_admin(t.lounge_id)
  )
);

COMMIT;
