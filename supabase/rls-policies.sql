-- ============================================
-- Supabase RLS Policies for Be Electric CMMS
-- Run this in Supabase SQL Editor
-- ============================================

-- Ensure authenticated role can access tables (if not already granted)
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON users TO authenticated;
GRANT SELECT ON admin_users TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON work_orders TO authenticated;
GRANT SELECT ON assets TO authenticated;
GRANT SELECT ON companies TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON pm_tasks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON parts_requests TO authenticated;

-- Enable RLS on tables (if not already)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- admin_users: allow users to read only their own row (to check admin status)
CREATE OR REPLACE FUNCTION public.get_my_email()
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$ SELECT email FROM auth.users WHERE id = auth.uid() LIMIT 1; $$;

DROP POLICY IF EXISTS "Users can read own admin_users row" ON admin_users;
CREATE POLICY "Users can read own admin_users row"
  ON admin_users FOR SELECT
  TO authenticated
  USING (email = public.get_my_email());

-- ============================================
-- USERS TABLE
-- ============================================

-- Drop existing policies if they conflict
DROP POLICY IF EXISTS "Users can read own row" ON users;
DROP POLICY IF EXISTS "Allow read own user" ON users;

-- Allow authenticated users to read their own row (id = auth.uid())
-- Cast both to text to handle text/uuid column types
CREATE POLICY "Users can read own row"
  ON users FOR SELECT
  TO authenticated
  USING (id::text = auth.uid()::text);

-- To avoid recursion (policy reading users to check admin), use a SECURITY DEFINER function
-- to not depend on reading users. Alternative: use a database function:

-- Helper: get current user's role (SECURITY DEFINER = bypasses RLS).
-- Check admin_users FIRST so portal admins see all work orders (even if public.users has role 'requestor').
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
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

-- Admins/managers can read all users
DROP POLICY IF EXISTS "Admins can read all users" ON users;
CREATE POLICY "Admins can read all users"
  ON users FOR SELECT
  TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

-- ============================================
-- WORK_ORDERS TABLE
-- ============================================

DROP POLICY IF EXISTS "Requestors can read own work orders" ON work_orders;
DROP POLICY IF EXISTS "Admins can read all work orders" ON work_orders;
DROP POLICY IF EXISTS "Requestors can create work orders" ON work_orders;
DROP POLICY IF EXISTS "Admins can manage work orders" ON work_orders;

-- Requestors: read own (cast for text/uuid compatibility)
CREATE POLICY "Requestors can read own work orders"
  ON work_orders FOR SELECT
  TO authenticated
  USING ("requestorId"::text = auth.uid()::text);

-- Admins/managers: read all
CREATE POLICY "Admins can read all work orders"
  ON work_orders FOR SELECT
  TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

-- Technicians: read assigned (if assigned_technician_ids contains auth.uid())
-- Add if your schema has assigned_technician_ids as array
-- CREATE POLICY "Technicians can read assigned"
--   ON work_orders FOR SELECT TO authenticated
--   USING (auth.uid() = ANY(assigned_technician_ids));

-- Create: requestors, admins, managers
DROP POLICY IF EXISTS "Authenticated can create work orders" ON work_orders;
CREATE POLICY "Authenticated can create work orders"
  ON work_orders FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Update: admins/managers, assigned technicians, or requestor (own)
DROP POLICY IF EXISTS "Admins can update work orders" ON work_orders;
CREATE POLICY "Admins can update work orders"
  ON work_orders FOR UPDATE
  TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

DROP POLICY IF EXISTS "Technicians can update assigned work orders" ON work_orders;
CREATE POLICY "Technicians can update assigned work orders"
  ON work_orders FOR UPDATE
  TO authenticated
  USING (
    auth.uid()::text = ANY(COALESCE("assignedTechnicianIds", ARRAY[]::text[]))
  );

DROP POLICY IF EXISTS "Requestors can update own work orders" ON work_orders;
CREATE POLICY "Requestors can update own work orders"
  ON work_orders FOR UPDATE
  TO authenticated
  USING ("requestorId"::text = auth.uid()::text);

-- ============================================
-- ASSETS, COMPANIES (lookups for work orders)
-- ============================================
ALTER TABLE assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated can read assets" ON assets;
CREATE POLICY "Authenticated can read assets"
  ON assets FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Authenticated can read companies" ON companies;
CREATE POLICY "Authenticated can read companies"
  ON companies FOR SELECT TO authenticated USING (true);

-- ============================================
-- PM_TASKS
-- ============================================
ALTER TABLE pm_tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can read pm_tasks" ON pm_tasks;
CREATE POLICY "Admins can read pm_tasks"
  ON pm_tasks FOR SELECT TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

DROP POLICY IF EXISTS "Admins can manage pm_tasks" ON pm_tasks;
CREATE POLICY "Admins can manage pm_tasks"
  ON pm_tasks FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

DROP POLICY IF EXISTS "Technicians can read assigned pm_tasks" ON pm_tasks;
CREATE POLICY "Technicians can read assigned pm_tasks"
  ON pm_tasks FOR SELECT TO authenticated
  USING (
    auth.uid()::text = ANY(COALESCE("assignedTechnicianIds", ARRAY[]::text[]))
  );

-- ============================================
-- PARTS_REQUESTS
-- ============================================
ALTER TABLE parts_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can read parts_requests" ON parts_requests;
CREATE POLICY "Admins can read parts_requests"
  ON parts_requests FOR SELECT TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

DROP POLICY IF EXISTS "Admins can manage parts_requests" ON parts_requests;
CREATE POLICY "Admins can manage parts_requests"
  ON parts_requests FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

-- Technicians/requesters can read their own parts requests
DROP POLICY IF EXISTS "Users can read own parts_requests" ON parts_requests;
CREATE POLICY "Users can read own parts_requests"
  ON parts_requests FOR SELECT TO authenticated
  USING ("requestedBy"::text = auth.uid()::text);

DROP POLICY IF EXISTS "Users can insert own parts_requests" ON parts_requests;
CREATE POLICY "Users can insert own parts_requests"
  ON parts_requests FOR INSERT TO authenticated
  WITH CHECK ("requestedBy"::text = auth.uid()::text);

-- ============================================
-- TECHNICIANS: read assigned work orders
-- ============================================
DROP POLICY IF EXISTS "Technicians can read assigned work orders" ON work_orders;
CREATE POLICY "Technicians can read assigned work orders"
  ON work_orders FOR SELECT TO authenticated
  USING (
    auth.uid()::text = ANY(
      COALESCE("assignedTechnicianIds", ARRAY[]::text[])
    )
  );

-- ============================================
-- NOTE: Column names
-- ============================================
-- If work_orders uses snake_case in DB, replace "requestorId" with requestor_id
-- and "assignedTechnicianIds" with assigned_technician_ids.
