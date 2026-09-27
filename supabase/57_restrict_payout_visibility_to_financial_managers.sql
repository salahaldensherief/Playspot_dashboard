BEGIN;

DROP POLICY IF EXISTS payouts_select_policy ON public.payouts;

CREATE POLICY payouts_select_policy
ON public.payouts
FOR SELECT
TO authenticated
USING (
  public.is_super_admin()
  OR private.can_manage_playspot_lounge(lounge_id)
);

CREATE OR REPLACE FUNCTION public.get_all_payouts(
  p_user_id uuid DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_result json;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  SELECT json_agg(p ORDER BY p.created_at DESC)
  INTO v_result
  FROM public.payouts AS p
  WHERE public.is_super_admin()
     OR private.can_manage_playspot_lounge(p.lounge_id);

  RETURN json_build_object(
    'success', true,
    'data', COALESCE(v_result, '[]'::json)
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.get_all_payouts(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.get_all_payouts(uuid)
TO authenticated, service_role, supabase_auth_admin;

CREATE OR REPLACE FUNCTION public.get_pending_payouts(
  p_user_id uuid DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_result json;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  SELECT json_agg(p ORDER BY p.created_at DESC)
  INTO v_result
  FROM public.payouts AS p
  WHERE p.status = 'pending'
    AND (
      public.is_super_admin()
      OR private.can_manage_playspot_lounge(p.lounge_id)
    );

  RETURN json_build_object(
    'success', true,
    'data', COALESCE(v_result, '[]'::json)
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.get_pending_payouts(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.get_pending_payouts(uuid)
TO authenticated, service_role, supabase_auth_admin;

COMMIT;
