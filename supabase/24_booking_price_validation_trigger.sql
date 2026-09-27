-- Migration 24: Add BEFORE INSERT OR UPDATE trigger on public.bookings to clamp total_price and voucher_discount
CREATE OR REPLACE FUNCTION public.fn_validate_and_clamp_booking_price()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_subtotal NUMERIC;
  v_clamped_discount NUMERIC;
BEGIN
  -- 1. Ensure room_price is non-negative
  NEW.room_price := GREATEST(0, COALESCE(NEW.room_price, 0));

  -- 2. Ensure voucher_discount is non-negative
  NEW.voucher_discount := GREATEST(0, COALESCE(NEW.voucher_discount, 0));

  -- 3. Calculate subtotal
  v_subtotal := NEW.room_price;

  -- 4. Clamp voucher_discount so it never exceeds subtotal
  v_clamped_discount := LEAST(NEW.voucher_discount, v_subtotal);
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
