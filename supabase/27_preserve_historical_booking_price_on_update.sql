-- Migration 27: Preserve historical booking room_price on unrelated UPDATEs
-- Only re-calculates room_price on INSERT or when room_id, duration_minutes, or play_mode actually change on UPDATE.

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

  -- 3. Room price calculation: Only re-fetch room rate on INSERT or when room/duration/play_mode changes
  IF TG_OP = 'INSERT'
     OR (TG_OP = 'UPDATE' AND (
          OLD.room_id IS DISTINCT FROM NEW.room_id
          OR OLD.duration_minutes IS DISTINCT FROM NEW.duration_minutes
          OR OLD.play_mode IS DISTINCT FROM NEW.play_mode
     )) THEN

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

    IF v_actual_hourly_rate <= 0 THEN
      RAISE EXCEPTION 'Cannot validate booking price: room % has no valid rate configured.', NEW.room_id;
    END IF;

    NEW.room_price := (NEW.duration_minutes / 60.0) * v_actual_hourly_rate;
  ELSE
    -- On unrelated UPDATEs (e.g. status changes, notes), preserve historical agreed room_price
    NEW.room_price := GREATEST(0, COALESCE(NEW.room_price, OLD.room_price, 0));
  END IF;

  -- 4. Calculate extras_total by summing NEW.extras JSONB array
  IF NEW.extras IS NOT NULL AND jsonb_typeof(NEW.extras) = 'array' AND jsonb_array_length(NEW.extras) > 0 THEN
    SELECT COALESCE(SUM(
      (COALESCE(NULLIF(elem->>'price', '')::numeric, NULLIF(elem->>'unit_price', '')::numeric, 0) *
       COALESCE(NULLIF(elem->>'quantity', '')::numeric, NULLIF(elem->>'qty', '')::numeric, 1))
    ), 0)
    INTO v_extras_total
    FROM jsonb_array_elements(NEW.extras) AS elem;
  END IF;

  -- 5. Calculate subtotal = room_price + extras_total
  v_subtotal := NEW.room_price + v_extras_total;

  -- 6. Clamp voucher_discount so it never exceeds subtotal or < 0
  v_clamped_discount := LEAST(GREATEST(0, COALESCE(NEW.voucher_discount, 0)), v_subtotal);
  NEW.voucher_discount := v_clamped_discount;

  -- 7. Calculate final total_price
  NEW.total_price := GREATEST(0, v_subtotal - v_clamped_discount);

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_and_clamp_booking_price ON public.bookings;

CREATE TRIGGER trg_validate_and_clamp_booking_price
BEFORE INSERT OR UPDATE ON public.bookings
FOR EACH ROW
EXECUTE FUNCTION public.fn_validate_and_clamp_booking_price();
