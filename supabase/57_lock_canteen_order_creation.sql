BEGIN;

CREATE OR REPLACE FUNCTION public.place_canteen_order(
  p_booking_id uuid DEFAULT NULL::uuid,
  p_items jsonb DEFAULT '[]'::jsonb,
  p_note text DEFAULT NULL::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_actor uuid := auth.uid();
  v_booking public.bookings%ROWTYPE;
  v_shift_id uuid;
  v_lounge_id uuid;
  v_shift_count integer;
  v_order_id uuid;
  v_note text := NULLIF(btrim(p_note), '');
  v_item jsonb;
  v_extra_id uuid;
  v_quantity integer;
  v_extra record;
  v_line_total numeric;
  v_total numeric := 0;
  v_items jsonb := '[]'::jsonb;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  IF p_items IS NULL
     OR jsonb_typeof(p_items) <> 'array'
     OR jsonb_array_length(p_items) < 1
     OR jsonb_array_length(p_items) > 50 THEN
    RAISE EXCEPTION 'Items must be a JSON array containing 1 to 50 entries'
      USING ERRCODE = '22023';
  END IF;

  IF v_note IS NOT NULL AND length(v_note) > 1000 THEN
    RAISE EXCEPTION 'Order note is too long' USING ERRCODE = '22023';
  END IF;

  IF p_booking_id IS NOT NULL THEN
    SELECT b.*
    INTO v_booking
    FROM public.bookings AS b
    WHERE b.id = p_booking_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Booking not found' USING ERRCODE = 'P0002';
    END IF;

    IF v_booking.lounge_id IS NULL THEN
      RAISE EXCEPTION 'Booking has no lounge' USING ERRCODE = '55000';
    END IF;

    IF v_booking.status NOT IN (
      'pending'::public.booking_status,
      'upcoming'::public.booking_status,
      'in_progress'::public.booking_status
    ) THEN
      RAISE EXCEPTION 'Canteen orders are not allowed for this booking status'
        USING ERRCODE = '55000';
    END IF;

    IF v_actor IS DISTINCT FROM v_booking.user_id
       AND NOT private.can_operate_playspot_lounge(v_booking.lounge_id) THEN
      RAISE EXCEPTION 'Not authorized to order for this booking'
        USING ERRCODE = '42501';
    END IF;

    v_lounge_id := v_booking.lounge_id;
  ELSE
    SELECT count(*),
           (array_agg(s.id ORDER BY s.opened_at DESC))[1],
           (array_agg(s.lounge_id ORDER BY s.opened_at DESC))[1]
    INTO v_shift_count, v_shift_id, v_lounge_id
    FROM public.shifts AS s
    WHERE s.status = 'open'
      AND s.cashier_id = v_actor;

    IF v_shift_count <> 1 THEN
      RAISE EXCEPTION 'A single open cashier shift is required for a counter sale'
        USING ERRCODE = '55000';
    END IF;
  END IF;

  FOR v_item IN
    SELECT e.value
    FROM jsonb_array_elements(p_items) AS e(value)
    ORDER BY e.value->>'extra_id'
  LOOP
    IF jsonb_typeof(v_item) <> 'object'
       OR NULLIF(v_item->>'extra_id', '') IS NULL THEN
      RAISE EXCEPTION 'Each item must contain extra_id and quantity'
        USING ERRCODE = '22023';
    END IF;

    BEGIN
      v_extra_id := (v_item->>'extra_id')::uuid;
      v_quantity := (v_item->>'quantity')::integer;
    EXCEPTION
      WHEN invalid_text_representation OR numeric_value_out_of_range THEN
        RAISE EXCEPTION 'Invalid extra_id or quantity'
          USING ERRCODE = '22023';
    END;

    IF v_quantity < 1 OR v_quantity > 100 THEN
      RAISE EXCEPTION 'Quantity must be between 1 and 100'
        USING ERRCODE = '22023';
    END IF;

    UPDATE public.extras AS e
    SET stock_quantity = CASE
          WHEN e.track_stock IS TRUE
            THEN COALESCE(e.stock_quantity, 0) - v_quantity
          ELSE e.stock_quantity
        END
    WHERE e.id = v_extra_id
      AND e.lounge_id = v_lounge_id
      AND e.is_active IS TRUE
      AND e.is_available IS TRUE
      AND (
        e.track_stock IS NOT TRUE
        OR COALESCE(e.stock_quantity, 0) >= v_quantity
      )
    RETURNING
      e.price,
      e.name,
      e.name_ar,
      e.name_en,
      e.track_stock
    INTO v_extra;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Extra unavailable or insufficient tracked stock: %', v_extra_id
        USING ERRCODE = '23514';
    END IF;

    IF v_extra.price IS NULL OR v_extra.price < 0 THEN
      RAISE EXCEPTION 'Extra has an invalid price'
        USING ERRCODE = '23514';
    END IF;

    v_line_total := v_extra.price * v_quantity;
    v_total := v_total + v_line_total;

    v_items := v_items || jsonb_build_array(
      jsonb_build_object(
        'extra_id', v_extra_id,
        'product_id', v_extra_id,
        'name', COALESCE(v_extra.name_ar, v_extra.name_en, v_extra.name),
        'quantity', v_quantity,
        'unit_price', v_extra.price,
        'total_price', v_line_total
      )
    );
  END LOOP;

  INSERT INTO public.canteen_orders (
    booking_id,
    lounge_id,
    user_id,
    shift_id,
    items,
    total_price,
    status,
    note,
    notes,
    created_at,
    updated_at
  )
  VALUES (
    p_booking_id,
    v_lounge_id,
    CASE
      WHEN p_booking_id IS NULL THEN v_actor
      ELSE COALESCE(v_booking.user_id, v_actor)
    END,
    v_shift_id,
    v_items,
    v_total,
    'pending',
    v_note,
    v_note,
    now(),
    now()
  )
  RETURNING id INTO v_order_id;

  FOR v_item IN
    SELECT e.value
    FROM jsonb_array_elements(v_items) AS e(value)
  LOOP
    INSERT INTO public.canteen_order_items (
      order_id,
      extra_id,
      item_name,
      quantity,
      unit_price,
      total_price,
      created_at
    )
    VALUES (
      v_order_id,
      (v_item->>'extra_id')::uuid,
      v_item->>'name',
      (v_item->>'quantity')::integer,
      (v_item->>'unit_price')::numeric,
      (v_item->>'total_price')::numeric,
      now()
    );

    IF p_booking_id IS NOT NULL THEN
      INSERT INTO public.booking_items (
        booking_id,
        product_id,
        extra_id,
        quantity,
        unit_price,
        total_price,
        price,
        name,
        status,
        created_at
      )
      VALUES (
        p_booking_id,
        (v_item->>'extra_id')::uuid,
        (v_item->>'extra_id')::uuid,
        (v_item->>'quantity')::integer,
        (v_item->>'unit_price')::numeric,
        (v_item->>'total_price')::numeric,
        (v_item->>'unit_price')::numeric,
        v_item->>'name',
        'pending',
        now()
      );
    END IF;
  END LOOP;

  IF p_booking_id IS NOT NULL THEN
    UPDATE public.bookings AS b
    SET addons_price = COALESCE(b.addons_price, 0) + v_total,
        total_price = GREATEST(
          0::numeric,
          b.room_price
            + COALESCE(b.addons_price, 0)
            + v_total
            - COALESCE(b.discount_amount, 0)
        ),
        updated_at = now()
    WHERE b.id = p_booking_id;
  ELSE
    INSERT INTO public.shift_payments (
      shift_id,
      lounge_id,
      payment_method,
      category,
      amount,
      paid_at,
      created_at,
      canteen_order_id
    )
    VALUES (
      v_shift_id,
      v_lounge_id,
      'cash',
      'other',
      v_total,
      now(),
      now(),
      v_order_id
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'order_id', v_order_id,
    'lounge_id', v_lounge_id,
    'shift_id', v_shift_id,
    'total_price', v_total
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.place_canteen_order(uuid, jsonb, text)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.place_canteen_order(uuid, jsonb, text)
TO authenticated, service_role, supabase_auth_admin;

DROP POLICY IF EXISTS "canteen_orders_policy" ON public.canteen_orders;

COMMIT;
