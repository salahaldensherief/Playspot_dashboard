-- =============================================================================
-- 09_staff_creation_fix.sql
-- Fix Duplicate Overloads for create_lounge_staff & Ensure Immediate Staff Display
-- =============================================================================

-- 1. Drop ALL older overloaded variants of staff creation functions
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (
    SELECT pg_proc.oid::regprocedure AS func_signature
    FROM pg_proc
    JOIN pg_namespace ON pg_proc.pronamespace = pg_namespace.oid
    WHERE pg_namespace.nspname = 'public'
      AND proname IN ('create_lounge_staff', 'add_lounge_staff_member', 'add_staff_member', 'get_lounge_staff')
  ) LOOP
    EXECUTE 'DROP FUNCTION IF EXISTS ' || r.func_signature || ' CASCADE';
  END LOOP;
END $$;

-- 2. Create Single Canonical create_lounge_staff Function
CREATE OR REPLACE FUNCTION public.create_lounge_staff(
  p_email TEXT,
  p_password TEXT,
  p_full_name TEXT,
  p_lounge_id UUID,
  p_role TEXT DEFAULT 'cashier'::TEXT,
  p_phone TEXT DEFAULT ''::TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions, pg_temp
AS $$
DECLARE
  new_user_id UUID;
  encrypted_pw TEXT;
  v_staff_role TEXT;
  v_clean_email TEXT := lower(trim(p_email));
  v_clean_phone TEXT := trim(COALESCE(p_phone, ''));
  v_clean_name TEXT := trim(COALESCE(p_full_name, 'Staff Member'));
  v_requested_role TEXT := lower(trim(COALESCE(p_role, 'cashier')));
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Authorization Check
  IF NOT (public.is_super_admin() OR public.is_lounge_admin(p_lounge_id)) THEN
    RAISE EXCEPTION 'Not authorized to add staff to this lounge';
  END IF;

  IF p_lounge_id IS NULL THEN
    RAISE EXCEPTION 'Lounge ID is required';
  END IF;

  IF v_clean_email = '' OR p_password IS NULL OR length(p_password) < 6 THEN
    RAISE EXCEPTION 'Valid email and password (min 6 characters) are required';
  END IF;

  IF EXISTS (SELECT 1 FROM auth.users WHERE lower(email) = v_clean_email) THEN
    RAISE EXCEPTION 'Email already registered';
  END IF;

  v_staff_role := CASE
    WHEN v_requested_role IN ('manager', 'admin', 'lounge_admin') THEN 'manager'
    WHEN v_requested_role = 'owner' THEN 'owner'
    ELSE 'cashier'
  END;

  new_user_id := gen_random_uuid();
  encrypted_pw := crypt(p_password, gen_salt('bf'));

  -- 1. Insert into auth.users
  INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  ) VALUES (
    '00000000-0000-0000-0000-000000000000', new_user_id, 'authenticated', 'authenticated',
    v_clean_email, encrypted_pw, NOW(),
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object('full_name', v_clean_name, 'name', v_clean_name, 'role', v_staff_role),
    NOW(), NOW()
  );

  -- 2. Insert into auth.identities
  INSERT INTO auth.identities (
    id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
  ) VALUES (
    gen_random_uuid(), new_user_id,
    jsonb_build_object('sub', new_user_id::text, 'email', v_clean_email),
    'email', v_clean_email, NOW(), NOW(), NOW()
  );

  -- 3. Insert or Update public.profiles
  INSERT INTO public.profiles (id, email, full_name, phone, role, lounge_id, is_active, updated_at)
  VALUES (new_user_id, v_clean_email, v_clean_name, v_clean_phone, v_staff_role, p_lounge_id, true, NOW())
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name,
    phone = EXCLUDED.phone,
    role = EXCLUDED.role,
    lounge_id = EXCLUDED.lounge_id,
    is_active = true,
    updated_at = NOW();

  -- 4. Insert into public.lounge_staff
  INSERT INTO public.lounge_staff (lounge_id, user_id, role)
  VALUES (p_lounge_id, new_user_id, v_staff_role)
  ON CONFLICT DO NOTHING;

  RETURN jsonb_build_object('success', true, 'user_id', new_user_id);
END;
$$;

-- 3. Create Clean get_lounge_staff RPC
CREATE OR REPLACE FUNCTION public.get_lounge_staff(p_lounge_id UUID)
RETURNS TABLE(
  id UUID,
  email TEXT,
  full_name TEXT,
  phone TEXT,
  role TEXT,
  lounge_id UUID,
  is_active BOOLEAN,
  created_at TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions, pg_temp
AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.email::TEXT,
    COALESCE(p.full_name, 'Staff Member')::TEXT,
    COALESCE(p.phone, '')::TEXT,
    COALESCE(p.role, 'cashier')::TEXT,
    p.lounge_id,
    COALESCE(p.is_active, true) AS is_active,
    COALESCE(p.created_at::TEXT, NOW()::TEXT) AS created_at
  FROM public.profiles p
  WHERE (p.lounge_id = p_lounge_id OR p.id IN (SELECT ls.user_id FROM public.lounge_staff ls WHERE ls.lounge_id = p_lounge_id))
    AND p.role NOT IN ('super_admin', 'superadmin')
  ORDER BY p.created_at DESC;
END;
$$;

-- Explicit Grants
GRANT EXECUTE ON FUNCTION public.create_lounge_staff TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_lounge_staff TO authenticated;
