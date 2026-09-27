BEGIN;

CREATE OR REPLACE FUNCTION public.create_promotion(
  p_lounge_id uuid,
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
  v_id uuid;
  v_type text := lower(btrim(COALESCE(p_discount_type, 'percentage')));
  v_value numeric := COALESCE(p_discount_value, 0);
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE='28000';
  END IF;

  IF p_lounge_id IS NULL
     OR NOT public.has_lounge_permission(p_lounge_id, 'marketing_manage') THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE='42501';
  END IF;

  IF v_type NOT IN ('percentage','fixed') THEN
    RAISE EXCEPTION 'Unsupported discount type' USING ERRCODE='22023';
  END IF;

  IF v_value < 0 OR (v_type='percentage' AND v_value > 100) THEN
    RAISE EXCEPTION 'Invalid discount value' USING ERRCODE='22023';
  END IF;

  IF p_room_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.rooms r
    WHERE r.id=p_room_id AND r.lounge_id=p_lounge_id
  ) THEN
    RAISE EXCEPTION 'Room does not belong to lounge' USING ERRCODE='22023';
  END IF;

  IF p_colors IS NULL OR array_length(p_colors,1) < 2 THEN
    RAISE EXCEPTION 'At least two colors are required' USING ERRCODE='22023';
  END IF;

  INSERT INTO public.promotions(
    lounge_id, room_id, title, title_ar, title_en,
    tag, tag_ar, tag_en, colors, icon_key, image_url, deep_link,
    expires_at, is_room_specific, target_audience,
    discount_type, discount_value, is_active
  )
  VALUES(
    p_lounge_id,
    p_room_id,
    COALESCE(NULLIF(btrim(p_title_ar),''), NULLIF(btrim(p_title_en),''), 'Offer'),
    p_title_ar,
    p_title_en,
    COALESCE(NULLIF(btrim(p_tag_ar),''), NULLIF(btrim(p_tag_en),'')),
    p_tag_ar,
    p_tag_en,
    p_colors,
    COALESCE(NULLIF(btrim(p_icon_key),''),'local_offer'),
    p_image_url,
    p_deep_link,
    p_expires_at,
    p_room_id IS NOT NULL,
    COALESCE(NULLIF(btrim(p_target_audience),''),'all'),
    v_type,
    v_value,
    true
  )
  RETURNING id INTO v_id;

  INSERT INTO public.notifications(
    user_id, lounge_id, title_ar, title_en, body_ar, body_en,
    type, is_read, metadata
  )
  SELECT
    p.id,
    p_lounge_id,
    '🔥 ' || COALESCE(NULLIF(p_title_ar,''),'عرض جديد!'),
    '🔥 ' || COALESCE(NULLIF(p_title_en,''),'New Offer!'),
    COALESCE(NULLIF(p_tag_ar,''),'عرض جديد متاح الآن'),
    COALESCE(NULLIF(p_tag_en,''),'A new offer is available now'),
    'offer',
    false,
    jsonb_build_object(
      'promo_id',v_id,
      'lounge_id',p_lounge_id,
      'room_id',p_room_id,
      'discount_type',v_type,
      'discount_value',v_value
    )
  FROM public.profiles p
  WHERE p.role='user' AND COALESCE(p.is_active,true);

  RETURN jsonb_build_object(
    'success',true,
    'promo_id',v_id,
    'discount_type',v_type,
    'discount_value',v_value
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.create_promotion(
  uuid,uuid,text,text,text,text,text,numeric,timestamptz,text[],text,text,text,text
) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.create_promotion(
  uuid,uuid,text,text,text,text,text,numeric,timestamptz,text[],text,text,text,text
) TO authenticated, service_role, supabase_auth_admin;


-- Prevent duplicate delivery for the same promotion and user regardless of
-- whether the insert originated from the promotion trigger, an RPC, or a
-- repeated broadcast call. Existing historical duplicates are left untouched.
CREATE OR REPLACE FUNCTION public.guard_duplicate_offer_notification()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO ''
AS $function$
DECLARE
  v_promo_id text;
  v_lock_key text;
BEGIN
  IF NEW.type IS DISTINCT FROM 'offer' OR NEW.user_id IS NULL THEN
    RETURN NEW;
  END IF;

  v_promo_id := NULLIF(NEW.metadata->>'promo_id', '');
  IF v_promo_id IS NULL THEN
    RETURN NEW;
  END IF;

  v_lock_key :=
    NEW.user_id::text || ':offer:' || v_promo_id;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_lock_key, 0)
  );

  IF EXISTS (
    SELECT 1
    FROM public.notifications AS n
    WHERE n.user_id = NEW.user_id
      AND n.type = 'offer'
      AND n.metadata->>'promo_id' = v_promo_id
  ) THEN
    RETURN NULL;
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_guard_duplicate_offer_notification
ON public.notifications;

CREATE TRIGGER trg_guard_duplicate_offer_notification
BEFORE INSERT ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION public.guard_duplicate_offer_notification();

COMMIT;
