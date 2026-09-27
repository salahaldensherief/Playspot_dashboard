BEGIN;

DROP FUNCTION IF EXISTS public.update_role_permission(
  uuid, text, text, boolean
);

DROP FUNCTION IF EXISTS public.update_role_permission(
  text, text, boolean, uuid
);

CREATE OR REPLACE FUNCTION public.update_role_permission(
  p_role text,
  p_permission_key text,
  p_is_enabled boolean,
  p_lounge_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_role text := lower(btrim(p_role));
  v_permission_key text := btrim(p_permission_key);
  v_actor_role text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  IF v_role NOT IN ('owner', 'manager', 'cashier', 'staff', 'super_admin') THEN
    RAISE EXCEPTION 'Unsupported permission role' USING ERRCODE = '22023';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.app_permissions AS a
    WHERE a.key = v_permission_key
  ) THEN
    RAISE EXCEPTION 'Unknown permission key' USING ERRCODE = '22023';
  END IF;

  IF p_lounge_id IS NULL THEN
    IF NOT public.is_super_admin() THEN
      RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
    END IF;

    UPDATE public.role_permissions
    SET is_enabled = p_is_enabled,
        updated_at = now()
    WHERE role = v_role
      AND permission_key = v_permission_key;

    RETURN jsonb_build_object(
      'success', true,
      'scope', 'global',
      'role', v_role,
      'permission_key', v_permission_key,
      'is_enabled', p_is_enabled
    );
  END IF;

  v_actor_role := private.permission_role(auth.uid(), p_lounge_id);

  IF v_actor_role IS NULL OR v_actor_role NOT IN ('super_admin', 'owner', 'manager') THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
  END IF;

  INSERT INTO public.lounge_role_permissions (
    lounge_id,
    role,
    permission_key,
    is_enabled,
    updated_at
  )
  VALUES (
    p_lounge_id,
    v_role,
    v_permission_key,
    p_is_enabled,
    now()
  )
  ON CONFLICT (lounge_id, role, permission_key)
  DO UPDATE
  SET is_enabled = EXCLUDED.is_enabled,
      updated_at = now();

  RETURN jsonb_build_object(
    'success', true,
    'scope', 'lounge',
    'lounge_id', p_lounge_id,
    'role', v_role,
    'permission_key', v_permission_key,
    'is_enabled', p_is_enabled
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.update_role_permission(
  text, text, boolean, uuid
) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.update_role_permission(
  text, text, boolean, uuid
) TO authenticated, service_role, supabase_auth_admin;

DROP POLICY IF EXISTS "lounge_staff_policy" ON public.lounge_staff;

COMMIT;
