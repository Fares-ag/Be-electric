-- ============================================================
-- Fix "permission denied for table users"
-- Run in Supabase Dashboard → SQL Editor
-- ============================================================

-- The authenticated role needs explicit GRANT on public.users.
-- This must be run as a superuser (postgres role) — the SQL Editor uses postgres by default.
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO anon;
GRANT SELECT ON public.admin_users TO authenticated;
GRANT SELECT ON public.admin_users TO anon;

-- Also grant on sequences if any (for INSERT with serial/bigserial ids)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
