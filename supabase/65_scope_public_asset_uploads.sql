BEGIN;

DROP POLICY IF EXISTS "Authenticated public asset insert" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated public asset update" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated public asset delete" ON storage.objects;

DROP POLICY IF EXISTS "Legacy public asset owner insert" ON storage.objects;
CREATE POLICY "Legacy public asset owner insert"
ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id IN ('avatars','extra-assets','lounges','products'));

DROP POLICY IF EXISTS "Legacy public asset owner update" ON storage.objects;
CREATE POLICY "Legacy public asset owner update"
ON storage.objects
FOR UPDATE TO authenticated
USING (
  bucket_id IN ('avatars','extra-assets','lounges','products')
  AND owner = (select auth.uid())
)
WITH CHECK (
  bucket_id IN ('avatars','extra-assets','lounges','products')
  AND owner = (select auth.uid())
);

DROP POLICY IF EXISTS "Legacy public asset owner delete" ON storage.objects;
CREATE POLICY "Legacy public asset owner delete"
ON storage.objects
FOR DELETE TO authenticated
USING (
  bucket_id IN ('avatars','extra-assets','lounges','products')
  AND owner = (select auth.uid())
);

DROP POLICY IF EXISTS "Lounge asset authorized insert" ON storage.objects;
CREATE POLICY "Lounge asset authorized insert"
ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'lounge-assets'
  AND EXISTS (
    SELECT 1
    FROM public.lounges l
    WHERE l.id::text = CASE
      WHEN (storage.foldername(name))[1] = 'extras'
      THEN (storage.foldername(name))[2]
      ELSE (storage.foldername(name))[1]
    END
      AND (
        public.is_super_admin()
        OR public.has_lounge_permission(
          l.id,
          CASE
            WHEN (storage.foldername(name))[1] = 'extras'
            THEN 'menu_manage_items'
            ELSE 'lounges_manage_settings'
          END
        )
      )
  )
);

DROP POLICY IF EXISTS "Lounge asset owner update" ON storage.objects;
CREATE POLICY "Lounge asset owner update"
ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'lounge-assets' AND owner = (select auth.uid()))
WITH CHECK (bucket_id = 'lounge-assets' AND owner = (select auth.uid()));

DROP POLICY IF EXISTS "Lounge asset owner delete" ON storage.objects;
CREATE POLICY "Lounge asset owner delete"
ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'lounge-assets' AND owner = (select auth.uid()));

DROP POLICY IF EXISTS "Room asset authorized insert" ON storage.objects;
CREATE POLICY "Room asset authorized insert"
ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'room-assets'
  AND EXISTS (
    SELECT 1
    FROM public.lounges l
    WHERE l.id::text = (storage.foldername(name))[1]
      AND (
        public.is_super_admin()
        OR public.has_lounge_permission(l.id, 'rooms_manage')
      )
  )
);

DROP POLICY IF EXISTS "Room asset owner update" ON storage.objects;
CREATE POLICY "Room asset owner update"
ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'room-assets' AND owner = (select auth.uid()))
WITH CHECK (bucket_id = 'room-assets' AND owner = (select auth.uid()));

DROP POLICY IF EXISTS "Room asset owner delete" ON storage.objects;
CREATE POLICY "Room asset owner delete"
ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'room-assets' AND owner = (select auth.uid()));

DROP POLICY IF EXISTS "Promotion asset authorized insert" ON storage.objects;
CREATE POLICY "Promotion asset authorized insert"
ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'promotion-assets'
  AND EXISTS (
    SELECT 1
    FROM public.lounges l
    WHERE l.id::text = (storage.foldername(name))[1]
      AND (
        public.is_super_admin()
        OR public.has_lounge_permission(l.id, 'marketing_manage')
      )
  )
);

DROP POLICY IF EXISTS "Promotion asset owner update" ON storage.objects;
CREATE POLICY "Promotion asset owner update"
ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'promotion-assets' AND owner = (select auth.uid()))
WITH CHECK (bucket_id = 'promotion-assets' AND owner = (select auth.uid()));

DROP POLICY IF EXISTS "Promotion asset owner delete" ON storage.objects;
CREATE POLICY "Promotion asset owner delete"
ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'promotion-assets' AND owner = (select auth.uid()));

DROP POLICY IF EXISTS "Tournament owners can upload banners" ON storage.objects;
DROP POLICY IF EXISTS "Tournament owners can update banners" ON storage.objects;
DROP POLICY IF EXISTS "Tournament owners can delete banners" ON storage.objects;

DROP POLICY IF EXISTS "Tournament asset authorized insert" ON storage.objects;
CREATE POLICY "Tournament asset authorized insert"
ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'tournament-assets'
  AND EXISTS (
    SELECT 1
    FROM public.tournaments t
    WHERE t.id::text = (storage.foldername(name))[1]
      AND (
        t.created_by = (select auth.uid())
        OR public.is_super_admin()
        OR public.is_lounge_member_or_admin(t.lounge_id)
      )
  )
);

DROP POLICY IF EXISTS "Tournament asset owner update" ON storage.objects;
CREATE POLICY "Tournament asset owner update"
ON storage.objects
FOR UPDATE TO authenticated
USING (
  bucket_id = 'tournament-assets'
  AND (
    owner = (select auth.uid())
    OR public.is_super_admin()
    OR EXISTS (
      SELECT 1
      FROM public.tournaments t
      WHERE t.id::text = (storage.foldername(name))[1]
        AND public.is_lounge_member_or_admin(t.lounge_id)
    )
  )
)
WITH CHECK (
  bucket_id = 'tournament-assets'
  AND (
    owner = (select auth.uid())
    OR public.is_super_admin()
    OR EXISTS (
      SELECT 1
      FROM public.tournaments t
      WHERE t.id::text = (storage.foldername(name))[1]
        AND public.is_lounge_member_or_admin(t.lounge_id)
    )
  )
);

DROP POLICY IF EXISTS "Tournament asset authorized delete" ON storage.objects;
CREATE POLICY "Tournament asset authorized delete"
ON storage.objects
FOR DELETE TO authenticated
USING (
  bucket_id = 'tournament-assets'
  AND (
    owner = (select auth.uid())
    OR public.is_super_admin()
    OR EXISTS (
      SELECT 1
      FROM public.tournaments t
      WHERE t.id::text = (storage.foldername(name))[1]
        AND public.is_lounge_member_or_admin(t.lounge_id)
    )
  )
);

COMMIT;
