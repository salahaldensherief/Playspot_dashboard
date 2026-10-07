BEGIN;

ALTER TABLE public.canteen_upsell_events
  ADD COLUMN IF NOT EXISTS canteen_order_id uuid
  REFERENCES public.canteen_orders(id) ON DELETE SET NULL;

ALTER TABLE public.canteen_upsell_events
  DROP CONSTRAINT IF EXISTS canteen_upsell_events_event_type_check;

ALTER TABLE public.canteen_upsell_events
  ADD CONSTRAINT canteen_upsell_events_event_type_check
  CHECK (event_type IN ('shown','dismissed','accepted','impression','conversion'));

CREATE INDEX IF NOT EXISTS canteen_upsell_events_booking_rule_idx
  ON public.canteen_upsell_events(booking_id, rule_id, event_type);

CREATE OR REPLACE VIEW public.canteen_upsell_conversion_v
WITH (security_invoker = true)
AS
SELECT
  r.lounge_id,
  r.id AS rule_id,
  r.trigger_type,
  count(e.id) FILTER (
    WHERE e.event_type IN ('shown','impression')
  )::bigint AS impressions,
  count(e.id) FILTER (
    WHERE e.event_type IN ('accepted','conversion')
  )::bigint AS conversions,
  CASE
    WHEN count(e.id) FILTER (
      WHERE e.event_type IN ('shown','impression')
    ) = 0 THEN 0::numeric
    ELSE round(
      100.0
      * count(e.id) FILTER (
          WHERE e.event_type IN ('accepted','conversion')
        )
      / count(e.id) FILTER (
          WHERE e.event_type IN ('shown','impression')
        ),
      2
    )
  END AS conversion_rate_percent,
  COALESCE(
    sum(e.revenue_generated) FILTER (
      WHERE e.event_type IN ('accepted','conversion')
    ),
    0
  )::numeric AS revenue_generated
FROM public.upsell_rules AS r
LEFT JOIN public.canteen_upsell_events AS e
  ON e.rule_id = r.id
GROUP BY r.lounge_id, r.id, r.trigger_type;

