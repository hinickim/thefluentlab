-- Exercises Content Module
-- Stores exercise categories and exercises that the Flutter app reads dynamically
-- Admins manage this content via the HTML admin panel

-- 1. Core Tables

CREATE TABLE IF NOT EXISTS public.exercise_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    description TEXT,
    icon TEXT DEFAULT 'mic',
    color TEXT DEFAULT '#4A90D9',
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID REFERENCES public.exercise_categories(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    difficulty TEXT NOT NULL DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')),
    focus TEXT,
    tags TEXT[],
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. Indexes
CREATE INDEX IF NOT EXISTS idx_exercise_categories_slug ON public.exercise_categories(slug);
CREATE INDEX IF NOT EXISTS idx_exercise_categories_active ON public.exercise_categories(is_active);
CREATE INDEX IF NOT EXISTS idx_exercises_category_id ON public.exercises(category_id);
CREATE INDEX IF NOT EXISTS idx_exercises_difficulty ON public.exercises(difficulty);
CREATE INDEX IF NOT EXISTS idx_exercises_active ON public.exercises(is_active);

-- 3. Updated_at trigger function
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_exercise_categories_updated_at ON public.exercise_categories;
CREATE TRIGGER set_exercise_categories_updated_at
    BEFORE UPDATE ON public.exercise_categories
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_exercises_updated_at ON public.exercises;
CREATE TRIGGER set_exercises_updated_at
    BEFORE UPDATE ON public.exercises
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 4. Enable RLS
ALTER TABLE public.exercise_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies
-- Public read access (all users including unauthenticated can read exercises)
DROP POLICY IF EXISTS "public_read_exercise_categories" ON public.exercise_categories;
CREATE POLICY "public_read_exercise_categories"
ON public.exercise_categories
FOR SELECT
TO public
USING (is_active = true);

DROP POLICY IF EXISTS "public_read_exercises" ON public.exercises;
CREATE POLICY "public_read_exercises"
ON public.exercises
FOR SELECT
TO public
USING (is_active = true);

-- Admin write access (service role key bypasses RLS, used by admin panel)
-- Authenticated users with admin role can manage content
DROP POLICY IF EXISTS "admin_manage_exercise_categories" ON public.exercise_categories;
CREATE POLICY "admin_manage_exercise_categories"
ON public.exercise_categories
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM auth.users au
        WHERE au.id = auth.uid()
        AND (
            au.raw_user_meta_data->>'role' = 'admin'
            OR au.raw_app_meta_data->>'role' = 'admin'
        )
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM auth.users au
        WHERE au.id = auth.uid()
        AND (
            au.raw_user_meta_data->>'role' = 'admin'
            OR au.raw_app_meta_data->>'role' = 'admin'
        )
    )
);

DROP POLICY IF EXISTS "admin_manage_exercises" ON public.exercises;
CREATE POLICY "admin_manage_exercises"
ON public.exercises
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM auth.users au
        WHERE au.id = auth.uid()
        AND (
            au.raw_user_meta_data->>'role' = 'admin'
            OR au.raw_app_meta_data->>'role' = 'admin'
        )
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM auth.users au
        WHERE au.id = auth.uid()
        AND (
            au.raw_user_meta_data->>'role' = 'admin'
            OR au.raw_app_meta_data->>'role' = 'admin'
        )
    )
);

-- 6. Seed Data - Default categories and exercises
DO $$
DECLARE
    cat_tongue_twister UUID := gen_random_uuid();
    cat_natural_speech UUID := gen_random_uuid();
    cat_professional UUID := gen_random_uuid();
    cat_vowel_sounds UUID := gen_random_uuid();
