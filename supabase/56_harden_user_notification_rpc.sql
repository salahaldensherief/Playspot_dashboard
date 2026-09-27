BEGIN;

CREATE OR REPLACE FUNCTION public.send_user_notification(
  p_user_id uuid,
  p_title_ar text,
  p_title_en text,
  p_body_ar text,
  p_body_en text,
  p_type text,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_notification_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
  END IF;

  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'Target user is required' USING ERRCODE = '22023';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles AS p WHERE p.id = p_user_id
  ) THEN
    RAISE EXCEPTION 'Target user not found' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.notifications (
    user_id,
    title_ar,
    title_en,
    body_ar,
    body_en,
    type,
    is_read,
    metadata
  )
  VALUES (
    p_user_id,
    p_title_ar,
    p_title_en,
    p_body_ar,
    p_body_en,
    p_type,
    false,
    COALESCE(p_metadata, '{}'::jsonb)
  )
  RETURNING id INTO v_notification_id;

  RETURN v_notification_id;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.send_user_notification(
  uuid, text, text, text, text, text, jsonb
) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.send_user_notification(
  uuid, text, text, text, text, text, jsonb
) TO authenticated, service_role, supabase_auth_admin;

COMMIT;
