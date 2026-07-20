-- BE-QA-001/002/003/014: inactive users lose role; only true admins mint admin;
-- company-scope assets/companies for requestors; tighten files INSERT paths.
-- Idempotent. Do NOT apply to production without explicit approval.

-- ═══ 1. get_my_role honors isActive ═══
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
  SELECT CASE
    WHEN EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()::text
        AND COALESCE(u."isActive", true) = false
    ) THEN NULL
    ELSE COALESCE(
      (SELECT 'admin' WHERE EXISTS (
        SELECT 1 FROM public.admin_users a
        WHERE a.email = (SELECT email FROM auth.users WHERE id = auth.uid() LIMIT 1)
          AND (a.is_admin OR a.is_manager)
      )),
      (SELECT role::text FROM public.users WHERE id = auth.uid()::text LIMIT 1)
    )
  END;
$$;

-- ═══ 2. Helper: caller is true admin (admin_users.is_admin) ═══
CREATE OR REPLACE FUNCTION public.is_true_admin()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.admin_users a
    WHERE a.email = (SELECT email FROM auth.users WHERE id = auth.uid() LIMIT 1)
      AND a.is_admin = true
  );
$$;

REVOKE ALL ON FUNCTION public.is_true_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_true_admin() TO authenticated;

-- ═══ 3. insert_user / update_user: only true admin may set role=admin ═══
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

  IF public.get_my_role() IS NULL THEN
    RAISE EXCEPTION 'Forbidden: account inactive';
  END IF;

  IF p_role = 'admin' AND NOT public.is_true_admin() THEN
    RAISE EXCEPTION 'Forbidden: only admins can assign the admin role';
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
  IF public.get_my_role() IS NULL THEN
    RAISE EXCEPTION 'Forbidden: account inactive';
  END IF;
  IF public.get_my_role() NOT IN ('admin', 'manager') THEN
    RAISE EXCEPTION 'Forbidden: admin or manager role required';
  END IF;
  IF p_role = 'admin' AND NOT public.is_true_admin() THEN
    RAISE EXCEPTION 'Forbidden: only admins can assign the admin role';
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

-- ═══ 4. Assets / companies: close requestor cross-tenant SELECT ═══
DO $$
DECLARE
  pol record;
BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'assets'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.assets', pol.policyname); END LOOP;

  FOR pol IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'companies'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.companies', pol.policyname); END LOOP;
END $$;

CREATE POLICY "Staff read all assets"
  ON public.assets FOR SELECT TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager', 'technician'));

CREATE POLICY "Requestors read company assets"
  ON public.assets FOR SELECT TO authenticated
  USING (
    public.get_my_role() = 'requestor'
    AND "companyId" IS NOT NULL
    AND "companyId" = (
      SELECT u."companyId" FROM public.users u WHERE u.id = auth.uid()::text LIMIT 1
    )
  );

CREATE POLICY "Admins manage assets"
  ON public.assets FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'))
  WITH CHECK (public.get_my_role() IN ('admin', 'manager'));

CREATE POLICY "Staff read all companies"
  ON public.companies FOR SELECT TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager', 'technician'));

CREATE POLICY "Requestors read own company"
  ON public.companies FOR SELECT TO authenticated
  USING (
    public.get_my_role() = 'requestor'
    AND id = (
      SELECT u."companyId" FROM public.users u WHERE u.id = auth.uid()::text LIMIT 1
    )
  );

CREATE POLICY "Admins manage companies"
  ON public.companies FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'))
  WITH CHECK (public.get_my_role() IN ('admin', 'manager'));

-- ═══ 5. Storage files: path-prefixed INSERT ═══
DROP POLICY IF EXISTS "Authenticated can upload files" ON storage.objects;
CREATE POLICY "Authenticated can upload files"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'files'
    AND (
      name LIKE 'work_orders/%'
      OR name LIKE 'work-orders/%'
      OR name LIKE 'pm_tasks/%'
      OR name LIKE 'pm_occurrences/%'
      OR name LIKE 'pm_schedules/%'
      OR name LIKE 'support_requests/%'
      OR name LIKE 'inventory/%'
      OR name LIKE 'parts_requests/%'
    )
  );

NOTIFY pgrst, 'reload schema';
