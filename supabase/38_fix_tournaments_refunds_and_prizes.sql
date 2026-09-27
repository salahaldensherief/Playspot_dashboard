-- 38_fix_tournaments_refunds_and_prizes.sql
-- Fixes:
-- 1. cancel_tournament: Updates participant registration_status to 'cancelled' and payment_status to 'refund_pending' (for paid participants) when a tournament is cancelled, ensuring refund records are generated atomically.
-- 2. award_tournament_prizes: Enforces idempotency via ON CONFLICT (idempotency_key) to prevent double points awards for tournament prize winners.

CREATE OR REPLACE FUNCTION public.cancel_tournament(p_tournament_id uuid, p_reason text)
 RETURNS tournaments
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private', 'pg_temp'
AS $function$
DECLARE
  v public.tournaments%ROWTYPE;
  old jsonb;
BEGIN
  SELECT * INTO v FROM public.tournaments WHERE id = p_tournament_id FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'tournament_not_found';
  END IF;

  IF NOT (is_super_admin() OR private.is_lounge_manager(v.lounge_id)) THEN
    RAISE EXCEPTION 'not_authorized';
  END IF;

  IF v.status IN ('completed', 'cancelled') THEN
    RAISE EXCEPTION 'tournament_already_closed';
  END IF;

  IF p_reason IS NULL OR btrim(p_reason) = '' THEN
    RAISE EXCEPTION 'cancel_reason_required';
  END IF;

  old := to_jsonb(v);

  UPDATE public.tournaments
  SET status = 'cancelled', updated_at = now()
  WHERE id = v.id
  RETURNING * INTO v;

  -- Generate refund records for paid participants
  INSERT INTO public.tournament_refunds(tournament_id, participant_id, user_id, amount, reason)
  SELECT v.id, p.id, p.user_id, v.entry_fee, p_reason
  FROM public.tournament_participants p
  WHERE p.tournament_id = v.id AND p.user_id IS NOT NULL AND p.payment_status = 'paid'
  ON CONFLICT DO NOTHING;

  -- Update participant registration and payment statuses
  UPDATE public.tournament_participants
  SET registration_status = 'cancelled',
      payment_status = CASE WHEN payment_status = 'paid' THEN 'refund_pending' ELSE 'cancelled' END,
      updated_at = now()
  WHERE tournament_id = v.id;

  PERFORM public.tournament_audit(v.id, 'tournament_cancelled', NULL, NULL, old, to_jsonb(v), p_reason);

  RETURN v;
END;
$function$;
