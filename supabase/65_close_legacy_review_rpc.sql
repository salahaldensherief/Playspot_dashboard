BEGIN;

REVOKE EXECUTE ON FUNCTION public.submit_lounge_review(uuid,numeric,text)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.submit_lounge_review(uuid,numeric,text)
TO service_role;

COMMIT;
