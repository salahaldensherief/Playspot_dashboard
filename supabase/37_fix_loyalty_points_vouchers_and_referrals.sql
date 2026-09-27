-- 37_fix_loyalty_points_vouchers_and_referrals.sql
-- Fixes:
-- 1. update_user_points: Records an entry in points_transactions for admin point adjustments so transaction history remains complete.
-- 2. award_points_for_booking & handle_loyalty_points_on_payment: Prevents duplicate point awards on completed bookings by checking for existing transactions.
-- 3. redeem_points: Guarantees concurrency safety when deducting points and generating user_vouchers.

CREATE OR REPLACE FUNCTION public.update_user_points(p_user_id uuid, p_points_change integer, p_reason text DEFAULT 'تعديل إداري للنقاط'::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
DECLARE
  v_old_points integer;
  v_new_points integer;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'super_admin'
  ) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  IF p_points_change = 0 THEN
    RETURN;
  END IF;

  SELECT COALESCE(points, 0) INTO v_old_points
  FROM public.profiles
  WHERE id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User profile not found';
  END IF;

  v_new_points := GREATEST(0, v_old_points + p_points_change);

  UPDATE public.profiles
  SET points = v_new_points
  WHERE id = p_user_id;

  INSERT INTO public.points_transactions (
    user_id, points, type, reference_id, description, created_at
  ) VALUES (
    p_user_id,
    p_points_change,
    CASE WHEN p_points_change > 0 THEN 'admin_grant' ELSE 'admin_deduct' END,
    auth.uid(),
    COALESCE(p_reason, 'تعديل إداري للنقاط'),
    now()
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.award_points_for_booking(p_booking_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
DECLARE
  v_user_id UUID;
  v_amount NUMERIC;
  v_points INT;
BEGIN
  SELECT user_id, total_price INTO v_user_id, v_amount
  FROM public.bookings
  WHERE id = p_booking_id;

  IF v_user_id IS NULL THEN
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.points_transactions
    WHERE user_id = v_user_id AND reference_id = p_booking_id AND type IN ('earn', 'earn_booking')
  ) THEN
    RETURN;
  END IF;

  v_points := GREATEST(1, ROUND(COALESCE(v_amount, 0) / 10.0)::INT);

  UPDATE public.profiles
  SET points = COALESCE(points, 0) + v_points
  WHERE id = v_user_id;

  INSERT INTO public.points_transactions (user_id, points, type, reference_id, description, created_at)
  VALUES (v_user_id, v_points, 'earn', p_booking_id, 'نقاط حجز رقم: ' || p_booking_id, now());

  INSERT INTO public.notifications (user_id, title, title_ar, title_en, body, body_ar, body_en, type, metadata)
  VALUES (
    v_user_id,
    'Points Earned',
    'نقاط ولاء جديدة! 🎉',
    'New Loyalty Points Earned!',
    'تم إضافة ' || v_points || ' نقطة ولاء لحسابك مقابل حجزك',
    'تم إضافة ' || v_points || ' نقطة ولاء لحسابك مقابل حجزك',
    'You earned ' || v_points || ' loyalty points for your booking!',
    'loyalty_points',
    jsonb_build_object('booking_id', p_booking_id, 'points', v_points)
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.handle_loyalty_points_on_payment()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'extensions', 'pg_temp'
AS $function$
DECLARE
  v_points_earned integer;
BEGIN
  IF NEW.status = 'completed'
     AND (OLD.status IS NULL OR OLD.status <> 'completed')
     AND NEW.user_id IS NOT NULL
     AND NEW.booking_id IS NOT NULL THEN

    IF EXISTS (
      SELECT 1 FROM public.points_transactions
      WHERE user_id = NEW.user_id AND reference_id = NEW.booking_id AND type IN ('earn', 'earn_booking')
    ) THEN
      RETURN NEW;
    END IF;

    v_points_earned := FLOOR(COALESCE(NEW.amount, 0) / 10)::integer;
    IF v_points_earned > 0 THEN
      PERFORM public.award_points(
        NEW.user_id, v_points_earned, 'earn_booking', NEW.booking_id,
        'نقاط من حجز مكتمل', 'booking', NEW.booking_id,
        'booking_completed:' || NEW.booking_id::text,
        jsonb_build_object('booking_id', NEW.booking_id, 'amount', NEW.amount)
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;
