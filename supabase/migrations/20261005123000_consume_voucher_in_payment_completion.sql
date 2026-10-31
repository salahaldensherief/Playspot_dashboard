-- Migration: 20261005123000_consume_voucher_in_payment_completion.sql
-- Description: Fix vulnerability where vouchers applied from Dashboard were not consumed upon payment.
--              1. Add applied_voucher_code column to bookings to track voucher bindings.
--              2. Extend apply_booking_discount RPC to accept and record optional p_voucher_code.
--              3. Update complete_booking_payment RPC to atomically mark the voucher as 'used'
--                 when payment is completed.

-- 1. Add applied_voucher_code to public.bookings
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS applied_voucher_code text;

-- 2. Update apply_booking_discount
CREATE OR REPLACE FUNCTION public.apply_booking_discount(
  p_booking_id uuid,
  p_discount_amount numeric DEFAULT 0,
  p_discount_percentage numeric DEFAULT 0,
  p_discount_reason text DEFAULT NULL::text,
  p_voucher_code text DEFAULT NULL::text
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_booking public.bookings%ROWTYPE;
  v_amount numeric := GREATEST(COALESCE(p_discount_amount, 0), 0);
  v_percentage numeric := GREATEST(COALESCE(p_discount_percentage, 0), 0);
  v_reason text := NULLIF(btrim(p_discount_reason), '');
  v_clean_voucher text := NULLIF(upper(btrim(p_voucher_code)), '');
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  SELECT b.*
  INTO v_booking
  FROM public.bookings AS b
  WHERE b.id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found' USING ERRCODE = 'P0002';
  END IF;

  PERFORM private.assert_lounge_operator(v_booking.lounge_id, false);

  IF v_amount > 0 AND v_percentage > 0 THEN
    RAISE EXCEPTION 'Use either a fixed discount or a percentage discount, not both'
      USING ERRCODE = '22023';
  END IF;

  IF v_percentage > 100 THEN
    RAISE EXCEPTION 'Discount percentage must be between 0 and 100'
      USING ERRCODE = '22023';
  END IF;

  IF (v_amount > 0 OR v_percentage > 0) AND v_reason IS NULL AND v_clean_voucher IS NULL THEN
    RAISE EXCEPTION 'Discount reason or voucher code is required'
      USING ERRCODE = '22023';
  END IF;

  IF v_clean_voucher IS NOT NULL AND v_reason IS NULL THEN
    v_reason := 'Voucher: ' || v_clean_voucher;
  END IF;

  UPDATE public.bookings
  SET
    discount_amount = v_amount,
    discount_percentage = v_percentage,
    discount_reason = v_reason,
    applied_voucher_code = COALESCE(v_clean_voucher, applied_voucher_code),
    discount_approved_by = auth.uid(),
    updated_at = now()
  WHERE id = p_booking_id
  RETURNING *
  INTO v_booking;

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', v_booking.id,
    'discount_amount', v_booking.discount_amount,
    'discount_percentage', v_booking.discount_percentage,
    'discount_reason', v_booking.discount_reason,
    'applied_voucher_code', v_booking.applied_voucher_code,
    'total_price', v_booking.total_price
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.apply_booking_discount(uuid, numeric, numeric, text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.apply_booking_discount(uuid, numeric, numeric, text, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.apply_booking_discount(uuid, numeric, numeric, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.apply_booking_discount(uuid, numeric, numeric, text, text) TO service_role;

-- 3. Update complete_booking_payment to consume voucher atomically
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
  v_voucher_to_consume text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

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

  IF NOT public.is_super_admin()
     AND NOT public.has_lounge_permission(v_booking.lounge_id, 'billing_checkout') THEN
    RAISE EXCEPTION 'Not authorized for billing checkout in this lounge' USING ERRCODE = '42501';
  END IF;

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

  IF v_booking.status = 'completed'::public.booking_status THEN
    v_new_status := 'completed'::public.booking_status;
  ELSIF v_booking.status = 'in_progress'::public.booking_status THEN
    v_new_status := 'in_progress'::public.booking_status;
  ELSE
    v_new_status := 'upcoming'::public.booking_status;
  END IF;

  -- Consume attached voucher if exists
  v_voucher_to_consume := COALESCE(
    v_booking.applied_voucher_code,
    CASE 
      WHEN v_booking.discount_reason ~* '^voucher:\s*([A-Za-z0-9_-]+)' 
      THEN substring(v_booking.discount_reason from '(?i)^voucher:\s*([A-Za-z0-9_-]+)')
      ELSE NULL 
    END
  );

  IF v_voucher_to_consume IS NOT NULL AND v_booking.user_id IS NOT NULL THEN
    UPDATE public.user_vouchers
    SET status = 'used',
        used_at = now(),
        used_booking_id = p_booking_id
    WHERE UPPER(TRIM(code)) = UPPER(TRIM(v_voucher_to_consume))
      AND user_id = v_booking.user_id
      AND status = 'active';
  END IF;

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

  INSERT INTO public.shift_payments (
    shift_id, lounge_id, booking_id, payment_method, category, amount, paid_at
  ) VALUES (
    v_shift_id, v_booking.lounge_id, p_booking_id, p_payment_method, 'gaming_time', v_amount, now()
  );

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
