-- Migration script to add company/tenant support to existing database
-- Run this AFTER the main supabase_migration.sql if tables already exist

-- ============================================================================
-- STEP 1: Create companies table (if it doesn't exist)
-- ============================================================================
CREATE TABLE IF NOT EXISTS companies (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  name TEXT NOT NULL UNIQUE,
  "contactEmail" TEXT,
  "contactPhone" TEXT,
  address TEXT,
  "isActive" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_companies_name ON companies(name);
CREATE INDEX IF NOT EXISTS idx_companies_is_active ON companies("isActive");

-- ============================================================================
-- STEP 2: Add companyId to users table (if column doesn't exist)
-- ============================================================================
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'users' 
    AND (column_name = 'companyId' OR column_name = 'companyid')
  ) THEN
    ALTER TABLE users ADD COLUMN "companyId" TEXT REFERENCES companies(id) ON DELETE SET NULL;
    CREATE INDEX IF NOT EXISTS idx_users_company_id ON users("companyId");
  END IF;
END $$;

-- ============================================================================
-- STEP 3: Add companyId to assets table (if column doesn't exist)
-- ============================================================================
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'assets' 
    AND (column_name = 'companyId' OR column_name = 'companyid')
  ) THEN
    ALTER TABLE assets ADD COLUMN "companyId" TEXT REFERENCES companies(id) ON DELETE CASCADE;
    CREATE INDEX IF NOT EXISTS idx_assets_company_id ON assets("companyId");
  END IF;
END $$;

-- ============================================================================
-- STEP 4: Add companyId to work_orders table (if column doesn't exist)
-- ============================================================================
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'work_orders' 
    AND (column_name = 'companyId' OR column_name = 'companyid')
  ) THEN
    ALTER TABLE work_orders ADD COLUMN "companyId" TEXT REFERENCES companies(id) ON DELETE CASCADE;
    CREATE INDEX IF NOT EXISTS idx_work_orders_company_id ON work_orders("companyId");
  END IF;
END $$;

-- ============================================================================
-- STEP 5: Update RLS policies for companies
-- ============================================================================
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- Drop existing policy if it exists, then create new one
DROP POLICY IF EXISTS "Users can view their company" ON companies;
CREATE POLICY "Users can view their company" ON companies
  FOR SELECT USING (
    auth.role() = 'authenticated' AND
    (id IN (SELECT "companyId" FROM users WHERE id = auth.uid()::TEXT) OR
     EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::TEXT AND role IN ('admin', 'manager')))
  );

-- ============================================================================
-- STEP 6: Update RLS policies for users (company-based)
-- ============================================================================
DROP POLICY IF EXISTS "Users can view users in their company" ON users;
CREATE POLICY "Users can view users in their company" ON users
  FOR SELECT USING (
    auth.role() = 'authenticated' AND
    ("companyId" IN (SELECT "companyId" FROM users WHERE id = auth.uid()::TEXT) OR
     EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::TEXT AND role IN ('admin', 'manager')))
  );

-- ============================================================================
-- STEP 7: Update RLS policies for assets (company-based)
-- ============================================================================
DROP POLICY IF EXISTS "Users can view assets in their company" ON assets;
CREATE POLICY "Users can view assets in their company" ON assets
  FOR SELECT USING (
    auth.role() = 'authenticated' AND
    ("companyId" IN (SELECT "companyId" FROM users WHERE id = auth.uid()::TEXT) OR
     EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::TEXT AND role IN ('admin', 'manager')))
  );

-- ============================================================================
-- STEP 8: Update RLS policies for work_orders (company-based)
-- ============================================================================
DROP POLICY IF EXISTS "Users can view work orders in their company" ON work_orders;
CREATE POLICY "Users can view work orders in their company" ON work_orders
  FOR SELECT USING (
    auth.role() = 'authenticated' AND
    ("companyId" IN (SELECT "companyId" FROM users WHERE id = auth.uid()::TEXT) OR
     EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::TEXT AND role IN ('admin', 'manager')))
  );

DROP POLICY IF EXISTS "Users can create work orders for their company" ON work_orders;
CREATE POLICY "Users can create work orders for their company" ON work_orders
  FOR INSERT WITH CHECK (
    auth.role() = 'authenticated' AND
    ("companyId" IN (SELECT "companyId" FROM users WHERE id = auth.uid()::TEXT) OR
     EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::TEXT AND role IN ('admin', 'manager')))
  );

DROP POLICY IF EXISTS "Users can update work orders in their company" ON work_orders;
CREATE POLICY "Users can update work orders in their company" ON work_orders
  FOR UPDATE USING (
    auth.role() = 'authenticated' AND
    ("companyId" IN (SELECT "companyId" FROM users WHERE id = auth.uid()::TEXT) OR
     EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::TEXT AND role IN ('admin', 'manager')))
  );

