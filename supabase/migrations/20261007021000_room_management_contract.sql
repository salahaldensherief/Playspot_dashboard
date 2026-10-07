BEGIN;

CREATE OR REPLACE FUNCTION public.save_lounge_room_v2(
  p_room jsonb,
  p_activity_ids uuid[] DEFAULT ARRAY[]::uuid[]
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_room_id uuid;
  v_lounge_id uuid;
  v_existing public.rooms%ROWTYPE;
  v_status text;
  v_activity_id uuid;
  v_name text;
  v_requires_screen boolean;
  v_requires_controllers boolean;
  v_controllers_count integer;
  v_screen_size text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'AUTHENTICATION_REQUIRED' USING ERRCODE='28000';
  END IF;
  IF p_room IS NULL OR jsonb_typeof(p_room) <> 'object' THEN
    RAISE EXCEPTION 'ROOM_PAYLOAD_REQUIRED' USING ERRCODE='22023';
  END IF;

  v_lounge_id := NULLIF(p_room->>'lounge_id','')::uuid;
  v_room_id := COALESCE(NULLIF(p_room->>'id','')::uuid, gen_random_uuid());
  IF v_lounge_id IS NULL THEN
    RAISE EXCEPTION 'LOUNGE_ID_REQUIRED' USING ERRCODE='22023';
  END IF;
  IF NOT public.is_super_admin()
     AND NOT public.has_lounge_permission(v_lounge_id,'rooms_manage') THEN
    RAISE EXCEPTION 'NOT_AUTHORIZED' USING ERRCODE='42501';
  END IF;

  SELECT * INTO v_existing
  FROM public.rooms
  WHERE id=v_room_id
  FOR UPDATE;

  IF FOUND AND v_existing.lounge_id IS DISTINCT FROM v_lounge_id THEN
    RAISE EXCEPTION 'ROOM_LOUNGE_MISMATCH' USING ERRCODE='42501';
  END IF;

  v_name := COALESCE(
    NULLIF(btrim(p_room->>'name_en'),''),
    NULLIF(btrim(p_room->>'name_ar'),''),
    NULLIF(btrim(p_room->>'name'),'')
  );
  IF v_name IS NULL THEN
    RAISE EXCEPTION 'ROOM_NAME_REQUIRED' USING ERRCODE='22023';
  END IF;

  IF COALESCE((p_room->>'hourly_rate_single')::numeric,0) < 0
     OR COALESCE((p_room->>'hourly_rate_multi')::numeric,0) < 0
     OR COALESCE((p_room->>'extra_controller_price')::numeric,0) < 0 THEN
    RAISE EXCEPTION 'ROOM_PRICE_INVALID' USING ERRCODE='22023';
  END IF;

  IF COALESCE((p_room->>'max_capacity')::integer,1) < 1 THEN
    RAISE EXCEPTION 'ROOM_CAPACITY_INVALID' USING ERRCODE='22023';
  END IF;

  v_status := lower(COALESCE(NULLIF(btrim(p_room->>'status'),''), 'available'));
  IF v_status NOT IN ('available','occupied','maintenance') THEN
    RAISE EXCEPTION 'ROOM_STATUS_INVALID' USING ERRCODE='22023';
  END IF;

  IF FOUND AND v_status IS DISTINCT FROM v_existing.status THEN
    IF v_status='maintenance' THEN
      IF NOT public.is_super_admin()
         AND NOT public.has_lounge_permission(v_lounge_id,'rooms_manage') THEN
        RAISE EXCEPTION 'NOT_AUTHORIZED' USING ERRCODE='42501';
      END IF;
    ELSE
      IF NOT public.is_super_admin()
         AND NOT public.has_lounge_permission(v_lounge_id,'sessions_control') THEN
        RAISE EXCEPTION 'NOT_AUTHORIZED' USING ERRCODE='42501';
      END IF;
    END IF;
  END IF;

  v_requires_screen := COALESCE((p_room->>'requires_screen')::boolean,true);
  v_requires_controllers := COALESCE((p_room->>'requires_controllers')::boolean,true);
  v_controllers_count := CASE
    WHEN v_requires_controllers THEN GREATEST(COALESCE((p_room->>'controllers_count')::integer,0),0)
    ELSE 0
  END;
  v_screen_size := CASE
    WHEN v_requires_screen THEN NULLIF(btrim(p_room->>'screen_size'),'')
    ELSE NULL
  END;

  INSERT INTO public.rooms(
    id,lounge_id,name,name_ar,name_en,description_ar,description_en,
    space_type_id,max_capacity,hourly_rate_single,hourly_rate_multi,
    extra_controller_price,is_available,images,features_ar,features_en,
    controllers_count,screen_size,resource_type,requires_screen,
    requires_controllers,pricing_model,status,is_active,
    open_time_enabled,open_time_pricing_mode,open_time_custom_hourly_rate,
    open_time_price_multiplier,open_time_minimum_minutes,
    open_time_rounding_minutes,open_time_max_minutes,
    open_time_buffer_before_booking_minutes,updated_at
  )
  VALUES(
    v_room_id,v_lounge_id,v_name,
    NULLIF(p_room->>'name_ar',''),NULLIF(p_room->>'name_en',''),
    NULLIF(p_room->>'description_ar',''),NULLIF(p_room->>'description_en',''),
    NULLIF(p_room->>'space_type_id','')::uuid,
    COALESCE((p_room->>'max_capacity')::integer,4),
    COALESCE((p_room->>'hourly_rate_single')::numeric,0),
    COALESCE((p_room->>'hourly_rate_multi')::numeric,0),
    CASE WHEN v_requires_controllers
      THEN COALESCE((p_room->>'extra_controller_price')::numeric,0)
      ELSE 0 END,
    v_status='available',
    COALESCE(ARRAY(SELECT jsonb_array_elements_text(COALESCE(p_room->'images','[]'::jsonb))),ARRAY[]::text[]),
    COALESCE(ARRAY(SELECT jsonb_array_elements_text(COALESCE(p_room->'features_ar','[]'::jsonb))),ARRAY[]::text[]),
    COALESCE(ARRAY(SELECT jsonb_array_elements_text(COALESCE(p_room->'features_en','[]'::jsonb))),ARRAY[]::text[]),
    v_controllers_count,v_screen_size,
    COALESCE(NULLIF(p_room->>'resource_type',''),'console'),
    v_requires_screen,v_requires_controllers,
    COALESCE(NULLIF(p_room->>'pricing_model',''),'per_room_hour'),
    v_status,true,
    COALESCE((p_room->>'open_time_enabled')::boolean,true),
    COALESCE(NULLIF(p_room->>'open_time_pricing_mode',''),'same_hourly'),
    NULLIF(p_room->>'open_time_custom_hourly_rate','')::numeric,
    COALESCE(NULLIF(p_room->>'open_time_price_multiplier','')::numeric,1),
    COALESCE(NULLIF(p_room->>'open_time_minimum_minutes','')::integer,30),
    COALESCE(NULLIF(p_room->>'open_time_rounding_minutes','')::integer,15),
    NULLIF(p_room->>'open_time_max_minutes','')::integer,
    COALESCE(NULLIF(p_room->>'open_time_buffer_before_booking_minutes','')::integer,15),
    now()
  )
  ON CONFLICT(id) DO UPDATE SET
    name=EXCLUDED.name,
    name_ar=EXCLUDED.name_ar,
    name_en=EXCLUDED.name_en,
    description_ar=EXCLUDED.description_ar,
    description_en=EXCLUDED.description_en,
    space_type_id=EXCLUDED.space_type_id,
    max_capacity=EXCLUDED.max_capacity,
    hourly_rate_single=EXCLUDED.hourly_rate_single,
    hourly_rate_multi=EXCLUDED.hourly_rate_multi,
    extra_controller_price=EXCLUDED.extra_controller_price,
    is_available=EXCLUDED.is_available,
    images=EXCLUDED.images,
    features_ar=EXCLUDED.features_ar,
    features_en=EXCLUDED.features_en,
    controllers_count=EXCLUDED.controllers_count,
    screen_size=EXCLUDED.screen_size,
    resource_type=EXCLUDED.resource_type,
    requires_screen=EXCLUDED.requires_screen,
    requires_controllers=EXCLUDED.requires_controllers,
    pricing_model=EXCLUDED.pricing_model,
    status=EXCLUDED.status,
    open_time_enabled=EXCLUDED.open_time_enabled,
    open_time_pricing_mode=EXCLUDED.open_time_pricing_mode,
    open_time_custom_hourly_rate=EXCLUDED.open_time_custom_hourly_rate,
    open_time_price_multiplier=EXCLUDED.open_time_price_multiplier,
    open_time_minimum_minutes=EXCLUDED.open_time_minimum_minutes,
    open_time_rounding_minutes=EXCLUDED.open_time_rounding_minutes,
    open_time_max_minutes=EXCLUDED.open_time_max_minutes,
    open_time_buffer_before_booking_minutes=EXCLUDED.open_time_buffer_before_booking_minutes,
    updated_at=now();

  DELETE FROM public.room_activities WHERE room_id=v_room_id;
  FOREACH v_activity_id IN ARRAY COALESCE(p_activity_ids,ARRAY[]::uuid[])
  LOOP
    IF NOT EXISTS(SELECT 1 FROM public.activity_types WHERE id=v_activity_id) THEN
      RAISE EXCEPTION 'ACTIVITY_NOT_FOUND' USING ERRCODE='22023';
    END IF;
    INSERT INTO public.room_activities(room_id,activity_type_id)
    VALUES(v_room_id,v_activity_id)
    ON CONFLICT DO NOTHING;
  END LOOP;

  RETURN jsonb_build_object(
    'success',true,
    'room_id',v_room_id,
    'lounge_id',v_lounge_id,
    'activities_count',COALESCE(cardinality(p_activity_ids),0)
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.save_lounge_room_v2(jsonb,uuid[]) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.save_lounge_room_v2(jsonb,uuid[])
TO authenticated,service_role;

CREATE OR REPLACE FUNCTION public.archive_lounge_room(p_room_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_room public.rooms%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'AUTHENTICATION_REQUIRED' USING ERRCODE='28000';
  END IF;

  SELECT * INTO v_room
  FROM public.rooms
  WHERE id=p_room_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'ROOM_NOT_FOUND' USING ERRCODE='P0002';
  END IF;

  IF NOT public.is_super_admin()
     AND NOT public.has_lounge_permission(v_room.lounge_id,'rooms_manage') THEN
    RAISE EXCEPTION 'NOT_AUTHORIZED' USING ERRCODE='42501';
  END IF;

  IF EXISTS(
    SELECT 1 FROM public.bookings b
    WHERE b.room_id=p_room_id AND b.status='in_progress'
  ) THEN
    RAISE EXCEPTION 'ROOM_HAS_ACTIVE_SESSION' USING ERRCODE='55000';
  END IF;

  UPDATE public.rooms
  SET status='deleted',is_available=false,is_active=false,updated_at=now()
  WHERE id=p_room_id;

  RETURN jsonb_build_object(
    'success',true,'room_id',p_room_id,'status','deleted'
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.archive_lounge_room(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.archive_lounge_room(uuid)
TO authenticated,service_role;

COMMIT;
