-- Migration 19: Create lounge_role_permissions table and set RLS policies

CREATE TABLE IF NOT EXISTS public.lounge_role_permissions (
    lounge_id UUID NOT NULL REFERENCES public.lounges(id) ON DELETE CASCADE,
    role TEXT NOT NULL,
    permission_key TEXT NOT NULL,
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (lounge_id, role, permission_key)
);

-- Enable Row Level Security
ALTER TABLE public.lounge_role_permissions ENABLE ROW LEVEL SECURITY;

-- 1. Super Admins have full access to all lounge permissions
CREATE POLICY "Super Admins full access on lounge_role_permissions"
ON public.lounge_role_permissions
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.platform_super_admins
        WHERE user_id = auth.uid()
    )
    OR EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'super_admin'
    )
);

-- 2. Lounge Owners and Managers can select permissions for their lounge
CREATE POLICY "Lounge Staff select own lounge_role_permissions"
ON public.lounge_role_permissions
FOR SELECT
TO authenticated
USING (
    lounge_id IN (
        SELECT lounge_id FROM public.profiles
        WHERE id = auth.uid()
    )
);

-- 3. Lounge Owners and Managers can upsert permissions for their lounge
CREATE POLICY "Lounge Admins modify own lounge_role_permissions"
ON public.lounge_role_permissions
FOR ALL
TO authenticated
USING (
    lounge_id IN (
        SELECT lounge_id FROM public.profiles
        WHERE id = auth.uid()
        AND role IN ('owner', 'manager', 'lounge_admin')
    )
)
WITH CHECK (
    lounge_id IN (
        SELECT lounge_id FROM public.profiles
        WHERE id = auth.uid()
        AND role IN ('owner', 'manager', 'lounge_admin')
    )
);

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_lounge_role_permissions_lounge_role
ON public.lounge_role_permissions (lounge_id, role);
