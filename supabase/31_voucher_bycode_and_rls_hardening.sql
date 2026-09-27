-- ============================================================================
-- 31_voucher_bycode_and_rls_hardening.sql
-- Scope 3 audit fixes (2026-09-27). Evidence: live pg_proc / pg_policies / 42703 probe.
--
-- A) validate_voucher_by_code / consume_voucher_by_code referenced columns that do
--    not exist on public.user_vouchers (is_used, used_in_booking_id) and selected a
--    nonexistent min_spend column. Live proof:
--    ERROR 42703: column "is_used" does not exist. Both rewritten against the real
--    schema (status, used_booking_id) with the same expiry semantics as the by-id
--    variants (validate_voucher / consume_voucher). min_spend kept in the output as 0
--    for caller compatibility.
--
-- B) profiles_update_policy WITH CHECK only blocked role='super_admin' and did not
--    constrain lounge_id/is_banned. The guard trigger private.guard_profile_sensitive_columns
--    already reverts those columns for authenticated writers, so this tightens the policy
--    to match exactly what the guard enforces (no behavior change for legitimate callers;
--    invalid writes now fail at the policy instead of silently reverting).
--
-- C) Pinned search_path on SECURITY DEFINER functions that had none (all object
--    references are schema-qualified):
--    calculate_booking_total(uuid,numeric,text,numeric,text)
--    consume_voucher_by_code(text,uuid)
--    validate_voucher_by_code(text)
--    verify_and_hold_slot(uuid,timestamptz,timestamptz,uuid,integer)
--    submit_tournament_payment(uuid,uuid,uuid,numeric,text,text)
-- ============================================================================

BEGIN;

