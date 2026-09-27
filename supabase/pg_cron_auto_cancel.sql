-- =====================================================================
-- PlaySpot Dashboard - Supabase pg_cron Setup for Auto-Canceling Expired Bookings
-- =====================================================================
-- This script sets up a database-level scheduled job that runs every 1 minute.
-- It automatically transitions overdue/expired pending bookings to 'cancelled'
-- without relying on active client connections or client-side periodic timers.

-- 1. Enable pg_cron Extension (requires Supabase Postgres Extensions enabled)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 2. Create Stored Procedure for Auto-Canceling Expired Bookings
CREATE OR REPLACE FUNCTION auto_cancel_expired_bookings_job()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Cancel pending bookings whose start time + grace period (e.g., 15 minutes) has passed
  UPDATE bookings
  SET
    status = 'cancelled',
    updated_at = NOW()
  WHERE
    status = 'pending'
    AND (date + (start_time::interval) + INTERVAL '15 minutes') < NOW();

  -- Log automated execution if audit table exists
  RAISE NOTICE 'Auto-cancel job executed successfully at %', NOW();
END;
$$;

-- 3. Schedule the Cron Job to run every minute
SELECT cron.schedule(
  'auto-cancel-expired-bookings-cron', -- Unique Job Name
  '* * * * *',                         -- Every Minute Cron Schedule
  'SELECT auto_cancel_expired_bookings_job();'
);
