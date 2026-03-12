-- Fix 403 on: assets, companies, inventory_items, parts_requests, purchase_orders
-- Drop ALL existing policies on each table, recreate clean ones.

-- ═══ ASSETS ═══
ALTER TABLE public.assets ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE pol RECORD;
BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'assets'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.assets', pol.policyname); END LOOP;
END $$;

CREATE POLICY "Authenticated can read assets"
  ON public.assets FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admins can manage assets"
  ON public.assets FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

GRANT SELECT, INSERT, UPDATE, DELETE ON public.assets TO authenticated;

-- ═══ COMPANIES ═══
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE pol RECORD;
BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'companies'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.companies', pol.policyname); END LOOP;
END $$;

CREATE POLICY "Authenticated can read companies"
  ON public.companies FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admins can manage companies"
  ON public.companies FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

GRANT SELECT, INSERT, UPDATE, DELETE ON public.companies TO authenticated;

-- ═══ INVENTORY_ITEMS ═══
ALTER TABLE public.inventory_items ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE pol RECORD;
BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'inventory_items'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.inventory_items', pol.policyname); END LOOP;
END $$;

CREATE POLICY "Authenticated can read inventory"
  ON public.inventory_items FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admins can manage inventory"
  ON public.inventory_items FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

GRANT SELECT, INSERT, UPDATE, DELETE ON public.inventory_items TO authenticated;

-- ═══ PARTS_REQUESTS ═══
ALTER TABLE public.parts_requests ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE pol RECORD;
BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'parts_requests'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.parts_requests', pol.policyname); END LOOP;
END $$;

CREATE POLICY "Authenticated can read parts_requests"
  ON public.parts_requests FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admins can manage parts_requests"
  ON public.parts_requests FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

CREATE POLICY "Users can insert own parts_requests"
  ON public.parts_requests FOR INSERT TO authenticated
  WITH CHECK ("requestedBy"::text = auth.uid()::text);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.parts_requests TO authenticated;

-- ═══ PURCHASE_ORDERS ═══
ALTER TABLE public.purchase_orders ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE pol RECORD;
BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'purchase_orders'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.purchase_orders', pol.policyname); END LOOP;
END $$;

CREATE POLICY "Authenticated can read purchase_orders"
  ON public.purchase_orders FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admins can manage purchase_orders"
  ON public.purchase_orders FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'));

GRANT SELECT, INSERT, UPDATE, DELETE ON public.purchase_orders TO authenticated;

-- ═══ Reload ═══
NOTIFY pgrst, 'reload schema';
