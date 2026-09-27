BEGIN;

CREATE OR REPLACE FUNCTION public.create_system_announcement(
  p_id uuid,
  p_target_audience text,
  p_target_lounge_id uuid,
  p_title_ar text,
  p_title_en text,
  p_body_ar text,
  p_body_en text,
  p_type text DEFAULT 'info'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_id uuid := COALESCE(p_id, gen_random_uuid());
  v_db_audience public.announcement_target_audience;
  v_db_type public.announcement_type;
  v_count integer := 0;
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'not_authorized' USING ERRCODE = '42501';
  END IF;

  v_db_audience := CASE lower(btrim(COALESCE(p_target_audience, 'all')))
    WHEN 'all' THEN 'all'::public.announcement_target_audience
    WHEN 'owners' THEN 'owners'::public.announcement_target_audience
    WHEN 'lounge_owners' THEN 'owners'::public.announcement_target_audience
    WHEN 'specific_venue' THEN 'specific_venue'::public.announcement_target_audience
    WHEN 'specific_lounge' THEN 'specific_venue'::public.announcement_target_audience
    ELSE NULL
  END;

  IF v_db_audience IS NULL THEN
    RAISE EXCEPTION 'invalid_target_audience' USING ERRCODE = '22023';
  END IF;

  v_db_type := CASE lower(btrim(COALESCE(p_type, 'info')))
    WHEN 'info' THEN 'info'::public.announcement_type
    WHEN 'warning' THEN 'warning'::public.announcement_type
    WHEN 'update' THEN 'update'::public.announcement_type
    ELSE NULL
  END;

  IF v_db_type IS NULL THEN
    RAISE EXCEPTION 'invalid_announcement_type' USING ERRCODE = '22023';
  END IF;

  IF v_db_audience = 'specific_venue'::public.announcement_target_audience
     AND (
       p_target_lounge_id IS NULL
       OR NOT EXISTS (
         SELECT 1 FROM public.lounges l
         WHERE l.id = p_target_lounge_id
       )
     ) THEN
    RAISE EXCEPTION 'target_lounge_required' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.announcements (
    id,
    title_ar,
    title_en,
    body_ar,
    body_en,
    target_audience,
    target_venue_id,
    type,
    is_active,
    start_at,
    created_by,
    created_at
  )
  VALUES (
    v_id,
    btrim(p_title_ar),
    btrim(p_title_en),
    btrim(p_body_ar),
    btrim(p_body_en),
    v_db_audience,
    CASE
      WHEN v_db_audience = 'specific_venue'::public.announcement_target_audience
      THEN p_target_lounge_id
      ELSE NULL
    END,
    v_db_type,
    true,
    now(),
    auth.uid(),
    now()
  );

  WITH recipients AS (
    SELECT p.id AS user_id
    FROM public.profiles p
    WHERE v_db_audience = 'all'::public.announcement_target_audience
      AND COALESCE(p.is_active, true)

    UNION

    SELECT l.owner_id
    FROM public.lounges l
    JOIN public.profiles p ON p.id = l.owner_id
    WHERE v_db_audience = 'owners'::public.announcement_target_audience
      AND l.owner_id IS NOT NULL
      AND COALESCE(p.is_active, true)

    UNION

    SELECT l.owner_id
    FROM public.lounges l
    JOIN public.profiles p ON p.id = l.owner_id
    WHERE v_db_audience = 'specific_venue'::public.announcement_target_audience
      AND l.id = p_target_lounge_id
      AND l.owner_id IS NOT NULL
      AND COALESCE(p.is_active, true)

    UNION

    SELECT ls.user_id
    FROM public.lounge_staff ls
    JOIN public.profiles p ON p.id = ls.user_id
    WHERE v_db_audience = 'specific_venue'::public.announcement_target_audience
      AND ls.lounge_id = p_target_lounge_id
      AND COALESCE(p.is_active, true)

    UNION

    SELECT p.id
    FROM public.profiles p
    WHERE v_db_audience = 'specific_venue'::public.announcement_target_audience
      AND p.lounge_id = p_target_lounge_id
      AND COALESCE(p.is_active, true)
  ),
  inserted AS (
    INSERT INTO public.notifications (
      user_id,
      lounge_id,
      title_ar,
      title_en,
      body_ar,
      body_en,
      type,
      is_read,
      metadata,
      created_at
    )
    SELECT
      r.user_id,
      CASE
        WHEN v_db_audience = 'specific_venue'::public.announcement_target_audience
        THEN p_target_lounge_id
        ELSE NULL
      END,
      btrim(p_title_ar),
      btrim(p_title_en),
      btrim(p_body_ar),
      btrim(p_body_en),
      'system',
      false,
      jsonb_build_object(
        'announcement_id', v_id,
        'announcement_type', v_db_type::text,
        'target_audience', v_db_audience::text,
        'lounge_id', p_target_lounge_id
      ),
      now()
    FROM recipients r
    WHERE r.user_id IS NOT NULL
    RETURNING id
  )
  SELECT count(*) INTO v_count FROM inserted;

  RETURN jsonb_build_object(
    'success', true,
    'announcement_id', v_id,
    'notifications_created', v_count
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.create_system_announcement(
  uuid, text, uuid, text, text, text, text, text
) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.create_system_announcement(
  uuid, text, uuid, text, text, text, text, text
) TO authenticated, service_role, supabase_auth_admin;

COMMIT;