BEGIN
    -- Insert categories
    INSERT INTO public.exercise_categories (id, name, slug, description, icon, color, display_order)
    VALUES
        (cat_tongue_twister, 'Tongue Twisters', 'tongue_twister', 'Fast-paced exercises to improve consonant precision and rhythm', 'record_voice_over', '#4A90D9', 1),
        (cat_natural_speech, 'Natural Speech', 'natural_speech', 'Everyday conversational phrases for natural fluency', 'chat_bubble', '#7B68EE', 2),
        (cat_professional, 'Professional', 'professional', 'Business and workplace communication exercises', 'business_center', '#20B2AA', 3),
        (cat_vowel_sounds, 'Vowel Sounds', 'vowel_sounds', 'Targeted exercises for vowel clarity and distinction', 'graphic_eq', '#FF6B6B', 4)
    ON CONFLICT (slug) DO NOTHING;

    -- Insert exercises for Tongue Twisters
    INSERT INTO public.exercises (category_id, text, difficulty, focus, tags, display_order)
    VALUES
        (cat_tongue_twister, 'How much wood would a woodchuck chuck if a woodchuck could chuck wood?', 'medium', 'Consonant clusters & rhythm', ARRAY['w-sound', 'rhythm', 'classic'], 1),
        (cat_tongue_twister, 'She sells seashells by the seashore, and the shells she sells are surely seashells.', 'hard', 'S and SH distinction', ARRAY['s-sound', 'sh-sound', 'classic'], 2),
        (cat_tongue_twister, 'Peter Piper picked a peck of pickled peppers from the pepper patch.', 'hard', 'P consonant precision', ARRAY['p-sound', 'alliteration'], 3),
        (cat_tongue_twister, 'Red lorry, yellow lorry, red lorry, yellow lorry.', 'medium', 'L and R distinction', ARRAY['l-sound', 'r-sound', 'repetition'], 4),
        (cat_tongue_twister, 'Unique New York, unique New York, you know you need unique New York.', 'medium', 'NY vowel sounds', ARRAY['vowels', 'rhythm'], 5),
        (cat_tongue_twister, 'Betty Botter bought some butter, but the butter was bitter.', 'easy', 'B consonant & vowel sounds', ARRAY['b-sound', 'vowels', 'classic'], 6)
    ON CONFLICT (id) DO NOTHING;

    -- Insert exercises for Natural Speech
    INSERT INTO public.exercises (category_id, text, difficulty, focus, tags, display_order)
    VALUES
        (cat_natural_speech, 'The weather in Seattle was particularly pleasant last Wednesday evening.', 'medium', 'TH sound & vowel reduction', ARRAY['th-sound', 'vowel-reduction', 'weather'], 1),
        (cat_natural_speech, 'Could you please pass the salt and pepper when you get a chance?', 'easy', 'Polite requests & intonation', ARRAY['intonation', 'requests', 'everyday'], 2),
        (cat_natural_speech, 'I was wondering if you had a few minutes to chat about the project.', 'medium', 'Linking words & rhythm', ARRAY['linking', 'rhythm', 'casual'], 3),
        (cat_natural_speech, 'The restaurant around the corner has the most amazing pasta I have ever tasted.', 'medium', 'Stress patterns & enthusiasm', ARRAY['stress', 'enthusiasm', 'food'], 4),
        (cat_natural_speech, 'What are your plans for the weekend? I was thinking we could go hiking.', 'easy', 'Question intonation & suggestions', ARRAY['questions', 'intonation', 'plans'], 5)
    ON CONFLICT (id) DO NOTHING;

    -- Insert exercises for Professional
    INSERT INTO public.exercises (category_id, text, difficulty, focus, tags, display_order)
    VALUES
        (cat_professional, 'I would like to schedule a meeting for Thursday afternoon if that works for you.', 'easy', 'Intonation & linking words', ARRAY['meetings', 'scheduling', 'formal'], 1),
        (cat_professional, 'Thank you for your presentation. I have a few questions regarding the quarterly results.', 'medium', 'Formal register & clarity', ARRAY['presentations', 'questions', 'formal'], 2),
        (cat_professional, 'We need to align our strategy with the stakeholders before moving forward with implementation.', 'hard', 'Business vocabulary & fluency', ARRAY['strategy', 'business', 'vocabulary'], 3),
        (cat_professional, 'I appreciate your feedback and will incorporate your suggestions into the revised proposal.', 'medium', 'Professional courtesy & clarity', ARRAY['feedback', 'proposals', 'courtesy'], 4),
        (cat_professional, 'Could you please send me the report by end of business today? It is quite urgent.', 'easy', 'Urgency & polite requests', ARRAY['requests', 'urgency', 'email'], 5)
    ON CONFLICT (id) DO NOTHING;

    -- Insert exercises for Vowel Sounds
    INSERT INTO public.exercises (category_id, text, difficulty, focus, tags, display_order)
    VALUES
        (cat_vowel_sounds, 'The old oak tree stood alone on the open hill overlooking the ocean.', 'medium', 'Long O sound variations', ARRAY['long-o', 'vowels', 'nature'], 1),
        (cat_vowel_sounds, 'Each eager eagle eats eighteen eels eagerly every evening.', 'hard', 'Long E sound precision', ARRAY['long-e', 'vowels', 'alliteration'], 2),
        (cat_vowel_sounds, 'The big ship slipped through the thick mist at midnight.', 'medium', 'Short I vs long I distinction', ARRAY['short-i', 'long-i', 'contrast'], 3),
        (cat_vowel_sounds, 'A cat sat on a flat mat and had a nap after a snack.', 'easy', 'Short A sound consistency', ARRAY['short-a', 'vowels', 'simple'], 4),
        (cat_vowel_sounds, 'The blue moon bloomed beautifully above the smooth lagoon.', 'medium', 'OO vowel sound variations', ARRAY['oo-sound', 'vowels', 'poetry'], 5)
    ON CONFLICT (id) DO NOTHING;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Seed data insertion failed: %', SQLERRM;
END $$;
