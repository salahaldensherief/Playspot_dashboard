BEGIN;

-- 1. Add Future Booking and Open Time configuration to lounges table
ALTER TABLE public.lounges
  ADD COLUMN IF NOT EXISTS allow_future_booking_without_shift boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS notify_customer_when_shift_opens boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS future_confirmation_window_hours numeric(5,2) NOT NULL DEFAULT 2.0,
  ADD COLUMN IF NOT EXISTS notify_staff_before_unconfirmed_booking boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS auto_cancel_unconfirmed_future_booking boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS auto_cancel_before_start_minutes integer NOT NULL DEFAULT 60,
  ADD COLUMN IF NOT EXISTS reserve_slot_for_future_intent boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS show_payment_details_without_shift boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS open_time_payment_mode text NOT NULL DEFAULT 'pay_at_end';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'lounges_open_time_payment_mode_check'
      AND conrelid = 'public.lounges'::regclass
  ) THEN
    ALTER TABLE public.lounges
      ADD CONSTRAINT lounges_open_time_payment_mode_check
      CHECK (open_time_payment_mode IN ('prepaid_only', 'pay_at_end', 'deposit_required'));
  END IF;
END $$;

-- 2. Add confirmation_status and future booking columns to bookings table
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS confirmation_status text NOT NULL DEFAULT 'confirmed',
  ADD COLUMN IF NOT EXISTS is_future_intent boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS staff_contacted_at timestamptz,
  ADD COLUMN IF NOT EXISTS staff_contacted_by uuid REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS confirmation_notified_at timestamptz,
  ADD COLUMN IF NOT EXISTS confirmed_at timestamptz;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'bookings_confirmation_status_check'
      AND conrelid = 'public.bookings'::regclass
  ) THEN
    ALTER TABLE public.bookings
      ADD CONSTRAINT bookings_confirmation_status_check
      CHECK (confirmation_status IN (
        'confirmed',
        'pending_shift',
        'awaiting_confirmation',
        'payment_under_review',
        'contacted',
        'cancelled',
        'expired'
      ));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_bookings_confirmation_status
ON public.bookings (lounge_id, confirmation_status, date, start_time);

-- 3. Extend shift-binding logic to cover checked_in_at
CREATE OR REPLACE FUNCTION public.attach_booking_to_active_shift()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
DECLARE
  v_shift_id uuid;
  v_shift_lounge_id uuid;
  v_shift_status text;
  v_requires_open_shift boolean :=
    NEW.status::text = 'in_progress'
    OR NEW.actual_start_time IS NOT NULL
    OR NEW.checked_in_at IS NOT NULL;
BEGIN
  IF v_requires_open_shift
     AND NEW.shift_id IS NULL
     AND NEW.lounge_id IS NOT NULL THEN
    SELECT id
    INTO v_shift_id
    FROM public.shifts
    WHERE lounge_id = NEW.lounge_id
      AND status = 'open'
    ORDER BY opened_at DESC
    LIMIT 1;

    IF v_shift_id IS NULL THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P0001',
        MESSAGE = 'NO_OPEN_SHIFT';
    END IF;

    NEW.shift_id := v_shift_id;
  END IF;

  IF NEW.shift_id IS NOT NULL THEN
    SELECT lounge_id, status
    INTO v_shift_lounge_id, v_shift_status
    FROM public.shifts
    WHERE id = NEW.shift_id;

    IF v_shift_lounge_id IS NULL THEN
      RAISE EXCEPTION 'The selected shift does not exist.';
    END IF;

    IF NEW.lounge_id IS DISTINCT FROM v_shift_lounge_id THEN
      RAISE EXCEPTION 'Booking and shift must belong to the same lounge.';
    END IF;

    IF v_requires_open_shift AND v_shift_status <> 'open' THEN
      RAISE EXCEPTION 'An active booking must be linked to an open shift.';
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

