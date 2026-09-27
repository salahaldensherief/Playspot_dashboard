BEGIN;

CREATE OR REPLACE FUNCTION public.calculate_booking_total(
  p_room_id uuid,
  p_duration_hours numeric,
  p_voucher_code text DEFAULT NULL,
  p_manual_discount numeric DEFAULT 0,
  p_manual_discount_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_room public.rooms%ROWTYPE;
  v_base_subtotal numeric;
  v_voucher_discount numeric := 0;
  v_staff_discount numeric := COALESCE(p_manual_discount, 0);
  v_final_total numeric;
  v_voucher_res jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE='28000';
  END IF;

  IF p_duration_hours IS NULL OR p_duration_hours <= 0 THEN
    RAISE EXCEPTION 'Invalid duration' USING ERRCODE='22023';
  END IF;

  IF v_staff_discount < 0 THEN
    RAISE EXCEPTION 'Invalid manual discount' USING ERRCODE='22023';
  END IF;

  SELECT *
  INTO v_room
  FROM public.rooms
  WHERE id = p_room_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Room not found' USING ERRCODE='P0002';
  END IF;

  IF NOT public.has_lounge_permission(v_room.lounge_id, 'billing_checkout') THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE='42501';
  END IF;

  IF v_staff_discount > 0
     AND NOT public.has_lounge_permission(v_room.lounge_id, 'billing_apply_discount') THEN
    RAISE EXCEPTION 'Discount permission required' USING ERRCODE='42501';
  END IF;

  IF v_staff_discount > 0
     AND NULLIF(btrim(COALESCE(p_manual_discount_reason, '')), '') IS NULL THEN
    RAISE EXCEPTION 'Manual discount reason required' USING ERRCODE='22023';
  END IF;

  v_base_subtotal := COALESCE(v_room.hourly_rate_single, 0) * p_duration_hours;

  IF p_voucher_code IS NOT NULL AND btrim(p_voucher_code) <> '' THEN
    v_voucher_res := public.validate_voucher_by_code(p_voucher_code);
    IF COALESCE((v_voucher_res->>'valid')::boolean, false) THEN
      IF (v_voucher_res->>'reward_type') = 'discount_fixed' THEN
        v_voucher_discount := COALESCE((v_voucher_res->>'reward_value')::numeric, 0);
      ELSIF (v_voucher_res->>'reward_type') = 'free_hour' THEN
        v_voucher_discount :=
          COALESCE(v_room.hourly_rate_single, 0)
          * COALESCE((v_voucher_res->>'reward_value')::numeric, 0);
      END IF;
    END IF;
  END IF;

  v_final_total := GREATEST(
    0,
    v_base_subtotal - v_voucher_discount - v_staff_discount
  );

  RETURN jsonb_build_object(
    'base_subtotal', v_base_subtotal,
    'voucher_discount', v_voucher_discount,
    'staff_manual_discount', v_staff_discount,
    'manual_discount_reason', p_manual_discount_reason,
    'final_total', v_final_total
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.calculate_booking_total(
  uuid, numeric, text, numeric, text
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.calculate_booking_total(
  uuid, numeric, text, numeric, text
) TO authenticated, service_role;

COMMIT;
