-- =============================================================================
-- Test Suite: test_phase1_p0_hardening.sql
-- Description: Isolated Verification of Phase 1 (P0) Hardening
-- Execution: Runs in a transactional block (BEGIN; ... ROLLBACK;)
-- =============================================================================

BEGIN;

DO $test$
DECLARE
  v_test_owner uuid := gen_random_uuid();
  v_test_cashier uuid := gen_random_uuid();
  v_other_user uuid := gen_random_uuid();
  v_lounge_id uuid := gen_random_uuid();
  v_room_id uuid := gen_random_uuid();
  v_shift_id uuid := gen_random_uuid();
  v_booking_id uuid := gen_random_uuid();
  v_extra_id uuid := gen_random_uuid();
  v_order_id uuid;
  v_quote jsonb;
  v_res jsonb;
  v_stock int;
  v_err_thrown boolean;
BEGIN
  RAISE NOTICE '>>> Starting Phase 1 Isolated Test Suite...';

  SELECT id INTO v_test_owner FROM public.profiles WHERE role = 'owner' LIMIT 1;
  IF v_test_owner IS NULL THEN
    SELECT id INTO v_test_owner FROM public.profiles LIMIT 1;
  END IF;

  INSERT INTO public.lounges (
    open_time_rounding_minutes, open_time_minimum_minutes, open_time_max_minutes,
    vodafone_cash_number
  ) VALUES (
    v_lounge_id, 'Test P0 Lounge', v_test_owner, 'Africa/Cairo', 'EGP', true,
    15, 60, 480, '01012345678'
  );

  INSERT INTO public.rooms (
    id, lounge_id, name, hourly_rate_single, hourly_rate_multi, extra_controller_price,
    is_available, status, control_type
  ) VALUES (
    v_room_id, v_lounge_id, 'Room P0-1', 100.0, 150.0, 20.0,
    true, 'available', 'manual'
  );

  INSERT INTO public.extras (
    id, lounge_id, name, name_ar, price, is_active, is_available, track_stock, stock_quantity
  ) VALUES (
    v_extra_id, v_lounge_id, 'Cola', 'كولا', 25.0, true, true, true, 10
  );

  -- 2. Test Quote Booking Price (Server-Side Calculation & Midnight Crossing)
  v_quote := public.quote_booking_price(
    v_room_id,
    current_date,
    time '23:00',
    time '01:00',
    'single',
    1,
    NULL
  );

  IF (v_quote->>'total')::numeric <> 240.00 THEN -- 2 hours * 100 + 2 hours * 20 (extra controller) = 240
    RAISE EXCEPTION 'TEST FAILED: Quote booking price mismatch. Expected 240.00, got %', v_quote->>'total';
  END IF;

  IF (v_quote->>'currency') <> 'EGP' THEN
    RAISE EXCEPTION 'TEST FAILED: Quote currency mismatch';
  END IF;

  RAISE NOTICE '✓ Quote Booking Price & Midnight duration test passed';

  -- 3. Test Shift Gating on Payment Collection
  -- Create an unpaid completed booking fixture
  INSERT INTO public.bookings (
    id, lounge_id, room_id, user_id, date, start_time, end_time,
    room_price, total_price, status, payment_status, is_open_time
  ) VALUES (
    v_booking_id, v_lounge_id, v_room_id, v_test_owner, current_date,
    time '14:00', time '16:00', 200.0, 200.0, 'completed'::public.booking_status,
    'unpaid', false
  );

  -- Attempt collection without active shift (must fail)
  v_err_thrown := false;
  BEGIN
    PERFORM public.collect_completed_booking_payment(v_booking_id, 'cash', 200.0);
  EXCEPTION WHEN OTHERS THEN
    v_err_thrown := true;
  END;

  IF NOT v_err_thrown THEN
    RAISE EXCEPTION 'TEST FAILED: Payment collection succeeded without an open shift';
  END IF;
  RAISE NOTICE '✓ Shift gating (missing shift rejection) test passed';

  -- Now open a shift for the lounge
  INSERT INTO public.shifts (
    id, lounge_id, cashier_id, status, starting_cash, opened_at
  ) VALUES (
    v_shift_id, v_lounge_id, v_test_owner, 'open', 500.0, now()
  );

  -- Now collect payment for the completed session
  v_res := public.collect_completed_booking_payment(v_booking_id, 'cash', 200.0);
  IF (v_res->>'payment_status') <> 'paid' THEN
    RAISE EXCEPTION 'TEST FAILED: Booking payment status not marked as paid';
  END IF;

  -- Verify shift_payment created
  IF NOT EXISTS (
    SELECT 1 FROM public.shift_payments WHERE booking_id = v_booking_id AND shift_id = v_shift_id
  ) THEN
    RAISE EXCEPTION 'TEST FAILED: shift_payments record missing after collection';
  END IF;

  -- Verify booking status remained completed (NOT reverted or re-opened)
  IF NOT EXISTS (
    SELECT 1 FROM public.bookings WHERE id = v_booking_id AND status = 'completed' AND payment_status = 'paid'
  ) THEN
    RAISE EXCEPTION 'TEST FAILED: Booking status changed or not completed';
  END IF;

  RAISE NOTICE '✓ Post-close session payment collection test passed';

  -- 4. Test Idempotent Repeated Closure
  v_res := public.complete_booking_session(v_booking_id, NULL);
  IF (v_res->>'already_completed')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION 'TEST FAILED: Repeated closure must report already_completed = true';
  END IF;
  IF (v_res->>'final_total')::numeric <> 200.0 THEN
    RAISE EXCEPTION 'TEST FAILED: Repeated closure final_total mismatch';
  END IF;
  RAISE NOTICE '✓ Idempotent session closure test passed';

  -- 5. Test Canteen Stock Atomic Decrement & Cancellation Recovery
  v_res := public.place_canteen_order(
    NULL,
    jsonb_build_array(jsonb_build_object('extra_id', v_extra_id, 'quantity', 3)),
    'Test order'
  );
  v_order_id := (v_res->>'order_id')::uuid;

  SELECT stock_quantity INTO v_stock FROM public.extras WHERE id = v_extra_id;
  IF v_stock <> 7 THEN
    RAISE EXCEPTION 'TEST FAILED: Stock not decremented after canteen order. Expected 7, got %', v_stock;
  END IF;

  -- Cancel the canteen order
  v_res := public.cancel_canteen_order(v_order_id, 'Test cancel');
  IF (v_res->>'status') <> 'cancelled' THEN
    RAISE EXCEPTION 'TEST FAILED: Order status not marked as cancelled';
  END IF;

  SELECT stock_quantity INTO v_stock FROM public.extras WHERE id = v_extra_id;
  IF v_stock <> 10 THEN
    RAISE EXCEPTION 'TEST FAILED: Stock not restored after canteen order cancel. Expected 10, got %', v_stock;
  END IF;
  RAISE NOTICE '✓ Canteen stock atomic reservation & cancel recovery test passed';

  -- 6. Test Audit Logging
  IF NOT EXISTS (
    SELECT 1 FROM public.audit_events
    WHERE lounge_id = v_lounge_id AND event_code = 'payment_collected'
  ) THEN
    RAISE EXCEPTION 'TEST FAILED: Audit event for payment_collected missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.audit_events
    WHERE lounge_id = v_lounge_id AND event_code = 'canteen_order_cancelled'
  ) THEN
    RAISE EXCEPTION 'TEST FAILED: Audit event for canteen_order_cancelled missing';
  END IF;
  RAISE NOTICE '✓ Audit logging verification passed';

  RAISE NOTICE '>>> ALL PHASE 1 TESTS PASSED SUCCESSFULLY! <<<';
END $test$;

ROLLBACK; -- Always rollback in test script to prevent test data pollution!
