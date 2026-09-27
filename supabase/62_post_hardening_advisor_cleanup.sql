BEGIN;

CREATE INDEX IF NOT EXISTS booking_holds_lounge_id_idx
  ON public.booking_holds (lounge_id);
CREATE INDEX IF NOT EXISTS booking_holds_user_id_idx
  ON public.booking_holds (user_id);
CREATE INDEX IF NOT EXISTS bookings_approved_by_idx
  ON public.bookings (approved_by);
CREATE INDEX IF NOT EXISTS bookings_cancelled_by_idx
  ON public.bookings (cancelled_by);

REVOKE EXECUTE ON FUNCTION public.calculate_booking_total(
  uuid, numeric, text, numeric, text
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.calculate_booking_total(
  uuid, numeric, text, numeric, text
) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.validate_voucher_by_code(text)
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.validate_voucher_by_code(text)
TO authenticated, service_role;

DO $$
DECLARE
  r record;
  new_qual text;
  new_check text;
BEGIN
  FOR r IN
    SELECT schemaname, tablename, policyname, qual, with_check
    FROM pg_policies
    WHERE schemaname = 'public'
      AND (
        (tablename = 'profiles' AND policyname IN ('profiles_select_policy', 'profiles_update_policy'))
        OR (tablename = 'bookings' AND policyname = 'bookings_select_policy')
        OR (tablename = 'service_calls' AND policyname IN ('service_calls_policy', 'Staff can view service calls', 'Staff can update service calls'))
        OR (tablename = 'client_requests' AND policyname = 'client_requests_policy')
        OR (tablename = 'lounge_reviews' AND policyname = 'lounge_reviews_insert')
        OR (tablename = 'canteen_orders' AND policyname IN ('Staff can view canteen orders', 'Staff can update canteen orders'))
        OR (tablename = 'canteen_order_items' AND policyname = 'Staff can view canteen order items')
        OR (tablename = 'points_transactions' AND policyname = 'points_transactions_select')
        OR (tablename = 'referrals' AND policyname = 'referrals_select')
        OR (tablename = 'lounges' AND policyname = 'lounges_write_policy')
      )
  LOOP
    new_qual := CASE
      WHEN r.qual IS NULL THEN NULL
      ELSE replace(r.qual, 'auth.uid()', '(select auth.uid())')
    END;
    new_check := CASE
      WHEN r.with_check IS NULL THEN NULL
      ELSE replace(r.with_check, 'auth.uid()', '(select auth.uid())')
    END;

    IF new_qual IS NOT NULL AND new_check IS NOT NULL THEN
      EXECUTE format(
        'ALTER POLICY %I ON %I.%I USING (%s) WITH CHECK (%s)',
        r.policyname, r.schemaname, r.tablename, new_qual, new_check
      );
    ELSIF new_qual IS NOT NULL THEN
      EXECUTE format(
        'ALTER POLICY %I ON %I.%I USING (%s)',
        r.policyname, r.schemaname, r.tablename, new_qual
      );
    ELSIF new_check IS NOT NULL THEN
      EXECUTE format(
        'ALTER POLICY %I ON %I.%I WITH CHECK (%s)',
        r.policyname, r.schemaname, r.tablename, new_check
      );
    END IF;
  END LOOP;
END $$;

COMMIT;
