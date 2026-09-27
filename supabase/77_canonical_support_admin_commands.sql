BEGIN;

CREATE OR REPLACE FUNCTION public.admin_update_support_settings(
  p_whatsapp_phone text,
  p_support_phone text,
  p_support_email text,
  p_vodafone_cash_number text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE='42501';
  END IF;

  INSERT INTO public.support_settings (
    id, whatsapp_phone, support_phone, support_email,
    vodafone_cash_number, updated_by, updated_at
  )
  VALUES (
    1,
    nullif(btrim(p_whatsapp_phone), ''),
    nullif(btrim(p_support_phone), ''),
    nullif(btrim(p_support_email), ''),
    nullif(btrim(p_vodafone_cash_number), ''),
    auth.uid(),
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    whatsapp_phone = EXCLUDED.whatsapp_phone,
    support_phone = EXCLUDED.support_phone,
    support_email = EXCLUDED.support_email,
    vodafone_cash_number = EXCLUDED.vodafone_cash_number,
    updated_by = auth.uid(),
    updated_at = now();

  RETURN jsonb_build_object('success', true);
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_upsert_legal_policy(
  p_policy_key text,
  p_title_ar text,
  p_title_en text,
  p_content_ar text,
  p_content_en text,
  p_is_published boolean
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_key text := btrim(coalesce(p_policy_key, ''));
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE='42501';
  END IF;
  IF v_key = '' THEN
    RAISE EXCEPTION 'policy_key is required' USING ERRCODE='22023';
  END IF;

  INSERT INTO public.legal_policies (
    policy_key, title_ar, title_en, content_ar, content_en,
    is_published, updated_by, updated_at
  )
  VALUES (
    v_key, btrim(p_title_ar), btrim(p_title_en),
    coalesce(p_content_ar, ''), coalesce(p_content_en, ''),
    coalesce(p_is_published, true), auth.uid(), now()
  )
  ON CONFLICT (policy_key) DO UPDATE SET
    title_ar = EXCLUDED.title_ar,
    title_en = EXCLUDED.title_en,
    content_ar = EXCLUDED.content_ar,
    content_en = EXCLUDED.content_en,
    is_published = EXCLUDED.is_published,
    updated_by = auth.uid(),
    updated_at = now();

  RETURN jsonb_build_object('success', true, 'policy_key', v_key);
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_save_faq(
  p_id uuid,
  p_question_ar text,
  p_answer_ar text,
  p_question_en text,
  p_answer_en text,
  p_sort_order integer,
  p_is_active boolean
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_id uuid := coalesce(p_id, gen_random_uuid());
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE='42501';
  END IF;

  IF nullif(btrim(p_question_ar), '') IS NULL
     OR nullif(btrim(p_question_en), '') IS NULL
     OR nullif(btrim(p_answer_ar), '') IS NULL
     OR nullif(btrim(p_answer_en), '') IS NULL THEN
    RAISE EXCEPTION 'FAQ question and answer are required' USING ERRCODE='22023';
  END IF;

  INSERT INTO public.faqs (
    id, question_ar, answer_ar, question_en, answer_en,
    sort_order, is_active, created_by, updated_by, updated_at
  )
  VALUES (
    v_id, btrim(p_question_ar), btrim(p_answer_ar),
    btrim(p_question_en), btrim(p_answer_en),
    coalesce(p_sort_order, 0), coalesce(p_is_active, true),
    auth.uid(), auth.uid(), now()
  )
  ON CONFLICT (id) DO UPDATE SET
    question_ar = EXCLUDED.question_ar,
    answer_ar = EXCLUDED.answer_ar,
    question_en = EXCLUDED.question_en,
    answer_en = EXCLUDED.answer_en,
    sort_order = EXCLUDED.sort_order,
    is_active = EXCLUDED.is_active,
    updated_by = auth.uid(),
    updated_at = now();

  RETURN jsonb_build_object('success', true, 'id', v_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_delete_faq(p_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE='42501';
  END IF;

  DELETE FROM public.faqs WHERE id = p_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'FAQ not found' USING ERRCODE='P0002';
  END IF;

  RETURN jsonb_build_object('success', true, 'id', p_id);
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_update_support_ticket(
  p_ticket_id uuid,
  p_status text,
  p_admin_notes text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_status text := lower(btrim(coalesce(p_status, '')));
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE='42501';
  END IF;

  IF v_status NOT IN ('new','in_progress','resolved') THEN
    RAISE EXCEPTION 'Invalid support ticket status' USING ERRCODE='22023';
  END IF;

  UPDATE public.support_tickets
  SET status = v_status,
      admin_notes = nullif(btrim(p_admin_notes), ''),
      assigned_to = CASE WHEN v_status = 'new' THEN assigned_to ELSE auth.uid() END,
      resolved_at = CASE WHEN v_status = 'resolved' THEN now() ELSE NULL END,
      updated_at = now()
  WHERE id = p_ticket_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Support ticket not found' USING ERRCODE='P0002';
  END IF;

  RETURN jsonb_build_object('success', true, 'ticket_id', p_ticket_id, 'status', v_status);
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.admin_update_support_settings(text,text,text,text)
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_update_support_settings(text,text,text,text)
TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.admin_upsert_legal_policy(text,text,text,text,text,boolean)
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_upsert_legal_policy(text,text,text,text,text,boolean)
TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.admin_save_faq(uuid,text,text,text,text,integer,boolean)
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_save_faq(uuid,text,text,text,text,integer,boolean)
TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.admin_delete_faq(uuid)
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_delete_faq(uuid)
TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.admin_update_support_ticket(uuid,text,text)
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_update_support_ticket(uuid,text,text)
TO authenticated, service_role;

REVOKE INSERT, UPDATE, DELETE ON public.support_settings FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.legal_policies FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.faqs FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.support_tickets FROM anon, authenticated;

COMMIT;
