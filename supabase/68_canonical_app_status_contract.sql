BEGIN;

ALTER TABLE public.app_status
  ADD COLUMN IF NOT EXISTS maintenance_message_ar text,
  ADD COLUMN IF NOT EXISTS maintenance_message_en text,
  ADD COLUMN IF NOT EXISTS update_message_ar text,
  ADD COLUMN IF NOT EXISTS update_message_en text;

UPDATE public.app_status
SET
  maintenance_message_ar = COALESCE(maintenance_message_ar, maintenance_message),
  maintenance_message_en = COALESCE(maintenance_message_en, maintenance_message),
  update_message_ar = COALESCE(update_message_ar, update_message),
  update_message_en = COALESCE(update_message_en, update_message)
WHERE id = 1;

CREATE OR REPLACE FUNCTION public.update_app_status(
  p_maintenance_mode boolean,
  p_maintenance_message_ar text,
  p_maintenance_message_en text,
  p_maintenance_until timestamptz,
  p_min_supported_version_android text,
  p_min_supported_version_ios text,
  p_latest_version_android text,
  p_latest_version_ios text,
  p_update_message_ar text,
  p_update_message_en text,
  p_store_url_android text,
  p_store_url_ios text
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

  INSERT INTO public.app_status (
    id,
    maintenance_mode,
    maintenance_message,
    maintenance_message_ar,
    maintenance_message_en,
    maintenance_until,
    min_supported_version_android,
    min_supported_version_ios,
    latest_version_android,
    latest_version_ios,
    update_message,
    update_message_ar,
    update_message_en,
    store_url_android,
    store_url_ios,
    updated_at
  )
  VALUES (
    1,
    COALESCE(p_maintenance_mode, false),
    COALESCE(NULLIF(btrim(p_maintenance_message_ar), ''), NULLIF(btrim(p_maintenance_message_en), '')),
    NULLIF(btrim(p_maintenance_message_ar), ''),
    NULLIF(btrim(p_maintenance_message_en), ''),
    p_maintenance_until,
    NULLIF(btrim(p_min_supported_version_android), ''),
    NULLIF(btrim(p_min_supported_version_ios), ''),
    NULLIF(btrim(p_latest_version_android), ''),
    NULLIF(btrim(p_latest_version_ios), ''),
    COALESCE(NULLIF(btrim(p_update_message_ar), ''), NULLIF(btrim(p_update_message_en), '')),
    NULLIF(btrim(p_update_message_ar), ''),
    NULLIF(btrim(p_update_message_en), ''),
    NULLIF(btrim(p_store_url_android), ''),
    NULLIF(btrim(p_store_url_ios), ''),
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    maintenance_mode = EXCLUDED.maintenance_mode,
    maintenance_message = EXCLUDED.maintenance_message,
    maintenance_message_ar = EXCLUDED.maintenance_message_ar,
    maintenance_message_en = EXCLUDED.maintenance_message_en,
    maintenance_until = EXCLUDED.maintenance_until,
    min_supported_version_android = EXCLUDED.min_supported_version_android,
    min_supported_version_ios = EXCLUDED.min_supported_version_ios,
    latest_version_android = EXCLUDED.latest_version_android,
    latest_version_ios = EXCLUDED.latest_version_ios,
    update_message = EXCLUDED.update_message,
    update_message_ar = EXCLUDED.update_message_ar,
    update_message_en = EXCLUDED.update_message_en,
    store_url_android = EXCLUDED.store_url_android,
    store_url_ios = EXCLUDED.store_url_ios,
    updated_at = now();

  RETURN jsonb_build_object('success', true);
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.update_app_status(
  boolean,text,text,timestamptz,text,text,text,text,text,text,text,text
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_app_status(
  boolean,text,text,timestamptz,text,text,text,text,text,text,text,text
) TO authenticated, service_role;

DROP POLICY IF EXISTS app_status_admin_update ON public.app_status;
DROP POLICY IF EXISTS app_status_write ON public.app_status;
DROP POLICY IF EXISTS app_status_select ON public.app_status;

COMMIT;
