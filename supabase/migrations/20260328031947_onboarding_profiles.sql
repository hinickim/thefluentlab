-- Onboarding profiles migration
-- Stores user onboarding answers: role, struggles, recommended level, streak commitment

CREATE TABLE IF NOT EXISTS public.onboarding_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    user_role TEXT NOT NULL,
    user_role_other TEXT,
    struggles TEXT[] NOT NULL DEFAULT '{}',
    recommended_level TEXT NOT NULL DEFAULT 'Beginner',
    streak_committed BOOLEAN NOT NULL DEFAULT false,
    completed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_onboarding_profiles_user_id ON public.onboarding_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_onboarding_profiles_created_at ON public.onboarding_profiles(created_at);

ALTER TABLE public.onboarding_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_manage_own_onboarding_profiles" ON public.onboarding_profiles;
CREATE POLICY "users_manage_own_onboarding_profiles"
ON public.onboarding_profiles
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
