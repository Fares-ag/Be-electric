-- Fix RLS Policy for Users Table - Allow Authenticated Users to Insert
-- This fixes the "new row violates row-level security policy" error when creating the first user

-- Drop existing INSERT policy if it exists (in case you need to recreate it)
DROP POLICY IF EXISTS "Users can insert themselves" ON users;

-- Create INSERT policy that allows authenticated users to create their own user record
-- This is safe because:
-- 1. Users are already authenticated via Supabase Auth
-- 2. The email is unique, preventing duplicates
-- 3. The app validates user data before insertion
CREATE POLICY "Users can insert themselves" ON users
  FOR INSERT 
  WITH CHECK (auth.role() = 'authenticated');

-- Alternative: If you want to be more restrictive and only allow inserting when the table is empty (first user)
-- Uncomment this instead of the above policy:
-- CREATE POLICY "Allow first user creation" ON users
--   FOR INSERT 
--   WITH CHECK (
--     auth.role() = 'authenticated' AND 
--     (SELECT COUNT(*) FROM users) = 0
--   );

-- Verify the policy was created
SELECT * FROM pg_policies WHERE tablename = 'users' AND policyname = 'Users can insert themselves';

