-- Settings: Add difficulty_level and notifications_enabled to onboarding_profiles
ALTER TABLE public.onboarding_profiles
ADD COLUMN IF NOT EXISTS difficulty_level TEXT DEFAULT 'Beginner',
ADD COLUMN IF NOT EXISTS notifications_enabled BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS display_name TEXT,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

-- Update RLS policies to ensure they cover the new columns
DROP POLICY IF EXISTS "users_manage_own_onboarding_profiles" ON public.onboarding_profiles;
CREATE POLICY "users_manage_own_onboarding_profiles"
ON public.onboarding_profiles
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
