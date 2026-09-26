-- =============================================================================
-- 28_revoke_anon_write_privileges.sql
-- Defense-in-Depth: Revoke all write privileges from anon role on public tables
-- Playspot Dashboard - 2026
-- =============================================================================

-- Revoke write privileges from unauthenticated anon role across public schema
REVOKE INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public FROM anon;

-- Re-grant SELECT on public browsing tables so unauthenticated visitors can browse lounges and rooms
GRANT SELECT ON public.lounges, public.rooms, public.promotions, public.cities, public.activity_types, public.lounge_reviews, public.faqs, public.legal_policies TO anon;
