BEGIN;

DROP POLICY IF EXISTS "Authenticated public asset insert" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated public asset update" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated public asset delete" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to upload avatars" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload avatars" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update avatars" ON storage.objects;

DROP POLICY IF EXISTS "Avatar owner insert" ON storage.objects;
CREATE POLICY "Avatar owner insert"
ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = (select auth.uid())::text
);

DROP POLICY IF EXISTS "Avatar owner update" ON storage.objects;
CREATE POLICY "Avatar owner update"
ON storage.objects
FOR UPDATE TO authenticated
USING (
  bucket_id = 'avatars'
  AND owner = (select auth.uid())
)
WITH CHECK (
  bucket_id = 'avatars'
  AND owner = (select auth.uid())
);

DROP POLICY IF EXISTS "Avatar owner delete" ON storage.objects;
CREATE POLICY "Avatar owner delete"
ON storage.objects
FOR DELETE TO authenticated
USING (
  bucket_id = 'avatars'
  AND owner = (select auth.uid())
);

DROP POLICY IF EXISTS "Lounge asset operator insert" ON storage.objects;
CREATE POLICY "Lounge asset operator insert"
ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'lounge-assets'
  AND (
    (
      (storage.foldername(name))[1] ~* '^[0-9a-f-]{36}$'
      AND public.is_lounge_member_or_admin(((storage.foldername(name))[1])::uuid)
    )
    OR (
      (storage.foldername(name))[1] = 'extras'
      AND (storage.foldername(name))[2] ~* '^[0-9a-f-]{36}$'
      AND public.is_lounge_member_or_admin(((storage.foldername(name))[2])::uuid)
    )
  )
);

DROP POLICY IF EXISTS "Room asset operator insert" ON storage.objects;
CREATE POLICY "Room asset operator insert"
ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'room-assets'
  AND (storage.foldername(name))[1] ~* '^[0-9a-f-]{36}$'
  AND public.is_lounge_member_or_admin(((storage.foldername(name))[1])::uuid)
);

DROP POLICY IF EXISTS "Promotion asset operator insert" ON storage.objects;
CREATE POLICY "Promotion asset operator insert"
ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'promotion-assets'
  AND EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = (select auth.uid())
      AND coalesce(p.is_active, true)
      AND p.role IN ('super_admin','owner','manager','admin','lounge_admin')
  )
);

DROP POLICY IF EXISTS "Tournament asset operator insert canonical" ON storage.objects;
CREATE POLICY "Tournament asset operator insert canonical"
ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'tournament-assets'
  AND (storage.foldername(name))[1] ~* '^[0-9a-f-]{36}$'
  AND EXISTS (
    SELECT 1
    FROM public.tournaments t
    WHERE t.id = ((storage.foldername(name))[1])::uuid
      AND (
        t.created_by = (select auth.uid())
        OR public.is_super_admin()
        OR public.is_lounge_member_or_admin(t.lounge_id)
      )
  )
);

DROP POLICY IF EXISTS "Owned public asset update" ON storage.objects;
CREATE POLICY "Owned public asset update"
ON storage.objects
FOR UPDATE TO authenticated
USING (
  bucket_id IN ('lounge-assets','room-assets','promotion-assets','tournament-assets')
  AND owner = (select auth.uid())
)
WITH CHECK (
  bucket_id IN ('lounge-assets','room-assets','promotion-assets','tournament-assets')
  AND owner = (select auth.uid())
);

DROP POLICY IF EXISTS "Owned public asset delete" ON storage.objects;
CREATE POLICY "Owned public asset delete"
ON storage.objects
FOR DELETE TO authenticated
USING (
  bucket_id IN ('lounge-assets','room-assets','promotion-assets','tournament-assets')
  AND owner = (select auth.uid())
);

COMMIT;
