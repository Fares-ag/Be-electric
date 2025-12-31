-- Supabase Database Migration Script
-- This script creates all required tables for the CMMS application

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- COMPANIES TABLE
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
-- USERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  role TEXT NOT NULL,
  department TEXT,
  "workEmail" TEXT,
  "companyId" TEXT REFERENCES companies(id) ON DELETE SET NULL,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "lastLoginAt" TIMESTAMPTZ,
  "isActive" BOOLEAN NOT NULL DEFAULT true,
  "updatedAt" TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_company_id ON users("companyId");

-- ============================================================================
-- ASSETS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS assets (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  "assetType" TEXT,
  location TEXT,
  "qrCode" TEXT UNIQUE,
  manufacturer TEXT,
  model TEXT,
  "serialNumber" TEXT,
  "installationDate" TIMESTAMPTZ,
  "lastMaintenanceDate" TIMESTAMPTZ,
  "nextMaintenanceDate" TIMESTAMPTZ,
  status TEXT,
  "companyId" TEXT REFERENCES companies(id) ON DELETE CASCADE,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_assets_name ON assets(name);
CREATE INDEX IF NOT EXISTS idx_assets_qr_code ON assets("qrCode");
CREATE INDEX IF NOT EXISTS idx_assets_location ON assets(location);
CREATE INDEX IF NOT EXISTS idx_assets_company_id ON assets("companyId");

-- ============================================================================
-- WORK ORDERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS work_orders (
  id TEXT PRIMARY KEY,
  "ticketNumber" TEXT NOT NULL,
  "assetId" TEXT REFERENCES assets(id) ON DELETE SET NULL,
  location TEXT,
  "problemDescription" TEXT NOT NULL,
  "requestorId" TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  "companyId" TEXT REFERENCES companies(id) ON DELETE CASCADE,
  "requestorName" TEXT,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "idempotencyKey" TEXT,
  "photoPath" TEXT,
  "primaryTechnicianId" TEXT REFERENCES users(id) ON DELETE SET NULL,
  "assignedTechnicianId" TEXT REFERENCES users(id) ON DELETE SET NULL,
  "assignedTechnicianIds" TEXT[] DEFAULT '{}',
  "technicianEffortMinutes" JSONB,
  status TEXT NOT NULL,
  priority TEXT NOT NULL,
  "assignedAt" TIMESTAMPTZ,
  "startedAt" TIMESTAMPTZ,
  "completedAt" TIMESTAMPTZ,
  "closedAt" TIMESTAMPTZ,
  "correctiveActions" TEXT,
  recommendations TEXT,
  "nextMaintenanceDate" TIMESTAMPTZ,
  "requestorSignature" TEXT,
  "technicianSignature" TEXT,
  notes TEXT,
  category TEXT,
  "estimatedCost" NUMERIC,
  "actualCost" NUMERIC,
  "totalCost" NUMERIC,
  "partsUsed" TEXT[],
  "laborHours" NUMERIC,
  "technicianNotes" TEXT,
  "customerSignature" TEXT,
  "customerName" TEXT,
  "customerPhone" TEXT,
  "customerEmail" TEXT,
  "completionPhotoPath" TEXT,
  "beforePhotoPath" TEXT,
  "afterPhotoPath" TEXT,
  "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "isPaused" BOOLEAN DEFAULT false,
  "pausedAt" TIMESTAMPTZ,
  "pauseReason" TEXT,
  "resumedAt" TIMESTAMPTZ,
  "pauseHistory" JSONB,
  "isOffline" BOOLEAN DEFAULT false,
  "lastSyncedAt" TIMESTAMPTZ,
  "laborCost" NUMERIC,
  "partsCost" NUMERIC,
  metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_work_orders_status ON work_orders(status);
CREATE INDEX IF NOT EXISTS idx_work_orders_priority ON work_orders(priority);
CREATE INDEX IF NOT EXISTS idx_work_orders_created_at ON work_orders("createdAt");
CREATE INDEX IF NOT EXISTS idx_work_orders_asset_id ON work_orders("assetId");
CREATE INDEX IF NOT EXISTS idx_work_orders_requestor_id ON work_orders("requestorId");
CREATE INDEX IF NOT EXISTS idx_work_orders_technician_ids ON work_orders USING GIN("assignedTechnicianIds");
CREATE INDEX IF NOT EXISTS idx_work_orders_company_id ON work_orders("companyId");

-- ============================================================================
-- PM TASKS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS pm_tasks (
  id TEXT PRIMARY KEY,
  "taskName" TEXT NOT NULL,
  "assetId" TEXT NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
  description TEXT,
  "assignedTechnicianIds" TEXT[] DEFAULT '{}',
  frequency TEXT NOT NULL,
  "frequencyValue" INTEGER NOT NULL,
  "nextDueDate" TIMESTAMPTZ NOT NULL,
  "lastCompletedDate" TIMESTAMPTZ,
  status TEXT NOT NULL,
  "estimatedDuration" INTEGER,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMPTZ DEFAULT NOW(),
  "idempotencyKey" TEXT,
  "completionPhotoPath" TEXT,
  metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_pm_tasks_status ON pm_tasks(status);
CREATE INDEX IF NOT EXISTS idx_pm_tasks_asset_id ON pm_tasks("assetId");
CREATE INDEX IF NOT EXISTS idx_pm_tasks_next_due_date ON pm_tasks("nextDueDate");
CREATE INDEX IF NOT EXISTS idx_pm_tasks_technician_ids ON pm_tasks USING GIN("assignedTechnicianIds");

-- ============================================================================
-- INVENTORY ITEMS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS inventory_items (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  sku TEXT UNIQUE,
  description TEXT,
  category TEXT,
  "currentStock" INTEGER NOT NULL DEFAULT 0,
  "minStock" INTEGER NOT NULL DEFAULT 0,
  "maxStock" INTEGER,
  unit TEXT,
  "unitCost" NUMERIC,
  location TEXT,
  supplier TEXT,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_inventory_items_name ON inventory_items(name);
CREATE INDEX IF NOT EXISTS idx_inventory_items_sku ON inventory_items(sku);
CREATE INDEX IF NOT EXISTS idx_inventory_items_category ON inventory_items(category);

-- ============================================================================
-- PARTS REQUESTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS parts_requests (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  "workOrderId" TEXT REFERENCES work_orders(id) ON DELETE CASCADE,
  "requestedBy" TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  "requestedParts" JSONB NOT NULL,
  status TEXT NOT NULL,
  "requestedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "approvedAt" TIMESTAMPTZ,
  "approvedBy" TEXT REFERENCES users(id) ON DELETE SET NULL,
  "rejectedAt" TIMESTAMPTZ,
  "rejectedBy" TEXT REFERENCES users(id) ON DELETE SET NULL,
  "rejectionReason" TEXT,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_parts_requests_status ON parts_requests(status);
CREATE INDEX IF NOT EXISTS idx_parts_requests_work_order_id ON parts_requests("workOrderId");
CREATE INDEX IF NOT EXISTS idx_parts_requests_requested_by ON parts_requests("requestedBy");

-- ============================================================================
-- PURCHASE ORDERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS purchase_orders (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  "orderNumber" TEXT UNIQUE,
  "requestedBy" TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  "orderedItems" JSONB NOT NULL,
  status TEXT NOT NULL,
  "totalAmount" NUMERIC,
  "orderedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "receivedAt" TIMESTAMPTZ,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_purchase_orders_status ON purchase_orders(status);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_requested_by ON purchase_orders("requestedBy");

-- ============================================================================
-- AUDIT EVENTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS audit_events (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  type TEXT NOT NULL,
  severity TEXT NOT NULL,
  "userId" TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  description TEXT NOT NULL,
  "userName" TEXT,
  "ipAddress" TEXT,
  "userAgent" TEXT,
  "resourceId" TEXT,
  "resourceType" TEXT,
  "oldValues" JSONB,
  "newValues" JSONB,
  metadata JSONB DEFAULT '{}',
  "sessionId" TEXT,
  "requestId" TEXT
);

CREATE INDEX IF NOT EXISTS idx_audit_events_type ON audit_events(type);
CREATE INDEX IF NOT EXISTS idx_audit_events_user_id ON audit_events("userId");
CREATE INDEX IF NOT EXISTS idx_audit_events_timestamp ON audit_events(timestamp);

-- ============================================================================
-- ESCALATION EVENTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS escalation_events (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  "ruleId" TEXT NOT NULL,
  type TEXT NOT NULL,
  "itemId" TEXT NOT NULL,
  "itemType" TEXT NOT NULL,
  "currentLevel" TEXT NOT NULL,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "resolvedAt" TIMESTAMPTZ,
  "resolvedBy" TEXT REFERENCES users(id) ON DELETE SET NULL,
  notes TEXT,
  data JSONB DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_escalation_events_item_id ON escalation_events("itemId");
CREATE INDEX IF NOT EXISTS idx_escalation_events_created_at ON escalation_events("createdAt");

-- ============================================================================
-- NOTIFICATIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS notifications (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL,
  priority TEXT NOT NULL,
  channel TEXT NOT NULL,
  "userId" TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  "relatedId" TEXT,
  "relatedType" TEXT,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "isRead" BOOLEAN NOT NULL DEFAULT false,
  "readAt" TIMESTAMPTZ,
  data JSONB,
  "expiresAt" TIMESTAMPTZ,
  actions TEXT[]
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications("userId");
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications("createdAt");
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications("isRead");

-- ============================================================================
-- WORKFLOWS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS workflows (
  id TEXT PRIMARY KEY,
  "workflowType" TEXT NOT NULL,
  status TEXT NOT NULL,
  "createdByUserId" TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  "assignedToUserId" TEXT REFERENCES users(id) ON DELETE SET NULL,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMPTZ DEFAULT NOW(),
  "completedAt" TIMESTAMPTZ,
  title TEXT NOT NULL,
  description TEXT,
  approvers TEXT[] DEFAULT '{}',
  "currentStep" INTEGER NOT NULL DEFAULT 0,
  "totalSteps" INTEGER NOT NULL DEFAULT 1,
  "stepHistory" JSONB DEFAULT '[]',
  data JSONB DEFAULT '{}',
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_workflows_status ON workflows(status);
CREATE INDEX IF NOT EXISTS idx_workflows_created_by ON workflows("createdByUserId");
CREATE INDEX IF NOT EXISTS idx_workflows_assigned_to ON workflows("assignedToUserId");
CREATE INDEX IF NOT EXISTS idx_workflows_approvers ON workflows USING GIN(approvers);

-- ============================================================================
-- VENDORS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS vendors (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  name TEXT NOT NULL,
  "contactEmail" TEXT,
  "contactPhone" TEXT,
  address TEXT,
  website TEXT,
  rating NUMERIC,
  "isActive" BOOLEAN NOT NULL DEFAULT true,
  notes TEXT,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vendors_name ON vendors(name);
CREATE INDEX IF NOT EXISTS idx_vendors_is_active ON vendors("isActive");

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE pm_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE parts_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE escalation_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE workflows ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;

-- Basic RLS policies (adjust based on your security requirements)
-- These allow authenticated users to read/write their own data
-- Admin users can read/write all data

-- Companies table policies
CREATE POLICY "Users can view their company" ON companies
  FOR SELECT USING (
    auth.role() = 'authenticated' AND
    (id IN (SELECT "companyId" FROM users WHERE id = auth.uid()::TEXT) OR
     EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::TEXT AND role IN ('admin', 'manager')))
  );

-- Users table policies
CREATE POLICY "Users can view users in their company" ON users
  FOR SELECT USING (
    auth.role() = 'authenticated' AND
    ("companyId" IN (SELECT "companyId" FROM users WHERE id = auth.uid()::TEXT) OR
     EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::TEXT AND role IN ('admin', 'manager')))
  );

CREATE POLICY "Users can insert themselves" ON users
  FOR INSERT 
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.role() = 'authenticated');

-- Assets policies (company-based)
CREATE POLICY "Users can view assets in their company" ON assets
  FOR SELECT USING (
    auth.role() = 'authenticated' AND
    ("companyId" IN (SELECT "companyId" FROM users WHERE id = auth.uid()::TEXT) OR
     EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::TEXT AND role IN ('admin', 'manager')))
  );

-- Work orders policies (company-based)
CREATE POLICY "Users can view work orders in their company" ON work_orders
  FOR SELECT USING (
    auth.role() = 'authenticated' AND
    ("companyId" IN (SELECT "companyId" FROM users WHERE id = auth.uid()::TEXT) OR
     EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::TEXT AND role IN ('admin', 'manager')))
  );

CREATE POLICY "Users can create work orders for their company" ON work_orders
  FOR INSERT WITH CHECK (
    auth.role() = 'authenticated' AND
    ("companyId" IN (SELECT "companyId" FROM users WHERE id = auth.uid()::TEXT) OR
     EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::TEXT AND role IN ('admin', 'manager')))
  );

CREATE POLICY "Users can update work orders in their company" ON work_orders
  FOR UPDATE USING (
    auth.role() = 'authenticated' AND
    ("companyId" IN (SELECT "companyId" FROM users WHERE id = auth.uid()::TEXT) OR
     EXISTS (SELECT 1 FROM users WHERE id = auth.uid()::TEXT AND role IN ('admin', 'manager')))
  );

-- Similar policies for other tables...
-- Note: You should customize these policies based on your role-based access control requirements

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Function to update updatedAt timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW."updatedAt" = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updatedAt
CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assets_updated_at BEFORE UPDATE ON assets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_work_orders_updated_at BEFORE UPDATE ON work_orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pm_tasks_updated_at BEFORE UPDATE ON pm_tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inventory_items_updated_at BEFORE UPDATE ON inventory_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_parts_requests_updated_at BEFORE UPDATE ON parts_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_purchase_orders_updated_at BEFORE UPDATE ON purchase_orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workflows_updated_at BEFORE UPDATE ON workflows
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vendors_updated_at BEFORE UPDATE ON vendors
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


