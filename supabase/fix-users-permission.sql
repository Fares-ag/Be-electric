-- Run this in Supabase Dashboard → SQL Editor to fix "permission denied for table users".
-- Workaround: use an RPC that runs with definer rights so the app can load users without table GRANT.

-- 1. Ensure helper exists
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT role::text FROM public.users WHERE id::text = auth.uid()::text LIMIT 1),
    CASE WHEN EXISTS (
      SELECT 1 FROM public.admin_users a
      WHERE a.email = (SELECT email FROM auth.users WHERE id = auth.uid() LIMIT 1)
      AND (a.is_admin OR a.is_manager)
    ) THEN 'admin' ELSE NULL END
  );
$$;

-- 2. RPC: return users list for admins (bypasses table SELECT permission)
CREATE OR REPLACE FUNCTION public.get_users_list()
RETURNS SETOF public.users
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT * FROM public.users
  WHERE public.get_my_role() IN ('admin', 'manager')
  ORDER BY name;
$$;

-- 3. RPCs for insert/update/delete (work when table GRANT fails)
CREATE OR REPLACE FUNCTION public.insert_user(payload jsonb)
RETURNS public.users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_id uuid := coalesce((payload->>'id')::uuid, gen_random_uuid());
  row public.users;
BEGIN
  IF public.get_my_role() NOT IN ('admin', 'manager') THEN
    RAISE EXCEPTION 'permission denied';
  END IF;
  INSERT INTO public.users (id, email, name, role, "companyId", department, "isActive", "updatedAt")
  VALUES (
    new_id,
    payload->>'email',
    payload->>'name',
    coalesce(payload->>'role', 'requestor'),
    nullif(trim(payload->>'companyId'), '')::uuid,
    nullif(trim(payload->>'department'), ''),
    coalesce((payload->>'isActive')::boolean, true),
    now()
  )
  RETURNING * INTO row;
  RETURN row;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_user(user_id uuid, payload jsonb)
RETURNS public.users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  row public.users;
BEGIN
  IF public.get_my_role() NOT IN ('admin', 'manager') THEN
    RAISE EXCEPTION 'permission denied';
  END IF;
  UPDATE public.users SET
    name = coalesce(payload->>'name', name),
    role = coalesce(payload->>'role', role),
    "isActive" = coalesce((payload->>'isActive')::boolean, "isActive"),
    "companyId" = CASE WHEN payload ? 'companyId' THEN nullif(trim(payload->>'companyId'), '')::uuid ELSE "companyId" END,
    department = CASE WHEN payload ? 'department' THEN nullif(trim(payload->>'department'), '') ELSE department END,
    "updatedAt" = now()
  WHERE id = user_id
  RETURNING * INTO row;
  IF NOT FOUND THEN RAISE EXCEPTION 'user not found'; END IF;
  RETURN row;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_user(user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF public.get_my_role() NOT IN ('admin', 'manager') THEN
    RAISE EXCEPTION 'permission denied';
  END IF;
  DELETE FROM public.users WHERE id = user_id;
END;
$$;

-- Allow authenticated to execute the RPCs
GRANT EXECUTE ON FUNCTION public.get_users_list() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.insert_user(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_user(uuid, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_user(uuid) TO authenticated;

-- 4. Try granting table anyway (some projects need this for insert/update/delete)
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO anon;

-- 5. RLS for direct table access (if grant works for mutate)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can read own row" ON public.users;
CREATE POLICY "Users can read own row"
  ON public.users FOR SELECT TO authenticated
  USING (id::text = auth.uid()::text);
DROP POLICY IF EXISTS "Admins can read all users" ON public.users;
CREATE POLICY "Admins can read all users"
  ON public.users FOR SELECT TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));
DROP POLICY IF EXISTS "Admins can manage users" ON public.users;
DROP POLICY IF EXISTS "Admins can update users" ON public.users;
DROP POLICY IF EXISTS "Admins can delete users" ON public.users;
CREATE POLICY "Admins can manage users"
  ON public.users FOR INSERT TO authenticated
  WITH CHECK (public.get_my_role() IN ('admin', 'manager'));
CREATE POLICY "Admins can update users"
  ON public.users FOR UPDATE TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));
CREATE POLICY "Admins can delete users"
  ON public.users FOR DELETE TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));
