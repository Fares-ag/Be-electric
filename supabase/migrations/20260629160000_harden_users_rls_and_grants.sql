-- Production hardening pass: users/admin_users RLS, scoped RPC auth, revoke anon table access,
-- tighten inventory/parts/PO policies, fix work_orders INSERT spoofing.

-- ═══ 1. Revoke direct anon access to public tables (RPCs + RLS enforce access) ═══
DO $$
DECLARE
  t record;
BEGIN
  FOR t IN SELECT tablename FROM pg_tables WHERE schemaname = 'public'
  LOOP
    EXECUTE format('REVOKE ALL ON public.%I FROM anon', t.tablename);
  END LOOP;
END $$;

REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon;

ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON SEQUENCES FROM anon;

GRANT USAGE ON SCHEMA public TO authenticated;

-- ═══ 2. Re-enable RLS on users + admin_users ═══
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE pol record;
BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'users'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.users', pol.policyname); END LOOP;
  FOR pol IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'admin_users'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.admin_users', pol.policyname); END LOOP;
END $$;

CREATE POLICY "Users read own profile"
  ON public.users FOR SELECT TO authenticated
  USING (id = auth.uid()::text);

CREATE POLICY "Admins manage users"
  ON public.users FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'))
  WITH CHECK (public.get_my_role() IN ('admin', 'manager'));

CREATE POLICY "Users read own admin_users row"
  ON public.admin_users FOR SELECT TO authenticated
  USING (
    email = (SELECT au.email FROM auth.users au WHERE au.id = auth.uid() LIMIT 1)
  );

CREATE POLICY "Admins manage admin_users"
  ON public.admin_users FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'))
  WITH CHECK (public.get_my_role() IN ('admin', 'manager'));

GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.admin_users TO authenticated;

-- ═══ 3. Harden user/admin RPCs (authenticated only; scoped by role/self) ═══

CREATE OR REPLACE FUNCTION public.get_user_by_id(p_id text)
RETURNS SETOF public.users
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF public.get_my_role() IN ('admin', 'manager') OR p_id = auth.uid()::text THEN
    RETURN QUERY SELECT * FROM public.users WHERE id = p_id LIMIT 1;
  ELSE
    RAISE EXCEPTION 'Forbidden';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_user_by_email(p_email text)
RETURNS SETOF public.users
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF public.get_my_role() IN ('admin', 'manager')
    OR lower(trim(p_email)) = lower(coalesce(public.get_my_email(), ''))
  THEN
    RETURN QUERY
    SELECT * FROM public.users
    WHERE lower(email) = lower(trim(p_email))
    LIMIT 1;
  ELSE
    RAISE EXCEPTION 'Forbidden';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_users_list()
RETURNS SETOF public.users
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
BEGIN
  IF public.get_my_role() NOT IN ('admin', 'manager') THEN
    RAISE EXCEPTION 'Forbidden: admin or manager role required';
  END IF;
  RETURN QUERY SELECT * FROM public.users ORDER BY name;
END;
$$;

CREATE OR REPLACE FUNCTION public.insert_user(
  p_id        text,
  p_email     text,
  p_name      text,
  p_role      text,
  p_is_active boolean,
  p_company_id text,
  p_department text
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF public.get_my_role() IN ('admin', 'manager') THEN
    NULL;
  ELSIF p_id = auth.uid()::text THEN
    IF p_role NOT IN ('requestor', 'technician') THEN
      RAISE EXCEPTION 'Forbidden role for self-registration';
    END IF;
  ELSE
    RAISE EXCEPTION 'Forbidden';
  END IF;

  INSERT INTO public.users
    (id, email, name, role, "isActive", "companyId", department, "updatedAt")
  VALUES
    (p_id, p_email, p_name, p_role, p_is_active, p_company_id, p_department, now())
  ON CONFLICT (id) DO NOTHING;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_user(
  p_id         text,
  p_name       text,
  p_role       text,
  p_is_active  boolean,
  p_company_id text,
  p_department text
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF public.get_my_role() NOT IN ('admin', 'manager') THEN
    RAISE EXCEPTION 'Forbidden: admin or manager role required';
  END IF;

  UPDATE public.users SET
    name        = p_name,
    role        = p_role,
    "isActive"  = p_is_active,
    "companyId" = p_company_id,
    department  = p_department,
    "updatedAt" = now()
  WHERE id = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_user_by_id(p_id text)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF public.get_my_role() NOT IN ('admin', 'manager') THEN
    RAISE EXCEPTION 'Forbidden: admin or manager role required';
  END IF;
  DELETE FROM public.users WHERE id = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_admin_by_email(p_email text)
RETURNS TABLE(is_admin boolean, is_manager boolean)
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF public.get_my_role() IN ('admin', 'manager')
    OR lower(trim(p_email)) = lower(coalesce(public.get_my_email(), ''))
  THEN
    RETURN QUERY
    SELECT a.is_admin, a.is_manager
    FROM public.admin_users a
    WHERE lower(a.email) = lower(trim(p_email))
    LIMIT 1;
  ELSE
    RAISE EXCEPTION 'Forbidden';
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_user_by_id(text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_user_by_email(text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_users_list() FROM anon;
REVOKE EXECUTE ON FUNCTION public.insert_user(text,text,text,text,boolean,text,text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.update_user(text,text,text,boolean,text,text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.delete_user_by_id(text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_admin_by_email(text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_my_role() FROM anon;

GRANT EXECUTE ON FUNCTION public.get_user_by_id(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_by_email(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_users_list() TO authenticated;
GRANT EXECUTE ON FUNCTION public.insert_user(text,text,text,text,boolean,text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_user(text,text,text,boolean,text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_user_by_id(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_by_email(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_role() TO authenticated;

-- ═══ 4. work_orders: prevent requestorId spoof on INSERT ═══
DROP POLICY IF EXISTS "Authenticated can create work orders" ON public.work_orders;
DROP POLICY IF EXISTS "Authenticated users can create work orders" ON public.work_orders;

CREATE POLICY "Authenticated can create own work orders"
  ON public.work_orders FOR INSERT TO authenticated
  WITH CHECK (
    public.get_my_role() IN ('admin', 'manager')
    OR "requestorId"::text = auth.uid()::text
  );

-- ═══ 5. inventory / parts / purchase orders: role-scoped reads ═══

DO $$
DECLARE pol record;
BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'inventory_items'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.inventory_items', pol.policyname); END LOOP;
  FOR pol IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'parts_requests'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.parts_requests', pol.policyname); END LOOP;
  FOR pol IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'purchase_orders'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.purchase_orders', pol.policyname); END LOOP;
END $$;

CREATE POLICY "Admins manage inventory"
  ON public.inventory_items FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'))
  WITH CHECK (public.get_my_role() IN ('admin', 'manager'));

CREATE POLICY "Admins manage parts_requests"
  ON public.parts_requests FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'))
  WITH CHECK (public.get_my_role() IN ('admin', 'manager'));

CREATE POLICY "Users read own parts_requests"
  ON public.parts_requests FOR SELECT TO authenticated
  USING ("requestedBy"::text = auth.uid()::text);

CREATE POLICY "Users insert own parts_requests"
  ON public.parts_requests FOR INSERT TO authenticated
  WITH CHECK ("requestedBy"::text = auth.uid()::text);

CREATE POLICY "Admins manage purchase_orders"
  ON public.purchase_orders FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'))
  WITH CHECK (public.get_my_role() IN ('admin', 'manager'));

NOTIFY pgrst, 'reload schema';
