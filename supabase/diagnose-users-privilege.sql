-- Run this in Supabase Dashboard → SQL Editor to diagnose "permission denied for table users".
-- It shows: who owns the table, who has grants, and what role you're connected as.

-- 1. Who are you connected as?
SELECT current_user AS connected_as;

-- 2. Who owns public.users?
SELECT schemaname, tablename, tableowner
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'users';

-- 3. What grants exist on public.users?
SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public' AND table_name = 'users'
ORDER BY grantee, privilege_type;

-- 4. If the list is empty or "authenticated" is missing, run the fix below as the table owner or superuser.
