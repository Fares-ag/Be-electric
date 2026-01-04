-- Fix Companies RLS Policies
-- Add INSERT, UPDATE, and DELETE policies for admins and managers

-- ============================================================================
-- STEP 1: Add INSERT policy for companies (admins and managers only)
-- ============================================================================
DROP POLICY IF EXISTS "Admins and managers can create companies" ON companies;
CREATE POLICY "Admins and managers can create companies" ON companies
  FOR INSERT WITH CHECK (
    auth.role() = 'authenticated' AND
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::TEXT AND role IN ('admin', 'manager'))
  );

-- ============================================================================
-- STEP 2: Add UPDATE policy for companies (admins and managers only)
-- ============================================================================
DROP POLICY IF EXISTS "Admins and managers can update companies" ON companies;
CREATE POLICY "Admins and managers can update companies" ON companies
  FOR UPDATE USING (
    auth.role() = 'authenticated' AND
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::TEXT AND role IN ('admin', 'manager'))
  );

-- ============================================================================
-- STEP 3: Add DELETE policy for companies (admins and managers only)
-- ============================================================================
DROP POLICY IF EXISTS "Admins and managers can delete companies" ON companies;
CREATE POLICY "Admins and managers can delete companies" ON companies
  FOR DELETE USING (
    auth.role() = 'authenticated' AND
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::TEXT AND role IN ('admin', 'manager'))
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

