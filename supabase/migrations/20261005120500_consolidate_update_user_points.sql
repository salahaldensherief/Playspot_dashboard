-- Migration: 20261005120500_consolidate_update_user_points.sql
-- Description: Consolidate update_user_points into single authoritative function with audit logging, row lock, and revoke anon execution.

BEGIN;

-- 1. Drop the legacy 2-parameter overload which bypassed points_transactions, row locking, and description
DROP FUNCTION IF EXISTS public.update_user_points(uuid, integer);

-- 2. Ensure authoritative 3-parameter function with default reason and security settings
CREATE OR REPLACE FUNCTION public.update_user_points(
  p_user_id uuid,
  p_points_change integer,
  p_reason text DEFAULT 'تعديل إداري للنقاط'::text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_old_points integer;
  v_new_points integer;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'super_admin'
  ) AND NOT (SELECT current_user = 'postgres') THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
  END IF;

  IF p_points_change = 0 THEN
    RETURN;
  END IF;

  SELECT COALESCE(points, 0) INTO v_old_points
  FROM public.profiles
  WHERE id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User profile not found' USING ERRCODE = 'P0002';
  END IF;

  v_new_points := GREATEST(0, v_old_points + p_points_change);

  UPDATE public.profiles
  SET points = v_new_points
  WHERE id = p_user_id;

  INSERT INTO public.points_transactions (
    user_id, points, type, reference_id, description, created_at
  ) VALUES (
    p_user_id,
    p_points_change,
    CASE WHEN p_points_change > 0 THEN 'admin_grant' ELSE 'admin_deduct' END,
    auth.uid(),
    COALESCE(p_reason, 'تعديل إداري للنقاط'),
    now()
  );
END;
$$;

-- 3. Access Control Hardening
REVOKE EXECUTE ON FUNCTION public.update_user_points(uuid, integer, text) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.update_user_points(uuid, integer, text) TO authenticated, service_role;

COMMIT;
