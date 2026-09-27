BEGIN;

SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobid = 13
   OR (
     schedule = '0 4 * * *'
     AND command ILIKE '%UPDATE public.bookings%'
     AND command ILIKE '%status = ''pending''%'
     AND command ILIKE '%24 hours%'
   );

COMMIT;
