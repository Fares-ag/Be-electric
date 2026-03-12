-- ============================================================
-- Fix permissions once and for all (users, admin_users, work_orders, etc.)
-- 1. get_admin_by_email RPC – bypass admin_users table access
-- 2. GRANT ALL on every table in public
-- 3. get_my_role() for RLS
-- 4. Seed admin users
-- ============================================================

-- RPC: Check if email is admin/manager (bypasses table GRANT/RLS)
CREATE OR REPLACE FUNCTION public.get_admin_by_email(p_email text)
RETURNS TABLE(is_admin boolean, is_manager boolean)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
  SELECT a.is_admin, a.is_manager
  FROM public.admin_users a
  WHERE a.email = p_email
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.get_admin_by_email(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_by_email(text) TO anon;

-- Grant on ALL tables (covers users, admin_users, work_orders, pm_tasks, assets, etc.)
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;

GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon;

GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon;

-- get_my_role() – check admin_users FIRST (for RLS policies)
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
GRANT EXECUTE ON FUNCTION public.get_my_role() TO anon;

-- Seed admin users
DO $$
DECLARE
  v_emails text[] := ARRAY['beelectric@q-auto.com', 'fares@q-auto.com'];
  v_email  text;
BEGIN
  FOREACH v_email IN ARRAY v_emails LOOP
    BEGIN
      INSERT INTO public.admin_users (email, is_admin, is_manager, updated_at)
      VALUES (v_email, true, true, now());
    EXCEPTION
      WHEN unique_violation THEN
        UPDATE public.admin_users
        SET is_admin = true, is_manager = true, updated_at = now()
        WHERE email = v_email;
    END;
  END LOOP;
END $$;

NOTIFY pgrst, 'reload schema';
