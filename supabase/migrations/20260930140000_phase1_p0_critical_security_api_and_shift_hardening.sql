-- =============================================================================
-- Migration: 20260930140000_phase1_p0_critical_security_api_and_shift_hardening.sql
-- Description: Phase 1 (P0) Critical Security, API Contracts, Shift Integrity & Audit Hardening
-- Target Project: tgpdexoitemmpruepgyt
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 1. Lounge Timezone & Currency Configuration
-- -----------------------------------------------------------------------------
ALTER TABLE public.lounges
  ADD COLUMN IF NOT EXISTS timezone text NOT NULL DEFAULT 'Africa/Cairo',
  ADD COLUMN IF NOT EXISTS currency text NOT NULL DEFAULT 'EGP';

-- -----------------------------------------------------------------------------
-- 2. Bookings Pricing Snapshot & Audit Support
-- -----------------------------------------------------------------------------
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS pricing_snapshot jsonb,
  ADD COLUMN IF NOT EXISTS pricing_rule_ids uuid[];

-- -----------------------------------------------------------------------------
-- 3. Pricing Rules Table & Policy Engine Foundation
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.pricing_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lounge_id uuid NOT NULL REFERENCES public.lounges(id) ON DELETE CASCADE,
  room_id uuid REFERENCES public.rooms(id) ON DELETE CASCADE,
  space_type_id uuid REFERENCES public.space_types(id) ON DELETE CASCADE,
  name_ar text NOT NULL,
  name_en text,
  rule_type text NOT NULL CHECK (rule_type IN ('peak', 'off_peak', 'special_day')),
  days_of_week smallint[] NOT NULL CHECK (
    days_of_week <@ array[0,1,2,3,4,5,6]::smallint[]
    AND cardinality(days_of_week) > 0
  ),
  start_time time without time zone NOT NULL,
  end_time time without time zone NOT NULL,
  valid_from date,
  valid_to date,
  adjustment_type text NOT NULL CHECK (adjustment_type IN ('multiplier', 'percent_delta', 'fixed_rate')),
  adjustment_value numeric(10,3) NOT NULL CHECK (
    (adjustment_type = 'percent_delta') OR (adjustment_value > 0)
  ),
  applies_to_play_mode text CHECK (applies_to_play_mode IN ('single', 'multi')),
  priority int NOT NULL DEFAULT 100,
  is_active boolean NOT NULL DEFAULT true,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pricing_rules_lookup
  ON public.pricing_rules (lounge_id, is_active, priority DESC);

ALTER TABLE public.pricing_rules ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'pricing_rules' AND policyname = 'pricing_rules_read_policy'
  ) THEN
    CREATE POLICY "pricing_rules_read_policy" ON public.pricing_rules
      FOR SELECT TO authenticated USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'pricing_rules' AND policyname = 'pricing_rules_operator_write'
  ) THEN
    CREATE POLICY "pricing_rules_operator_write" ON public.pricing_rules
      FOR ALL TO authenticated
      USING (
        public.has_lounge_permission(lounge_id, 'lounges_manage_settings')
        OR private.can_operate_playspot_lounge(lounge_id)
      )
      WITH CHECK (
        public.has_lounge_permission(lounge_id, 'lounges_manage_settings')
        OR private.can_operate_playspot_lounge(lounge_id)
      );
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- 4. Event Catalog & Immutable Audit Events Ledger
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.event_catalog (
  code text PRIMARY KEY,
  entity_type text NOT NULL,
  default_severity text NOT NULL CHECK (default_severity IN ('info', 'warning', 'critical')),
  label_key text NOT NULL,
  title_ar text NOT NULL,
  title_en text NOT NULL,
  description text,
  created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO public.event_catalog (
  code, entity_type, default_severity, label_key, title_ar, title_en, description
) VALUES
  ('booking_created', 'booking', 'info', 'events.booking.created', 'تم إنشاء الحجز', 'Booking Placed', 'إنشاء حجز جديد بواسطة العميل أو الكاشير'),
  ('booking_approved', 'booking', 'info', 'events.booking.approved', 'تمت الموافقة على الحجز', 'Booking Approved', 'تأكيد الحجز وقبوله'),
  ('booking_checked_in', 'booking', 'info', 'events.booking.checked_in', 'بدء الجلسة / الدخول', 'Session Checked In', 'تسجيل دخول العميل وبدء استخدام الغرفة'),
  ('booking_completed', 'booking', 'info', 'events.booking.completed', 'إكمال الحجز', 'Booking Completed', 'انتهاء الجلسة وحساب الإجمالي النهائي'),
  ('booking_cancelled', 'booking', 'warning', 'events.booking.cancelled', 'إلغاء الحجز', 'Booking Cancelled', 'إلغاء الحجز مع ذكر السبب'),
  ('payment_collected', 'payment', 'info', 'events.payment.collected', 'تحصيل دفعة مالية', 'Payment Collected', 'تسجيل عملية دفع ناجحة على الشيفت'),
  ('payment_refunded', 'payment', 'warning', 'events.payment.refunded', 'استرداد دفعة مالية', 'Payment Refunded', 'استرداد مبلغ مالي للعميل'),
  ('shift_opened', 'shift', 'info', 'events.shift.opened', 'فتح وردية جديدة', 'Shift Opened', 'بدء وردية كاشير برصيد افتتاح'),
  ('shift_closed', 'shift', 'info', 'events.shift.closed', 'إغلاق الوردية', 'Shift Closed', 'إنهاء وردية الكاشير وجرد المبالغ'),
  ('canteen_order_placed', 'canteen_order', 'info', 'events.canteen.placed', 'طلب كانتين', 'Canteen Order Placed', 'تسجيل طلب جديد من الكانتين'),
  ('canteen_order_cancelled', 'canteen_order', 'warning', 'events.canteen.cancelled', 'إلغاء طلب كانتين', 'Canteen Order Cancelled', 'إلغاء طلب واستعادة المخزون'),
  ('tournament_payment_submitted', 'tournament', 'info', 'events.tournament.payment', 'تقديم دفع بطولة', 'Tournament Payment Submitted', 'تقديم إيصال اشتراك في بطولة')
ON CONFLICT (code) DO UPDATE SET
  title_ar = EXCLUDED.title_ar,
  title_en = EXCLUDED.title_en,
  description = EXCLUDED.description;

CREATE TABLE IF NOT EXISTS public.audit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lounge_id uuid REFERENCES public.lounges(id) ON DELETE CASCADE,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  entity_type text NOT NULL,
  entity_id text NOT NULL,
  booking_id uuid REFERENCES public.bookings(id) ON DELETE SET NULL,
  actor_user_id uuid,
  severity text NOT NULL DEFAULT 'info' CHECK (severity IN ('info', 'warning', 'critical')),
  event_code text NOT NULL REFERENCES public.event_catalog(code),
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_events_lounge_timeline
  ON public.audit_events (lounge_id, occurred_at DESC, id DESC);

CREATE INDEX IF NOT EXISTS idx_audit_events_booking
  ON public.audit_events (booking_id, occurred_at DESC)
  WHERE booking_id IS NOT NULL;

ALTER TABLE public.audit_events ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'audit_events' AND policyname = 'audit_events_select_policy'
  ) THEN
    CREATE POLICY "audit_events_select_policy" ON public.audit_events
      FOR SELECT TO authenticated
      USING (
        public.has_lounge_permission(lounge_id, 'reports.view')
        OR private.can_operate_playspot_lounge(lounge_id)
        OR actor_user_id = auth.uid()
      );
  END IF;
