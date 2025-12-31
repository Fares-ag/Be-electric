-- Verify and troubleshoot user login for zmohammed@q-auto.com
-- Run this in Supabase SQL Editor to diagnose login issues

-- ============================================================================
-- STEP 1: Check if user exists in users table
-- ============================================================================
SELECT 
  'Users Table' as source,
  id,
  email,
  name,
  role,
  "companyId",
  "isActive",
  "createdAt"
FROM users 
WHERE email = 'zmohammed@q-auto.com';

-- ============================================================================
-- STEP 2: Check if user exists in Supabase Auth
-- ============================================================================
SELECT 
  'Auth Users' as source,
  id,
  email,
  confirmed_at,
  encrypted_password IS NOT NULL as has_password,
  created_at,
  last_sign_in_at
FROM auth.users 
WHERE email = 'zmohammed@q-auto.com';

-- ============================================================================
-- STEP 3: Check ID mismatch
-- ============================================================================
-- The app generates IDs like USER-zmohammed, but we used the UUID
-- This query shows both IDs
SELECT 
  u.id as users_table_id,
  a.id as auth_user_id,
  CASE 
    WHEN u.id = a.id::text THEN 'IDs match (UUID)'
    WHEN u.id LIKE 'USER-%' THEN 'Users table has readable ID'
    ELSE 'ID mismatch'
  END as id_status
FROM users u
LEFT JOIN auth.users a ON u.email = a.email
WHERE u.email = 'zmohammed@q-auto.com';

-- ============================================================================
-- STEP 4: Fix ID if needed (optional - only if you want readable ID)
-- ============================================================================
-- If you want to use the readable ID format (USER-zmohammed) instead of UUID,
-- uncomment and run this:
/*
UPDATE users 
SET id = 'USER-zmohammed'
WHERE email = 'zmohammed@q-auto.com'
AND id = '061a29db-0771-4ce5-b664-dc6562437bcb';
*/

-- ============================================================================
-- STEP 5: Verify RLS policies allow user to read their own record
-- ============================================================================
-- Check if the user can read their own record (this should work after auth)
-- This is just for verification - RLS should allow authenticated users

-- ============================================================================
-- IMPORTANT: Password Setup
-- ============================================================================
-- The user MUST have a password set in Supabase Auth to log in.
-- 
-- To set a password:
-- 1. Go to Supabase Dashboard → Authentication → Users
-- 2. Find zmohammed@q-auto.com
-- 3. Click "Send password reset email" or manually set password
--
-- OR use the password reset flow from the app login screen

