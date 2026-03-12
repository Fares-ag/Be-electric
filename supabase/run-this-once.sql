-- ============================================================
-- RUN THIS ONCE in Supabase Dashboard → SQL Editor
-- Fixes 403 on work_orders and all related permission issues.
-- ============================================================

-- ── 1. Grants so authenticated role can access all tables
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.users            TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users            TO anon;
GRANT SELECT                         ON public.admin_users      TO authenticated;
GRANT SELECT                         ON public.admin_users      TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.work_orders      TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.work_orders      TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.pm_tasks         TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.parts_requests   TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.companies        TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.assets           TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.inventory_items  TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.purchase_orders  TO authenticated;
GRANT SELECT, INSERT, UPDATE         ON public.notifications    TO authenticated;

-- ── 2. get_my_role() – check admin_users FIRST so portal admins are not
--       blocked by a 'requestor' role in public.users (from auth sync).
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

-- ── 2b. assigned_ids_as_text – avoids "operator does not exist: text = uuid" when column is uuid[]
CREATE OR REPLACE FUNCTION public.assigned_ids_as_text(ids uuid[])
RETURNS text[]
LANGUAGE sql STABLE PARALLEL SAFE
AS $$
  SELECT COALESCE(
    (SELECT array_agg(t::text) FROM unnest(COALESCE(ids, ARRAY[]::uuid[])) AS t),
    ARRAY[]::text[]
  );
$$;
CREATE OR REPLACE FUNCTION public.assigned_ids_as_text(ids text[])
RETURNS text[]
LANGUAGE sql STABLE PARALLEL SAFE
AS $$
  SELECT COALESCE(ids, ARRAY[]::text[]);
$$;

-- ── 3. Seed admin users
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

-- ── 4. RLS policies for work_orders (drop all, then recreate cleanly)
ALTER TABLE public.work_orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Requestors can read own work orders"           ON public.work_orders;
DROP POLICY IF EXISTS "Admins can read all work orders"               ON public.work_orders;
DROP POLICY IF EXISTS "Technicians can read assigned work orders"     ON public.work_orders;
DROP POLICY IF EXISTS "Authenticated can create work orders"          ON public.work_orders;
DROP POLICY IF EXISTS "Admins can update work orders"                 ON public.work_orders;
DROP POLICY IF EXISTS "Technicians can update assigned work orders"   ON public.work_orders;
DROP POLICY IF EXISTS "Requestors can update own work orders"         ON public.work_orders;
DROP POLICY IF EXISTS "Admins can manage work orders"                 ON public.work_orders;
DROP POLICY IF EXISTS "Requestors can create work orders"             ON public.work_orders;
DROP POLICY IF EXISTS "work_orders_select_policy"                     ON public.work_orders;

-- SELECT
CREATE POLICY "Admins can read all work orders"
  ON public.work_orders FOR SELECT TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

CREATE POLICY "Requestors can read own work orders"
  ON public.work_orders FOR SELECT TO authenticated
  USING ("requestorId"::text = auth.uid()::text);

CREATE POLICY "Technicians can read assigned work orders"
  ON public.work_orders FOR SELECT TO authenticated
  USING (auth.uid()::text = ANY(public.assigned_ids_as_text("assignedTechnicianIds")));

-- INSERT
CREATE POLICY "Authenticated can create work orders"
  ON public.work_orders FOR INSERT TO authenticated
  WITH CHECK (true);

-- UPDATE
CREATE POLICY "Admins can update work orders"
  ON public.work_orders FOR UPDATE TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

CREATE POLICY "Technicians can update assigned work orders"
  ON public.work_orders FOR UPDATE TO authenticated
  USING (auth.uid()::text = ANY(public.assigned_ids_as_text("assignedTechnicianIds")));

CREATE POLICY "Requestors can update own work orders"
  ON public.work_orders FOR UPDATE TO authenticated
  USING ("requestorId"::text = auth.uid()::text);

-- ── 5. RLS for public.users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own row"      ON public.users;
DROP POLICY IF EXISTS "Admins can read all users"   ON public.users;
DROP POLICY IF EXISTS "Admins can manage users"     ON public.users;
DROP POLICY IF EXISTS "Admins can update users"     ON public.users;
DROP POLICY IF EXISTS "Admins can delete users"     ON public.users;

CREATE POLICY "Users can read own row"
  ON public.users FOR SELECT TO authenticated
  USING (id::text = auth.uid()::text);

CREATE POLICY "Admins can read all users"
  ON public.users FOR SELECT TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

CREATE POLICY "Admins can manage users"
  ON public.users FOR INSERT TO authenticated
  WITH CHECK (public.get_my_role() IN ('admin', 'manager'));

CREATE POLICY "Admins can update users"
  ON public.users FOR UPDATE TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

CREATE POLICY "Admins can delete users"
  ON public.users FOR DELETE TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

-- ── 6. Verify (uncomment to check)
-- SELECT public.get_my_role();
-- SELECT count(*) FROM public.work_orders;
-- SELECT email, is_admin, is_manager FROM public.admin_users;

NOTIFY pgrst, 'reload schema';
