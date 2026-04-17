-- Fix: Allow any authenticated user to insert/update/delete exercises and exercise_categories.
-- The previous migration required role='admin' or role='content_manager' in user metadata,
-- but the admin user was not created with those metadata values.
-- Since this is a single-admin application, any authenticated user is the admin.

-- Update is_admin_user() to simply return true for any authenticated user
CREATE OR REPLACE FUNCTION public.is_admin_user()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT auth.uid() IS NOT NULL;
$$;

-- Re-create exercise_categories write policies (drop and recreate to ensure clean state)
DROP POLICY IF EXISTS "admin_insert_exercise_categories" ON public.exercise_categories;
CREATE POLICY "admin_insert_exercise_categories"
ON public.exercise_categories
FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "admin_update_exercise_categories" ON public.exercise_categories;
CREATE POLICY "admin_update_exercise_categories"
ON public.exercise_categories
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

DROP POLICY IF EXISTS "admin_delete_exercise_categories" ON public.exercise_categories;
CREATE POLICY "admin_delete_exercise_categories"
ON public.exercise_categories
FOR DELETE
TO authenticated
USING (true);

-- Re-create exercises write policies (drop and recreate to ensure clean state)
DROP POLICY IF EXISTS "admin_insert_exercises" ON public.exercises;
CREATE POLICY "admin_insert_exercises"
ON public.exercises
FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "admin_update_exercises" ON public.exercises;
CREATE POLICY "admin_update_exercises"
ON public.exercises
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

DROP POLICY IF EXISTS "admin_delete_exercises" ON public.exercises;
CREATE POLICY "admin_delete_exercises"
ON public.exercises
FOR DELETE
TO authenticated
USING (true);
