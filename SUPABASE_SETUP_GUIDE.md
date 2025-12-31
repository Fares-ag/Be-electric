# Supabase Setup Guide

## Overview
This guide will help you set up your Supabase project and migrate from Firebase.

## Step 1: Create Database Tables

1. Go to your Supabase project dashboard: https://sdhqjyjeczrbnvukrmny.supabase.co
2. Navigate to **SQL Editor**
3. Copy and paste the contents of `supabase_migration.sql`
4. Run the migration script to create all required tables

## Step 2: Create Storage Bucket

1. In Supabase dashboard, go to **Storage**
2. Click **New bucket**
3. Name it: `files`
4. Make it **Public** (or configure RLS policies as needed)
5. Click **Create bucket**

## Step 3: Configure Row Level Security (RLS)

The migration script includes basic RLS policies. You should customize them based on your security requirements:

- **Admin users**: Full access to all data
- **Managers**: Read/write access to their department's data
- **Technicians**: Read/write access to assigned work orders and PM tasks
- **Requestors**: Read access to their own requests, create new requests

### Example Custom RLS Policy

```sql
-- Allow managers to view all work orders
CREATE POLICY "Managers can view all work orders" ON work_orders
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()::TEXT
      AND users.role = 'manager'
    )
  );
```

## Step 4: Update Authentication Settings

1. Go to **Authentication** > **Settings** in Supabase dashboard
2. Configure email templates if needed
3. Set up email verification (optional)
4. Configure password reset settings

## Step 5: Test the Connection

1. Run your Flutter app
2. Check the console for initialization messages
3. Try logging in with a test user
4. Verify data is being saved to Supabase

## Step 6: Migrate Existing Data (if applicable)

If you have existing Firebase data, you'll need to:

1. Export data from Firebase
2. Transform the data format (Firestore Timestamps → ISO8601 strings)
3. Import into Supabase using the SQL Editor or API

### Example Data Migration Script

```sql
-- Example: Migrate work orders
INSERT INTO work_orders (id, "ticketNumber", "assetId", ...)
VALUES 
  ('WO-2025-00001', 'WO-2025-00001', 'asset-123', ...),
  ...
ON CONFLICT (id) DO UPDATE SET
  "updatedAt" = NOW();
```

## Troubleshooting

### Issue: "Table does not exist"
- **Solution**: Make sure you've run the migration script in the SQL Editor

### Issue: "Permission denied"
- **Solution**: Check your RLS policies and ensure they allow the current user's role

### Issue: "Storage bucket not found"
- **Solution**: Create the `files` bucket in Storage section

### Issue: "Authentication failed"
- **Solution**: Verify your Supabase URL and API key in `lib/config/supabase_config.dart`

## Next Steps

1. ✅ Run the migration script
2. ✅ Create the storage bucket
3. ✅ Test authentication
4. ✅ Test CRUD operations
5. ✅ Test file uploads
6. ✅ Configure RLS policies for your use case
7. ✅ Migrate existing data (if needed)

## Configuration

Your Supabase configuration is in `lib/config/supabase_config.dart`:

```dart
static const String projectUrl = 'https://sdhqjyjeczrbnvukrmny.supabase.co';
static const String publishableKey = 'sb_publishable_jymzllhRW_CVJH6pY3qleA_7GRd1ETA';
```

## Support

For issues or questions:
- Check Supabase documentation: https://supabase.com/docs
- Check the migration summary: `SUPABASE_MIGRATION_SUMMARY.md`


