BEGIN;

CREATE OR REPLACE FUNCTION public.deactivate_system_announcement(
  p_announcement_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE='42501';
  END IF;

  UPDATE public.announcements
  SET is_active = false
  WHERE id = p_announcement_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Announcement not found' USING ERRCODE='P0002';
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'announcement_id', p_announcement_id
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.deactivate_system_announcement(uuid)
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.deactivate_system_announcement(uuid)
TO authenticated, service_role;

COMMIT;
