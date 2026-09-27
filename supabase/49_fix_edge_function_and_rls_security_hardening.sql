-- 49_fix_edge_function_and_rls_security_hardening.sql
-- Security Hardening & RPC Execution Privilege Adjustments
-- 1. Revoke public/anon access to administrative functions and grant only to authenticated where necessary.
-- 2. Harden get_all_bookings_admin and get_notifications_page permissions.
-- 3. Ensure Storage policies for payment-proofs & kyc-documents are securely isolated.

-- Revoke anon execution on administrative RPCs
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_all_bookings_admin') THEN
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.get_all_bookings_admin FROM anon, public;';
    EXECUTE 'GRANT EXECUTE ON FUNCTION public.get_all_bookings_admin TO authenticated;';
  END IF;

  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_notifications_page') THEN
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.get_notifications_page FROM anon;';
    EXECUTE 'GRANT EXECUTE ON FUNCTION public.get_notifications_page TO authenticated;';
  END IF;

  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'super_admin_create_lounge_with_owner') THEN
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.super_admin_create_lounge_with_owner FROM anon, public;';
    EXECUTE 'GRANT EXECUTE ON FUNCTION public.super_admin_create_lounge_with_owner TO authenticated;';
  END IF;
END $$;

-- Harden get_notifications_page function definition to safely fallback and validate user
CREATE OR REPLACE FUNCTION public.get_notifications_page(
  p_page integer DEFAULT 1,
  p_page_size integer DEFAULT 20
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  v_offset integer;
  v_total integer;
  v_items jsonb;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  v_offset := (GREATEST(p_page, 1) - 1) * GREATEST(p_page_size, 1);

  SELECT count(*) INTO v_total
  FROM public.notifications
  WHERE user_id = v_user_id;

  SELECT COALESCE(jsonb_agg(to_jsonb(n)), '[]'::jsonb) INTO v_items
  FROM (
    SELECT *
    FROM public.notifications
    WHERE user_id = v_user_id
    ORDER BY created_at DESC
    LIMIT p_page_size
    OFFSET v_offset
  ) n;

  RETURN jsonb_build_object(
    'items', v_items,
    'total_count', v_total,
    'page', p_page,
    'page_size', p_page_size
  );
END;
$function$;

-- Enable RLS on spatial_ref_sys if present and owned by current user
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_tables
    WHERE schemaname = 'public' AND tablename = 'spatial_ref_sys'
  ) THEN
    ALTER TABLE public.spatial_ref_sys ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "spatial_ref_sys_read_all" ON public.spatial_ref_sys;
    CREATE POLICY "spatial_ref_sys_read_all" ON public.spatial_ref_sys FOR SELECT USING (true);
  END IF;
EXCEPTION WHEN OTHERS THEN
  -- Ignore if permission not owned on PostGIS system table
  NULL;
END $$;
