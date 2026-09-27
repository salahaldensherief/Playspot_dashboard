BEGIN;

CREATE OR REPLACE FUNCTION public.check_and_send_booking_reminders()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_now_local timestamp without time zone :=
    pg_catalog.now() AT TIME ZONE 'Africa/Cairo';
BEGIN
  INSERT INTO public.notifications (
    id, user_id, title, body, title_ar, title_en, body_ar, body_en,
    type, is_read, created_at, metadata, lounge_id
  )
  SELECT
    gen_random_uuid(),
    b.user_id,
    r.title_ar,
    r.body_ar,
    r.title_ar,
    r.title_en,
    r.body_ar,
    r.body_en,
    'booking',
    false,
    now(),
    jsonb_build_object(
      'booking_id', b.id,
      'lounge_id', b.lounge_id,
      'event', 'booking_reminder:' || r.reminder_key,
      'reminder_key', r.reminder_key,
      'scheduled_for', CASE
        WHEN r.reminder_key = 'extension_offer' THEN upper(b.booking_period)
        ELSE b.date + b.start_time
      END,
      'extension_minutes', CASE
        WHEN r.reminder_key = 'extension_offer' THEN 60
        ELSE NULL
      END
    ),
    b.lounge_id
  FROM public.bookings AS b
  CROSS JOIN LATERAL (
    VALUES
      (
        'one_hour',
        'تذكير بموعد الحجز ⏰',
        'حجزك يبدأ خلال ساعة، حضّر نفسك واستمتع بوقتك!',
        'Booking reminder ⏰',
        'Your booking starts in one hour.'
      ),
      (
        'five_minutes',
        'حجزك سيبدأ بعد 5 دقائق ⏰',
        'حجزك في الصالة سيبدأ خلال 5 دقائق، استعد!',
        'Your booking starts in 5 minutes ⏰',
        'Your lounge booking starts in 5 minutes.'
      ),
      (
        'extension_offer',
        'هل تريد تمديد وقت الحجز؟ ⏰',
        'متبقي 5 دقائق على انتهاء حجزك. الساعة التالية متاحة، هل تريد تمديد الوقت؟',
        'Would you like to extend your booking? ⏰',
        'Your booking ends in 5 minutes. The next hour is available. Would you like to extend?'
      )
  ) AS r(reminder_key, title_ar, body_ar, title_en, body_en)
  WHERE b.user_id IS NOT NULL
    AND b.status IN ('upcoming', 'in_progress')
    AND (
      (
        r.reminder_key = 'one_hour'
        AND (b.date + b.start_time)
          BETWEEN (v_now_local + interval '59 minutes')
          AND (v_now_local + interval '61 minutes')
      )
      OR (
        r.reminder_key = 'five_minutes'
        AND (b.date + b.start_time)
          BETWEEN (v_now_local + interval '4 minutes')
          AND (v_now_local + interval '6 minutes')
      )
      OR (
        r.reminder_key = 'extension_offer'
        AND b.room_id IS NOT NULL
        AND upper(b.booking_period)
          BETWEEN (v_now_local + interval '4 minutes')
          AND (v_now_local + interval '6 minutes')
        AND NOT EXISTS (
          SELECT 1
          FROM public.bookings AS next_booking
          WHERE next_booking.id <> b.id
            AND next_booking.room_id = b.room_id
            AND next_booking.status IN ('upcoming', 'in_progress')
            AND next_booking.booking_period && tsrange(
              upper(b.booking_period),
              upper(b.booking_period) + interval '1 hour',
              '[)'
            )
        )
      )
    )
    AND NOT EXISTS (
      SELECT 1
      FROM public.notifications AS n
      WHERE n.user_id = b.user_id
        AND n.type = 'booking'
        AND n.metadata->>'booking_id' = b.id::text
        AND n.metadata->>'reminder_key' = r.reminder_key
        AND n.metadata->>'scheduled_for' = (
          CASE
            WHEN r.reminder_key = 'extension_offer' THEN upper(b.booking_period)
            ELSE b.date + b.start_time
          END
        )::text
    );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.check_and_send_booking_reminders()
FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.check_and_send_booking_reminders()
TO service_role;

COMMIT;
