-- Fix RLS policy infinite recursion issue for users table
-- 
-- ERROR: infinite recursion detected in policy for relation "users"
--
-- The problem: The policy "Users can view users in their company" queries the 
-- users table to check companyId, which triggers the same policy again, causing 
-- infinite recursion.
--
-- Solution: Use SECURITY DEFINER functions to bypass RLS when checking the
-- current user's companyId and role.

-- ============================================================================
-- STEP 1: Drop ALL existing SELECT policies on users table
-- ============================================================================
DROP POLICY IF EXISTS "Users can view users in their company" ON users;
DROP POLICY IF EXISTS "Users can read their own record" ON users;
DROP POLICY IF EXISTS "Users can find themselves by email" ON users;

-- ============================================================================
-- STEP 2: Create SECURITY DEFINER functions to get current user info
-- ============================================================================
-- These functions run with superuser privileges, so they bypass RLS
-- This allows us to check the current user's companyId and role without recursion

-- Function to get current user's companyId
CREATE OR REPLACE FUNCTION get_current_user_company_id()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT "companyId"::TEXT
  FROM users
  WHERE id = auth.uid()::TEXT
  LIMIT 1;
$$;

-- Function to check if current user is admin or manager
CREATE OR REPLACE FUNCTION is_current_user_admin_or_manager()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 
    FROM users 
    WHERE id = auth.uid()::TEXT 
    AND role IN ('admin', 'manager')
  );
$$;

-- ============================================================================
-- STEP 3: Create policy to allow users to read their own record (NO RECURSION)
-- ============================================================================
-- This is the simplest policy and has NO subqueries
CREATE POLICY "Users can read their own record" ON users
  FOR SELECT USING (
    auth.role() = 'authenticated' AND
    id = auth.uid()::TEXT
  );

-- ============================================================================
-- STEP 4: Create policy to allow lookup by email for login (NO RECURSION)
-- ============================================================================
-- This allows users to find their own record by email during login
-- Uses auth.users table (NOT the users table) to avoid recursion
CREATE POLICY "Users can find themselves by email" ON users
  FOR SELECT USING (
    auth.role() = 'authenticated' AND
    -- Check against auth.users table (NOT the users table) to avoid recursion
    email = (SELECT email FROM auth.users WHERE id = auth.uid())
  );

-- ============================================================================
-- STEP 5: Create company-based policy using SECURITY DEFINER functions
-- ============================================================================
-- This policy uses the functions created above, which bypass RLS, avoiding recursion
CREATE POLICY "Users can view users in their company" ON users
  FOR SELECT USING (
    auth.role() = 'authenticated' AND
    (
      -- Allow if this is the user's own record (already covered by policy #3, but harmless)
      id = auth.uid()::TEXT
      OR
      -- Allow if companyId matches current user's companyId (using function to avoid recursion)
      "companyId" = get_current_user_company_id()
      OR
      -- Allow if current user is admin or manager (using function to avoid recursion)
      is_current_user_admin_or_manager()
    )
  );

-- ============================================================================
-- STEP 6: Verify the policies are in place
-- ============================================================================
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;

-- ============================================================================
-- STEP 7: Test the functions (optional - run while logged in as the user)
-- ============================================================================
-- SELECT get_current_user_company_id();
-- SELECT is_current_user_admin_or_manager();

-- ============================================================================
-- NOTES:
-- ============================================================================
-- The key fix is using SECURITY DEFINER functions. These functions run with
-- the privileges of the function creator (usually a superuser), so they can
-- read from the users table without triggering RLS policies. This breaks
-- the recursion cycle.
--
-- Policy evaluation order (PostgreSQL uses OR logic - if ANY policy allows, access is granted):
-- 1. "Users can read their own record" - allows reading own record by ID
-- 2. "Users can find themselves by email" - allows finding own record by email  
-- 3. "Users can view users in their company" - allows reading users in same company
--
-- The functions are marked as STABLE, which means they return the same result
-- for the same input within a single query execution, allowing PostgreSQL to
-- optimize them.
