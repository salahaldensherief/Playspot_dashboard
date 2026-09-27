BEGIN;

DROP POLICY IF EXISTS "Legacy public asset owner insert" ON storage.objects;
DROP POLICY IF EXISTS "Legacy public asset owner update" ON storage.objects;
DROP POLICY IF EXISTS "Legacy public asset owner delete" ON storage.objects;

DROP POLICY IF EXISTS "Lounge asset authorized insert" ON storage.objects;
DROP POLICY IF EXISTS "Lounge asset owner update" ON storage.objects;
DROP POLICY IF EXISTS "Lounge asset owner delete" ON storage.objects;

DROP POLICY IF EXISTS "Room asset authorized insert" ON storage.objects;
DROP POLICY IF EXISTS "Room asset owner update" ON storage.objects;
DROP POLICY IF EXISTS "Room asset owner delete" ON storage.objects;

DROP POLICY IF EXISTS "Promotion asset authorized insert" ON storage.objects;
DROP POLICY IF EXISTS "Promotion asset owner update" ON storage.objects;
DROP POLICY IF EXISTS "Promotion asset owner delete" ON storage.objects;
DROP POLICY IF EXISTS "Promotion asset operator insert" ON storage.objects;

DROP POLICY IF EXISTS "Tournament asset operator insert canonical" ON storage.objects;
DROP POLICY IF EXISTS "Owned public asset update" ON storage.objects;
DROP POLICY IF EXISTS "Owned public asset delete" ON storage.objects;

DROP POLICY IF EXISTS "Avatar owner insert" ON storage.objects;
CREATE POLICY "Avatar owner insert"
ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'avatars'
  AND (storage.foldername(storage.objects.name))[1] = (select auth.uid())::text
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
  AND EXISTS (
    SELECT 1
    FROM public.lounges l
    WHERE l.id::text = CASE
      WHEN (storage.foldername(storage.objects.name))[1] = 'extras'
        THEN (storage.foldername(storage.objects.name))[2]
      ELSE (storage.foldername(storage.objects.name))[1]
    END
      AND (
        public.is_super_admin()
        OR public.has_lounge_permission(
          l.id,
          CASE
            WHEN (storage.foldername(storage.objects.name))[1] = 'extras'
              THEN 'menu_manage_items'
            ELSE 'lounges_manage_settings'
          END
        )
      )
  )
);

DROP POLICY IF EXISTS "Lounge asset owner update canonical" ON storage.objects;
CREATE POLICY "Lounge asset owner update canonical"
ON storage.objects
FOR UPDATE TO authenticated
USING (
  bucket_id = 'lounge-assets'
  AND owner = (select auth.uid())
)
WITH CHECK (
  bucket_id = 'lounge-assets'
  AND owner = (select auth.uid())
);

DROP POLICY IF EXISTS "Lounge asset owner delete canonical" ON storage.objects;
CREATE POLICY "Lounge asset owner delete canonical"
ON storage.objects
FOR DELETE TO authenticated
USING (
  bucket_id = 'lounge-assets'
  AND owner = (select auth.uid())
);

DROP POLICY IF EXISTS "Room asset operator insert" ON storage.objects;
CREATE POLICY "Room asset operator insert"
ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'room-assets'
  AND EXISTS (
    SELECT 1
    FROM public.lounges l
    WHERE l.id::text = (storage.foldername(storage.objects.name))[1]
      AND (
        public.is_super_admin()
        OR public.has_lounge_permission(l.id, 'rooms_manage')
      )
  )
);

DROP POLICY IF EXISTS "Room asset owner update canonical" ON storage.objects;
CREATE POLICY "Room asset owner update canonical"
ON storage.objects
FOR UPDATE TO authenticated
USING (
  bucket_id = 'room-assets'
  AND owner = (select auth.uid())
)
WITH CHECK (
  bucket_id = 'room-assets'
  AND owner = (select auth.uid())
);

DROP POLICY IF EXISTS "Room asset owner delete canonical" ON storage.objects;
CREATE POLICY "Room asset owner delete canonical"
ON storage.objects
FOR DELETE TO authenticated
USING (
  bucket_id = 'room-assets'
  AND owner = (select auth.uid())
);

DROP POLICY IF EXISTS "Promotion asset operator insert canonical" ON storage.objects;
CREATE POLICY "Promotion asset operator insert canonical"
ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'promotion-assets'
  AND EXISTS (
    SELECT 1
    FROM public.lounges l
    WHERE l.id::text = (storage.foldername(storage.objects.name))[1]
      AND (
        public.is_super_admin()
        OR public.has_lounge_permission(l.id, 'marketing_manage')
      )
  )
);

DROP POLICY IF EXISTS "Promotion asset owner update canonical" ON storage.objects;
CREATE POLICY "Promotion asset owner update canonical"
ON storage.objects
FOR UPDATE TO authenticated
USING (
  bucket_id = 'promotion-assets'
  AND owner = (select auth.uid())
)
WITH CHECK (
  bucket_id = 'promotion-assets'
  AND owner = (select auth.uid())
);

DROP POLICY IF EXISTS "Promotion asset owner delete canonical" ON storage.objects;
CREATE POLICY "Promotion asset owner delete canonical"
ON storage.objects
FOR DELETE TO authenticated
USING (
  bucket_id = 'promotion-assets'
  AND owner = (select auth.uid())
);

COMMIT;
