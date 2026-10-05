-- Migration: 20261005122000_remove_pos_payment_method_from_rpc.sql
-- Description: Align complete_booking_payment with database check constraints by removing 'pos'
--              from allowed payment methods. 'pos' is not a valid payment_method in bookings,
--              payments, or shift_payments check constraints.

CREATE OR REPLACE FUNCTION public.complete_booking_payment(
  p_booking_id uuid,
  p_payment_method text DEFAULT 'cash'::text,
  p_final_amount numeric DEFAULT NULL::numeric
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_booking public.bookings%ROWTYPE;
  v_amount numeric;
  v_commission numeric;
  v_shift_id uuid;
  v_new_status public.booking_status;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  -- Validate against canonical payment methods matching table CHECK constraints
  IF p_payment_method IS NULL OR p_payment_method NOT IN (
    'cash','manual_transfer','card','vodafone_cash','fawry','instapay','app_wallet'
  ) THEN
    RAISE EXCEPTION 'Invalid payment method' USING ERRCODE = '22023';
  END IF;

  SELECT b.*
  INTO v_booking
  FROM public.bookings AS b
  WHERE b.id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found' USING ERRCODE = 'P0002';
  END IF;

  -- Verify billing_checkout permission rather than mere lounge membership
  IF NOT public.is_super_admin()
     AND NOT public.has_lounge_permission(v_booking.lounge_id, 'billing_checkout') THEN
    RAISE EXCEPTION 'Not authorized for billing checkout in this lounge' USING ERRCODE = '42501';
  END IF;

  -- Idempotency check: if already marked paid, return success without duplicate entries
  IF v_booking.payment_status = 'paid' THEN
    RETURN jsonb_build_object(
      'success', true,
      'booking_id', p_booking_id,
      'room_id', v_booking.room_id,
      'status', v_booking.status::text,
      'amount_paid', v_booking.total_price,
      'payment_method', v_booking.payment_method,
      'idempotent', true
    );
  END IF;

  IF v_booking.status::text IN ('cancelled', 'rejected') THEN
    RAISE EXCEPTION 'Cannot collect payment for a cancelled or rejected booking' USING ERRCODE = '55000';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.payments AS p
    WHERE p.booking_id = p_booking_id AND p.status = 'refunded'
  ) THEN
    RAISE EXCEPTION 'A refunded payment cannot be completed again through this RPC' USING ERRCODE = '55000';
  END IF;

  IF v_booking.total_price IS NULL OR v_booking.total_price < 0 THEN
    RAISE EXCEPTION 'Booking has an invalid server-calculated total' USING ERRCODE = '22023';
  END IF;

  IF p_final_amount IS NOT NULL AND round(p_final_amount, 2) <> round(v_booking.total_price, 2) THEN
    RAISE EXCEPTION 'Payment amount must match the booking total; update an approved discount before collecting'
      USING ERRCODE = '22023';
  END IF;

  v_amount := round(v_booking.total_price, 2);
  v_commission := round(v_amount * 0.15, 2);

  -- Mandatory active shift for the same lounge
  SELECT s.id
  INTO v_shift_id
  FROM public.shifts AS s
  WHERE s.lounge_id = v_booking.lounge_id
    AND s.status = 'open'
    AND s.closed_at IS NULL
  ORDER BY s.opened_at DESC
  LIMIT 1
  FOR SHARE;

  IF v_shift_id IS NULL THEN
    RAISE EXCEPTION 'An open shift is required to collect payment' USING ERRCODE = '55000';
  END IF;

  -- Status preservation: never downgrade a completed session
  IF v_booking.status = 'completed'::public.booking_status THEN
    v_new_status := 'completed'::public.booking_status;
  ELSIF v_booking.status = 'in_progress'::public.booking_status THEN
    v_new_status := 'in_progress'::public.booking_status;
  ELSE
    v_new_status := 'upcoming'::public.booking_status;
  END IF;

  -- Atomic payment recording
  INSERT INTO public.payments (
    booking_id, user_id, lounge_id, amount, commission, net_to_lounge,
    payment_method, status, paid_at, discount_amount, discount_percentage,
    discount_reason, discount_approved_by
  ) VALUES (
    p_booking_id, v_booking.user_id, v_booking.lounge_id, v_amount,
    v_commission, v_amount - v_commission, p_payment_method, 'completed', now(),
    COALESCE(v_booking.discount_amount, 0), COALESCE(v_booking.discount_percentage, 0),
    v_booking.discount_reason, v_booking.discount_approved_by
  )
  ON CONFLICT (booking_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    lounge_id = EXCLUDED.lounge_id,
    amount = EXCLUDED.amount,
    commission = EXCLUDED.commission,
    net_to_lounge = EXCLUDED.net_to_lounge,
    payment_method = EXCLUDED.payment_method,
    status = 'completed',
    paid_at = EXCLUDED.paid_at,
    discount_amount = EXCLUDED.discount_amount,
    discount_percentage = EXCLUDED.discount_percentage,
    discount_reason = EXCLUDED.discount_reason,
    discount_approved_by = EXCLUDED.discount_approved_by;

  -- Record shift payment atomically
  INSERT INTO public.shift_payments (
    shift_id, lounge_id, booking_id, payment_method, category, amount, paid_at
  ) VALUES (
    v_shift_id, v_booking.lounge_id, p_booking_id, p_payment_method, 'gaming_time', v_amount, now()
  );

  -- Update booking atomically
  UPDATE public.bookings AS b
  SET status = v_new_status,
      payment_status = 'paid',
      payment_method = p_payment_method,
      total_price = v_amount,
      shift_id = v_shift_id,
      updated_at = now()
  WHERE b.id = p_booking_id;

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', p_booking_id,
    'room_id', v_booking.room_id,
    'status', v_new_status::text,
    'amount_paid', v_amount,
    'payment_method', p_payment_method,
    'commission', v_commission,
    'net_to_lounge', v_amount - v_commission,
    'shift_id', v_shift_id
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.complete_booking_payment(uuid, text, numeric) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.complete_booking_payment(uuid, text, numeric) FROM anon;
GRANT EXECUTE ON FUNCTION public.complete_booking_payment(uuid, text, numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION public.complete_booking_payment(uuid, text, numeric) TO service_role;
