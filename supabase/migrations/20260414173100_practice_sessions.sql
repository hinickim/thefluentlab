-- Practice Sessions Module
-- Stores past practice sessions with transcripts, scores, and progress data

-- 1. Core Tables
CREATE TABLE IF NOT EXISTS public.practice_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    overall_score INTEGER NOT NULL DEFAULT 0,
    sentences_practiced INTEGER NOT NULL DEFAULT 0,
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    category TEXT NOT NULL DEFAULT 'mixed',
    difficulty TEXT NOT NULL DEFAULT 'medium',
    streak_earned BOOLEAN NOT NULL DEFAULT false,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.session_sentences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES public.practice_sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    sentence_text TEXT NOT NULL,
    transcript TEXT,
    score INTEGER NOT NULL DEFAULT 0,
    pronunciation_score INTEGER,
    fluency_score INTEGER,
    accuracy_score INTEGER,
    feedback TEXT,
    category TEXT,
    difficulty TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. Indexes
CREATE INDEX IF NOT EXISTS idx_practice_sessions_user_id ON public.practice_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_practice_sessions_created_at ON public.practice_sessions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_session_sentences_session_id ON public.session_sentences(session_id);
CREATE INDEX IF NOT EXISTS idx_session_sentences_user_id ON public.session_sentences(user_id);

-- 3. Enable RLS
ALTER TABLE public.practice_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_sentences ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
DROP POLICY IF EXISTS "users_manage_own_practice_sessions" ON public.practice_sessions;
CREATE POLICY "users_manage_own_practice_sessions"
ON public.practice_sessions
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_session_sentences" ON public.session_sentences;
CREATE POLICY "users_manage_own_session_sentences"
ON public.session_sentences
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
