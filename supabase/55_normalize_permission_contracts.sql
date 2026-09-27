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

  IF v_actor_role IS NULL THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
  END IF;

  IF v_actor_role <> 'super_admin'
     AND NOT public.has_lounge_permission(p_lounge_id, 'staff_manage') THEN
    RAISE EXCEPTION 'Missing staff_manage permission'
      USING ERRCODE = '42501';
  END IF;

  IF v_role = 'super_admin' THEN
    RAISE EXCEPTION 'Super admin permissions are global-only'
      USING ERRCODE = '42501';
  END IF;

  IF v_role = 'owner' AND v_actor_role <> 'super_admin' THEN
    RAISE EXCEPTION 'Only a super admin can change owner permissions'
      USING ERRCODE = '42501';
  END IF;

  IF v_actor_role = 'manager'
     AND v_role NOT IN ('cashier', 'staff') THEN
    RAISE EXCEPTION 'Managers can only edit cashier or staff permissions'
      USING ERRCODE = '42501';
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


CREATE OR REPLACE FUNCTION public.create_lounge_staff(
  p_email text,
  p_password text,
  p_full_name text,
  p_lounge_id uuid,
  p_role text DEFAULT 'cashier',
  p_phone text DEFAULT ''
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth', 'extensions', 'pg_temp'
AS $function$
DECLARE
  new_user_id uuid;
  encrypted_pw text;
  v_staff_role text;
  v_actor_role text;
  v_clean_email text := lower(btrim(p_email));
  v_clean_phone text := btrim(COALESCE(p_phone, ''));
  v_clean_name text := btrim(COALESCE(p_full_name, 'Staff Member'));
  v_requested_role text := lower(btrim(COALESCE(p_role, 'cashier')));
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  IF p_lounge_id IS NULL THEN
    RAISE EXCEPTION 'Lounge ID is required' USING ERRCODE = '22023';
  END IF;

  v_actor_role := private.permission_role(auth.uid(), p_lounge_id);

  IF v_actor_role IS NULL THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
  END IF;

  IF v_actor_role <> 'super_admin'
     AND NOT public.has_lounge_permission(p_lounge_id, 'staff_manage') THEN
    RAISE EXCEPTION 'Missing staff_manage permission'
      USING ERRCODE = '42501';
  END IF;

  IF v_requested_role IN ('owner', 'lounge_owner', 'super_admin', 'superadmin') THEN
    RAISE EXCEPTION 'Owner accounts cannot be created through staff management'
      USING ERRCODE = '42501';
  END IF;

  v_staff_role := CASE
    WHEN v_requested_role IN ('manager', 'admin', 'lounge_admin') THEN 'manager'
    WHEN v_requested_role = 'staff' THEN 'staff'
    ELSE 'cashier'
  END;

  IF v_actor_role = 'manager' AND v_staff_role = 'manager' THEN
    RAISE EXCEPTION 'Managers cannot create or promote peer managers'
      USING ERRCODE = '42501';
  END IF;

  IF v_clean_email = ''
     OR p_password IS NULL
     OR length(p_password) < 6 THEN
    RAISE EXCEPTION 'Valid email and password (min 6 characters) are required'
      USING ERRCODE = '22023';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM auth.users
    WHERE lower(email) = v_clean_email
  ) THEN
    RAISE EXCEPTION 'Email already registered'
      USING ERRCODE = '23505';
  END IF;

  new_user_id := gen_random_uuid();
  encrypted_pw := crypt(p_password, gen_salt('bf'));

  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  )
  VALUES (
    '00000000-0000-0000-0000-000000000000',
    new_user_id,
    'authenticated',
    'authenticated',
    v_clean_email,
    encrypted_pw,
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object(
      'full_name', v_clean_name,
      'name', v_clean_name,
      'role', v_staff_role
    ),
    now(),
    now()
  );

  INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
  )
  VALUES (
    gen_random_uuid(),
    new_user_id,
    jsonb_build_object(
      'sub', new_user_id::text,
      'email', v_clean_email
    ),
    'email',
    v_clean_email,
    now(),
    now(),
    now()
  );

  INSERT INTO public.profiles (
    id,
    email,
    full_name,
    phone,
    role,
    lounge_id,
    is_active,
    updated_at
  )
  VALUES (
    new_user_id,
    v_clean_email,
    v_clean_name,
    v_clean_phone,
    v_staff_role,
    p_lounge_id,
    true,
    now()
  )
  ON CONFLICT (id)
  DO UPDATE SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name,
    phone = EXCLUDED.phone,
    role = EXCLUDED.role,
    lounge_id = EXCLUDED.lounge_id,
    is_active = true,
    updated_at = now();

  INSERT INTO public.lounge_staff (
    lounge_id,
    user_id,
    role
  )
  VALUES (
    p_lounge_id,
    new_user_id,
    v_staff_role
  )
  ON CONFLICT DO NOTHING;

  RETURN jsonb_build_object(
    'success', true,
    'user_id', new_user_id,
    'role', v_staff_role
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.create_lounge_staff(
  text, text, text, uuid, text, text
) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.create_lounge_staff(
  text, text, text, uuid, text, text
) TO authenticated, service_role, supabase_auth_admin;


CREATE OR REPLACE FUNCTION public.update_lounge_staff_member(
  p_target_user_id uuid,
  p_full_name text DEFAULT NULL,
  p_phone text DEFAULT NULL,
  p_role text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_target public.profiles%ROWTYPE;
  v_actor_role text;
  v_new_role text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  SELECT p.*
  INTO v_target
  FROM public.profiles AS p
  WHERE p.id = p_target_user_id
  FOR UPDATE;

  IF NOT FOUND OR v_target.lounge_id IS NULL THEN
    RAISE EXCEPTION 'Staff member not found' USING ERRCODE = 'P0002';
  END IF;

  IF v_target.role IN ('owner', 'lounge_owner', 'super_admin', 'superadmin') THEN
    RAISE EXCEPTION 'Owner and super admin accounts are protected'
      USING ERRCODE = '42501';
  END IF;

  v_actor_role := private.permission_role(auth.uid(), v_target.lounge_id);

  IF v_actor_role IS NULL THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
  END IF;

  IF v_actor_role <> 'super_admin'
     AND NOT public.has_lounge_permission(
       v_target.lounge_id,
       'staff_manage'
     ) THEN
    RAISE EXCEPTION 'Missing staff_manage permission'
      USING ERRCODE = '42501';
  END IF;

  IF v_actor_role = 'manager'
     AND v_target.role = 'manager' THEN
    RAISE EXCEPTION 'Managers cannot modify peer managers'
      USING ERRCODE = '42501';
  END IF;

  IF p_role IS NOT NULL THEN
    v_new_role := CASE lower(btrim(p_role))
      WHEN 'manager' THEN 'manager'
      WHEN 'admin' THEN 'manager'
      WHEN 'lounge_admin' THEN 'manager'
      WHEN 'cashier' THEN 'cashier'
      WHEN 'staff' THEN 'staff'
      ELSE NULL
    END;

    IF v_new_role IS NULL THEN
      RAISE EXCEPTION 'Unsupported staff role'
        USING ERRCODE = '22023';
    END IF;

    IF v_actor_role = 'manager' AND v_new_role = 'manager' THEN
      RAISE EXCEPTION 'Managers cannot promote staff to manager'
        USING ERRCODE = '42501';
    END IF;
  ELSE
    v_new_role := v_target.role;
  END IF;

  UPDATE public.profiles
  SET full_name = COALESCE(NULLIF(btrim(p_full_name), ''), full_name),
      phone = COALESCE(NULLIF(btrim(p_phone), ''), phone),
      role = v_new_role,
      updated_at = now()
  WHERE id = p_target_user_id;

  UPDATE public.lounge_staff
  SET role = v_new_role
  WHERE lounge_id = v_target.lounge_id
    AND user_id = p_target_user_id;

  RETURN jsonb_build_object(
    'success', true,
    'user_id', p_target_user_id,
    'lounge_id', v_target.lounge_id,
    'role', v_new_role
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.update_lounge_staff_member(
  uuid, text, text, text
) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.update_lounge_staff_member(
  uuid, text, text, text
) TO authenticated, service_role, supabase_auth_admin;


CREATE OR REPLACE FUNCTION public.set_lounge_staff_active(
  p_target_user_id uuid,
  p_is_active boolean
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_target public.profiles%ROWTYPE;
  v_actor_role text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  SELECT p.*
  INTO v_target
  FROM public.profiles AS p
  WHERE p.id = p_target_user_id
  FOR UPDATE;

  IF NOT FOUND OR v_target.lounge_id IS NULL THEN
    RAISE EXCEPTION 'Staff member not found' USING ERRCODE = 'P0002';
  END IF;

  IF v_target.role IN ('owner', 'lounge_owner', 'super_admin', 'superadmin') THEN
    RAISE EXCEPTION 'Owner and super admin accounts are protected'
      USING ERRCODE = '42501';
  END IF;

  v_actor_role := private.permission_role(auth.uid(), v_target.lounge_id);

  IF v_actor_role IS NULL
     OR (
       v_actor_role <> 'super_admin'
       AND NOT public.has_lounge_permission(
         v_target.lounge_id,
         'staff_manage'
       )
     ) THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
  END IF;

  IF v_actor_role = 'manager' AND v_target.role = 'manager' THEN
    RAISE EXCEPTION 'Managers cannot modify peer managers'
      USING ERRCODE = '42501';
  END IF;

  UPDATE public.profiles
  SET is_active = COALESCE(p_is_active, false),
      updated_at = now()
  WHERE id = p_target_user_id;

  RETURN jsonb_build_object(
    'success', true,
    'user_id', p_target_user_id,
    'is_active', COALESCE(p_is_active, false)
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.set_lounge_staff_active(uuid, boolean)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.set_lounge_staff_active(uuid, boolean)
TO authenticated, service_role, supabase_auth_admin;


CREATE OR REPLACE FUNCTION public.remove_lounge_staff_member(
  p_target_user_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_target public.profiles%ROWTYPE;
  v_actor_role text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  SELECT p.*
  INTO v_target
  FROM public.profiles AS p
  WHERE p.id = p_target_user_id
  FOR UPDATE;

  IF NOT FOUND OR v_target.lounge_id IS NULL THEN
    RAISE EXCEPTION 'Staff member not found' USING ERRCODE = 'P0002';
  END IF;

  IF v_target.role IN ('owner', 'lounge_owner', 'super_admin', 'superadmin') THEN
    RAISE EXCEPTION 'Owner and super admin accounts are protected'
      USING ERRCODE = '42501';
  END IF;

  v_actor_role := private.permission_role(auth.uid(), v_target.lounge_id);

  IF v_actor_role IS NULL
     OR (
       v_actor_role <> 'super_admin'
       AND NOT public.has_lounge_permission(
         v_target.lounge_id,
         'staff_manage'
       )
     ) THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
  END IF;

  IF v_actor_role = 'manager' AND v_target.role = 'manager' THEN
    RAISE EXCEPTION 'Managers cannot remove peer managers'
      USING ERRCODE = '42501';
  END IF;

  DELETE FROM public.lounge_staff
  WHERE lounge_id = v_target.lounge_id
    AND user_id = p_target_user_id;

  UPDATE public.profiles
  SET lounge_id = NULL,
      role = 'user',
      is_active = false,
      updated_at = now()
  WHERE id = p_target_user_id;

  RETURN jsonb_build_object(
    'success', true,
    'user_id', p_target_user_id,
    'removed_from_lounge', v_target.lounge_id
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.remove_lounge_staff_member(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.remove_lounge_staff_member(uuid)
TO authenticated, service_role, supabase_auth_admin;

COMMIT;
