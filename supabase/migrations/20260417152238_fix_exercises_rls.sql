-- Fix RLS policies for exercises and exercise_categories
-- The previous policies queried auth.users directly inside the policy USING clause,
-- which causes "permission denied for table users" errors because the anon/authenticated
-- role does not have SELECT access to auth.users.
-- Fix: Use a SECURITY DEFINER function to safely check admin role from auth metadata.

-- 1. Create a SECURITY DEFINER function to check admin role
--    This runs with elevated privileges so it can query auth.users safely.
CREATE OR REPLACE FUNCTION public.is_admin_user()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND (
      raw_user_meta_data->>'role' = 'admin'
      OR raw_app_meta_data->>'role' = 'admin'
      OR raw_user_meta_data->>'role' = 'content_manager'
      OR raw_app_meta_data->>'role' = 'content_manager'
    )
  );
$$;

-- 2. Fix exercise_categories RLS policies

-- Drop old broken policies
DROP POLICY IF EXISTS "admin_manage_exercise_categories" ON public.exercise_categories;
DROP POLICY IF EXISTS "public_read_exercise_categories" ON public.exercise_categories;

-- Allow public (unauthenticated) to read active categories
CREATE POLICY "public_read_exercise_categories"
ON public.exercise_categories
FOR SELECT
TO public
USING (is_active = true);

-- Allow all authenticated users to read ALL categories (including inactive, for admin panel)
DROP POLICY IF EXISTS "authenticated_read_all_exercise_categories" ON public.exercise_categories;
CREATE POLICY "authenticated_read_all_exercise_categories"
ON public.exercise_categories
FOR SELECT
TO authenticated
USING (true);

-- Allow admin/content_manager to insert/update/delete categories
DROP POLICY IF EXISTS "admin_insert_exercise_categories" ON public.exercise_categories;
CREATE POLICY "admin_insert_exercise_categories"
ON public.exercise_categories
FOR INSERT
TO authenticated
WITH CHECK (public.is_admin_user());

DROP POLICY IF EXISTS "admin_update_exercise_categories" ON public.exercise_categories;
CREATE POLICY "admin_update_exercise_categories"
ON public.exercise_categories
FOR UPDATE
TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

DROP POLICY IF EXISTS "admin_delete_exercise_categories" ON public.exercise_categories;
CREATE POLICY "admin_delete_exercise_categories"
ON public.exercise_categories
FOR DELETE
TO authenticated
USING (public.is_admin_user());

-- 3. Fix exercises RLS policies

-- Drop old broken policies
DROP POLICY IF EXISTS "admin_manage_exercises" ON public.exercises;
DROP POLICY IF EXISTS "public_read_exercises" ON public.exercises;

-- Allow public (unauthenticated) to read active exercises
CREATE POLICY "public_read_exercises"
ON public.exercises
FOR SELECT
TO public
USING (is_active = true);

-- Allow all authenticated users to read ALL exercises (including inactive, for admin panel)
DROP POLICY IF EXISTS "authenticated_read_all_exercises" ON public.exercises;
CREATE POLICY "authenticated_read_all_exercises"
ON public.exercises
FOR SELECT
TO authenticated
USING (true);

-- Allow admin/content_manager to insert/update/delete exercises
DROP POLICY IF EXISTS "admin_insert_exercises" ON public.exercises;
CREATE POLICY "admin_insert_exercises"
ON public.exercises
FOR INSERT
TO authenticated
WITH CHECK (public.is_admin_user());

DROP POLICY IF EXISTS "admin_update_exercises" ON public.exercises;
CREATE POLICY "admin_update_exercises"
ON public.exercises
FOR UPDATE
TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

DROP POLICY IF EXISTS "admin_delete_exercises" ON public.exercises;
CREATE POLICY "admin_delete_exercises"
ON public.exercises
FOR DELETE
TO authenticated
USING (public.is_admin_user());
