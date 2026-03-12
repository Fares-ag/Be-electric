-- ============================================================
-- ONCE AND FOR ALL FIX
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================

-- ── 1. Fix get_my_role() – check admin_users FIRST so portal admins see all work orders.
--       (If public.users.role is checked first, admins synced with role 'requestor' get wrong role.)
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

CREATE OR REPLACE FUNCTION public.get_my_email()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
  SELECT email FROM auth.users WHERE id = auth.uid() LIMIT 1;
$$;

-- ── 2. Ensure all necessary GRANTs
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.users            TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users            TO anon;
GRANT SELECT                         ON public.admin_users      TO authenticated;
GRANT SELECT                         ON public.admin_users      TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.work_orders      TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.pm_tasks         TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.parts_requests   TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.companies        TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.assets           TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.inventory_items  TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.purchase_orders  TO authenticated;
GRANT SELECT, INSERT, UPDATE         ON public.notifications    TO authenticated;

GRANT EXECUTE ON FUNCTION public.get_my_role()  TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_role()  TO anon;
GRANT EXECUTE ON FUNCTION public.get_my_email() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_email() TO anon;

-- ── 3. Sync existing auth.users → public.users
--       This inserts a profile row for every Supabase Auth user that doesn't
--       already have one. Skips duplicates (ON CONFLICT DO NOTHING).
INSERT INTO public.users (id, email, name, role, "isActive", "createdAt", "updatedAt")
SELECT
  au.id,
  au.email,
  COALESCE(
    au.raw_user_meta_data->>'name',
    split_part(au.email, '@', 1)
  ) AS name,
  COALESCE(
    au.raw_user_meta_data->>'role',
    'requestor'
  ) AS role,
  true AS "isActive",
  au.created_at AS "createdAt",
  now()         AS "updatedAt"
FROM auth.users au
WHERE au.email IS NOT NULL
ON CONFLICT (id) DO NOTHING;

-- ── 4. Auto-create profile for future sign-ups via a trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role, "isActive", "createdAt", "updatedAt")
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'requestor'),
    true,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ── 5. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
