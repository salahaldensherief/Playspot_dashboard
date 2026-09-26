-- Migration 25: Harden fn_validate_and_clamp_booking_price trigger
-- Re-validates room_price from rooms table and sums extras JSONB before clamping voucher_discount and total_price.

CREATE OR REPLACE FUNCTION public.fn_validate_and_clamp_booking_price()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_actual_hourly_rate NUMERIC := 0;
  v_extras_total NUMERIC := 0;
  v_subtotal NUMERIC := 0;
  v_clamped_discount NUMERIC := 0;
BEGIN
  -- 1. Re-validate room_price using actual room hourly rate and duration_minutes
  IF NEW.room_id IS NOT NULL AND COALESCE(NEW.duration_minutes, 0) > 0 THEN
    SELECT
      COALESCE(
        CASE
          WHEN NEW.play_mode = 'multi' AND COALESCE(hourly_rate_multi, 0) > 0 THEN hourly_rate_multi
          WHEN COALESCE(hourly_rate_single, 0) > 0 THEN hourly_rate_single
          ELSE COALESCE(hourly_rate_single, price_per_hour, 0)
        END, 0
      )
    INTO v_actual_hourly_rate
    FROM public.rooms
    WHERE id = NEW.room_id;

    IF v_actual_hourly_rate > 0 THEN
      NEW.room_price := (NEW.duration_minutes / 60.0) * v_actual_hourly_rate;
    ELSE
      NEW.room_price := GREATEST(0, COALESCE(NEW.room_price, 0));
    END IF;
  ELSE
    NEW.room_price := GREATEST(0, COALESCE(NEW.room_price, 0));
  END IF;

  -- 2. Calculate extras_total by summing NEW.extras JSONB array
  IF NEW.extras IS NOT NULL AND jsonb_typeof(NEW.extras) = 'array' AND jsonb_array_length(NEW.extras) > 0 THEN
    SELECT COALESCE(SUM(
      (COALESCE(NULLIF(elem->>'price', '')::numeric, NULLIF(elem->>'unit_price', '')::numeric, 0) *
       COALESCE(NULLIF(elem->>'quantity', '')::numeric, NULLIF(elem->>'qty', '')::numeric, 1))
    ), 0)
    INTO v_extras_total
    FROM jsonb_array_elements(NEW.extras) AS elem;
  END IF;

  -- 3. Calculate subtotal = room_price + extras_total
  v_subtotal := NEW.room_price + v_extras_total;

  -- 4. Clamp voucher_discount so it never exceeds subtotal or < 0
  v_clamped_discount := LEAST(GREATEST(0, COALESCE(NEW.voucher_discount, 0)), v_subtotal);
  NEW.voucher_discount := v_clamped_discount;

  -- 5. Calculate and clamp total_price
  NEW.total_price := GREATEST(0, v_subtotal - v_clamped_discount);

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_and_clamp_booking_price ON public.bookings;

CREATE TRIGGER trg_validate_and_clamp_booking_price
BEFORE INSERT OR UPDATE ON public.bookings
FOR EACH ROW
EXECUTE FUNCTION public.fn_validate_and_clamp_booking_price();
