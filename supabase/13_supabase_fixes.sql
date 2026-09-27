-- Migration 13: Comprehensive Supabase DB RPC & Schema Fixes
-- Date: 2026-09-23

-- 1. Ensure notification_preferences column exists on public.profiles
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS notification_preferences JSONB DEFAULT '{"push_notifications_enabled": true}'::jsonb;

-- 2. Drop ALL overloaded legacy function signatures
DROP FUNCTION IF EXISTS public.get_role_permissions(text);
DROP FUNCTION IF EXISTS public.create_lounge_with_admin(text, text, text, text, text);
DROP FUNCTION IF EXISTS public.create_lounge_admin(text, text, text, uuid);
DROP FUNCTION IF EXISTS public.create_lounge_admin(uuid, text, text, text);
DROP FUNCTION IF EXISTS public.get_nearby_rooms(double precision, double precision, text, double precision, uuid[], text);
DROP FUNCTION IF EXISTS public.get_nearby_rooms(double precision, double precision, double precision, text, text, uuid[]);
DROP FUNCTION IF EXISTS public.swap_booking_room(uuid, uuid);
DROP FUNCTION IF EXISTS public.swap_booking_room(uuid, uuid, text);
DROP FUNCTION IF EXISTS public.swap_booking_room(uuid, uuid, uuid);
DROP FUNCTION IF EXISTS public.create_lounge_with_team_and_permissions(text, text, text, uuid, jsonb);
DROP FUNCTION IF EXISTS public.delete_user_account();
DROP FUNCTION IF EXISTS public.check_and_expire_promos();
DROP FUNCTION IF EXISTS public.expire_tournament_payments();
DROP FUNCTION IF EXISTS public.send_topic_notification(text, text, text, text, text, text, jsonb);
DROP FUNCTION IF EXISTS public.get_my_bookings(uuid);
DROP FUNCTION IF EXISTS public.get_my_bookings();
DROP FUNCTION IF EXISTS public.broadcast_promo_notification(uuid, uuid, text, text, text, text);
DROP FUNCTION IF EXISTS public.get_revenue_over_time(uuid, text);
DROP FUNCTION IF EXISTS public.get_all_lounges_with_owners();

-- 3. Fix get_role_permissions (permission_key instead of permission)
CREATE OR REPLACE FUNCTION public.get_role_permissions(p_role text)
RETURNS jsonb
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(jsonb_agg(permission_key), '[]'::jsonb)
  FROM public.role_permissions
  WHERE role = p_role AND is_enabled = true;
$$;

