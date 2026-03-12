-- Run this in Supabase Dashboard → SQL Editor to fix empty admin portal data.
-- Ensures: admin user, companies, assets, inventory_items, purchase_orders, notifications.

-- Step 0: Ensure helper exists (skip if you already ran full RLS migration)
CREATE OR REPLACE FUNCTION public.get_my_email()
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$ SELECT email FROM auth.users WHERE id = auth.uid() LIMIT 1; $$;

CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT role::text FROM public.users WHERE id::text = auth.uid()::text LIMIT 1),
    CASE WHEN EXISTS (
      SELECT 1 FROM public.admin_users a
      WHERE a.email = (SELECT email FROM auth.users WHERE id = auth.uid() LIMIT 1)
      AND (a.is_admin OR a.is_manager)
    ) THEN 'admin' ELSE NULL END
  );
$$;

-- Step 1: Add admin so RLS returns 'admin' for beelectric@q-auto.com
DO $$
BEGIN
  INSERT INTO public.admin_users (email, is_admin, is_manager, updated_at)
  VALUES ('beelectric@q-auto.com', true, true, now());
EXCEPTION
  WHEN unique_violation THEN
    UPDATE public.admin_users
    SET is_admin = true, is_manager = true, updated_at = now()
    WHERE email = 'beelectric@q-auto.com';
END $$;

-- Step 2: Companies – read for all authenticated; full CRUD for admins
GRANT SELECT, INSERT, UPDATE, DELETE ON public.companies TO authenticated;
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated can read companies" ON public.companies;
CREATE POLICY "Authenticated can read companies"
  ON public.companies FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Admins can manage companies" ON public.companies;
CREATE POLICY "Admins can manage companies"
  ON public.companies FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

-- Step 3: Assets – read for all authenticated; full CRUD for admins
GRANT SELECT, INSERT, UPDATE, DELETE ON public.assets TO authenticated;
ALTER TABLE public.assets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated can read assets" ON public.assets;
CREATE POLICY "Authenticated can read assets"
  ON public.assets FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Admins can manage assets" ON public.assets;
CREATE POLICY "Admins can manage assets"
  ON public.assets FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

-- Step 4: Inventory (admin portal /dashboard and /inventory)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.inventory_items TO authenticated;
ALTER TABLE public.inventory_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can read inventory_items" ON public.inventory_items;
CREATE POLICY "Admins can read inventory_items"
  ON public.inventory_items FOR SELECT TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));
DROP POLICY IF EXISTS "Admins can manage inventory_items" ON public.inventory_items;
CREATE POLICY "Admins can manage inventory_items"
  ON public.inventory_items FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

-- Step 5: Purchase orders (admin portal /purchase-orders)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.purchase_orders TO authenticated;
ALTER TABLE public.purchase_orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can read purchase_orders" ON public.purchase_orders;
CREATE POLICY "Admins can read purchase_orders"
  ON public.purchase_orders FOR SELECT TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));
DROP POLICY IF EXISTS "Admins can manage purchase_orders" ON public.purchase_orders;
CREATE POLICY "Admins can manage purchase_orders"
  ON public.purchase_orders FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

-- Step 6: Notifications (user sees own; app filters by userId)
GRANT SELECT, INSERT, UPDATE ON public.notifications TO authenticated;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can read own notifications" ON public.notifications;
CREATE POLICY "Users can read own notifications"
  ON public.notifications FOR SELECT TO authenticated
  USING ("userId"::text = auth.uid()::text);
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications"
  ON public.notifications FOR UPDATE TO authenticated
  USING ("userId"::text = auth.uid()::text)
  WITH CHECK ("userId"::text = auth.uid()::text);
-- Allow insert so app/triggers can create notifications for users
DROP POLICY IF EXISTS "Authenticated can insert notifications" ON public.notifications;
CREATE POLICY "Authenticated can insert notifications"
  ON public.notifications FOR INSERT TO authenticated
  WITH CHECK (true);

-- Step 7: Users – grant, own row read, admins read all + manage (insert/update/delete)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO authenticated;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own row" ON public.users;
CREATE POLICY "Users can read own row"
  ON public.users FOR SELECT TO authenticated
  USING (id::text = auth.uid()::text);

-- Explicit SELECT for admins (so users list loads even if get_my_role is strict)
DROP POLICY IF EXISTS "Admins can read all users" ON public.users;
CREATE POLICY "Admins can read all users"
  ON public.users FOR SELECT TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

DROP POLICY IF EXISTS "Admins can manage users" ON public.users;
CREATE POLICY "Admins can manage users"
  ON public.users FOR INSERT TO authenticated
  WITH CHECK (public.get_my_role() IN ('admin', 'manager'));
CREATE POLICY "Admins can update users"
  ON public.users FOR UPDATE TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));
CREATE POLICY "Admins can delete users"
  ON public.users FOR DELETE TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

-- Step 8: Work orders – admins can delete (full CRUD)
DROP POLICY IF EXISTS "Admins can delete work orders" ON public.work_orders;
CREATE POLICY "Admins can delete work orders"
  ON public.work_orders FOR DELETE TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));
