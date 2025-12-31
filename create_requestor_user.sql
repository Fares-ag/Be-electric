-- Create Requestor User for fmahmoud@q-auto.com
-- This user already exists in Supabase Auth (ID: 3bd786ab-243a-47ff-918c-ba358792485d)
-- This script creates the corresponding user record in the users table

-- Insert the user with role 'requestor'
-- User ID format: USER-{email_prefix} = USER-fmahmoud
INSERT INTO users (
  id,
  email,
  name,
  role,
  "createdAt",
  "isActive",
  "updatedAt"
) VALUES (
  'USER-fmahmoud',
  'fmahmoud@q-auto.com',
  'F. Mahmoud',  -- You can change this name if needed
  'requestor',
  NOW(),
  true,
  NOW()
)
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  name = EXCLUDED.name,
  role = EXCLUDED.role,
  "isActive" = EXCLUDED."isActive",
  "updatedAt" = NOW();

-- Verify the user was created
SELECT * FROM users WHERE email = 'fmahmoud@q-auto.com';