CREATE OR REPLACE FUNCTION public.get_canteen_menu(p_lounge_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_now timestamp := timezone('Africa/Cairo', now());
  v_dow integer := extract(dow from timezone('Africa/Cairo', now()))::integer;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE='28000';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.lounges AS l
    WHERE l.id = p_lounge_id
      AND COALESCE(l.is_active,true) IS TRUE
      AND COALESCE(l.status,'active') <> 'deleted'
  ) THEN
    RAISE EXCEPTION 'Lounge not found' USING ERRCODE='P0002';
  END IF;

  RETURN jsonb_build_object(
    'extras',
    COALESCE((
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', e.id,
          'lounge_id', e.lounge_id,
          'name', e.name,
          'name_ar', e.name_ar,
          'name_en', e.name_en,
          'price', e.price,
          'category', e.category,
          'icon_key', e.icon_key,
          'image_url', e.image_url,
          'is_available', COALESCE(e.is_available,true)
            AND (
              COALESCE(e.track_stock,false) IS FALSE
              OR COALESCE(e.stock_quantity,0) > 0
            ),
          'stock_quantity', COALESCE(e.stock_quantity,0),
          'track_stock', COALESCE(e.track_stock,false),
          'min_stock_alert', COALESCE(e.min_stock_alert,5)
        )
        ORDER BY e.category, COALESCE(e.name_en,e.name_ar,e.name)
      )
      FROM public.extras AS e
      WHERE e.lounge_id = p_lounge_id
        AND COALESCE(e.is_active,true) IS TRUE
        AND COALESCE(e.is_available,true) IS TRUE
    ), '[]'::jsonb),
    'combos',
    COALESCE((
      SELECT jsonb_agg(combo_payload ORDER BY sort_order, name_ar)
      FROM (
        SELECT
          c.sort_order,
          c.name_ar,
          jsonb_build_object(
            'id', c.id,
            'name_ar', c.name_ar,
            'name_en', c.name_en,
            'description_ar', c.description_ar,
            'description_en', c.description_en,
            'price', c.price,
            'image_url', c.image_url,
            'separate_items_price', COALESCE((
              SELECT sum(e.price * ci.quantity)
              FROM public.canteen_combo_items AS ci
              JOIN public.extras AS e ON e.id = ci.extra_id
              WHERE ci.combo_id = c.id
            ),0),
            'savings', GREATEST(
              0,
              COALESCE((
                SELECT sum(e.price * ci.quantity)
                FROM public.canteen_combo_items AS ci
                JOIN public.extras AS e ON e.id = ci.extra_id
                WHERE ci.combo_id = c.id
              ),0) - c.price
            ),
            'is_available',
              COALESCE(c.is_active,true)
              AND (c.valid_from IS NULL OR v_now::date >= c.valid_from)
              AND (c.valid_to IS NULL OR v_now::date <= c.valid_to)
              AND (c.days_of_week IS NULL OR v_dow = ANY(c.days_of_week))
              AND (
                c.available_from IS NULL
                OR c.available_to IS NULL
                OR CASE
                  WHEN c.available_to > c.available_from
                    THEN v_now::time >= c.available_from
                     AND v_now::time < c.available_to
                  ELSE v_now::time >= c.available_from
                    OR v_now::time < c.available_to
                END
              )
              AND NOT EXISTS (
                SELECT 1
                FROM public.canteen_combo_items AS ci
                JOIN public.extras AS e ON e.id = ci.extra_id
                WHERE ci.combo_id = c.id
                  AND (
                    COALESCE(e.is_active,true) IS FALSE
                    OR COALESCE(e.is_available,true) IS FALSE
                    OR (
                      COALESCE(e.track_stock,false) IS TRUE
                      AND COALESCE(e.stock_quantity,0) < ci.quantity
                    )
                  )
              ),
            'items', COALESCE((
              SELECT jsonb_agg(
                jsonb_build_object(
                  'extra_id', e.id,
                  'name_ar', COALESCE(e.name_ar,e.name),
                  'name_en', COALESCE(e.name_en,e.name),
                  'price', e.price,
                  'quantity', ci.quantity
                )
                ORDER BY COALESCE(e.name_en,e.name_ar,e.name)
              )
              FROM public.canteen_combo_items AS ci
              JOIN public.extras AS e ON e.id = ci.extra_id
              WHERE ci.combo_id = c.id
            ), '[]'::jsonb)
          ) AS combo_payload
        FROM public.canteen_combos AS c
        WHERE c.lounge_id = p_lounge_id
          AND COALESCE(c.is_active,true) IS TRUE
          AND (c.valid_from IS NULL OR v_now::date >= c.valid_from)
          AND (c.valid_to IS NULL OR v_now::date <= c.valid_to)
          AND (c.days_of_week IS NULL OR v_dow = ANY(c.days_of_week))
      ) AS q
    ), '[]'::jsonb)
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_upsell_suggestions(p_booking_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_booking public.bookings%ROWTYPE;
  v_now timestamp := timezone('Africa/Cairo', now());
  v_start_at timestamp;
  v_elapsed_minutes integer;
  v_result jsonb := '[]'::jsonb;
  v_rule public.upsell_rules%ROWTYPE;
  v_trigger_ok boolean;
  v_target_type text;
  v_target_id uuid;
  v_name_ar text;
  v_name_en text;
  v_image_url text;
  v_original_price numeric;
  v_discount numeric;
  v_final_price numeric;
  v_start_time time;
  v_end_time time;
  v_category text;
  v_minutes integer;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE='28000';
  END IF;

  SELECT b.*
  INTO v_booking
  FROM public.bookings AS b
  WHERE b.id = p_booking_id
    AND b.user_id = auth.uid();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found' USING ERRCODE='P0002';
  END IF;

  IF v_booking.status <> 'in_progress'::public.booking_status THEN
    RETURN '[]'::jsonb;
  END IF;

  v_start_at := v_booking.date + v_booking.start_time;
  v_elapsed_minutes := GREATEST(
    0,
    floor(extract(epoch FROM (v_now - v_start_at))/60.0)::integer
  );

  FOR v_rule IN
    SELECT r.*
    FROM public.upsell_rules AS r
    WHERE r.lounge_id = v_booking.lounge_id
      AND r.is_active IS TRUE
      AND (
        SELECT count(*)
        FROM public.canteen_upsell_events AS ev
        WHERE ev.rule_id = r.id
          AND ev.booking_id = p_booking_id
          AND ev.event_type IN ('shown','impression')
      ) < r.max_impressions_per_booking
    ORDER BY r.priority DESC, r.created_at ASC
  LOOP
    v_trigger_ok := false;

    CASE v_rule.trigger_type
      WHEN 'session_minutes_elapsed' THEN
        BEGIN
          v_minutes := COALESCE((v_rule.trigger_params->>'minutes')::integer,45);
        EXCEPTION WHEN OTHERS THEN
          v_minutes := 45;
        END;
        v_trigger_ok := v_elapsed_minutes >= GREATEST(0,v_minutes);

      WHEN 'session_start' THEN
        v_trigger_ok := v_elapsed_minutes BETWEEN 0 AND 15;

      WHEN 'time_of_day' THEN
        BEGIN
          v_start_time := COALESCE(
            NULLIF(v_rule.trigger_params->>'start_time','')::time,
            '00:00'::time
          );
          v_end_time := COALESCE(
            NULLIF(v_rule.trigger_params->>'end_time','')::time,
            '23:59:59'::time
          );
        EXCEPTION WHEN OTHERS THEN
          v_start_time := '00:00'::time;
          v_end_time := '23:59:59'::time;
        END;
        v_trigger_ok := CASE
          WHEN v_end_time > v_start_time
            THEN v_now::time >= v_start_time AND v_now::time < v_end_time
          ELSE v_now::time >= v_start_time OR v_now::time < v_end_time
        END;

      WHEN 'cart_contains_category' THEN
        v_category := lower(btrim(COALESCE(
          v_rule.trigger_params->>'category',''
        )));
        v_trigger_ok := v_category <> ''
          AND EXISTS (
            SELECT 1
            FROM public.canteen_orders AS co
            JOIN public.canteen_order_items AS coi ON coi.order_id = co.id
            JOIN public.extras AS e ON e.id = coi.extra_id
            WHERE co.booking_id = p_booking_id
              AND lower(btrim(e.category)) = v_category
          );

      ELSE
        v_trigger_ok := false;
    END CASE;

    IF NOT v_trigger_ok THEN
      CONTINUE;
    END IF;

    IF v_rule.suggest_combo_id IS NOT NULL THEN
      SELECT
        'combo',
        c.id,
        c.name_ar,
        c.name_en,
        c.image_url,
        c.price
      INTO
        v_target_type,
        v_target_id,
        v_name_ar,
        v_name_en,
        v_image_url,
        v_original_price
      FROM public.canteen_combos AS c
      WHERE c.id = v_rule.suggest_combo_id
        AND c.lounge_id = v_booking.lounge_id
        AND c.is_active IS TRUE
        AND (c.valid_from IS NULL OR v_now::date >= c.valid_from)
        AND (c.valid_to IS NULL OR v_now::date <= c.valid_to)
        AND NOT EXISTS (
          SELECT 1
          FROM public.canteen_combo_items AS ci
          JOIN public.extras AS e ON e.id = ci.extra_id
          WHERE ci.combo_id = c.id
            AND (
              COALESCE(e.is_active,true) IS FALSE
              OR COALESCE(e.is_available,true) IS FALSE
              OR (
                COALESCE(e.track_stock,false) IS TRUE
                AND COALESCE(e.stock_quantity,0) < ci.quantity
              )
            )
        );
    ELSE
      SELECT
        'extra',
        e.id,
        COALESCE(e.name_ar,e.name),
        COALESCE(e.name_en,e.name),
        e.image_url,
        e.price
      INTO
        v_target_type,
        v_target_id,
        v_name_ar,
        v_name_en,
        v_image_url,
        v_original_price
      FROM public.extras AS e
      WHERE e.id = v_rule.suggest_extra_id
        AND e.lounge_id = v_booking.lounge_id
        AND COALESCE(e.is_active,true) IS TRUE
        AND COALESCE(e.is_available,true) IS TRUE
        AND (
          COALESCE(e.track_stock,false) IS FALSE
          OR COALESCE(e.stock_quantity,0) > 0
        );
    END IF;

    IF v_target_id IS NULL THEN
      CONTINUE;
    END IF;

    v_discount := LEAST(
      100,
      GREATEST(0,COALESCE(v_rule.discount_percent,0))
    );
    v_final_price := round(
      GREATEST(0,v_original_price * (1 - v_discount/100.0)),
      2
    );

    v_result := v_result || jsonb_build_array(
      jsonb_build_object(
        'rule_id', v_rule.id,
        'suggestion_type', v_target_type,
        'target_id', v_target_id,
        'name_ar', v_name_ar,
        'name_en', v_name_en,
        'original_price', v_original_price,
        'discount_percent', v_discount,
        'final_price', v_final_price,
        'image_url', v_image_url
      )
    );

    v_target_id := NULL;
  END LOOP;

  RETURN v_result;
END;
$function$;

CREATE OR REPLACE FUNCTION public.record_upsell_event(
  p_rule_id uuid,
  p_booking_id uuid,
  p_event text,
  p_canteen_order_id uuid DEFAULT NULL,
  p_amount numeric DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_booking public.bookings%ROWTYPE;
  v_rule public.upsell_rules%ROWTYPE;
  v_event text := lower(btrim(COALESCE(p_event,'')));
  v_amount numeric := GREATEST(0,COALESCE(p_amount,0));
  v_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE='28000';
  END IF;

  IF v_event NOT IN ('shown','dismissed','accepted','impression','conversion') THEN
    RAISE EXCEPTION 'Unsupported upsell event' USING ERRCODE='22023';
  END IF;

  SELECT b.*
  INTO v_booking
  FROM public.bookings AS b
  WHERE b.id = p_booking_id
    AND b.user_id = auth.uid();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found' USING ERRCODE='P0002';
  END IF;

  SELECT r.*
  INTO v_rule
  FROM public.upsell_rules AS r
  WHERE r.id = p_rule_id
    AND r.lounge_id = v_booking.lounge_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Upsell rule not found' USING ERRCODE='P0002';
  END IF;

  IF p_canteen_order_id IS NOT NULL
     AND NOT EXISTS (
       SELECT 1
       FROM public.canteen_orders AS co
       WHERE co.id = p_canteen_order_id
         AND co.booking_id = p_booking_id
         AND co.user_id = auth.uid()
     ) THEN
    RAISE EXCEPTION 'Canteen order mismatch' USING ERRCODE='23514';
  END IF;

  INSERT INTO public.canteen_upsell_events (
    lounge_id,
    rule_id,
    booking_id,
    canteen_order_id,
    event_type,
    revenue_generated
  )
  VALUES (
    v_booking.lounge_id,
    p_rule_id,
    p_booking_id,
    p_canteen_order_id,
    v_event,
    CASE
      WHEN v_event IN ('accepted','conversion') THEN v_amount
      ELSE 0
    END
  )
  RETURNING id INTO v_id;

  RETURN jsonb_build_object(
    'success',true,
    'event_id',v_id,
    'event_type',v_event
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.save_canteen_combo(
  p_combo jsonb,
  p_items jsonb DEFAULT '[]'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_id uuid;
  v_lounge_id uuid;
  v_item jsonb;
  v_extra_id uuid;
  v_quantity integer;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE='28000';
  END IF;

  BEGIN
    v_id := NULLIF(p_combo->>'id','')::uuid;
    v_lounge_id := NULLIF(p_combo->>'lounge_id','')::uuid;
  EXCEPTION WHEN invalid_text_representation THEN
    RAISE EXCEPTION 'Invalid combo identifier' USING ERRCODE='22023';
  END;

  IF v_lounge_id IS NULL THEN
    RAISE EXCEPTION 'Lounge is required' USING ERRCODE='22023';
  END IF;

  IF NOT (
    public.is_super_admin()
    OR public.has_lounge_permission(v_lounge_id,'menu_manage_items')
  ) THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE='42501';
  END IF;

  IF COALESCE((p_combo->>'price')::numeric,-1) < 0 THEN
    RAISE EXCEPTION 'Invalid combo price' USING ERRCODE='22023';
  END IF;

  IF NULLIF(btrim(COALESCE(p_combo->>'name_ar','')),'') IS NULL THEN
    RAISE EXCEPTION 'Arabic combo name is required' USING ERRCODE='22023';
  END IF;

  IF p_items IS NULL OR jsonb_typeof(p_items) <> 'array' THEN
    RAISE EXCEPTION 'Combo items must be an array' USING ERRCODE='22023';
  END IF;

  IF v_id IS NULL THEN
    INSERT INTO public.canteen_combos (
      lounge_id,name_ar,name_en,description_ar,description_en,image_url,
      price,days_of_week,available_from,available_to,valid_from,valid_to,
      is_active,sort_order
    )
    VALUES (
      v_lounge_id,
      btrim(p_combo->>'name_ar'),
      NULLIF(btrim(COALESCE(p_combo->>'name_en','')),''),
      NULLIF(btrim(COALESCE(p_combo->>'description_ar','')),''),
      NULLIF(btrim(COALESCE(p_combo->>'description_en','')),''),
      NULLIF(btrim(COALESCE(p_combo->>'image_url','')),''),
      (p_combo->>'price')::numeric,
      CASE
        WHEN p_combo ? 'days_of_week'
          AND p_combo->'days_of_week' IS NOT NULL
        THEN ARRAY(
          SELECT jsonb_array_elements_text(p_combo->'days_of_week')::integer
        )
        ELSE NULL
      END,
      NULLIF(p_combo->>'available_from','')::time,
      NULLIF(p_combo->>'available_to','')::time,
      NULLIF(p_combo->>'valid_from','')::date,
      NULLIF(p_combo->>'valid_to','')::date,
      COALESCE((p_combo->>'is_active')::boolean,true),
      COALESCE((p_combo->>'sort_order')::integer,0)
    )
    RETURNING id INTO v_id;
  ELSE
    UPDATE public.canteen_combos AS c
    SET
      name_ar=btrim(p_combo->>'name_ar'),
      name_en=NULLIF(btrim(COALESCE(p_combo->>'name_en','')),''),
      description_ar=NULLIF(btrim(COALESCE(p_combo->>'description_ar','')),''),
      description_en=NULLIF(btrim(COALESCE(p_combo->>'description_en','')),''),
      image_url=NULLIF(btrim(COALESCE(p_combo->>'image_url','')),''),
      price=(p_combo->>'price')::numeric,
      days_of_week=CASE
        WHEN p_combo ? 'days_of_week'
          AND p_combo->'days_of_week' IS NOT NULL
        THEN ARRAY(
          SELECT jsonb_array_elements_text(p_combo->'days_of_week')::integer
        )
        ELSE NULL
      END,
      available_from=NULLIF(p_combo->>'available_from','')::time,
      available_to=NULLIF(p_combo->>'available_to','')::time,
      valid_from=NULLIF(p_combo->>'valid_from','')::date,
      valid_to=NULLIF(p_combo->>'valid_to','')::date,
      is_active=COALESCE((p_combo->>'is_active')::boolean,true),
      sort_order=COALESCE((p_combo->>'sort_order')::integer,0),
      updated_at=now()
    WHERE c.id=v_id
      AND c.lounge_id=v_lounge_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Combo not found' USING ERRCODE='P0002';
    END IF;
  END IF;

  DELETE FROM public.canteen_combo_items WHERE combo_id=v_id;

  FOR v_item IN SELECT value FROM jsonb_array_elements(p_items)
  LOOP
    BEGIN
      v_extra_id := NULLIF(v_item->>'extra_id','')::uuid;
      v_quantity := COALESCE((v_item->>'quantity')::integer,1);
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'Invalid combo item' USING ERRCODE='22023';
    END;

    IF v_extra_id IS NULL OR v_quantity < 1 THEN
      RAISE EXCEPTION 'Invalid combo item' USING ERRCODE='22023';
    END IF;

    IF NOT EXISTS (
      SELECT 1
      FROM public.extras AS e
      WHERE e.id=v_extra_id
        AND e.lounge_id=v_lounge_id
        AND COALESCE(e.is_active,true) IS TRUE
    ) THEN
      RAISE EXCEPTION 'Combo item does not belong to lounge'
        USING ERRCODE='23514';
    END IF;

    INSERT INTO public.canteen_combo_items(combo_id,extra_id,quantity)
    VALUES(v_id,v_extra_id,v_quantity);
  END LOOP;

  RETURN (
    SELECT to_jsonb(c)
      || jsonb_build_object(
        'items', COALESCE((
          SELECT jsonb_agg(
            jsonb_build_object(
              'extra_id',e.id,
              'name_ar',COALESCE(e.name_ar,e.name),
              'name_en',COALESCE(e.name_en,e.name),
              'price',e.price,
              'quantity',ci.quantity
            )
          )
          FROM public.canteen_combo_items AS ci
          JOIN public.extras AS e ON e.id=ci.extra_id
          WHERE ci.combo_id=c.id
        ),'[]'::jsonb)
      )
    FROM public.canteen_combos AS c
    WHERE c.id=v_id
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.get_canteen_menu(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.get_upsell_suggestions(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.record_upsell_event(uuid,uuid,text,uuid,numeric)
  FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.save_canteen_combo(jsonb,jsonb)
  FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.get_canteen_menu(uuid)
  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_upsell_suggestions(uuid)
  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.record_upsell_event(uuid,uuid,text,uuid,numeric)
  TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.save_canteen_combo(jsonb,jsonb)
  TO authenticated, service_role;

COMMIT;