-- ---------- A + C: voucher by-code functions ----------
CREATE OR REPLACE FUNCTION public.validate_voucher_by_code(p_code text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  v_voucher public.user_vouchers%ROWTYPE;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('valid', false, 'error', 'Unauthenticated user');
  END IF;

  SELECT * INTO v_voucher
  FROM public.user_vouchers
  WHERE UPPER(TRIM(code)) = UPPER(TRIM(p_code))
    AND user_id = v_user_id
    AND status = 'active'
    AND (expires_at IS NULL OR expires_at > NOW())
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('valid', false, 'error', 'Voucher is invalid, expired, or already used');
  END IF;

  RETURN jsonb_build_object(
    'valid', true,
    'voucher_id', v_voucher.id,
    'code', v_voucher.code,
    'reward_type', v_voucher.reward_type,
    'reward_value', v_voucher.reward_value,
    'min_spend', 0
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.consume_voucher_by_code(p_code text, p_booking_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthenticated user';
  END IF;

  UPDATE public.user_vouchers
  SET status = 'used',
      used_at = NOW(),
      used_booking_id = p_booking_id
  WHERE UPPER(TRIM(code)) = UPPER(TRIM(p_code))
    AND user_id = v_user_id
    AND status = 'active'
    AND (expires_at IS NULL OR expires_at >= NOW());

  RETURN FOUND;
END;
$function$;

-- ---------- C: pin search_path, bodies unchanged ----------
CREATE OR REPLACE FUNCTION public.calculate_booking_total(p_room_id uuid, p_duration_hours numeric, p_voucher_code text DEFAULT NULL::text, p_manual_discount numeric DEFAULT 0, p_manual_discount_reason text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_room record;
  v_base_subtotal numeric;
  v_voucher_discount numeric := 0;
  v_staff_discount numeric := COALESCE(p_manual_discount, 0);
  v_final_total numeric;
  v_voucher_res jsonb;
BEGIN
  SELECT * INTO v_room
  FROM public.rooms
  WHERE id = p_room_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Room not found';
  END IF;

  v_base_subtotal := COALESCE(v_room.hourly_rate_single, 0) * p_duration_hours;

  -- Apply voucher discount if valid code is supplied
  IF p_voucher_code IS NOT NULL AND TRIM(p_voucher_code) <> '' THEN
    v_voucher_res := public.validate_voucher_by_code(p_voucher_code);
    IF (v_voucher_res->>'valid')::boolean THEN
      IF (v_voucher_res->>'reward_type') = 'discount_fixed' THEN
        v_voucher_discount := (v_voucher_res->>'reward_value')::numeric;
      ELSIF (v_voucher_res->>'reward_type') = 'free_hour' THEN
        v_voucher_discount := COALESCE(v_room.hourly_rate_single, 0) * (v_voucher_res->>'reward_value')::numeric;
      END IF;
    END IF;
  END IF;

  -- Total price calculation respects both voucher discount and staff manual discount/offline offer
  v_final_total := GREATEST(0, v_base_subtotal - v_voucher_discount - v_staff_discount);

  RETURN jsonb_build_object(
    'base_subtotal', v_base_subtotal,
    'voucher_discount', v_voucher_discount,
    'staff_manual_discount', v_staff_discount,
    'manual_discount_reason', p_manual_discount_reason,
    'final_total', v_final_total
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.verify_and_hold_slot(p_room_id uuid, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_user_id uuid, p_hold_minutes integer DEFAULT 10)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_overlapping_count integer;
  v_hold_expires_at timestamptz := NOW() + (p_hold_minutes || ' minutes')::interval;
  v_hold_id uuid;
BEGIN
  -- Perform atomic lock check on existing non-cancelled bookings or active holds for the target room
  SELECT COUNT(*) INTO v_overlapping_count
  FROM public.bookings
  WHERE room_id = p_room_id
    AND status NOT IN ('cancelled', 'rejected', 'expired')
    AND (
      (p_start_time < end_time AND p_end_time > start_time)
    );

  IF v_overlapping_count > 0 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'SLOT_OVERLAP_CONFLICT',
      'message', 'The selected time slot overlaps with an existing booking or hold.'
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'hold_expires_at', v_hold_expires_at
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.submit_tournament_payment(p_participant_id uuid, p_tournament_id uuid, p_user_id uuid, p_amount numeric, p_payment_method text, p_receipt_url text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
        DECLARE
            v_curr_status TEXT;
            v_result JSONB;
        BEGIN
            -- Atomic row lock on participant row to prevent TOCTOU race conditions
            SELECT status INTO v_curr_status
            FROM public.tournament_participants
            WHERE id = p_participant_id
            FOR UPDATE;

            IF v_curr_status IN ('payment_submitted', 'paid', 'confirmed') THEN
                RETURN jsonb_build_object(
                    'success', true,
                    'already_submitted', true,
                    'message', 'Payment receipt already submitted and under review.'
                );
            END IF;

            -- Update status atomically
            UPDATE public.tournament_participants
            SET status = 'payment_submitted',
                payment_method = p_payment_method,
                receipt_url = p_receipt_url,
                updated_at = NOW()
            WHERE id = p_participant_id;

            RETURN jsonb_build_object(
                'success', true,
                'already_submitted', false,
                'participant_id', p_participant_id
            );
        END;
        $function$;

-- ---------- B: tighten profiles_update_policy ----------
DROP POLICY IF EXISTS profiles_update_policy ON public.profiles;
CREATE POLICY profiles_update_policy ON public.profiles
  AS PERMISSIVE
  FOR UPDATE
  TO authenticated
  USING (
    (id = auth.uid())
    OR is_super_admin()
    OR ((lounge_id IS NOT NULL) AND is_lounge_member_or_admin(lounge_id))
  )
  WITH CHECK (
    is_super_admin()
    OR (
      (SELECT auth.uid()) = id
      AND role      IS NOT DISTINCT FROM (SELECT s.role      FROM private.current_profile_security_values((SELECT auth.uid())) AS s(role, lounge_id, is_banned))
      AND lounge_id IS NOT DISTINCT FROM (SELECT s.lounge_id FROM private.current_profile_security_values((SELECT auth.uid())) AS s(role, lounge_id, is_banned))
      AND is_banned IS NOT DISTINCT FROM (SELECT s.is_banned FROM private.current_profile_security_values((SELECT auth.uid())) AS s(role, lounge_id, is_banned))
    )
    OR (
      lounge_id IS NOT NULL
      AND is_lounge_member_or_admin(lounge_id)
      AND role      IS NOT DISTINCT FROM (SELECT s.role      FROM private.current_profile_security_values(id) AS s(role, lounge_id, is_banned))
      AND lounge_id IS NOT DISTINCT FROM (SELECT s.lounge_id FROM private.current_profile_security_values(id) AS s(role, lounge_id, is_banned))
      AND is_banned IS NOT DISTINCT FROM (SELECT s.is_banned FROM private.current_profile_security_values(id) AS s(role, lounge_id, is_banned))
    )
  );

COMMIT;
