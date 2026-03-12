-- ============================================================
-- SECURITY DEFINER functions for public.users
-- These bypass all GRANT / RLS issues by running as postgres (owner).
-- ============================================================

-- Read one user by id (used by auth-store on login)
CREATE OR REPLACE FUNCTION public.get_user_by_id(p_id text)
RETURNS SETOF public.users
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
  SELECT * FROM public.users WHERE id = p_id LIMIT 1;
$$;

-- Read all users (used by admin Users page)
CREATE OR REPLACE FUNCTION public.get_users_list()
RETURNS SETOF public.users
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
  SELECT * FROM public.users ORDER BY name;
$$;

-- Insert a new user profile
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
LANGUAGE sql SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
  INSERT INTO public.users
    (id, email, name, role, "isActive", "companyId", department, "updatedAt")
  VALUES
    (p_id, p_email, p_name, p_role, p_is_active, p_company_id, p_department, now())
  ON CONFLICT (id) DO NOTHING;
$$;

-- Update an existing user profile
CREATE OR REPLACE FUNCTION public.update_user(
  p_id         text,
  p_name       text,
  p_role       text,
  p_is_active  boolean,
  p_company_id text,
  p_department text
)
RETURNS void
LANGUAGE sql SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
  UPDATE public.users SET
    name        = p_name,
    role        = p_role,
    "isActive"  = p_is_active,
    "companyId" = p_company_id,
    department  = p_department,
    "updatedAt" = now()
  WHERE id = p_id;
$$;

-- Delete a user profile
CREATE OR REPLACE FUNCTION public.delete_user_by_id(p_id text)
RETURNS void
LANGUAGE sql SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
  DELETE FROM public.users WHERE id = p_id;
$$;

-- Grant execute to authenticated users (admins call these from the browser)
GRANT EXECUTE ON FUNCTION public.get_user_by_id(text)      TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_users_list()           TO authenticated;
GRANT EXECUTE ON FUNCTION public.insert_user(text,text,text,text,boolean,text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_user(text,text,text,boolean,text,text)      TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_user_by_id(text)    TO authenticated;

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
