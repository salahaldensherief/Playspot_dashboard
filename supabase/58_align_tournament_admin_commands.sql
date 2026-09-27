BEGIN;

CREATE OR REPLACE FUNCTION public.review_tournament_payment_for_participant(
  p_participant_id uuid,
  p_approved boolean,
  p_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_participant public.tournament_participants%ROWTYPE;
  v_tournament public.tournaments%ROWTYPE;
  v_submission public.tournament_payment_submissions%ROWTYPE;
  v_result jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000';
  END IF;

  SELECT *
  INTO v_participant
  FROM public.tournament_participants
  WHERE id = p_participant_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'participant_not_found' USING ERRCODE = 'P0002';
  END IF;

  SELECT *
  INTO v_tournament
  FROM public.tournaments
  WHERE id = v_participant.tournament_id;

  IF NOT (
    public.is_super_admin()
    OR private.is_lounge_manager(v_tournament.lounge_id)
  ) THEN
    RAISE EXCEPTION 'not_authorized' USING ERRCODE = '42501';
  END IF;

  SELECT *
  INTO v_submission
  FROM public.tournament_payment_submissions
  WHERE participant_id = p_participant_id
    AND status = 'pending'
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'pending_payment_submission_not_found'
      USING ERRCODE = 'P0002';
  END IF;

  IF p_approved THEN
    v_result := to_jsonb(
      public.approve_tournament_payment(
        v_submission.id,
        NULLIF(btrim(p_reason), '')
      )
    );
  ELSE
    IF NULLIF(btrim(p_reason), '') IS NULL THEN
      RAISE EXCEPTION 'rejection_reason_required'
        USING ERRCODE = '22023';
    END IF;

    PERFORM public.reject_tournament_payment(
      v_submission.id,
      btrim(p_reason)
    );

    SELECT to_jsonb(tp)
    INTO v_result
    FROM public.tournament_participants AS tp
    WHERE tp.id = p_participant_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'participant', v_result,
    'approved', p_approved
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.review_tournament_payment_for_participant(
  uuid, boolean, text
) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.review_tournament_payment_for_participant(
  uuid, boolean, text
) TO authenticated, service_role, supabase_auth_admin;

CREATE OR REPLACE FUNCTION public.withdraw_tournament_participant(
  p_participant_id uuid,
  p_reason text DEFAULT 'Admin withdrawal'
)
RETURNS public.tournament_participants
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_participant public.tournament_participants%ROWTYPE;
  v_tournament public.tournaments%ROWTYPE;
  v_old_waitlist_position integer;
  v_was_seat_holder boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000';
  END IF;

  SELECT *
  INTO v_participant
  FROM public.tournament_participants
  WHERE id = p_participant_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'participant_not_found' USING ERRCODE = 'P0002';
  END IF;

  SELECT *
  INTO v_tournament
  FROM public.tournaments
  WHERE id = v_participant.tournament_id
  FOR UPDATE;

  IF NOT (
    public.is_super_admin()
    OR private.is_lounge_manager(v_tournament.lounge_id)
  ) THEN
    RAISE EXCEPTION 'not_authorized' USING ERRCODE = '42501';
  END IF;

  IF v_tournament.status IN (
    'draw_completed',
    'in_progress',
    'completed',
    'cancelled'
  ) THEN
    RAISE EXCEPTION 'withdrawal_closed_after_draw'
      USING ERRCODE = '55000';
  END IF;

  IF v_participant.registration_status IN (
    'withdrawn',
    'cancelled',
    'expired',
    'eliminated',
    'no_show'
  ) THEN
    RAISE EXCEPTION 'participant_not_withdrawable'
      USING ERRCODE = '55000';
  END IF;

  v_was_seat_holder := v_participant.registration_status IN (
    'pending_payment',
    'confirmed',
    'checked_in'
  );
  v_old_waitlist_position := v_participant.waitlist_position;

  IF v_participant.payment_status = 'paid' THEN
    INSERT INTO public.tournament_refunds (
      tournament_id,
      participant_id,
      user_id,
      amount,
      reason
    )
    VALUES (
      v_tournament.id,
      v_participant.id,
      v_participant.user_id,
      v_tournament.entry_fee,
      COALESCE(NULLIF(btrim(p_reason), ''), 'Admin withdrawal')
    )
    ON CONFLICT DO NOTHING;
  END IF;

  UPDATE public.tournament_participants
  SET registration_status = 'withdrawn',
      payment_status = CASE
        WHEN payment_status = 'paid' THEN 'refund_pending'
        ELSE payment_status
      END,
      payment_deadline = NULL,
      waitlist_position = NULL,
      updated_at = now()
  WHERE id = v_participant.id
  RETURNING *
  INTO v_participant;

  IF v_old_waitlist_position IS NOT NULL THEN
    UPDATE public.tournament_participants
    SET waitlist_position = waitlist_position - 1,
        updated_at = now()
    WHERE tournament_id = v_tournament.id
      AND registration_status = 'waitlist'
      AND waitlist_position > v_old_waitlist_position;
  END IF;

  IF v_was_seat_holder THEN
    PERFORM private.promote_tournament_waitlist_internal(v_tournament.id);
  END IF;

  PERFORM public.tournament_audit(
    v_tournament.id,
    'participant_withdrawn_by_admin',
    v_participant.id,
    NULL,
    NULL,
    to_jsonb(v_participant),
    COALESCE(NULLIF(btrim(p_reason), ''), 'Admin withdrawal')
  );

  RETURN v_participant;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.withdraw_tournament_participant(uuid, text)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.withdraw_tournament_participant(uuid, text)
TO authenticated, service_role, supabase_auth_admin;


CREATE OR REPLACE FUNCTION public.start_tournament_match(
  p_match_id uuid,
  p_room_id uuid
)
RETURNS public.tournament_matches
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_match public.tournament_matches%ROWTYPE;
  v_tournament public.tournaments%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000';
  END IF;

  SELECT *
  INTO v_match
  FROM public.tournament_matches
  WHERE id = p_match_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'match_not_found' USING ERRCODE = 'P0002';
  END IF;

  SELECT *
  INTO v_tournament
  FROM public.tournaments
  WHERE id = v_match.tournament_id;

  IF NOT (
    public.is_super_admin()
    OR private.is_lounge_manager(v_tournament.lounge_id)
  ) THEN
    RAISE EXCEPTION 'not_authorized' USING ERRCODE = '42501';
  END IF;

  IF v_match.status <> 'scheduled'
     OR v_match.player1_id IS NULL
     OR v_match.player2_id IS NULL THEN
    RAISE EXCEPTION 'match_not_ready' USING ERRCODE = '55000';
  END IF;

  IF p_room_id IS NOT NULL AND NOT EXISTS (
    SELECT 1
    FROM public.rooms AS r
    WHERE r.id = p_room_id
      AND r.lounge_id = v_tournament.lounge_id
      AND r.is_active IS TRUE
      AND r.status <> 'deleted'
  ) THEN
    RAISE EXCEPTION 'invalid_tournament_room' USING ERRCODE = '22023';
  END IF;

  UPDATE public.tournament_matches
  SET room_id = COALESCE(p_room_id, room_id),
      status = 'in_progress',
      started_at = COALESCE(started_at, now()),
      updated_at = now()
  WHERE id = v_match.id
  RETURNING *
  INTO v_match;

  PERFORM public.tournament_audit(
    v_tournament.id,
    'match_started',
    NULL,
    v_match.id,
    NULL,
    to_jsonb(v_match)
  );

  RETURN v_match;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.start_tournament_match(uuid, uuid)
FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.start_tournament_match(uuid, uuid)
TO authenticated, service_role, supabase_auth_admin;

COMMIT;
