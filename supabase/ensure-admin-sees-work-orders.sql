-- ============================================================
-- Run this in Supabase Dashboard → SQL Editor
-- Ensures admins see all work orders (including from Flutter requestor).
-- Fixes "permission denied for table users" when loading work orders list.
-- For Flutter sync: run migration 20260311140000_flutter_sync_rpcs.sql first
-- so get_user_by_email and upsert_work_order exist (or the GRANTs below will fail).
-- ============================================================

-- Step 0: Grant read on public.users so the work orders query can join requestor (users)
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO authenticated;
GRANT SELECT ON public.admin_users TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.work_orders TO authenticated;

-- Step 1: get_my_role() must check admin_users FIRST (so portal admins get role 'admin')
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
  SELECT COALESCE(
    (SELECT 'admin' WHERE EXISTS (
      SELECT 1 FROM public.admin_users a
      WHERE a.email = (SELECT email FROM auth.users WHERE id = auth.uid() LIMIT 1)
        AND (a.is_admin OR a.is_manager)
    )),
    (SELECT role::text FROM public.users WHERE id::text = auth.uid()::text LIMIT 1)
  );
$$;
GRANT EXECUTE ON FUNCTION public.get_my_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_by_email(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_by_email(text) TO anon;
GRANT EXECUTE ON FUNCTION public.upsert_work_order(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_work_order(jsonb) TO anon;

-- Step 2: Add your admin email here so they are treated as admin (edit and run again if needed)
DO $$
BEGIN
  INSERT INTO public.admin_users (email, is_admin, is_manager, updated_at)
  VALUES ('beelectric@q-auto.com', true, true, now());
EXCEPTION
  WHEN unique_violation THEN
    UPDATE public.admin_users SET is_admin = true, is_manager = true, updated_at = now() WHERE email = 'beelectric@q-auto.com';
END $$;

-- Step 3: Verify – run as yourself or check counts (uncomment and replace email)
-- SELECT (SELECT count(*) FROM public.work_orders) AS total_work_orders;
-- SELECT email, is_admin, is_manager FROM public.admin_users;
