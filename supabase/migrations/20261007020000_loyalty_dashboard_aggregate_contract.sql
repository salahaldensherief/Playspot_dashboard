BEGIN;

CREATE OR REPLACE FUNCTION public.get_loyalty_dashboard_stats(
  p_start_date timestamptz DEFAULT NULL,
  p_end_date timestamptz DEFAULT NULL,
  p_level_id uuid DEFAULT NULL,
  p_referral_status text DEFAULT NULL,
  p_user_query text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_result jsonb;
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'NOT_AUTHORIZED' USING ERRCODE = '42501';
  END IF;

  WITH user_levels AS (
    SELECT
      p.id,
      p.full_name,
      p.email,
      p.phone,
      COALESCE(p.points, 0) AS points,
      level_row.id AS level_id,
      COALESCE(level_row.name_en, level_row.name_ar, level_row.code, 'Unassigned') AS level_name
    FROM public.profiles AS p
    LEFT JOIN LATERAL (
      SELECT ll.*
      FROM public.loyalty_levels AS ll
      WHERE ll.min_points <= COALESCE(p.points, 0)
      ORDER BY ll.min_points DESC
      LIMIT 1
    ) AS level_row ON true
    WHERE p.role = 'user'
      AND COALESCE(p.is_active, true) IS TRUE
      AND COALESCE(p.is_banned, false) IS FALSE
  ),
  scoped_users AS (
    SELECT ul.*
    FROM user_levels AS ul
    WHERE (p_level_id IS NULL OR ul.level_id = p_level_id)
      AND (
        NULLIF(btrim(p_user_query), '') IS NULL
        OR ul.id::text = btrim(p_user_query)
        OR COALESCE(ul.full_name, '') ILIKE '%' || btrim(p_user_query) || '%'
        OR COALESCE(ul.email, '') ILIKE '%' || btrim(p_user_query) || '%'
        OR COALESCE(ul.phone, '') ILIKE '%' || btrim(p_user_query) || '%'
      )
  ),
  level_counts AS (
    SELECT
      su.level_name,
      count(*)::int AS user_count
    FROM scoped_users AS su
    GROUP BY su.level_name
  ),
  points_stats AS (
    SELECT
      COALESCE(sum(CASE WHEN pt.points > 0 THEN pt.points ELSE 0 END), 0)::int AS total_added_points,
      COALESCE(sum(CASE WHEN pt.type = 'earn_referral' AND pt.points > 0 THEN pt.points ELSE 0 END), 0)::int AS total_referral_points
    FROM public.points_transactions AS pt
    JOIN scoped_users AS su ON su.id = pt.user_id
    WHERE (p_start_date IS NULL OR pt.created_at >= p_start_date)
      AND (
        p_end_date IS NULL
        OR pt.created_at < date_trunc('day', p_end_date) + interval '1 day'
      )
  ),
  referral_stats AS (
    SELECT
      count(*)::int AS total_referrals,
      count(*) FILTER (WHERE r.status = 'completed')::int AS completed_referrals
    FROM public.referrals AS r
    WHERE EXISTS (
        SELECT 1
        FROM scoped_users AS su
        WHERE su.id = r.referrer_id OR su.id = r.referred_id
      )
      AND (p_start_date IS NULL OR r.created_at >= p_start_date)
      AND (
        p_end_date IS NULL
        OR r.created_at < date_trunc('day', p_end_date) + interval '1 day'
      )
      AND (
        NULLIF(btrim(p_referral_status), '') IS NULL
        OR lower(btrim(p_referral_status)) = 'all'
        OR r.status = lower(btrim(p_referral_status))
      )
  ),
  voucher_stats AS (
    SELECT
      count(*)::int AS total_vouchers_issued,
      count(*) FILTER (WHERE uv.status = 'used')::int AS total_vouchers_used,
      count(*) FILTER (
        WHERE uv.status = 'active'
          AND (uv.expires_at IS NULL OR uv.expires_at > now())
      )::int AS total_vouchers_active,
      COALESCE(
        sum(
          CASE
            WHEN uv.status = 'used'
            THEN COALESCE(b.discount_amount, 0)
            ELSE 0
          END
        ),
        0
      )::numeric AS total_discount_value_used
    FROM public.user_vouchers AS uv
    JOIN scoped_users AS su ON su.id = uv.user_id
    LEFT JOIN public.bookings AS b ON b.id = uv.used_booking_id
    WHERE (p_start_date IS NULL OR uv.created_at >= p_start_date)
      AND (
        p_end_date IS NULL
        OR uv.created_at < date_trunc('day', p_end_date) + interval '1 day'
      )
  )
  SELECT jsonb_build_object(
    'total_added_points', ps.total_added_points,
    'user_count_by_level',
      COALESCE(
        (
          SELECT jsonb_object_agg(lc.level_name, lc.user_count ORDER BY lc.level_name)
          FROM level_counts AS lc
        ),
        '{}'::jsonb
      ),
    'total_referrals', rs.total_referrals,
    'completed_referrals', rs.completed_referrals,
    'total_referral_points', ps.total_referral_points,
    'total_vouchers_issued', vs.total_vouchers_issued,
    'total_vouchers_used', vs.total_vouchers_used,
    'total_vouchers_active', vs.total_vouchers_active,
    'total_discount_value_used', vs.total_discount_value_used
  )
  INTO v_result
  FROM points_stats AS ps
  CROSS JOIN referral_stats AS rs
  CROSS JOIN voucher_stats AS vs;

  RETURN COALESCE(
    v_result,
    jsonb_build_object(
      'total_added_points', 0,
      'user_count_by_level', '{}'::jsonb,
      'total_referrals', 0,
      'completed_referrals', 0,
      'total_referral_points', 0,
      'total_vouchers_issued', 0,
      'total_vouchers_used', 0,
      'total_vouchers_active', 0,
      'total_discount_value_used', 0
    )
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.get_loyalty_dashboard_stats(
  timestamptz, timestamptz, uuid, text, text
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_loyalty_dashboard_stats(
  timestamptz, timestamptz, uuid, text, text
) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.get_loyalty_referrals(
  p_start_date timestamptz DEFAULT NULL,
  p_end_date timestamptz DEFAULT NULL,
  p_status text DEFAULT NULL,
  p_user_query text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_result jsonb;
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'NOT_AUTHORIZED' USING ERRCODE = '42501';
  END IF;

  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id', r.id,
        'referrer_id', r.referrer_id,
        'referred_id', r.referred_id,
        'status', r.status,
        'reward_claimed', r.reward_claimed,
        'created_at', r.created_at,
        'referrer', jsonb_build_object(
          'id', referrer.id,
          'full_name', referrer.full_name,
          'email', referrer.email
        ),
        'referred', jsonb_build_object(
          'id', referred.id,
          'full_name', referred.full_name,
          'email', referred.email
        )
      )
      ORDER BY r.created_at DESC, r.id
    ),
    '[]'::jsonb
  )
  INTO v_result
  FROM public.referrals AS r
  LEFT JOIN public.profiles AS referrer ON referrer.id = r.referrer_id
  LEFT JOIN public.profiles AS referred ON referred.id = r.referred_id
  WHERE (p_start_date IS NULL OR r.created_at >= p_start_date)
    AND (
      p_end_date IS NULL
      OR r.created_at < date_trunc('day', p_end_date) + interval '1 day'
    )
    AND (
      NULLIF(btrim(p_status), '') IS NULL
      OR lower(btrim(p_status)) = 'all'
      OR r.status = lower(btrim(p_status))
    )
    AND (
      NULLIF(btrim(p_user_query), '') IS NULL
      OR r.referrer_id::text = btrim(p_user_query)
      OR r.referred_id::text = btrim(p_user_query)
      OR COALESCE(referrer.full_name, '') ILIKE '%' || btrim(p_user_query) || '%'
      OR COALESCE(referrer.email, '') ILIKE '%' || btrim(p_user_query) || '%'
      OR COALESCE(referrer.phone, '') ILIKE '%' || btrim(p_user_query) || '%'
      OR COALESCE(referred.full_name, '') ILIKE '%' || btrim(p_user_query) || '%'
      OR COALESCE(referred.email, '') ILIKE '%' || btrim(p_user_query) || '%'
      OR COALESCE(referred.phone, '') ILIKE '%' || btrim(p_user_query) || '%'
    );

  RETURN v_result;
END;
$function$;

REVOKE ALL ON FUNCTION public.get_loyalty_referrals(
  timestamptz, timestamptz, text, text
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_loyalty_referrals(
  timestamptz, timestamptz, text, text
) TO authenticated, service_role;

COMMIT;
