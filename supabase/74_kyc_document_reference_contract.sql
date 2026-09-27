BEGIN;

CREATE OR REPLACE FUNCTION public.submit_kyc_documents(
  p_id_document_url text,
  p_business_document_url text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth', 'extensions', 'pg_temp'
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  v_user_prefix text;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
  END IF;

  v_user_prefix := v_user_id::text || '/';

  IF p_id_document_url IS NULL OR btrim(p_id_document_url) = '' THEN
    RAISE EXCEPTION 'ID document reference is required'
      USING ERRCODE = '22023';
  END IF;

  IF NOT (
    btrim(p_id_document_url) LIKE v_user_prefix || '%'
    OR btrim(p_id_document_url) LIKE '%/kyc-documents/' || v_user_prefix || '%'
  ) THEN
    RAISE EXCEPTION 'ID document reference does not belong to caller'
      USING ERRCODE = '42501';
  END IF;

  IF p_business_document_url IS NOT NULL
     AND btrim(p_business_document_url) <> ''
     AND NOT (
       btrim(p_business_document_url) LIKE v_user_prefix || '%'
       OR btrim(p_business_document_url) LIKE '%/kyc-documents/' || v_user_prefix || '%'
     ) THEN
    RAISE EXCEPTION 'Business document reference does not belong to caller'
      USING ERRCODE = '42501';
  END IF;

  INSERT INTO public.kyc_submissions (
    user_id,
    id_document_url,
    business_document_url,
    status
  )
  VALUES (
    v_user_id,
    btrim(p_id_document_url),
    nullif(btrim(p_business_document_url), ''),
    'pending'
  )
  ON CONFLICT (user_id)
  DO UPDATE SET
    id_document_url = EXCLUDED.id_document_url,
    business_document_url = EXCLUDED.business_document_url,
    status = 'pending',
    updated_at = now();
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.submit_kyc_documents(text,text)
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_kyc_documents(text,text)
TO authenticated, service_role;

COMMIT;