END $$;

-- Centralized Audit Logger Function
CREATE OR REPLACE FUNCTION public.log_audit_event(
  p_lounge_id uuid,
  p_event_code text,
  p_entity_type text,
  p_entity_id text,
  p_payload jsonb DEFAULT '{}'::jsonb,
  p_booking_id uuid DEFAULT NULL,
  p_severity text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_event_id uuid;
  v_default_sev text;
  v_actor uuid := auth.uid();
BEGIN
  SELECT default_severity INTO v_default_sev
  FROM public.event_catalog
  WHERE code = p_event_code;

  IF v_default_sev IS NULL THEN
    v_default_sev := 'info';
  END IF;

  INSERT INTO public.audit_events (
    lounge_id,
    occurred_at,
    entity_type,
    entity_id,
    booking_id,
    actor_user_id,
    severity,
    event_code,
    payload,
    created_at
  ) VALUES (
    p_lounge_id,
    now(),
    p_entity_type,
    p_entity_id,
    p_booking_id,
    v_actor,
    COALESCE(p_severity, v_default_sev),
    p_event_code,
    COALESCE(p_payload, '{}'::jsonb),
    now()
  ) RETURNING id INTO v_event_id;

  RETURN v_event_id;
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. Operational Permission Assertion Helper
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.assert_lounge_permission(
  p_lounge_id uuid,
  p_permission_key text,
  p_allow_super_admin boolean DEFAULT true
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_actor uuid := auth.uid();
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  IF p_allow_super_admin AND public.is_super_admin() THEN
    RETURN true;
  END IF;

  -- 1. Check exact operational permission key
  IF public.has_lounge_permission(p_lounge_id, p_permission_key) THEN
    RETURN true;
  END IF;

  -- 2. Fallback check for owner/manager role while permissions migrate
  IF private.can_operate_playspot_lounge(p_lounge_id) THEN
    RETURN true;
  END IF;

  RAISE EXCEPTION 'INSUFFICIENT_PERMISSIONS: % required for lounge %', p_permission_key, p_lounge_id
    USING ERRCODE = '42501';
END;
$$;

-- -----------------------------------------------------------------------------
-- 6. Shift Attachment Trigger Fix (checked_in_at & open_time gap)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.attach_booking_to_active_shift()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public', 'auth', 'pg_temp'
AS $$
DECLARE
  v_shift_id uuid;
  v_shift_lounge_id uuid;
  v_shift_status text;
  v_requires_open_shift boolean :=
    NEW.status::text = 'in_progress'
    OR NEW.actual_start_time IS NOT NULL
    OR NEW.checked_in_at IS NOT NULL
    OR (NEW.is_open_time IS TRUE AND NEW.open_time_started_at IS NOT NULL);
BEGIN
  IF v_requires_open_shift
     AND NEW.shift_id IS NULL
     AND NEW.lounge_id IS NOT NULL THEN
    SELECT id
    INTO v_shift_id
    FROM public.shifts
    WHERE lounge_id = NEW.lounge_id
      AND status = 'open'
    ORDER BY opened_at DESC
    LIMIT 1;

    IF v_shift_id IS NULL THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P0001',
        MESSAGE = 'NO_OPEN_SHIFT';
    END IF;

    NEW.shift_id := v_shift_id;
  END IF;

  IF NEW.shift_id IS NOT NULL THEN
    SELECT lounge_id, status
    INTO v_shift_lounge_id, v_shift_status
    FROM public.shifts
    WHERE id = NEW.shift_id;

    IF v_shift_lounge_id IS NULL THEN
      RAISE EXCEPTION 'The selected shift does not exist.' USING ERRCODE = '22023';
    END IF;

    IF NEW.lounge_id IS DISTINCT FROM v_shift_lounge_id THEN
      RAISE EXCEPTION 'Booking and shift must belong to the same lounge.' USING ERRCODE = '42501';
    END IF;

    IF v_requires_open_shift AND v_shift_status <> 'open' THEN
      RAISE EXCEPTION 'An active booking must be linked to an open shift.' USING ERRCODE = '55000';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- -----------------------------------------------------------------------------
-- 7. Overlap & Midnight Crossing Protection
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prevent_booking_tournament_room_overlap()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public', 'auth', 'extensions', 'pg_temp'
AS $$
DECLARE
  v_conflict record;
  v_tz text := 'Africa/Cairo';
BEGIN
  IF NEW.room_id IS NULL
     OR NEW.booking_period IS NULL
     OR NEW.status::text IN ('cancelled', 'rejected') THEN
    RETURN NEW;
  END IF;

  SELECT COALESCE(timezone, 'Africa/Cairo') INTO v_tz
  FROM public.lounges
  WHERE id = NEW.lounge_id;

  SELECT tm.id, tm.tournament_id, tm.scheduled_at, tm.scheduled_end_at
    INTO v_conflict
  FROM public.tournament_matches tm
  WHERE tm.room_id = NEW.room_id
    AND tm.status <> 'cancelled'
    AND tm.scheduled_at IS NOT NULL
    AND tm.scheduled_end_at IS NOT NULL
    AND tsrange(
      tm.scheduled_at AT TIME ZONE v_tz,
      tm.scheduled_end_at AT TIME ZONE v_tz,
      '[)'
    ) && NEW.booking_period
  LIMIT 1;

  IF FOUND THEN
    RAISE EXCEPTION
      'Room is reserved for a tournament match during this booking period (match_id: %, tournament_id: %)',
      v_conflict.id,
      v_conflict.tournament_id
      USING ERRCODE = '23P01';
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.check_booking_no_overlap()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public', 'pg_temp'
AS $$
BEGIN
  IF NEW.status IN ('pending', 'upcoming', 'in_progress')
     AND NEW.room_id IS NOT NULL
     AND NEW.booking_period IS NOT NULL THEN
    IF EXISTS (
      SELECT 1 FROM public.bookings
      WHERE room_id = NEW.room_id
        AND id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
        AND status IN ('pending', 'upcoming', 'in_progress')
        AND booking_period && NEW.booking_period
    ) THEN
      RAISE EXCEPTION 'هذه الغرفة محجوزة بالفعل في هذا التوقيت'
        USING ERRCODE = '23P01';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- -----------------------------------------------------------------------------
-- 8. Authoritative Server-Side Pricing RPCs
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.quote_booking_price(
  p_room_id uuid,
  p_date date,
  p_start time without time zone,
  p_end time without time zone,
  p_play_mode text DEFAULT 'single',
  p_extra_controllers int DEFAULT 0,
  p_coupon_code text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_room record;
  v_lounge record;
  v_dow smallint;
  v_play_mode text;
  v_base_rate numeric(10,2);
  v_controller_rate numeric(10,2);
  v_total_minutes numeric;
  v_start_min numeric;
  v_end_min numeric;
  v_cur_min numeric;
  v_next_min numeric;
  v_rule record;
  v_seg_rate numeric(10,3);
  v_seg_amount numeric(12,4);
  v_room_subtotal numeric(12,4) := 0;
  v_controllers_amount numeric(12,4) := 0;
  v_discount_amount numeric(12,4) := 0;
  v_final_total numeric(12,2) := 0;
  v_has_peak boolean := false;
  v_segments jsonb := '[]'::jsonb;
  v_applied_rule_ids uuid[] := '{}';
  v_promo record;
  v_currency text := 'EGP';
BEGIN
  v_play_mode := lower(COALESCE(NULLIF(btrim(p_play_mode), ''), 'single'));
  IF v_play_mode NOT IN ('single', 'multi') THEN
    RAISE EXCEPTION 'Invalid play mode' USING ERRCODE = '22023';
  END IF;

  SELECT
    r.id, r.lounge_id, r.hourly_rate_single, r.hourly_rate_multi,
    r.extra_controller_price, r.is_active, r.is_available
  INTO v_room
  FROM public.rooms r
  WHERE r.id = p_room_id;

  IF v_room.id IS NULL THEN
    RAISE EXCEPTION 'Room not found' USING ERRCODE = 'P0002';
  END IF;

  SELECT l.id, COALESCE(l.currency, 'EGP') as currency
  INTO v_lounge
  FROM public.lounges l
  WHERE l.id = v_room.lounge_id;

  v_currency := COALESCE(v_lounge.currency, 'EGP');

  IF v_play_mode = 'multi' AND COALESCE(v_room.hourly_rate_multi, 0) > 0 THEN
    v_base_rate := v_room.hourly_rate_multi;
  ELSE
    v_base_rate := v_room.hourly_rate_single;
  END IF;

  IF COALESCE(v_base_rate, 0) <= 0 THEN
    RAISE EXCEPTION 'Room has no valid base rate' USING ERRCODE = '23514';
  END IF;

  v_start_min := (EXTRACT(HOUR FROM p_start) * 60) + EXTRACT(MINUTE FROM p_start);
  v_end_min := (EXTRACT(HOUR FROM p_end) * 60) + EXTRACT(MINUTE FROM p_end);

  IF v_end_min <= v_start_min THEN
    v_end_min := v_end_min + 1440;
  END IF;

  v_total_minutes := v_end_min - v_start_min;
  IF v_total_minutes <= 0 THEN
    RAISE EXCEPTION 'Invalid booking duration' USING ERRCODE = '22023';
  END IF;

  v_dow := EXTRACT(DOW FROM p_date)::smallint;
  v_cur_min := v_start_min;

  WHILE v_cur_min < v_end_min LOOP
    v_next_min := v_end_min;

    FOR v_rule IN
      SELECT
        pr.id,
        pr.rule_type,
        pr.adjustment_type,
        pr.adjustment_value,
        ((EXTRACT(HOUR FROM pr.start_time) * 60) + EXTRACT(MINUTE FROM pr.start_time)) AS r_start,
        ((EXTRACT(HOUR FROM pr.end_time) * 60) + EXTRACT(MINUTE FROM pr.end_time)) AS r_end,
        pr.priority
      FROM public.pricing_rules pr
      WHERE pr.lounge_id = v_room.lounge_id
        AND pr.is_active = true
        AND v_dow = ANY(pr.days_of_week)
        AND (pr.room_id IS NULL OR pr.room_id = p_room_id)
        AND (pr.applies_to_play_mode IS NULL OR pr.applies_to_play_mode = v_play_mode)
        AND (pr.valid_from IS NULL OR p_date >= pr.valid_from)
        AND (pr.valid_to IS NULL OR p_date <= pr.valid_to)
    LOOP
      IF v_rule.r_end <= v_rule.r_start THEN
        v_rule.r_end := v_rule.r_end + 1440;
      END IF;

      IF v_rule.r_start > (v_cur_min % 1440) AND v_rule.r_start < (v_next_min % 1440) THEN
        v_next_min := v_cur_min + (v_rule.r_start - (v_cur_min % 1440));
      END IF;
      IF v_rule.r_end > (v_cur_min % 1440) AND v_rule.r_end < (v_next_min % 1440) THEN
        v_next_min := v_cur_min + (v_rule.r_end - (v_cur_min % 1440));
      END IF;
    END LOOP;

    IF v_next_min <= v_cur_min THEN
      v_next_min := v_cur_min + 15;
    END IF;
    IF v_next_min > v_end_min THEN
      v_next_min := v_end_min;
    END IF;

    -- Pick highest priority matching rule for current minute
    SELECT
      pr.id, pr.rule_type, pr.adjustment_type, pr.adjustment_value
    INTO v_rule
    FROM public.pricing_rules pr
    WHERE pr.lounge_id = v_room.lounge_id
      AND pr.is_active = true
      AND v_dow = ANY(pr.days_of_week)
      AND (pr.room_id IS NULL OR pr.room_id = p_room_id)
      AND (pr.applies_to_play_mode IS NULL OR pr.applies_to_play_mode = v_play_mode)
      AND (pr.valid_from IS NULL OR p_date >= pr.valid_from)
      AND (pr.valid_to IS NULL OR p_date <= pr.valid_to)
      AND (
        CASE
          WHEN pr.end_time <= pr.start_time THEN
            (v_cur_min % 1440) >= ((EXTRACT(HOUR FROM pr.start_time)*60)+EXTRACT(MINUTE FROM pr.start_time))
            OR (v_cur_min % 1440) < ((EXTRACT(HOUR FROM pr.end_time)*60)+EXTRACT(MINUTE FROM pr.end_time))
          ELSE
            (v_cur_min % 1440) >= ((EXTRACT(HOUR FROM pr.start_time)*60)+EXTRACT(MINUTE FROM pr.start_time))
            AND (v_cur_min % 1440) < ((EXTRACT(HOUR FROM pr.end_time)*60)+EXTRACT(MINUTE FROM pr.end_time))
        END
      )
    ORDER BY pr.priority DESC, pr.created_at ASC
    LIMIT 1;

    IF v_rule.id IS NOT NULL THEN
      IF v_rule.adjustment_type = 'multiplier' THEN
        v_seg_rate := v_base_rate * v_rule.adjustment_value;
      ELSIF v_rule.adjustment_type = 'percent_delta' THEN
        v_seg_rate := v_base_rate * (1.0 + (v_rule.adjustment_value / 100.0));
      ELSE
        v_seg_rate := v_rule.adjustment_value;
      END IF;

      IF v_rule.rule_type = 'peak' THEN
        v_has_peak := true;
      END IF;

      IF NOT (v_rule.id = ANY(v_applied_rule_ids)) THEN
        v_applied_rule_ids := array_append(v_applied_rule_ids, v_rule.id);
      END IF;
    ELSE
      v_seg_rate := v_base_rate;
    END IF;

    v_seg_amount := (v_seg_rate / 60.0) * (v_next_min - v_cur_min);
    v_room_subtotal := v_room_subtotal + v_seg_amount;

    v_segments := v_segments || jsonb_build_array(
      jsonb_build_object(
        'from', to_char((interval '1 minute' * (v_cur_min % 1440)), 'HH24:MI:SS'),
        'to', to_char((interval '1 minute' * (v_next_min % 1440)), 'HH24:MI:SS'),
        'minutes', (v_next_min - v_cur_min)::int,
        'base_rate', v_base_rate,
        'applied_rule_id', v_rule.id,
        'rule_type', COALESCE(v_rule.rule_type, 'standard'),
        'rate', round(v_seg_rate, 2),
        'amount', round(v_seg_amount, 2)
      )
    );

    v_cur_min := v_next_min;
  END LOOP;

  -- Controllers
  IF p_extra_controllers > 0 AND COALESCE(v_room.extra_controller_price, 0) > 0 THEN
    v_controller_rate := v_room.extra_controller_price;
    v_controllers_amount := (v_controller_rate * p_extra_controllers) * (v_total_minutes / 60.0);
  END IF;

  -- Coupons / Discounts
  IF p_coupon_code IS NOT NULL AND btrim(p_coupon_code) <> '' THEN
    SELECT v.* INTO v_promo
    FROM public.vouchers v
    WHERE v.code = upper(btrim(p_coupon_code))
      AND v.lounge_id = v_room.lounge_id
      AND v.is_active = true
      AND (v.expires_at IS NULL OR v.expires_at > now())
      AND (v.max_uses IS NULL OR v.current_uses < v.max_uses)
    LIMIT 1;

    IF v_promo.id IS NOT NULL THEN
      IF v_promo.discount_type = 'percentage' THEN
        v_discount_amount := (v_room_subtotal + v_controllers_amount) * (v_promo.discount_value / 100.0);
      ELSE
        v_discount_amount := v_promo.discount_value;
      END IF;

      IF v_promo.max_discount_amount IS NOT NULL AND v_discount_amount > v_promo.max_discount_amount THEN
        v_discount_amount := v_promo.max_discount_amount;
      END IF;
    END IF;
  END IF;

  v_final_total := GREATEST(0.0, round(v_room_subtotal + v_controllers_amount - v_discount_amount, 2));

  RETURN jsonb_build_object(
    'segments', v_segments,
    'room_subtotal', round(v_room_subtotal, 2),
    'extra_controllers_amount', round(v_controllers_amount, 2),
    'discount_amount', round(v_discount_amount, 2),
    'total', v_final_total,
    'currency', v_currency,
    'has_peak', v_has_peak,
    'pricing_version', 1,
    'applied_rule_ids', to_jsonb(v_applied_rule_ids)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_room_slots_with_prices(
  p_room_id uuid,
  p_date date
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_slots jsonb := '[]'::jsonb;
  v_hour int;
  v_start time;
  v_end time;
  v_quote jsonb;
  v_available boolean;
BEGIN
  FOR v_hour IN 10..23 LOOP
    v_start := make_time(v_hour, 0, 0.0);
    v_end := make_time((v_hour + 1) % 24, 0, 0.0);

    SELECT NOT EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.room_id = p_room_id
        AND b.date = p_date
        AND b.status IN ('pending', 'upcoming', 'in_progress')
        AND b.booking_period && tsrange(p_date + v_start, p_date + (CASE WHEN v_end <= v_start THEN interval '1 day' ELSE interval '0' END) + v_end, '[)')
    ) INTO v_available;

    BEGIN
      v_quote := public.quote_booking_price(p_room_id, p_date, v_start, v_end, 'single', 0, NULL);
    EXCEPTION WHEN OTHERS THEN
      v_quote := jsonb_build_object('total', 0, 'has_peak', false);
    END;

    v_slots := v_slots || jsonb_build_array(
      jsonb_build_object(
        'start_time', to_char(v_start, 'HH24:MI'),
        'end_time', to_char(v_end, 'HH24:MI'),
        'is_available', v_available,
        'price', v_quote->'total',
        'has_peak', COALESCE((v_quote->>'has_peak')::boolean, false)
      )
    );
  END LOOP;

  RETURN v_slots;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_lounge_price_range(
  p_lounge_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_min numeric := 0;
  v_max numeric := 0;
  v_curr text := 'EGP';
BEGIN
  SELECT
    COALESCE(MIN(LEAST(r.hourly_rate_single, COALESCE(r.hourly_rate_multi, r.hourly_rate_single))), 0),
    COALESCE(MAX(GREATEST(r.hourly_rate_single, COALESCE(r.hourly_rate_multi, r.hourly_rate_single))), 0)
  INTO v_min, v_max
  FROM public.rooms r
  WHERE r.lounge_id = p_lounge_id
    AND r.is_active = true
    AND r.status <> 'deleted';

  SELECT COALESCE(currency, 'EGP') INTO v_curr
  FROM public.lounges
  WHERE id = p_lounge_id;

  RETURN jsonb_build_object(
    'min_hourly_rate', v_min,
    'max_hourly_rate', v_max,
    'currency', v_curr
  );
END;
$$;

-- -----------------------------------------------------------------------------
-- 9. Decoupled Session Completion & Post-Close Payment Settlement
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.complete_booking_session(
  p_booking_id uuid,
  p_action_by uuid DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_actor uuid := auth.uid();
  v_booking public.bookings%ROWTYPE;
  v_room public.rooms%ROWTYPE;
  v_lounge public.lounges%ROWTYPE;
  v_now timestamptz := now();
  v_tz text := 'Africa/Cairo';
  v_now_local timestamp without time zone;
  v_started_at timestamptz;
  v_elapsed_minutes integer;
  v_billable_minutes integer;
  v_billable_capped integer;
  v_room_rate numeric;
  v_new_room_price numeric;
  v_existing_room_price numeric;
  v_non_room_total numeric;
  v_new_total numeric;
  v_delta numeric;
  v_payment_method text;
  v_shift_id uuid;
  v_commission numeric := 0;
  v_paid_amount numeric := 0;
  v_remaining numeric := 0;
  v_payment_status text := 'unpaid';
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  IF p_action_by IS NOT NULL AND p_action_by IS DISTINCT FROM v_actor AND NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Action actor does not match authenticated user' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found' USING ERRCODE = 'P0002';
  END IF;

  PERFORM private.assert_lounge_permission(v_booking.lounge_id, 'sessions_control');

  SELECT * INTO v_lounge
  FROM public.lounges
  WHERE id = v_booking.lounge_id;

  v_tz := COALESCE(v_lounge.timezone, 'Africa/Cairo');
  v_now_local := v_now AT TIME ZONE v_tz;

  -- 1. Idempotency Check: if already completed, return cached final numbers
  IF v_booking.status = 'completed'::public.booking_status THEN
    SELECT COALESCE(SUM(amount), 0) INTO v_paid_amount
    FROM public.payments
    WHERE booking_id = p_booking_id AND status = 'completed';

    v_remaining := GREATEST(0, COALESCE(v_booking.total_price, 0) - v_paid_amount);

    RETURN json_build_object(
      'success', true,
      'booking_id', p_booking_id,
      'lounge_id', v_booking.lounge_id,
      'status', 'completed',
      'final_total', v_booking.total_price,
      'amount_paid', v_paid_amount,
      'remaining_amount', v_remaining,
      'payment_status', v_booking.payment_status,
      'already_completed', true
    );
  END IF;

  IF v_booking.status IN ('cancelled'::public.booking_status, 'rejected'::public.booking_status) THEN
    RAISE EXCEPTION 'Cannot complete a cancelled or rejected booking' USING ERRCODE = '55000';
  END IF;

  IF v_booking.is_open_time IS TRUE THEN
    SELECT * INTO v_room
    FROM public.rooms
    WHERE id = v_booking.room_id AND lounge_id = v_booking.lounge_id;

    v_started_at := COALESCE(v_booking.open_time_started_at, v_booking.actual_start_time, v_booking.checked_in_at);
    IF v_started_at IS NULL THEN
      RAISE EXCEPTION 'OPEN_TIME_START_MISSING' USING ERRCODE = '22023';
    END IF;

    v_elapsed_minutes := GREATEST(1, CEIL(EXTRACT(EPOCH FROM (v_now - v_started_at)) / 60.0)::integer);

    v_billable_minutes := CEIL(
      GREATEST(v_elapsed_minutes, COALESCE(v_lounge.open_time_minimum_minutes, 60))::numeric
      / COALESCE(NULLIF(v_lounge.open_time_rounding_minutes, 0), 15)
    )::integer * COALESCE(NULLIF(v_lounge.open_time_rounding_minutes, 0), 15);

    v_billable_capped := LEAST(v_billable_minutes, COALESCE(v_lounge.open_time_max_minutes, 720));

    v_room_rate := CASE
      WHEN lower(COALESCE(v_booking.play_mode, '')) = 'single' THEN v_room.hourly_rate_single
      ELSE v_room.hourly_rate_multi
    END;

    IF v_room_rate IS NULL OR v_room_rate < 0 THEN
      RAISE EXCEPTION 'ROOM_RATE_NOT_CONFIGURED' USING ERRCODE = '22023';
    END IF;

    v_new_room_price := public.calculate_booking_price(v_room_rate, v_billable_capped);
    v_existing_room_price := COALESCE(v_booking.room_price, 0);
    v_non_room_total := COALESCE(v_booking.total_price, 0) - v_existing_room_price;
    v_new_total := GREATEST(0, v_new_room_price + v_non_room_total);
    v_delta := GREATEST(0, v_new_total - COALESCE(v_booking.total_price, 0));
    v_payment_method := COALESCE(v_booking.payment_method, 'cash');

    UPDATE public.bookings
    SET status = 'completed'::public.booking_status,
        open_time_closed_at = v_now,
        open_time_billing_minutes = v_billable_capped,
        duration_minutes = v_billable_capped,
        room_price = v_new_room_price,
        total_price = v_new_total,
        end_time = v_now_local::time,
        end_at = v_now_local::time,
        updated_at = v_now
    WHERE id = p_booking_id;

    -- If booking was previously paid and delta > 0, settle delta to shift
    IF COALESCE(v_booking.payment_status, 'unpaid') = 'paid' THEN
      SELECT s.id INTO v_shift_id
      FROM public.shifts AS s
      WHERE s.lounge_id = v_booking.lounge_id AND s.status = 'open'
      ORDER BY s.opened_at DESC
      LIMIT 1
      FOR UPDATE;

      IF v_shift_id IS NOT NULL AND v_delta > 0 THEN
        INSERT INTO public.shift_payments (
          shift_id, lounge_id, booking_id, payment_method, category, amount, paid_at
        ) VALUES (
          v_shift_id, v_booking.lounge_id, p_booking_id, v_payment_method, 'gaming_time', v_delta, v_now
        );

        v_commission := round(v_new_total * 0.15, 2);
        UPDATE public.payments
        SET amount = v_new_total,
            commission = v_commission,
            net_to_lounge = v_new_total - v_commission,
            updated_at = v_now
        WHERE booking_id = p_booking_id;
      END IF;
      v_paid_amount := v_new_total;
      v_remaining := 0;
      v_payment_status := 'paid';
    ELSE
      -- Session completed but remains unpaid
      v_paid_amount := 0;
      v_remaining := v_new_total;
      v_payment_status := 'unpaid';
    END IF;
  ELSE
    UPDATE public.bookings
    SET status = 'completed'::public.booking_status,
        updated_at = v_now
    WHERE id = p_booking_id;

    v_new_total := COALESCE(v_booking.total_price, 0);
    SELECT COALESCE(SUM(amount), 0) INTO v_paid_amount
    FROM public.payments
    WHERE booking_id = p_booking_id AND status = 'completed';

    v_remaining := GREATEST(0, v_new_total - v_paid_amount);
    v_payment_status := CASE WHEN v_remaining = 0 THEN 'paid' ELSE 'unpaid' END;
  END IF;

  -- Free room
  IF v_booking.room_id IS NOT NULL THEN
    UPDATE public.rooms
    SET status = 'available', is_available = true, updated_at = v_now
    WHERE id = v_booking.room_id AND lounge_id = v_booking.lounge_id AND status = 'occupied';
  END IF;

  PERFORM public.log_audit_event(
    v_booking.lounge_id,
    'booking_completed',
    'booking',
    p_booking_id::text,
    jsonb_build_object(
      'final_total', v_new_total,
      'paid_amount', v_paid_amount,
      'remaining_amount', v_remaining,
      'payment_status', v_payment_status,
      'is_open_time', v_booking.is_open_time
    ),
    p_booking_id
  );

  RETURN json_build_object(
    'success', true,
    'booking_id', p_booking_id,
    'lounge_id', v_booking.lounge_id,
    'status', 'completed',
    'final_total', v_new_total,
    'amount_paid', v_paid_amount,
    'remaining_amount', v_remaining,
    'payment_status', v_payment_status
  );
END;
$$;

-- -----------------------------------------------------------------------------
-- 10. Post-Session Collection (Collect payment for completed session)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.collect_completed_booking_payment(
  p_booking_id uuid,
  p_payment_method text DEFAULT 'cash',
  p_amount numeric DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_actor uuid := auth.uid();
  v_booking public.bookings%ROWTYPE;
  v_shift public.shifts%ROWTYPE;
  v_already_paid numeric := 0;
  v_collect_amount numeric;
  v_commission numeric;
  v_now timestamptz := now();
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  SELECT * INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found' USING ERRCODE = 'P0002';
  END IF;

  PERFORM private.assert_lounge_permission(v_booking.lounge_id, 'billing_checkout');

  IF v_booking.status IN ('cancelled'::public.booking_status, 'rejected'::public.booking_status) THEN
    RAISE EXCEPTION 'Cannot collect payment for a cancelled or rejected booking' USING ERRCODE = '55000';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.payments WHERE booking_id = p_booking_id AND status = 'refunded'
  ) THEN
    RAISE EXCEPTION 'Cannot collect payment for a refunded booking' USING ERRCODE = '55000';
  END IF;

  SELECT COALESCE(SUM(amount), 0) INTO v_already_paid
  FROM public.payments
  WHERE booking_id = p_booking_id AND status = 'completed';

  v_collect_amount := COALESCE(p_amount, v_booking.total_price - v_already_paid);
  IF v_collect_amount <= 0 THEN
    RAISE EXCEPTION 'Booking is already fully paid' USING ERRCODE = '55000';
  END IF;

  -- 1. Ensure active shift exists for lounge and lock it against concurrent closure
  SELECT * INTO v_shift
  FROM public.shifts
  WHERE lounge_id = v_booking.lounge_id AND status = 'open'
  ORDER BY opened_at DESC
  LIMIT 1
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'An open shift is required to collect payment' USING ERRCODE = '55000';
  END IF;

  v_commission := round(v_collect_amount * 0.15, 2);

  -- 2. Insert Shift Payment
  INSERT INTO public.shift_payments (
    shift_id, lounge_id, booking_id, payment_method, category, amount, paid_at
  ) VALUES (
    v_shift.id, v_booking.lounge_id, p_booking_id, p_payment_method, 'gaming_time', v_collect_amount, v_now
  );

  -- 3. Upsert Payments record
  INSERT INTO public.payments (
    booking_id, user_id, lounge_id, amount, commission, net_to_lounge,
    payment_method, status, paid_at
  ) VALUES (
    p_booking_id, v_booking.user_id, v_booking.lounge_id, v_collect_amount,
    v_commission, v_collect_amount - v_commission, p_payment_method, 'completed', v_now
  )
  ON CONFLICT (booking_id) DO UPDATE SET
    amount = public.payments.amount + EXCLUDED.amount,
    commission = public.payments.commission + EXCLUDED.commission,
    net_to_lounge = public.payments.net_to_lounge + EXCLUDED.net_to_lounge,
    payment_method = EXCLUDED.payment_method,
    status = 'completed',
    paid_at = v_now;

  -- 4. Update Booking
  UPDATE public.bookings
  SET payment_status = 'paid',
      payment_method = p_payment_method,
      shift_id = v_shift.id,
      updated_at = v_now
  WHERE id = p_booking_id;

  PERFORM public.log_audit_event(
    v_booking.lounge_id,
    'payment_collected',
    'payment',
    p_booking_id::text,
    jsonb_build_object(
      'amount', v_collect_amount,
      'payment_method', p_payment_method,
      'shift_id', v_shift.id,
      'booking_id', p_booking_id
    ),
    p_booking_id
  );

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', p_booking_id,
    'shift_id', v_shift.id,
    'amount_collected', v_collect_amount,
    'payment_status', 'paid',
    'status', v_booking.status
  );
END;
$$;

-- -----------------------------------------------------------------------------
-- 11. Hardened Manual Booking Review (InstaPay / Vodafone Cash)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.approve_manual_booking(
  p_booking_id uuid,
  p_action_by uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_booking public.bookings%ROWTYPE;
  v_shift public.shifts%ROWTYPE;
  v_actor uuid := auth.uid();
  v_now timestamptz := now();
  v_amount numeric;
  v_commission numeric;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  IF p_action_by IS NOT NULL AND p_action_by IS DISTINCT FROM v_actor AND NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Action actor does not match authenticated user' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found' USING ERRCODE = 'P0002';
  END IF;

  PERFORM private.assert_lounge_permission(v_booking.lounge_id, 'billing_checkout');

  IF NULLIF(btrim(COALESCE(v_booking.receipt_url, '')), '') IS NULL THEN
    RAISE EXCEPTION 'Payment receipt is required before approval' USING ERRCODE = '22023';
  END IF;

  IF v_booking.status NOT IN ('pending'::public.booking_status, 'upcoming'::public.booking_status) THEN
    RAISE EXCEPTION 'Booking cannot be approved in its current status' USING ERRCODE = '55000';
  END IF;

  -- Ensure active shift exists and lock it
  SELECT * INTO v_shift
  FROM public.shifts
  WHERE lounge_id = v_booking.lounge_id AND status = 'open'
  ORDER BY opened_at DESC
  LIMIT 1
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'An open shift is required to approve manual payments' USING ERRCODE = '55000';
  END IF;

  v_amount := round(v_booking.total_price, 2);
  v_commission := round(v_amount * 0.15, 2);

  -- Record Shift Payment
  INSERT INTO public.shift_payments (
    shift_id, lounge_id, booking_id, payment_method, category, amount, paid_at
  ) VALUES (
    v_shift.id, v_booking.lounge_id, p_booking_id, COALESCE(v_booking.payment_method, 'manual_transfer'), 'gaming_time', v_amount, v_now
  );

  -- Record Payment
  INSERT INTO public.payments (
    booking_id, user_id, lounge_id, amount, commission, net_to_lounge,
    payment_method, status, paid_at, discount_amount, discount_percentage,
    discount_reason, discount_approved_by
  ) VALUES (
    p_booking_id, v_booking.user_id, v_booking.lounge_id, v_amount,
    v_commission, v_amount - v_commission, COALESCE(v_booking.payment_method, 'manual_transfer'), 'completed', v_now,
    COALESCE(v_booking.discount_amount, 0), COALESCE(v_booking.discount_percentage, 0),
    v_booking.discount_reason, v_booking.discount_approved_by
  )
  ON CONFLICT (booking_id) DO UPDATE SET
    amount = EXCLUDED.amount,
    commission = EXCLUDED.commission,
    net_to_lounge = EXCLUDED.net_to_lounge,
    status = 'completed',
    paid_at = EXCLUDED.paid_at;

  UPDATE public.bookings
  SET status = 'upcoming'::public.booking_status,
      payment_status = 'paid',
      shift_id = v_shift.id,
      approved_by = v_actor,
      updated_at = v_now
  WHERE id = p_booking_id;

  PERFORM public.log_audit_event(
    v_booking.lounge_id,
    'booking_approved',
    'booking',
    p_booking_id::text,
    jsonb_build_object('approved_by', v_actor, 'shift_id', v_shift.id, 'amount', v_amount),
    p_booking_id
  );

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', p_booking_id,
    'status', 'upcoming',
    'payment_status', 'paid',
    'shift_id', v_shift.id,
    'approved_by', v_actor
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.reject_manual_booking(
  p_booking_id uuid,
  p_rejection_reason text,
  p_action_by uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_booking public.bookings%ROWTYPE;
  v_actor uuid := auth.uid();
  v_now timestamptz := now();
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  IF p_action_by IS NOT NULL AND p_action_by IS DISTINCT FROM v_actor AND NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Action actor does not match authenticated user' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found' USING ERRCODE = 'P0002';
  END IF;

  PERFORM private.assert_lounge_permission(v_booking.lounge_id, 'bookings_cancel');

  UPDATE public.bookings
  SET status = 'rejected'::public.booking_status,
      cancellation_reason = p_rejection_reason,
      cancelled_by = v_actor,
      cancelled_at = v_now,
      updated_at = v_now
  WHERE id = p_booking_id;

  PERFORM public.log_audit_event(
    v_booking.lounge_id,
    'booking_cancelled',
    'booking',
    p_booking_id::text,
    jsonb_build_object('reason', p_rejection_reason, 'rejected_by', v_actor),
    p_booking_id,
    'warning'
  );

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', p_booking_id,
    'status', 'rejected',
    'rejected_by', v_actor
  );
END;
$$;

-- -----------------------------------------------------------------------------
-- 12. Tournament Payment Overload Security Closure
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.submit_tournament_payment(
  p_participant_id uuid,
  p_amount numeric,
  p_payment_method text,
  p_receipt_url text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_p public.tournament_participants%ROWTYPE;
  v_t public.tournaments%ROWTYPE;
  v_s public.tournament_payment_submissions%ROWTYPE;
  v_actor uuid := auth.uid();
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  SELECT p.* INTO v_p
  FROM public.tournament_participants p
  WHERE p.id = p_participant_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Participant not found' USING ERRCODE = 'P0002';
  END IF;

  SELECT t.* INTO v_t
  FROM public.tournaments t
  WHERE t.id = v_p.tournament_id;

  IF v_p.user_id <> v_actor AND NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'not_participant' USING ERRCODE = '42501';
  END IF;

  IF v_p.registration_status <> 'pending_payment' OR v_p.payment_status <> 'unpaid' THEN
    RAISE EXCEPTION 'payment_not_allowed' USING ERRCODE = '55000';
  END IF;

  IF v_p.payment_deadline < now() THEN
    RAISE EXCEPTION 'payment_deadline_expired' USING ERRCODE = '55000';
  END IF;

  IF p_payment_method NOT IN ('instapay', 'vodafone_cash') OR p_receipt_url IS NULL OR btrim(p_receipt_url) = '' THEN
    RAISE EXCEPTION 'receipt_required' USING ERRCODE = '22023';
  END IF;

  IF p_amount <> v_t.entry_fee THEN
    RAISE EXCEPTION 'amount_mismatch' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.tournament_payment_submissions(
    participant_id, amount, payment_method, receipt_url, submitted_by
  ) VALUES (
    p_participant_id, p_amount, p_payment_method, p_receipt_url, v_actor
  ) RETURNING * INTO v_s;

  UPDATE public.tournament_participants
  SET payment_status = 'pending',
      payment_method = p_payment_method,
      receipt_url = p_receipt_url,
      updated_at = now()
  WHERE id = p_participant_id
  RETURNING * INTO v_p;

  PERFORM public.tournament_audit(v_t.id, 'payment_submitted', p_participant_id, NULL, NULL, to_jsonb(v_s));

  PERFORM public.log_audit_event(
    v_t.lounge_id,
    'tournament_payment_submitted',
    'tournament_participant',
    p_participant_id::text,
    jsonb_build_object('tournament_id', v_t.id, 'amount', p_amount, 'payment_method', p_payment_method)
  );

  RETURN row_to_json(v_p);
END;
$$;

-- Secure Legacy 6-Parameter Overload Wrapper
CREATE OR REPLACE FUNCTION public.submit_tournament_payment(
  p_participant_id uuid,
  p_tournament_id uuid,
  p_user_id uuid,
  p_amount numeric,
  p_payment_method text,
  p_receipt_url text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_actor uuid := auth.uid();
  v_res json;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  IF p_user_id IS NOT NULL AND p_user_id <> v_actor AND NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Action user does not match authenticated user' USING ERRCODE = '42501';
  END IF;

  v_res := public.submit_tournament_payment(
    p_participant_id,
    p_amount,
    p_payment_method,
    p_receipt_url
  );

  RETURN jsonb_build_object(
    'success', true,
    'participant_id', p_participant_id,
    'result', to_jsonb(v_res)
  );
END;
$$;

-- -----------------------------------------------------------------------------
-- 13. Canteen Stock & Order Cancellation Recovery
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.cancel_canteen_order(
  p_order_id uuid,
  p_reason text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_order public.canteen_orders%ROWTYPE;
  v_item record;
  v_actor uuid := auth.uid();
  v_now timestamptz := now();
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '28000';
  END IF;

  SELECT * INTO v_order
  FROM public.canteen_orders
  WHERE id = p_order_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Canteen order not found' USING ERRCODE = 'P0002';
  END IF;

  PERFORM private.assert_lounge_permission(v_order.lounge_id, 'billing_checkout');

  IF v_order.status = 'cancelled' THEN
    RETURN jsonb_build_object('success', true, 'order_id', p_order_id, 'already_cancelled', true);
  END IF;

  -- 1. Restore tracked stock
  FOR v_item IN
    SELECT extra_id, quantity
    FROM public.canteen_order_items
    WHERE order_id = p_order_id
  LOOP
    UPDATE public.extras
    SET stock_quantity = COALESCE(stock_quantity, 0) + v_item.quantity
    WHERE id = v_item.extra_id AND track_stock IS TRUE;
  END LOOP;

  -- 2. Update Canteen Order
  UPDATE public.canteen_orders
  SET status = 'cancelled',
      note = COALESCE(p_reason, note),
      updated_at = v_now
  WHERE id = p_order_id;

  -- 3. If linked to booking, subtract from addons_price and recalculate total
  IF v_order.booking_id IS NOT NULL THEN
    UPDATE public.bookings
    SET addons_price = GREATEST(0, COALESCE(addons_price, 0) - v_order.total_price),
        total_price = GREATEST(0, room_price + GREATEST(0, COALESCE(addons_price, 0) - v_order.total_price) - COALESCE(discount_amount, 0)),
        updated_at = v_now
    WHERE id = v_order.booking_id;
  ELSE
    -- If counter sale with shift_payments, mark as refunded/cancelled
    DELETE FROM public.shift_payments WHERE canteen_order_id = p_order_id;
  END IF;

  PERFORM public.log_audit_event(
    v_order.lounge_id,
    'canteen_order_cancelled',
    'canteen_order',
    p_order_id::text,
    jsonb_build_object('reason', p_reason, 'amount', v_order.total_price),
    v_order.booking_id,
    'warning'
  );

  RETURN jsonb_build_object(
    'success', true,
    'order_id', p_order_id,
    'status', 'cancelled'
  );
END;
$$;

-- -----------------------------------------------------------------------------
-- 14. Access Control & Privilege Hardening (Revoke anon/public, Grant authenticated)
-- -----------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.complete_booking_session(uuid, uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.collect_completed_booking_payment(uuid, text, numeric) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.approve_manual_booking(uuid, uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.reject_manual_booking(uuid, text, uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.submit_tournament_payment(uuid, numeric, text, text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.submit_tournament_payment(uuid, uuid, uuid, numeric, text, text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.cancel_canteen_order(uuid, text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.quote_booking_price(uuid, date, time without time zone, time without time zone, text, int, text) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.complete_booking_session(uuid, uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.collect_completed_booking_payment(uuid, text, numeric) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.approve_manual_booking(uuid, uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.reject_manual_booking(uuid, text, uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.submit_tournament_payment(uuid, numeric, text, text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.submit_tournament_payment(uuid, uuid, uuid, numeric, text, text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.cancel_canteen_order(uuid, text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.quote_booking_price(uuid, date, time without time zone, time without time zone, text, int, text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_room_slots_with_prices(uuid, date) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_lounge_price_range(uuid) TO authenticated, service_role;

COMMIT;