-- 4. Fix create_lounge_with_admin (image_url & extensions.gen_salt)
CREATE OR REPLACE FUNCTION public.create_lounge_with_admin(
    p_lounge_name text,
    p_owner_email text,
    p_owner_password text,
    p_owner_name text,
    p_banner_url text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
    new_user_id uuid;
    new_lounge_id uuid;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'super_admin'
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Super Admin access required.';
    END IF;

    SELECT id INTO new_user_id FROM auth.users WHERE email = p_owner_email;
    IF new_user_id IS NULL THEN
        new_user_id := gen_random_uuid();
        INSERT INTO auth.users (
            id, instance_id, email, encrypted_password, email_confirmed_at,
            raw_user_meta_data, role, aud, created_at, updated_at
        ) VALUES (
            new_user_id, '00000000-0000-0000-0000-000000000000', p_owner_email,
            extensions.crypt(p_owner_password, extensions.gen_salt('bf')), NOW(),
            jsonb_build_object('full_name', p_owner_name),
            'authenticated', 'authenticated', NOW(), NOW()
        );
    END IF;

    INSERT INTO lounges (
        name, image_url, owner_id, is_active
    ) VALUES (
        p_lounge_name, p_banner_url, new_user_id, true
    ) RETURNING id INTO new_lounge_id;

    INSERT INTO public.profiles (
        id, email, full_name, role, lounge_id, is_active
    ) VALUES (
        new_user_id, p_owner_email, p_owner_name, 'lounge_owner', new_lounge_id, true
    )
    ON CONFLICT (id) DO UPDATE SET
        lounge_id = new_lounge_id,
        role = 'lounge_owner',
        full_name = EXCLUDED.full_name;

    RETURN jsonb_build_object(
        'lounge_id', new_lounge_id,
        'owner_id', new_user_id,
        'success', true
    );
END;
$$;

-- 5. Fix swap_booking_room (hourly_rate_single instead of price_per_hour)
CREATE OR REPLACE FUNCTION public.swap_booking_room(
    p_booking_id uuid,
    p_new_room_id uuid,
    p_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_room_name text;
    v_hourly_rate numeric;
BEGIN
    SELECT COALESCE(name_ar, name), COALESCE(hourly_rate_single, hourly_rate, 0)
    INTO v_room_name, v_hourly_rate
    FROM public.rooms WHERE id = p_new_room_id;

    IF v_room_name IS NULL THEN
        RAISE EXCEPTION 'Target room does not exist';
    END IF;

    UPDATE public.bookings
    SET room_id = p_new_room_id,
        room_name = v_room_name,
        updated_at = NOW()
    WHERE id = p_booking_id;

    RETURN jsonb_build_object('success', true, 'new_room_name', v_room_name);
END;
$$;

-- 6. Fix delete_user_account (remove reference to non-existent reviews table)
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id uuid := auth.uid();
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    DELETE FROM public.notifications WHERE user_id = v_user_id;
    DELETE FROM public.profiles WHERE id = v_user_id;
    DELETE FROM auth.users WHERE id = v_user_id;

    RETURN jsonb_build_object('success', true);
END;
$$;

-- 7. Fix check_and_expire_promos (promotions table and expires_at column)
CREATE OR REPLACE FUNCTION public.check_and_expire_promos()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    UPDATE public.promotions
    SET is_active = false
    WHERE expires_at IS NOT NULL
      AND expires_at <= NOW()
      AND is_active = true;
$$;

-- 8. Fix expire_tournament_payments
CREATE OR REPLACE FUNCTION public.expire_tournament_payments()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT id, tournament_id FROM public.tournament_participants
             WHERE payment_status = 'pending' AND payment_deadline < NOW()
    LOOP
        UPDATE public.tournament_participants
        SET registration_status = 'pending_payment',
            payment_status = 'unpaid',
            waitlist_position = NULL,
            updated_at = NOW()
        WHERE id = r.id;
    END LOOP;
END;
$$;

-- 9. Fix send_topic_notification
CREATE OR REPLACE FUNCTION public.send_topic_notification(
    p_topic_key text,
    p_title_ar text,
    p_title_en text,
    p_body_ar text,
    p_body_en text,
    p_type text DEFAULT 'info',
    p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_count integer;
BEGIN
    WITH inserted_rows AS (
        INSERT INTO public.notifications (
            user_id, title_ar, title_en, body_ar, body_en, type, is_read, metadata
        )
        SELECT
            p.id, p_title_ar, p_title_en, p_body_ar, p_body_en, p_type, false,
            jsonb_build_object('topic', p_topic_key) || COALESCE(p_metadata, '{}'::jsonb)
        FROM public.profiles p
        WHERE p.is_active = true
        RETURNING id
    )
    SELECT COUNT(*) INTO v_count FROM inserted_rows;

    RETURN v_count;
END;
$$;

-- 10. Fix get_my_bookings (image_url instead of logo_url)
CREATE OR REPLACE FUNCTION public.get_my_bookings(p_user_id uuid DEFAULT NULL)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id uuid := COALESCE(p_user_id, auth.uid());
    v_result json;
BEGIN
    SELECT json_agg(row_to_json(t)) INTO v_result
    FROM (
        SELECT
            b.*,
            json_build_object(
                'id', l.id,
                'name', l.name,
                'image_url', l.image_url,
                'address', l.address,
                'city', l.city
            ) AS lounge,
            json_build_object(
                'id', r.id,
                'name_ar', r.name_ar,
                'name_en', r.name_en,
                'room_type', r.room_type
            ) AS room
        FROM public.bookings b
        LEFT JOIN public.lounges l ON l.id = b.lounge_id
        LEFT JOIN public.rooms r ON r.id = b.room_id
        WHERE b.user_id = v_user_id
        ORDER BY b.created_at DESC
    ) t;

    RETURN COALESCE(v_result, '[]'::json);
END;
$$;

-- 11. Fix broadcast_promo_notification (metadata instead of data)
CREATE OR REPLACE FUNCTION public.broadcast_promo_notification(
    p_promo_id uuid,
    p_lounge_id uuid,
    p_title_ar text,
    p_title_en text,
    p_body_ar text,
    p_body_en text
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_count integer;
BEGIN
    WITH inserted_rows AS (
        INSERT INTO public.notifications (
            user_id, title_ar, title_en, body_ar, body_en, type, metadata, is_read, created_at
        )
        SELECT
            p.id AS user_id, p_title_ar, p_title_en, p_body_ar, p_body_en, 'offer',
            jsonb_build_object('promo_id', p_promo_id, 'lounge_id', p_lounge_id),
            false, NOW()
        FROM public.profiles p
        WHERE p.is_active = true
        RETURNING id
    )
    SELECT COUNT(*) INTO v_count FROM inserted_rows;

    RETURN v_count;
END;
$$;

-- 12. Fix create_lounge_admin & get_revenue_over_time (profiles instead of admins)
CREATE OR REPLACE FUNCTION public.create_lounge_admin(
    p_lounge_id uuid,
    p_email text,
    p_password text,
    p_full_name text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
    new_user_id uuid;
BEGIN
    SELECT id INTO new_user_id FROM auth.users WHERE email = p_email;
    IF new_user_id IS NULL THEN
        new_user_id := gen_random_uuid();
        INSERT INTO auth.users (
            id, instance_id, email, encrypted_password, email_confirmed_at,
            raw_user_meta_data, role, aud, created_at, updated_at
        ) VALUES (
            new_user_id, '00000000-0000-0000-0000-000000000000', p_email,
            extensions.crypt(p_password, extensions.gen_salt('bf')), NOW(),
            jsonb_build_object('full_name', p_full_name),
            'authenticated', 'authenticated', NOW(), NOW()
        );
    END IF;

    INSERT INTO public.profiles (
        id, email, full_name, role, lounge_id, is_active, is_setup_completed
    ) VALUES (
        new_user_id, p_email, p_full_name, 'lounge_admin', p_lounge_id, true, true
    )
    ON CONFLICT (id) DO UPDATE SET
        lounge_id = p_lounge_id,
        role = 'lounge_admin',
        full_name = EXCLUDED.full_name;

    RETURN jsonb_build_object('user_id', new_user_id, 'success', true);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_revenue_over_time(
    p_lounge_id uuid DEFAULT NULL,
    p_period text DEFAULT 'month'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_is_super boolean;
    v_user_lounge_id uuid;
    v_result jsonb;
BEGIN
    SELECT (role = 'super_admin'), lounge_id INTO v_is_super, v_user_lounge_id
    FROM public.profiles WHERE id = auth.uid();

    SELECT jsonb_agg(row_to_json(r)) INTO v_result
    FROM (
        SELECT date_trunc(p_period, created_at) AS period, SUM(total_price) AS revenue
        FROM public.bookings
        WHERE (v_is_super OR lounge_id = COALESCE(p_lounge_id, v_user_lounge_id))
          AND status = 'completed'
        GROUP BY 1 ORDER BY 1 ASC
    ) r;

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- 13. Fix get_all_lounges_with_owners (ambiguous id column)
CREATE OR REPLACE FUNCTION public.get_all_lounges_with_owners()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result jsonb;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.role = 'super_admin'
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Super Admin access required.';
    END IF;

    SELECT jsonb_agg(row_to_json(t)) INTO v_result
    FROM (
        SELECT
            l.*,
            json_build_object(
                'id', p.id,
                'full_name', p.full_name,
                'email', p.email,
                'phone', p.phone
            ) AS owner
        FROM public.lounges l
        LEFT JOIN public.profiles p ON p.id = l.owner_id
        ORDER BY l.created_at DESC
    ) t;

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

-- 14. Fix get_nearby_rooms (hourly_rate_single instead of price_per_hour)
CREATE OR REPLACE FUNCTION public.get_nearby_rooms(
    user_lat double precision,
    user_lng double precision,
    max_distance_km double precision DEFAULT 50,
    city_name text DEFAULT NULL,
    space_type_name text DEFAULT NULL,
    activity_ids uuid[] DEFAULT NULL
)
RETURNS TABLE (
    id uuid,
    name_ar text,
    name_en text,
    photo_url text,
    images text[],
    price_per_hour numeric,
    capacity integer,
    is_available boolean,
    space_type_name_out text,
    lounge_id uuid,
    lounge_name text,
    city text,
    location text,
    dist_meters double precision
)
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    r.id,
    r.name_ar,
    r.name_en,
    r.photo_url,
    r.images,
    COALESCE(r.hourly_rate_single, r.hourly_rate, 0) AS price_per_hour,
    r.max_capacity AS capacity,
    r.is_available,
    st.name AS space_type_name_out,
    l.id AS lounge_id,
    l.name AS lounge_name,
    l.city,
    l.location,
    ST_Distance(
      l.location_point,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
    ) AS dist_meters
  FROM rooms r
  JOIN lounges l ON l.id = r.lounge_id
  LEFT JOIN space_types st ON st.id = r.space_type_id
  WHERE l.location_point IS NOT NULL
    AND r.is_available = true
    AND (city_name IS NULL OR l.city = city_name)
    AND (space_type_name IS NULL OR st.name = space_type_name)
    AND ST_DWithin(
      l.location_point,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
      max_distance_km * 1000
    )
  ORDER BY l.location_point <-> ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography;
$$;
