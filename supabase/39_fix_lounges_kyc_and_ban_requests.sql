-- 39_fix_lounges_kyc_and_ban_requests.sql
-- Fixes:
-- 1. Standardizes super admin permission checks across suspend_lounge, approve_lounge_ban_request, approve_global_ban_request, and reject_ban_request to use public.is_super_admin().
-- 2. Ensures KYC rejection retains profiles.is_active = true so owners can log in to view rejection reasons and re-submit valid documents.

CREATE OR REPLACE FUNCTION public.review_kyc(p_user_id uuid, p_approve boolean, p_notes text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
DECLARE
  v_kyc_updated INT;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Only Super Admin can review KYC';
  END IF;

  UPDATE public.kyc_submissions
  SET status = CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END,
      notes = p_notes,
      updated_at = NOW()
  WHERE user_id = p_user_id;

  GET DIAGNOSTICS v_kyc_updated = ROW_COUNT;
  IF v_kyc_updated = 0 THEN
    RAISE EXCEPTION 'KYC submission not found for user %', p_user_id;
  END IF;

  IF p_approve THEN
    UPDATE public.lounges
    SET status = 'active', is_open = true, is_active = true
    WHERE owner_id = p_user_id;

    UPDATE public.profiles
    SET role = 'owner', is_active = true, is_setup_completed = true, updated_at = NOW()
    WHERE id = p_user_id;
  ELSE
    UPDATE public.lounges
    SET status = 'rejected', is_open = false, is_active = false
    WHERE owner_id = p_user_id;

    UPDATE public.profiles
    SET is_setup_completed = false, updated_at = NOW()
    WHERE id = p_user_id;
  END IF;

  INSERT INTO public.notifications (user_id, title, title_ar, title_en, body, body_ar, body_en, type, metadata)
  VALUES (
    p_user_id,
    CASE WHEN p_approve THEN 'KYC Approved' ELSE 'KYC Rejected' END,
    CASE WHEN p_approve THEN 'تم توثيق الحساب (KYC)' ELSE 'تم رفض توثيق الحساب (KYC)' END,
    CASE WHEN p_approve THEN 'Your KYC verification has been approved' ELSE 'Your KYC verification has been rejected' END,
    CASE WHEN p_approve THEN 'تهانينا! تم اعتماد وتوثيق حسابك بنجاح' ELSE COALESCE('تم رفض طلب التوثيق: ' || p_notes, 'تم رفض طلب التوثيق') END,
    CASE WHEN p_approve THEN 'تهانينا! تم اعتماد وتوثيق حسابك بنجاح' ELSE COALESCE('تم رفض طلب التوثيق: ' || p_notes, 'تم رفض طلب التوثيق') END,
    CASE WHEN p_approve THEN 'Congratulations! Your KYC account verification was approved.' ELSE COALESCE('KYC verification rejected: ' || p_notes, 'KYC verification rejected.') END,
    CASE WHEN p_approve THEN 'kyc_approved' ELSE 'kyc_rejected' END,
    jsonb_build_object('approved', p_approve, 'notes', p_notes)
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.approve_lounge_ban_request(p_request_id uuid, p_admin_notes text DEFAULT NULL::text)
 RETURNS user_ban_requests
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_request public.user_ban_requests;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Only super admins can approve ban requests';
  END IF;

  SELECT * INTO v_request
  FROM public.user_ban_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Ban request not found';
  END IF;
  IF v_request.status <> 'pending' THEN
    RAISE EXCEPTION 'Ban request is not pending';
  END IF;

  INSERT INTO public.lounge_banned_users (lounge_id, user_id)
  VALUES (v_request.lounge_id, v_request.user_id)
  ON CONFLICT (lounge_id, user_id) DO NOTHING;

  UPDATE public.user_ban_requests
  SET status = 'approved_lounge_only', admin_notes = p_admin_notes
  WHERE id = p_request_id
  RETURNING * INTO v_request;

  RETURN v_request;
END;
$function$;

CREATE OR REPLACE FUNCTION public.approve_global_ban_request(p_request_id uuid, p_admin_notes text DEFAULT NULL::text)
 RETURNS user_ban_requests
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_request public.user_ban_requests;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Only super admins can approve ban requests';
  END IF;

  SELECT * INTO v_request
  FROM public.user_ban_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Ban request not found';
  END IF;
  IF v_request.status <> 'pending' THEN
    RAISE EXCEPTION 'Ban request is not pending';
  END IF;

  UPDATE public.profiles
  SET is_banned = true,
      banned_reason = v_request.reason,
      updated_at = now()
  WHERE id = v_request.user_id;

  UPDATE public.user_ban_requests
  SET status = 'approved_global', admin_notes = p_admin_notes
  WHERE id = p_request_id
  RETURNING * INTO v_request;

  RETURN v_request;
END;
$function$;

CREATE OR REPLACE FUNCTION public.suspend_lounge(p_lounge_id uuid, p_reason text)
 RETURNS lounges
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_lounge public.lounges;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Only super admins can suspend lounges';
  END IF;
  IF p_reason IS NULL OR length(btrim(p_reason)) = 0 THEN
    RAISE EXCEPTION 'Suspension reason is required';
  END IF;

  UPDATE public.lounges
  SET is_active = false,
      suspension_reason = p_reason
  WHERE id = p_lounge_id
  RETURNING * INTO v_lounge;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Lounge not found';
  END IF;
  RETURN v_lounge;
END;
$function$;

CREATE OR REPLACE FUNCTION public.reject_ban_request(p_request_id uuid, p_admin_notes text)
 RETURNS user_ban_requests
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_request public.user_ban_requests;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Only super admins can reject ban requests';
  END IF;
  IF p_admin_notes IS NULL OR length(btrim(p_admin_notes)) = 0 THEN
    RAISE EXCEPTION 'Rejection notes are required';
  END IF;

  UPDATE public.user_ban_requests
  SET status = 'rejected', admin_notes = p_admin_notes
  WHERE id = p_request_id
    AND status = 'pending'
  RETURNING * INTO v_request;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pending ban request not found';
  END IF;
  RETURN v_request;
END;
$function$;
