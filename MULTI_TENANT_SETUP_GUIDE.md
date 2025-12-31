# Multi-Tenant Setup Guide

## ✅ Step 1: Database Migration (COMPLETED)
You've successfully run `add_company_support.sql` which added:
- `companies` table
- `companyId` columns to `users`, `assets`, and `work_orders` tables
- RLS policies for company-based data isolation

## 📋 Step 2: Create Companies

1. Open `setup_companies.sql` in your Supabase SQL editor
2. Edit the INSERT statements to create your actual companies:
   - Replace `'Be Electric'` with actual company names
   - Update contact information
   - Add more companies as needed

Example:
```sql
INSERT INTO companies (id, name, "contactEmail", "contactPhone", address, "isActive")
VALUES (
  'COMPANY-acme-corp',
  'ACME Corporation',
  'contact@acme.com',
  '+1234567890',
  '123 Main St, City, Country',
  true
);
```

## 👥 Step 3: Assign Users to Companies

You have several options in `setup_companies.sql`:

**Option A: Assign all users to a default company**
```sql
UPDATE users 
SET "companyId" = 'COMPANY-be-electric-main'
WHERE "companyId" IS NULL;
```

**Option B: Assign by email domain**
```sql
UPDATE users 
SET "companyId" = 'COMPANY-acme-corp'
WHERE email LIKE '%@acme.com' AND "companyId" IS NULL;
```

**Option C: Assign specific users**
```sql
UPDATE users 
SET "companyId" = 'COMPANY-acme-corp'
WHERE email IN ('user1@acme.com', 'user2@acme.com');
```

## 🏢 Step 4: Assign Assets to Companies

**Option A: Assign all assets to a default company**
```sql
UPDATE assets 
SET "companyId" = 'COMPANY-be-electric-main'
WHERE "companyId" IS NULL;
```

**Option B: Assign by location or other criteria**
```sql
UPDATE assets 
SET "companyId" = 'COMPANY-acme-corp'
WHERE location LIKE '%ACME Office%';
```

## 📝 Step 5: Update Work Orders

Work orders will automatically get `companyId` from their requestor when created. For existing work orders, run:

```sql
UPDATE work_orders wo
SET "companyId" = u."companyId"
FROM users u
WHERE wo."requestorId" = u.id 
  AND wo."companyId" IS NULL 
  AND u."companyId" IS NOT NULL;
```

## ✅ Step 6: Verify Setup

Run these queries to verify everything is set up correctly:

```sql
-- Check companies
SELECT id, name, "isActive" FROM companies;

-- Check users and their companies
SELECT u.id, u.email, u.name, u.role, u."companyId", c.name as company_name
FROM users u
LEFT JOIN companies c ON u."companyId" = c.id;

-- Check assets and their companies
SELECT a.id, a.name, a.location, a."companyId", c.name as company_name
FROM assets a
LEFT JOIN companies c ON a."companyId" = c.id;
```

## 🎯 How It Works Now

### For Requestors:
- Requestors can only see assets from their company
- Requestors can only see work orders from their company
- When creating a work order, it automatically gets the requestor's `companyId`

### For Admins/Managers:
- Admins and managers can see all companies' data
- They can manage companies, users, and assets across all tenants

### For Technicians:
- Technicians can see work orders assigned to them (regardless of company)
- They can also see unassigned work orders from their company (if they have a `companyId`)

## 🔧 Next Steps

1. **Create your companies** using `setup_companies.sql`
2. **Assign users to companies** based on your business logic
3. **Assign assets (chargers) to companies** - each company should have their own list of chargers
4. **Test the isolation** - log in as a requestor and verify they only see their company's data

## 📝 Important Notes

- Each company should have their own list of chargers (assets) with serial numbers and locations
- Requestor emails should be assigned to the correct company
- When a new user signs up, you'll need to assign them a `companyId` (this can be automated later)
- When creating new assets, make sure to set the `companyId`

## 🚀 Future Enhancements

- Admin UI for managing companies
- Automatic company assignment based on email domain
- Company-specific settings and branding
- Bulk import of companies, users, and assets