-- 4. Update check_active_shift_before_booking to allow future booking requests
CREATE OR REPLACE FUNCTION public.check_active_shift_before_booking()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_allow_future boolean := false;
BEGIN
  -- If this is explicitly marked as a future booking intent awaiting shift
  IF NEW.is_future_intent IS TRUE
     AND NEW.confirmation_status = 'pending_shift'
     AND NEW.status = 'pending'::public.booking_status THEN
    SELECT COALESCE(allow_future_booking_without_shift, false)
    INTO v_allow_future
    FROM public.lounges
    WHERE id = NEW.lounge_id;

    IF v_allow_future THEN
      RETURN NEW;
    END IF;
  END IF;

  IF NEW.status IN (
       'pending'::public.booking_status,
       'upcoming'::public.booking_status,
       'in_progress'::public.booking_status
     )
     AND NOT EXISTS (
       SELECT 1
       FROM public.shifts AS s
       WHERE s.lounge_id = NEW.lounge_id
         AND s.status = 'open'
         AND s.closed_at IS NULL
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'NO_OPEN_SHIFT';
  END IF;

  RETURN NEW;
END;
$function$;

-- 5. Automatically notify customers and transition future bookings when a shift opens
CREATE OR REPLACE FUNCTION public.handle_shift_status_transition()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_booking record;
  v_notify_customer boolean;
  v_lounge_name text;
BEGIN
  IF NEW.status = 'open' AND (TG_OP = 'INSERT' OR OLD.status IS DISTINCT FROM 'open') THEN
    SELECT COALESCE(notify_customer_when_shift_opens, true), COALESCE(name_ar, name_en, name, 'PlaySpot Lounge')
    INTO v_notify_customer, v_lounge_name
    FROM public.lounges
    WHERE id = NEW.lounge_id;

    FOR v_booking IN
      SELECT b.id, b.user_id, b.date, b.start_time
      FROM public.bookings b
      WHERE b.lounge_id = NEW.lounge_id
        AND b.is_future_intent IS TRUE
        AND b.confirmation_status = 'pending_shift'
        AND b.status = 'pending'::public.booking_status
      FOR UPDATE
    LOOP
      UPDATE public.bookings
      SET confirmation_status = 'awaiting_confirmation',
          confirmation_notified_at = now(),
          updated_at = now()
      WHERE id = v_booking.id;

      IF v_notify_customer AND v_booking.user_id IS NOT NULL THEN
        INSERT INTO public.notifications (
          user_id,
          lounge_id,
          title_ar,
          title_en,
          body_ar,
          body_en,
          type,
          is_read,
          metadata,
          created_at
        ) VALUES (
          v_booking.user_id,
          NEW.lounge_id,
          'الفرع متاح الآن - تأكيد الحجز',
          'Lounge is now open - Confirm booking',
          'تم فتح الوردية في ' || v_lounge_name || '. يرجى تأكيد حجزك وإتمام الدفع لتثبيت الحجز.',
          'Shift is now open at ' || v_lounge_name || '. Please confirm your booking and complete payment.',
          'booking',
          false,
          jsonb_build_object(
            'event', 'shift_opened_confirm_booking',
            'booking_id', v_booking.id,
            'lounge_id', NEW.lounge_id,
            'shift_id', NEW.id
          ),
          now()
        );
      END IF;
    END LOOP;
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_handle_shift_status_transition ON public.shifts;
CREATE TRIGGER trg_handle_shift_status_transition
AFTER INSERT OR UPDATE OF status ON public.shifts
FOR EACH ROW
EXECUTE FUNCTION public.handle_shift_status_transition();

-- 6. Safe Payment Instructions RPC
CREATE OR REPLACE FUNCTION public.get_lounge_payment_instructions(
  p_lounge_id uuid,
  p_booking_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
DECLARE
  v_lounge public.lounges%ROWTYPE;
  v_shift_open boolean := false;
  v_booking public.bookings%ROWTYPE;
  v_allow_payment boolean := false;
  v_reason text := 'OK';
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  SELECT *
  INTO v_lounge
  FROM public.lounges
  WHERE id = p_lounge_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Lounge not found' USING ERRCODE = 'P0002';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.shifts s
    WHERE s.lounge_id = p_lounge_id
      AND s.status = 'open'
      AND s.closed_at IS NULL
  ) INTO v_shift_open;

  IF p_booking_id IS NOT NULL THEN
    SELECT *
    INTO v_booking
    FROM public.bookings
    WHERE id = p_booking_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Booking not found' USING ERRCODE = 'P0002';
    END IF;

    IF v_booking.user_id IS DISTINCT FROM auth.uid()
       AND NOT private.can_operate_playspot_lounge(v_booking.lounge_id) THEN
      RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
    END IF;

    IF v_booking.confirmation_status = 'pending_shift' AND NOT v_shift_open THEN
      v_allow_payment := false;
      v_reason := 'PENDING_SHIFT_LOUNGE_CLOSED';
    ELSIF v_booking.status = 'cancelled'::public.booking_status
          OR v_booking.status = 'rejected'::public.booking_status
          OR v_booking.confirmation_status IN ('cancelled', 'expired') THEN
      v_allow_payment := false;
      v_reason := 'BOOKING_CANCELLED';
    ELSE
      v_allow_payment := v_shift_open OR COALESCE(v_lounge.show_payment_details_without_shift, false);
      IF NOT v_allow_payment THEN
        v_reason := 'NO_OPEN_SHIFT';
      END IF;
    END IF;
  ELSE
    v_allow_payment := v_shift_open OR COALESCE(v_lounge.show_payment_details_without_shift, false);
    IF NOT v_allow_payment THEN
      v_reason := 'NO_OPEN_SHIFT';
    END IF;
  END IF;

  IF NOT v_allow_payment THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'reason', v_reason,
      'is_open', v_shift_open,
      'allow_future_booking', COALESCE(v_lounge.allow_future_booking_without_shift, false)
    );
  END IF;

  RETURN jsonb_build_object(
    'allowed', true,
    'reason', 'OK',
    'is_open', v_shift_open,
    'vodafone_cash_number', COALESCE(v_lounge.vodafone_cash_number, v_lounge.wallet_number, ''),
    'instapay_account', COALESCE(v_lounge.instapay_account, v_lounge.instapay_handle, '')
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.get_lounge_payment_instructions(uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_lounge_payment_instructions(uuid, uuid) TO authenticated, service_role;

-- 7. Create Future Booking Intent RPC
CREATE OR REPLACE FUNCTION public.create_future_booking_intent(
  p_room_id uuid,
  p_start_at timestamp without time zone,
  p_end_at timestamp without time zone,
  p_play_mode text DEFAULT 'single',
  p_extra_controllers integer DEFAULT 0,
  p_voucher_code text DEFAULT NULL,
  p_customer_name text DEFAULT NULL,
  p_customer_phone text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  v_room public.rooms%ROWTYPE;
  v_lounge public.lounges%ROWTYPE;
  v_user_name text;
  v_user_phone text;
  v_duration_minutes integer;
  v_base_rate numeric := 0;
  v_controller_rate numeric := 0;
  v_room_price numeric := 0;
  v_booking_id uuid;
  v_voucher_discount numeric := 0;
  v_voucher public.user_vouchers%ROWTYPE;
  v_clean_voucher text := NULLIF(upper(btrim(p_voucher_code)), '');
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  IF p_room_id IS NULL OR p_start_at IS NULL OR p_end_at IS NULL OR p_end_at <= p_start_at THEN
    RAISE EXCEPTION 'Invalid booking range' USING ERRCODE = '22023';
  END IF;

  v_duration_minutes := round(extract(epoch FROM (p_end_at - p_start_at)) / 60.0)::integer;
  IF v_duration_minutes <= 0 OR v_duration_minutes > 1440 THEN
    RAISE EXCEPTION 'Invalid booking duration' USING ERRCODE = '22023';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(p_room_id::text, 0)
  );

  SELECT * INTO v_room
  FROM public.rooms
  WHERE id = p_room_id
    AND is_active IS TRUE
    AND is_available IS TRUE
    AND COALESCE(status, '') <> 'deleted';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Room unavailable' USING ERRCODE = '23514';
  END IF;

  SELECT * INTO v_lounge
  FROM public.lounges
  WHERE id = v_room.lounge_id
    AND is_active IS TRUE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Lounge unavailable' USING ERRCODE = '23514';
  END IF;

  IF COALESCE(v_lounge.allow_future_booking_without_shift, false) IS FALSE THEN
    RAISE EXCEPTION 'FUTURE_BOOKINGS_DISABLED_WITHOUT_SHIFT' USING ERRCODE = '55000';
  END IF;

  -- Verify room slot availability
  IF EXISTS (
    SELECT 1 FROM public.bookings b
    WHERE b.room_id = p_room_id
      AND b.status IN (
        'pending'::public.booking_status,
        'upcoming'::public.booking_status,
        'in_progress'::public.booking_status
      )
      AND (b.status <> 'pending'::public.booking_status OR b.expires_at IS NULL OR b.expires_at > now())
      AND b.booking_period && pg_catalog.tsrange(p_start_at, p_end_at, '[)')
  ) THEN
    RAISE EXCEPTION 'SLOT_ALREADY_BOOKED' USING ERRCODE = '23514';
  END IF;

  SELECT p.full_name, p.phone
  INTO v_user_name, v_user_phone
  FROM public.profiles p
  WHERE p.id = v_user_id;

  v_user_name := COALESCE(NULLIF(btrim(p_customer_name), ''), v_user_name, 'App Customer');
  v_user_phone := COALESCE(NULLIF(btrim(p_customer_phone), ''), v_user_phone, '');

  v_base_rate := CASE
    WHEN lower(p_play_mode) = 'multi' AND COALESCE(v_room.hourly_rate_multi, 0) > 0
    THEN v_room.hourly_rate_multi
    ELSE v_room.hourly_rate_single
  END;

  v_controller_rate := GREATEST(0, COALESCE(p_extra_controllers, 0)) * COALESCE(v_room.extra_controller_price, 0);
  v_room_price := (v_duration_minutes / 60.0) * (v_base_rate + v_controller_rate);

  IF v_clean_voucher IS NOT NULL THEN
    SELECT uv.* INTO v_voucher
    FROM public.user_vouchers uv
    WHERE upper(btrim(uv.code)) = v_clean_voucher
      AND uv.user_id = v_user_id
      AND uv.status = 'active'
      AND (uv.expires_at IS NULL OR uv.expires_at > now())
    LIMIT 1;

    IF FOUND THEN
      IF v_voucher.reward_type = 'discount_fixed' THEN
        v_voucher_discount := LEAST(v_room_price, COALESCE(v_voucher.reward_value, 0));
      ELSIF v_voucher.reward_type = 'free_hour' THEN
        v_voucher_discount := LEAST(v_room_price, v_base_rate * COALESCE(v_voucher.reward_value, 0));
      END IF;
    END IF;
  END IF;

  INSERT INTO public.bookings (
    user_id,
    room_id,
    lounge_id,
    date,
    start_time,
    end_time,
    duration_hours,
    duration_minutes,
    room_price,
    addons_price,
    addons_total,
    total_price,
    status,
    confirmation_status,
    is_future_intent,
    payment_status,
    payment_method,
    user_name,
    user_phone,
    room_name,
    play_mode,
    extra_controllers,
    discount_amount,
    discount_reason,
    created_at,
    updated_at
  ) VALUES (
    v_user_id,
    v_room.id,
    v_lounge.id,
    p_start_at::date,
    p_start_at::time,
    p_end_at::time,
    v_duration_minutes / 60.0,
    v_duration_minutes,
    v_room_price,
    0,
    0,
    GREATEST(0, v_room_price - v_voucher_discount),
    'pending'::public.booking_status,
    'pending_shift',
    true,
    'unpaid',
    'manual_transfer',
    v_user_name,
    v_user_phone,
    COALESCE(NULLIF(v_room.name_ar, ''), NULLIF(v_room.name_en, ''), v_room.name),
    lower(COALESCE(NULLIF(p_play_mode, ''), 'single')),
    GREATEST(0, COALESCE(p_extra_controllers, 0)),
    v_voucher_discount,
    CASE WHEN v_voucher_discount > 0 THEN 'Voucher: ' || v_clean_voucher ELSE NULL END,
    now(),
    now()
  )
  RETURNING id INTO v_booking_id;

  IF v_clean_voucher IS NOT NULL AND v_voucher.id IS NOT NULL THEN
    PERFORM public.consume_voucher_by_code(v_clean_voucher, v_booking_id);
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', v_booking_id,
    'lounge_id', v_lounge.id,
    'room_id', v_room.id,
    'confirmation_status', 'pending_shift',
    'total_price', GREATEST(0, v_room_price - v_voucher_discount)
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.create_future_booking_intent(uuid, timestamp, timestamp, text, integer, text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_future_booking_intent(uuid, timestamp, timestamp, text, integer, text, text, text) TO authenticated, service_role;

-- 8. Confirm Future Booking RPC (Customer confirming once shift is open)
CREATE OR REPLACE FUNCTION public.confirm_future_booking(
  p_booking_id uuid,
  p_payment_method text DEFAULT 'manual_transfer',
  p_sender_wallet_phone text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  v_booking public.bookings%ROWTYPE;
  v_shift_open boolean := false;
  v_clean_sender text := NULLIF(btrim(p_sender_wallet_phone), '');
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  SELECT *
  INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found' USING ERRCODE = 'P0002';
  END IF;

  IF v_booking.user_id IS DISTINCT FROM v_user_id THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
  END IF;

  IF v_booking.confirmation_status NOT IN ('pending_shift', 'awaiting_confirmation', 'contacted') THEN
    RAISE EXCEPTION 'Booking cannot be confirmed in current status' USING ERRCODE = '55000';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.shifts s
    WHERE s.lounge_id = v_booking.lounge_id
      AND s.status = 'open'
      AND s.closed_at IS NULL
  ) INTO v_shift_open;

  IF NOT v_shift_open THEN
    RAISE EXCEPTION 'Lounge shift is not open yet' USING ERRCODE = '55000';
  END IF;

  UPDATE public.bookings
  SET confirmation_status = CASE
        WHEN v_clean_sender IS NOT NULL THEN 'payment_under_review'
        ELSE 'awaiting_confirmation'
      END,
      confirmed_at = now(),
      payment_method = lower(COALESCE(p_payment_method, 'manual_transfer')),
      sender_wallet_phone = COALESCE(v_clean_sender, sender_wallet_phone),
      updated_at = now()
  WHERE id = p_booking_id;

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', p_booking_id,
    'confirmation_status', CASE WHEN v_clean_sender IS NOT NULL THEN 'payment_under_review' ELSE 'awaiting_confirmation' END
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.confirm_future_booking(uuid, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.confirm_future_booking(uuid, text, text) TO authenticated, service_role;

-- 9. Harden attach_my_booking_receipt with shift check and confirmation gating
CREATE OR REPLACE FUNCTION public.attach_my_booking_receipt(
  p_booking_id uuid,
  p_receipt_url text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
DECLARE
  v_booking public.bookings%ROWTYPE;
  v_lounge public.lounges%ROWTYPE;
  v_receipt_url text := NULLIF(btrim(p_receipt_url), '');
  v_expected_prefix text;
  v_shift_open boolean := false;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  IF v_receipt_url IS NULL THEN
    RAISE EXCEPTION 'Receipt reference is required' USING ERRCODE = '22023';
  END IF;

  SELECT b.*
  INTO v_booking
  FROM public.bookings AS b
  WHERE b.id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found' USING ERRCODE = 'P0002';
  END IF;

  IF v_booking.user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE = '42501';
  END IF;

  IF v_booking.status NOT IN (
    'pending'::public.booking_status,
    'upcoming'::public.booking_status
  ) THEN
    RAISE EXCEPTION 'Receipt cannot be changed in the current booking status'
      USING ERRCODE = '55000';
  END IF;

  SELECT * INTO v_lounge
  FROM public.lounges
  WHERE id = v_booking.lounge_id;

  SELECT EXISTS (
    SELECT 1 FROM public.shifts s
    WHERE s.lounge_id = v_booking.lounge_id
      AND s.status = 'open'
      AND s.closed_at IS NULL
  ) INTO v_shift_open;

  IF NOT v_shift_open AND COALESCE(v_lounge.show_payment_details_without_shift, false) IS FALSE THEN
    RAISE EXCEPTION 'Cannot attach receipt when lounge has no open shift'
      USING ERRCODE = '55000';
  END IF;

  IF v_booking.confirmation_status = 'pending_shift' AND NOT v_shift_open THEN
    RAISE EXCEPTION 'Booking is pending shift opening. Please wait until shift opens.'
      USING ERRCODE = '55000';
  END IF;

  v_expected_prefix := auth.uid()::text || '/' || p_booking_id::text || '/';

  IF v_receipt_url NOT LIKE v_expected_prefix || '%' THEN
    RAISE EXCEPTION 'Receipt reference does not belong to this booking'
      USING ERRCODE = '42501';
  END IF;

  IF v_receipt_url LIKE 'http://%' OR v_receipt_url LIKE 'https://%' THEN
    RAISE EXCEPTION 'Receipt reference must be a private storage object path'
      USING ERRCODE = '22023';
  END IF;

  UPDATE public.bookings
  SET receipt_url = v_receipt_url,
      confirmation_status = 'payment_under_review',
      updated_at = now()
  WHERE id = p_booking_id;

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', p_booking_id,
    'receipt_url', v_receipt_url,
    'confirmation_status', 'payment_under_review'
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.attach_my_booking_receipt(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.attach_my_booking_receipt(uuid, text) TO authenticated, service_role;

-- 10. Authoritative Staff Approval and Rejection RPCs
CREATE OR REPLACE FUNCTION public.approve_manual_booking(
  p_booking_id uuid,
  p_action_by uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
DECLARE
  v_booking public.bookings%ROWTYPE;
  v_shift_id uuid;
  v_action_user uuid := COALESCE(p_action_by, auth.uid());
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  SELECT *
  INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found' USING ERRCODE = 'P0002';
  END IF;

  PERFORM private.assert_lounge_operator(v_booking.lounge_id, true);

  -- Verify active open shift exists
  SELECT id
  INTO v_shift_id
  FROM public.shifts
  WHERE lounge_id = v_booking.lounge_id
    AND status = 'open'
    AND closed_at IS NULL
  ORDER BY opened_at DESC
  LIMIT 1;

  IF v_shift_id IS NULL THEN
    RAISE EXCEPTION 'NO_OPEN_SHIFT: Staff must have an open shift to approve manual payments.'
      USING ERRCODE = '55000';
  END IF;

  UPDATE public.bookings
  SET status = 'upcoming'::public.booking_status,
      payment_status = 'paid',
      confirmation_status = 'confirmed',
      shift_id = v_shift_id,
      paid_at = now(),
      confirmed_at = now(),
      updated_at = now()
  WHERE id = p_booking_id;

  IF v_booking.user_id IS NOT NULL THEN
    INSERT INTO public.notifications (
      user_id,
      lounge_id,
      title_ar,
      title_en,
      body_ar,
      body_en,
      type,
      is_read,
      metadata,
      created_at
    ) VALUES (
      v_booking.user_id,
      v_booking.lounge_id,
      'تم تأكيد الحجز',
      'Booking Confirmed',
      'تم التحقق من الدفع وتأكيد حجزك بنجاح!',
      'Payment verified and your booking has been confirmed successfully!',
      'booking',
      false,
      jsonb_build_object(
        'event', 'booking_approved',
        'booking_id', p_booking_id,
        'action_by', v_action_user
      ),
      now()
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', p_booking_id,
    'status', 'upcoming',
    'payment_status', 'paid',
    'confirmation_status', 'confirmed',
    'shift_id', v_shift_id
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.approve_manual_booking(uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.approve_manual_booking(uuid, uuid) TO authenticated, service_role, supabase_auth_admin;

CREATE OR REPLACE FUNCTION public.reject_manual_booking(
  p_booking_id uuid,
  p_rejection_reason text,
  p_action_by uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
DECLARE
  v_booking public.bookings%ROWTYPE;
  v_clean_reason text := COALESCE(NULLIF(btrim(p_rejection_reason), ''), 'Payment verification failed');
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  SELECT *
  INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found' USING ERRCODE = 'P0002';
  END IF;

  PERFORM private.assert_lounge_operator(v_booking.lounge_id, true);

  UPDATE public.bookings
  SET status = 'cancelled'::public.booking_status,
      confirmation_status = 'cancelled',
      rejection_reason = v_clean_reason,
      cancellation_reason = v_clean_reason,
      updated_at = now()
  WHERE id = p_booking_id;

  IF v_booking.user_id IS NOT NULL THEN
    INSERT INTO public.notifications (
      user_id,
      lounge_id,
      title_ar,
      title_en,
      body_ar,
      body_en,
      type,
      is_read,
      metadata,
      created_at
    ) VALUES (
      v_booking.user_id,
      v_booking.lounge_id,
      'تعذر تأكيد الحجز',
      'Booking Request Declined',
      'تم رفض التحويل للسبب التالي: ' || v_clean_reason,
      'Payment was not accepted: ' || v_clean_reason,
      'booking',
      false,
      jsonb_build_object(
        'event', 'booking_rejected',
        'booking_id', p_booking_id,
        'reason', v_clean_reason
      ),
      now()
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', p_booking_id,
    'status', 'cancelled',
    'confirmation_status', 'cancelled'
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.reject_manual_booking(uuid, text, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.reject_manual_booking(uuid, text, uuid) TO authenticated, service_role, supabase_auth_admin;

-- 11. Staff action: Mark Booking Customer Contacted
CREATE OR REPLACE FUNCTION public.mark_booking_customer_contacted(
  p_booking_id uuid,
  p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
DECLARE
  v_booking public.bookings%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  SELECT *
  INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found' USING ERRCODE = 'P0002';
  END IF;

  PERFORM private.assert_lounge_operator(v_booking.lounge_id, true);

  UPDATE public.bookings
  SET confirmation_status = 'contacted',
      staff_contacted_at = now(),
      staff_contacted_by = auth.uid(),
      updated_at = now()
  WHERE id = p_booking_id;

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', p_booking_id,
    'confirmation_status', 'contacted',
    'staff_contacted_at', now()
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.mark_booking_customer_contacted(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.mark_booking_customer_contacted(uuid, text) TO authenticated, service_role, supabase_auth_admin;

-- 12. Future Booking Settings Update RPC
CREATE OR REPLACE FUNCTION public.update_lounge_future_booking_settings(
  p_lounge_id uuid,
  p_allow_future_booking_without_shift boolean,
  p_notify_customer_when_shift_opens boolean DEFAULT true,
  p_future_confirmation_window_hours numeric DEFAULT 2.0,
  p_notify_staff_before_unconfirmed_booking boolean DEFAULT true,
  p_auto_cancel_unconfirmed_future_booking boolean DEFAULT false,
  p_auto_cancel_before_start_minutes integer DEFAULT 60,
  p_reserve_slot_for_future_intent boolean DEFAULT true,
  p_show_payment_details_without_shift boolean DEFAULT false,
  p_open_time_payment_mode text DEFAULT 'pay_at_end'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  PERFORM private.assert_lounge_operator(p_lounge_id, false);

  UPDATE public.lounges
  SET allow_future_booking_without_shift = COALESCE(p_allow_future_booking_without_shift, false),
      notify_customer_when_shift_opens = COALESCE(p_notify_customer_when_shift_opens, true),
      future_confirmation_window_hours = GREATEST(0.5, COALESCE(p_future_confirmation_window_hours, 2.0)),
      notify_staff_before_unconfirmed_booking = COALESCE(p_notify_staff_before_unconfirmed_booking, true),
      auto_cancel_unconfirmed_future_booking = COALESCE(p_auto_cancel_unconfirmed_future_booking, false),
      auto_cancel_before_start_minutes = GREATEST(10, COALESCE(p_auto_cancel_before_start_minutes, 60)),
      reserve_slot_for_future_intent = COALESCE(p_reserve_slot_for_future_intent, true),
      show_payment_details_without_shift = COALESCE(p_show_payment_details_without_shift, false),
      open_time_payment_mode = COALESCE(p_open_time_payment_mode, 'pay_at_end'),
      updated_at = now()
  WHERE id = p_lounge_id;

  RETURN jsonb_build_object('success', true, 'lounge_id', p_lounge_id);
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.update_lounge_future_booking_settings(uuid, boolean, boolean, numeric, boolean, boolean, integer, boolean, boolean, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_lounge_future_booking_settings(uuid, boolean, boolean, numeric, boolean, boolean, integer, boolean, boolean, text) TO authenticated, service_role, supabase_auth_admin;

-- 13. Lock down booking_waitlist table direct write access
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON TABLE public.booking_waitlist FROM PUBLIC, anon, authenticated;
GRANT SELECT ON TABLE public.booking_waitlist TO authenticated;
GRANT ALL ON TABLE public.booking_waitlist TO service_role;

-- 14. Background Worker: Auto-cancel unconfirmed future bookings close to start time
CREATE OR REPLACE FUNCTION public.process_unconfirmed_future_bookings()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_booking record;
  v_cancelled_count integer := 0;
  v_now_cairo timestamp without time zone := now() AT TIME ZONE 'Africa/Cairo';
BEGIN
  FOR v_booking IN
    SELECT b.id, b.lounge_id, b.user_id, b.date, b.start_time, l.auto_cancel_before_start_minutes
    FROM public.bookings b
    JOIN public.lounges l ON l.id = b.lounge_id
    WHERE b.is_future_intent IS TRUE
      AND b.confirmation_status IN ('pending_shift', 'awaiting_confirmation')
      AND b.status = 'pending'::public.booking_status
      AND l.auto_cancel_unconfirmed_future_booking IS TRUE
      AND (b.date::date + b.start_time::time) <= (v_now_cairo + make_interval(mins => COALESCE(l.auto_cancel_before_start_minutes, 60)))
    FOR UPDATE OF b SKIP LOCKED
  LOOP
    UPDATE public.bookings
    SET status = 'cancelled'::public.booking_status,
        confirmation_status = 'expired',
        cancellation_reason = 'Auto-cancelled: Future booking was not confirmed before start window deadline.',
        updated_at = now()
    WHERE id = v_booking.id;

    IF v_booking.user_id IS NOT NULL THEN
      INSERT INTO public.notifications (
        user_id,
        lounge_id,
        title_ar,
        title_en,
        body_ar,
        body_en,
        type,
        is_read,
        metadata,
        created_at
      ) VALUES (
        v_booking.user_id,
        v_booking.lounge_id,
        'انتهاء مهلة تأكيد الحجز',
        'Booking Confirmation Window Expired',
        'تم إلغاء طلب الحجز تلقائيًا لعدم التأكيد قبل موعد الحجز.',
        'Your booking request was auto-cancelled as it was not confirmed before the start window deadline.',
        'booking',
        false,
        jsonb_build_object('event', 'future_booking_expired', 'booking_id', v_booking.id),
        now()
      );
    END IF;

    v_cancelled_count := v_cancelled_count + 1;
  END LOOP;

  RETURN v_cancelled_count;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.process_unconfirmed_future_bookings() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.process_unconfirmed_future_bookings() TO service_role;

SELECT cron.schedule(
  'playspot-unconfirmed-future-bookings', '*/5 * * * *',
  'SELECT public.process_unconfirmed_future_bookings()'
);

COMMIT;
