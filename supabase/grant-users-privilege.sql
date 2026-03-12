-- Fix "permission denied for table users" by granting privilege to the roles Supabase uses.
-- Run this in Supabase Dashboard → SQL Editor (you are usually connected as a superuser there).

-- Use the role that OWNS the table, or postgres/supabase_admin. If you get "must be owner"
-- when running this, the Dashboard role cannot grant; then use the RPC workaround (fix-users-permission.sql) instead.

-- Grant schema usage (required to see tables in the schema)
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;

-- Grant full table privilege so the role can SELECT/INSERT/UPDATE/DELETE (RLS will still filter rows)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO anon;

-- Optional: if your project uses a role like "service_role" for server-side calls
-- GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO service_role;

-- Verify (run after the above – you should see authenticated and anon with privileges)
-- SELECT grantee, privilege_type FROM information_schema.role_table_grants
-- WHERE table_schema = 'public' AND table_name = 'users';
