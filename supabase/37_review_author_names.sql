create or replace function public.get_lounge_review_authors(p_lounge_id uuid)
returns table(user_id uuid, full_name text, avatar_url text)
language sql
stable
security definer
set search_path = ''
as $function$
  select distinct p.id, p.full_name, p.avatar_url
  from public.lounge_reviews as r
  join public.profiles as p on p.id = r.user_id
  where r.lounge_id = p_lounge_id
    and (select auth.uid()) is not null
    and (
      public.is_super_admin()
      or public.is_lounge_member_or_admin(p_lounge_id)
    );
$function$;

revoke all on function public.get_lounge_review_authors(uuid) from public, anon;
grant execute on function public.get_lounge_review_authors(uuid) to authenticated;
