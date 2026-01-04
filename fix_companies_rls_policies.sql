-- Fix Companies RLS Policies
-- Add INSERT, UPDATE, and DELETE policies for admins and managers
-- Uses SECURITY DEFINER functions to avoid RLS recursion issues

-- ============================================================================
-- STEP 1: Create helper function to check if user is admin/manager
-- ============================================================================
CREATE OR REPLACE FUNCTION is_admin_or_manager()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM users 
    WHERE id = auth.uid()::TEXT 
    AND role IN ('admin', 'manager')
  );
END;
$$;

-- ============================================================================
-- STEP 2: Add INSERT policy for companies (admins and managers only)
-- ============================================================================
DROP POLICY IF EXISTS "Admins and managers can create companies" ON companies;
CREATE POLICY "Admins and managers can create companies" ON companies
  FOR INSERT WITH CHECK (
    auth.role() = 'authenticated' AND
    is_admin_or_manager()
  );

-- ============================================================================
-- STEP 3: Add UPDATE policy for companies (admins and managers only)
-- ============================================================================
DROP POLICY IF EXISTS "Admins and managers can update companies" ON companies;
CREATE POLICY "Admins and managers can update companies" ON companies
  FOR UPDATE USING (
    auth.role() = 'authenticated' AND
    is_admin_or_manager()
  );

-- ============================================================================
-- STEP 4: Add DELETE policy for companies (admins and managers only)
-- ============================================================================
DROP POLICY IF EXISTS "Admins and managers can delete companies" ON companies;
CREATE POLICY "Admins and managers can delete companies" ON companies
  FOR DELETE USING (
    auth.role() = 'authenticated' AND
    is_admin_or_manager()
  );

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- Verify policies were created
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'companies'
ORDER BY policyname;

