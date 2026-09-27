BEGIN;

CREATE OR REPLACE FUNCTION public.update_promotion(
  p_promotion_id uuid,
  p_room_id uuid,
  p_title_ar text,
  p_title_en text,
  p_tag_ar text,
  p_tag_en text,
  p_discount_type text,
  p_discount_value numeric,
  p_expires_at timestamptz,
  p_colors text[],
  p_icon_key text,
  p_image_url text DEFAULT NULL,
  p_deep_link text DEFAULT NULL,
  p_target_audience text DEFAULT 'all'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_lounge_id uuid;
  v_type text := lower(btrim(COALESCE(p_discount_type, 'percentage')));
  v_value numeric := COALESCE(p_discount_value, 0);
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE='28000';
  END IF;

  SELECT lounge_id
  INTO v_lounge_id
  FROM public.promotions
  WHERE id = p_promotion_id;

  IF v_lounge_id IS NULL THEN
    RAISE EXCEPTION 'Promotion not found' USING ERRCODE='P0002';
  END IF;

  IF NOT public.has_lounge_permission(v_lounge_id, 'marketing_manage') THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE='42501';
  END IF;

  IF v_type NOT IN ('percentage','fixed') THEN
    RAISE EXCEPTION 'Unsupported discount type' USING ERRCODE='22023';
  END IF;

  IF v_value < 0 OR (v_type='percentage' AND v_value > 100) THEN
    RAISE EXCEPTION 'Invalid discount value' USING ERRCODE='22023';
  END IF;

  IF p_room_id IS NOT NULL AND NOT EXISTS (
    SELECT 1
    FROM public.rooms r
    WHERE r.id = p_room_id
      AND r.lounge_id = v_lounge_id
  ) THEN
    RAISE EXCEPTION 'Room does not belong to lounge' USING ERRCODE='22023';
  END IF;

  IF p_colors IS NULL OR array_length(p_colors,1) < 2 THEN
    RAISE EXCEPTION 'At least two colors are required' USING ERRCODE='22023';
  END IF;

  UPDATE public.promotions
  SET
    room_id = p_room_id,
    title = COALESCE(NULLIF(btrim(p_title_ar),''), NULLIF(btrim(p_title_en),''), 'Offer'),
    title_ar = p_title_ar,
    title_en = p_title_en,
    tag = COALESCE(NULLIF(btrim(p_tag_ar),''), NULLIF(btrim(p_tag_en),'')),
    tag_ar = p_tag_ar,
    tag_en = p_tag_en,
    colors = p_colors,
    icon_key = COALESCE(NULLIF(btrim(p_icon_key),''),'local_offer'),
    image_url = p_image_url,
    deep_link = p_deep_link,
    expires_at = p_expires_at,
    is_room_specific = p_room_id IS NOT NULL,
    target_audience = COALESCE(NULLIF(btrim(p_target_audience),''),'all'),
    discount_type = v_type,
    discount_value = v_value
  WHERE id = p_promotion_id;

  RETURN jsonb_build_object(
    'success', true,
    'promo_id', p_promotion_id,
    'discount_type', v_type,
    'discount_value', v_value
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.delete_promotion(
  p_promotion_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_lounge_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE='28000';
  END IF;

  SELECT lounge_id
  INTO v_lounge_id
  FROM public.promotions
  WHERE id = p_promotion_id;

  IF v_lounge_id IS NULL THEN
    RAISE EXCEPTION 'Promotion not found' USING ERRCODE='P0002';
  END IF;

  IF NOT public.has_lounge_permission(v_lounge_id, 'marketing_manage') THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE='42501';
  END IF;

  DELETE FROM public.promotions
  WHERE id = p_promotion_id;

  RETURN jsonb_build_object('success', true, 'promo_id', p_promotion_id);
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.update_promotion(
  uuid, uuid, text, text, text, text, text, numeric, timestamptz,
  text[], text, text, text, text
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_promotion(
  uuid, uuid, text, text, text, text, text, numeric, timestamptz,
  text[], text, text, text, text
) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.delete_promotion(uuid)
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_promotion(uuid)
TO authenticated, service_role;

DROP POLICY IF EXISTS "Lounge staff can insert promotions" ON public.promotions;
DROP POLICY IF EXISTS "Lounge staff can update promotions" ON public.promotions;
DROP POLICY IF EXISTS "Lounge staff can delete promotions" ON public.promotions;
DROP POLICY IF EXISTS promotions_write_policy ON public.promotions;

COMMIT;
