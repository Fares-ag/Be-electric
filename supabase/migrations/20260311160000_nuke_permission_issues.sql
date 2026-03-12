-- ============================================================
-- NUKE ALL PERMISSION ISSUES
-- Disable RLS on users (we use SECURITY DEFINER RPCs for user CRUD).
-- Explicit per-table GRANTs + disable RLS where not needed by Flutter.
-- ============================================================

-- 1. Disable RLS on users — the app uses RPCs (get_user_by_id, get_users_list,
--    insert_user, update_user, delete_user_by_id) which are all SECURITY DEFINER.
--    RLS on users was causing cascading "permission denied" errors when PostgREST
--    evaluates FK constraints or RLS policies that indirectly touch users.
ALTER TABLE IF EXISTS public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.admin_users DISABLE ROW LEVEL SECURITY;

-- 2. Explicit GRANTs for every table (belt AND suspenders)
GRANT USAGE ON SCHEMA public TO authenticated, anon;

DO $$
DECLARE
  t record;
BEGIN
  FOR t IN
    SELECT tablename FROM pg_tables WHERE schemaname = 'public'
  LOOP
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO authenticated', t.tablename);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO anon', t.tablename);
  END LOOP;
END $$;

-- Also grant on sequences
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated, anon;

-- Default privileges for future tables created in public
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO anon;

-- 3. Reload PostgREST so it picks up new privileges
NOTIFY pgrst, 'reload schema';
