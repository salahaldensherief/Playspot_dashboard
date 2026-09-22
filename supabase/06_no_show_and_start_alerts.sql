-- =============================================================================
-- 06_no_show_and_start_alerts.sql
-- Handling Paid/Confirmed No-Shows & Scheduling Cron Execution
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Function to Record Paid/Confirmed No-Show Bookings
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_no_show_paid_bookings()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_count integer := 0;
BEGIN
  -- Mark overdue paid/confirmed bookings where customer didn't check-in as 'cancelled'
  -- with specific cancellation_reason 'NO_SHOW: Customer confirmed but did not attend'
  WITH no_shows AS (
    SELECT b.id
    FROM public.bookings b
    JOIN public.lounges l ON l.id = b.lounge_id
    WHERE b.status IN ('upcoming', 'confirmed', 'pending')
      AND b.checked_in_at IS NULL
      AND (
        (b.booking_period IS NOT NULL AND (now() AT TIME ZONE 'UTC') >= upper(b.booking_period) + make_interval(mins => COALESCE(l.cash_grace_period_minutes, 15)))
        OR
        (b.end_time IS NOT NULL AND b.date IS NOT NULL AND (now() AT TIME ZONE 'UTC') >= (b.date || ' ' || b.end_time)::timestamp + interval '15 minutes')
      )
    FOR UPDATE OF b SKIP LOCKED
  )
  UPDATE public.bookings b
  SET status = 'cancelled'::public.booking_status,
      cancellation_reason = 'NO_SHOW: User confirmed booking but did not attend without cancelling',
      updated_at = now()
  FROM no_shows ns
  WHERE b.id = ns.id;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

-- Grant execution permission
GRANT EXECUTE ON FUNCTION public.handle_no_show_paid_bookings() TO authenticated;

-- -----------------------------------------------------------------------------
-- 2. Schedule Cron Job for No-Show Cleanup
-- -----------------------------------------------------------------------------
DO $outer$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    BEGIN
      PERFORM cron.unschedule('handle-no-show-paid-bookings');
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

    PERFORM cron.schedule(
      'handle-no-show-paid-bookings',
      '*/5 * * * *', -- Runs every 5 minutes
      $cmd$ SELECT public.handle_no_show_paid_bookings(); $cmd$
    );
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipped pg_cron job for no-show bookings: %', SQLERRM;
END $outer$;
