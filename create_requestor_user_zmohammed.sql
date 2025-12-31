-- Create requestor user for zmohammed@q-auto.com
-- This user already exists in Supabase auth.users table
-- We need to create a corresponding record in the users table

INSERT INTO users (
  id,
  email,
  name,
  role,
  "createdAt",
  "isActive",
  "updatedAt",
  "companyId"  -- Set this to the appropriate company ID, or leave NULL for now
) VALUES (
  '061a29db-0771-4ce5-b664-dc6562437bcb',  -- Use the Supabase auth user ID
  'zmohammed@q-auto.com',
  'Z. Mohammed',  -- Update this name if needed
  'requestor',
  NOW(),
  true,
  NOW(),
  NULL  -- Set companyId later, or replace NULL with a company ID like 'COMPANY-be-electric-main'
)
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  name = EXCLUDED.name,
  role = EXCLUDED.role,
  "isActive" = EXCLUDED."isActive",
  "updatedAt" = NOW();

-- Verify the user was created
SELECT id, email, name, role, "companyId", "isActive" 
FROM users 
WHERE email = 'zmohammed@q-auto.com';

