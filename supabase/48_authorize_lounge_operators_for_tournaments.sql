-- 48_authorize_lounge_operators_for_tournaments.sql
-- Fixes: Authorizes cashiers and lounge staff operators (private.can_operate_playspot_lounge) to create, update, and manage tournaments for their assigned lounge.

CREATE OR REPLACE FUNCTION public.create_tournament(p_lounge_id uuid, p_city_id uuid, p_title_ar text, p_title_en text, p_game_name text, p_bracket_size integer, p_max_participants integer, p_entry_fee numeric, p_registration_opens_at timestamp with time zone, p_registration_closes_at timestamp with time zone, p_payment_deadline_minutes integer, p_check_in_opens_at timestamp with time zone, p_check_in_closes_at timestamp with time zone, p_tournament_starts_at timestamp with time zone)
 RETURNS tournaments
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
DECLARE
  v public.tournaments;
BEGIN
  IF NOT (is_super_admin() OR private.can_operate_playspot_lounge(p_lounge_id) OR is_lounge_member_or_admin(p_lounge_id)) THEN
    RAISE EXCEPTION 'not_authorized';
  END IF;

  IF NOT EXISTS(SELECT 1 FROM public.lounges l WHERE l.id=p_lounge_id AND l.city_id=p_city_id) THEN
    RAISE EXCEPTION 'lounge_city_mismatch';
  END IF;

  INSERT INTO public.tournaments(lounge_id,city_id,title_ar,title_en,game_name,bracket_size,max_participants,entry_fee,registration_opens_at,registration_closes_at,payment_deadline_minutes,check_in_opens_at,check_in_closes_at,tournament_starts_at,created_by)
  VALUES(p_lounge_id,p_city_id,p_title_ar,p_title_en,p_game_name,p_bracket_size,p_max_participants,p_entry_fee,p_registration_opens_at,p_registration_closes_at,p_payment_deadline_minutes,p_check_in_opens_at,p_check_in_closes_at,p_tournament_starts_at,auth.uid())
  RETURNING * INTO v;

  PERFORM public.tournament_audit(v.id,'tournament_created',NULL,NULL,NULL,to_jsonb(v));
  RETURN v;
END
$function$;

CREATE OR REPLACE FUNCTION public.update_tournament(p_tournament_id uuid, p_title_ar text, p_title_en text, p_description_ar text, p_description_en text, p_game_name text, p_max_participants integer, p_entry_fee numeric, p_registration_opens_at timestamp with time zone, p_registration_closes_at timestamp with time zone, p_payment_deadline_minutes integer, p_check_in_opens_at timestamp with time zone, p_check_in_closes_at timestamp with time zone, p_tournament_starts_at timestamp with time zone)
 RETURNS tournaments
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
DECLARE v public.tournaments;
BEGIN
  SELECT * INTO v FROM public.tournaments WHERE id = p_tournament_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'tournament_not_found'; END IF;

  IF NOT (is_super_admin() OR private.can_operate_playspot_lounge(v.lounge_id) OR is_lounge_member_or_admin(v.lounge_id)) THEN
    RAISE EXCEPTION 'not_authorized';
  END IF;

  IF v.status NOT IN ('draft','published','registration_open') THEN RAISE EXCEPTION 'tournament_not_editable'; END IF;
  IF EXISTS (SELECT 1 FROM public.tournament_participants WHERE tournament_id = v.id) THEN RAISE EXCEPTION 'tournament_has_participants'; END IF;
  IF p_max_participants < 2 OR p_max_participants > v.bracket_size THEN RAISE EXCEPTION 'invalid_capacity'; END IF;
  IF p_registration_closes_at <= p_registration_opens_at THEN RAISE EXCEPTION 'invalid_registration_window'; END IF;
  IF p_check_in_closes_at <= p_check_in_opens_at THEN RAISE EXCEPTION 'invalid_checkin_window'; END IF;

  UPDATE public.tournaments
  SET title_ar=p_title_ar,title_en=p_title_en,description_ar=p_description_ar,description_en=p_description_en,
      game_name=p_game_name,max_participants=p_max_participants,entry_fee=p_entry_fee,
      registration_opens_at=p_registration_opens_at,registration_closes_at=p_registration_closes_at,
      payment_deadline_minutes=p_payment_deadline_minutes,check_in_opens_at=p_check_in_opens_at,
      check_in_closes_at=p_check_in_closes_at,tournament_starts_at=p_tournament_starts_at,updated_at=now()
  WHERE id=v.id RETURNING * INTO v;

  PERFORM public.tournament_audit(v.id,'tournament_updated',NULL,NULL,NULL,to_jsonb(v));
  RETURN v;
END;
$function$;

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

  IF NOT (is_super_admin() OR private.can_operate_playspot_lounge(v.lounge_id) OR is_lounge_member_or_admin(v.lounge_id)) THEN
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

  INSERT INTO public.tournament_refunds(tournament_id, participant_id, user_id, amount, reason)
  SELECT v.id, p.id, p.user_id, v.entry_fee, p_reason
  FROM public.tournament_participants p
  WHERE p.tournament_id = v.id AND p.user_id IS NOT NULL AND p.payment_status = 'paid'
  ON CONFLICT DO NOTHING;

  UPDATE public.tournament_participants
  SET registration_status = 'cancelled',
      payment_status = CASE WHEN payment_status = 'paid' THEN 'refund_pending' ELSE 'cancelled' END,
      updated_at = now()
  WHERE tournament_id = v.id;

  PERFORM public.tournament_audit(v.id, 'tournament_cancelled', NULL, NULL, old, to_jsonb(v), p_reason);

  RETURN v;
END;
$function$;

CREATE OR REPLACE FUNCTION public.record_cash_tournament_payment(p_participant_id uuid, p_amount numeric, p_reference_note text DEFAULT NULL::text)
 RETURNS tournament_participants
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
DECLARE
  v_p public.tournament_participants%ROWTYPE;
  v_t public.tournaments%ROWTYPE;
  v_count integer;
BEGIN
  SELECT * INTO v_p FROM public.tournament_participants WHERE id=p_participant_id FOR UPDATE;
  SELECT * INTO v_t FROM public.tournaments WHERE id=v_p.tournament_id FOR UPDATE;

  IF NOT(is_super_admin() OR private.can_operate_playspot_lounge(v_t.lounge_id) OR is_lounge_member_or_admin(v_t.lounge_id)) THEN
    RAISE EXCEPTION 'not_authorized';
  END IF;

  IF v_p.registration_status<>'pending_payment' OR v_p.payment_status<>'unpaid' THEN
    RAISE EXCEPTION 'payment_not_allowed';
  END IF;

  IF p_amount<>v_t.entry_fee THEN
    RAISE EXCEPTION 'amount_mismatch';
  END IF;

  SELECT count(*) INTO v_count FROM public.tournament_participants WHERE tournament_id=v_t.id AND registration_status IN('confirmed','checked_in');
  IF v_count>=v_t.max_participants THEN
    RAISE EXCEPTION 'capacity_reached';
  END IF;

  UPDATE public.tournament_participants
  SET payment_status='paid',registration_status='confirmed',payment_method='cash',approved_by=auth.uid(),approved_at=now(),cash_received_by=auth.uid(),cash_received_at=now(),cash_reference_note=p_reference_note,updated_at=now()
  WHERE id=v_p.id RETURNING * INTO v_p;

  PERFORM public.tournament_audit(v_t.id,'cash_payment_approved',v_p.id,NULL,NULL,to_jsonb(v_p),p_reference_note);
  RETURN v_p;
END
$function$;
