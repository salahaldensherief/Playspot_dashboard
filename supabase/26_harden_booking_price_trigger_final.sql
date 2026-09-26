-- Migration 26: Final Hardening of fn_validate_and_clamp_booking_price Trigger
-- Strictly validates room rates, duration bounds (1 to 1440 min), and rejects bogus room_id or zero-rate fallbacks.

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
  -- 1. Duration sanity bounds check (Must be between 1 and 1440 minutes / 24 hours)
  IF COALESCE(NEW.duration_minutes, 0) <= 0 OR NEW.duration_minutes > 1440 THEN
    RAISE EXCEPTION 'Invalid booking duration: % minutes. Duration must be between 1 and 1440 minutes.', NEW.duration_minutes;
  END IF;

  -- 2. Room ID presence check
  IF NEW.room_id IS NULL THEN
    RAISE EXCEPTION 'Cannot validate booking price: room_id is required.';
  END IF;

  -- 3. Lookup actual room hourly rate from public.rooms
  SELECT
    COALESCE(
      CASE
        WHEN NEW.play_mode = 'multi' AND COALESCE(hourly_rate_multi, 0) > 0 THEN hourly_rate_multi
        WHEN COALESCE(hourly_rate_single, 0) > 0 THEN hourly_rate_single
        ELSE COALESCE(price_per_hour, 0)
      END, 0
    )
  INTO v_actual_hourly_rate
  FROM public.rooms
  WHERE id = NEW.room_id;

  -- Strictly REJECT insert if room is not found or has no valid rate configured
  IF v_actual_hourly_rate <= 0 THEN
    RAISE EXCEPTION 'Cannot validate booking price: room % has no valid rate configured.', NEW.room_id;
  END IF;

  -- 4. Calculate exact room_price
  NEW.room_price := (NEW.duration_minutes / 60.0) * v_actual_hourly_rate;

  -- 5. Calculate extras_total by summing NEW.extras JSONB array
  IF NEW.extras IS NOT NULL AND jsonb_typeof(NEW.extras) = 'array' AND jsonb_array_length(NEW.extras) > 0 THEN
    SELECT COALESCE(SUM(
      (COALESCE(NULLIF(elem->>'price', '')::numeric, NULLIF(elem->>'unit_price', '')::numeric, 0) *
       COALESCE(NULLIF(elem->>'quantity', '')::numeric, NULLIF(elem->>'qty', '')::numeric, 1))
    ), 0)
    INTO v_extras_total
    FROM jsonb_array_elements(NEW.extras) AS elem;
  END IF;

  -- 6. Calculate subtotal = room_price + extras_total
  v_subtotal := NEW.room_price + v_extras_total;

  -- 7. Clamp voucher_discount so it never exceeds subtotal or < 0
  v_clamped_discount := LEAST(GREATEST(0, COALESCE(NEW.voucher_discount, 0)), v_subtotal);
  NEW.voucher_discount := v_clamped_discount;

  -- 8. Calculate final total_price
  NEW.total_price := GREATEST(0, v_subtotal - v_clamped_discount);

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_and_clamp_booking_price ON public.bookings;

CREATE TRIGGER trg_validate_and_clamp_booking_price
BEFORE INSERT OR UPDATE ON public.bookings
FOR EACH ROW
EXECUTE FUNCTION public.fn_validate_and_clamp_booking_price();
