-- Setup script to create companies and assign them to existing users/assets
-- Run this AFTER add_company_support.sql has been executed successfully

-- ============================================================================
-- STEP 1: Create sample companies
-- ============================================================================
-- Replace these with your actual company names and details

-- Example: Create a company for "Be Electric" (your main company)
INSERT INTO companies (id, name, "contactEmail", "contactPhone", address, "isActive", "createdAt", "updatedAt")
VALUES (
  'COMPANY-be-electric-main',
  'Be Electric',
  'info@beelectric.com',
  '+1234567890',
  'Main Office Address',
  true,
  NOW(),
  NOW()
)
ON CONFLICT (id) DO NOTHING;

-- Example: Create another company (replace with actual company names)
-- INSERT INTO companies (id, name, "contactEmail", "contactPhone", address, "isActive", "createdAt", "updatedAt")
-- VALUES (
--   'COMPANY-company-name-2',
--   'Company Name 2',
--   'contact@company2.com',
--   '+1234567891',
--   'Company 2 Address',
--   true,
--   NOW(),
--   NOW()
-- )
-- ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- STEP 2: Assign companyId to existing users
-- ============================================================================
-- Option A: Assign all existing users to a default company
-- UPDATE users 
-- SET "companyId" = 'COMPANY-be-electric-main'
-- WHERE "companyId" IS NULL;

-- Option B: Assign users by email domain (example)
-- UPDATE users 
-- SET "companyId" = 'COMPANY-be-electric-main'
-- WHERE email LIKE '%@beelectric.com' AND "companyId" IS NULL;

-- Option C: Assign specific users by email
-- UPDATE users 
-- SET "companyId" = 'COMPANY-be-electric-main'
-- WHERE email IN ('user1@example.com', 'user2@example.com') AND "companyId" IS NULL;

-- ============================================================================
-- STEP 3: Assign companyId to existing assets
-- ============================================================================
-- Option A: Assign all existing assets to a default company
-- UPDATE assets 
-- SET "companyId" = 'COMPANY-be-electric-main'
-- WHERE "companyId" IS NULL;

-- Option B: Assign assets based on location or other criteria
-- UPDATE assets 
-- SET "companyId" = 'COMPANY-be-electric-main'
-- WHERE location LIKE '%Main Office%' AND "companyId" IS NULL;

-- ============================================================================
-- STEP 4: Update existing work orders with companyId from their requestor
-- ============================================================================
-- This will set companyId on work orders based on the requestor's companyId
UPDATE work_orders wo
SET "companyId" = u."companyId"
FROM users u
WHERE wo."requestorId" = u.id 
  AND wo."companyId" IS NULL 
  AND u."companyId" IS NOT NULL;

-- ============================================================================
-- VERIFICATION QUERIES (run these to check the setup)
-- ============================================================================

-- Check companies
-- SELECT id, name, "isActive" FROM companies;

-- Check users and their companies
-- SELECT u.id, u.email, u.name, u.role, u."companyId", c.name as company_name
-- FROM users u
-- LEFT JOIN companies c ON u."companyId" = c.id
-- ORDER BY u."companyId", u.email;

-- Check assets and their companies
-- SELECT a.id, a.name, a.location, a."companyId", c.name as company_name
-- FROM assets a
-- LEFT JOIN companies c ON a."companyId" = c.id
-- ORDER BY a."companyId", a.name;

-- Check work orders and their companies
-- SELECT wo.id, wo."ticketNumber", wo."companyId", c.name as company_name
-- FROM work_orders wo
-- LEFT JOIN companies c ON wo."companyId" = c.id
-- ORDER BY wo."companyId", wo."createdAt" DESC
-- LIMIT 20;

