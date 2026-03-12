-- ============================================
-- Apply ALL table-level privileges (GRANTs)
-- Run this ONCE in Supabase Dashboard → SQL Editor (same project as your app).
-- Fixes: "permission denied for table users" and cascade failures on work_orders, pm_tasks, etc.
-- ============================================

-- Schema usage (required before table access)
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;

-- Core: users and admin_users (get_my_role, auth store, and any policy that reads users)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO anon;
GRANT SELECT ON public.admin_users TO authenticated;
GRANT SELECT ON public.admin_users TO anon;

-- App tables (RLS will still filter rows; these grants allow the role to touch the table at all)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.work_orders TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.work_orders TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.pm_tasks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.pm_tasks TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.parts_requests TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.parts_requests TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.companies TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.companies TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.assets TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.assets TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.inventory_items TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.inventory_items TO anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.purchase_orders TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.purchase_orders TO anon;

GRANT SELECT, INSERT, UPDATE ON public.notifications TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.notifications TO anon;

-- Optional: if you have these tables and the app uses them
-- GRANT ... ON public.audit_events TO authenticated;
-- GRANT ... ON public.escalation_events TO authenticated;
-- GRANT ... ON public.vendors TO authenticated;

-- Verify (run separately if you want to check)
-- SELECT grantee, table_name, privilege_type
-- FROM information_schema.role_table_grants
-- WHERE table_schema = 'public' AND table_name IN ('users', 'work_orders', 'pm_tasks')
-- ORDER BY table_name, grantee, privilege_type;
