-- Fix "new row violates row-level security policy" for requestors:
-- 1. Ensure work_orders allows authenticated users to INSERT (create requests).
-- 2. Allow authenticated uploads to work-order-photos bucket (storage.objects).

-- ═══ work_orders: allow any authenticated user to create (requestors submit here) ═══
ALTER TABLE public.work_orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated can create work orders" ON public.work_orders;
CREATE POLICY "Authenticated can create work orders"
  ON public.work_orders FOR INSERT TO authenticated
  WITH CHECK (true);

-- ═══ storage.objects: allow authenticated to upload to work-order-photos ═══
DROP POLICY IF EXISTS "Authenticated can upload work-order-photos" ON storage.objects;
CREATE POLICY "Authenticated can upload work-order-photos"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'work-order-photos');

-- Allow public read so photo URLs work (bucket is public)
DROP POLICY IF EXISTS "Public read work-order-photos" ON storage.objects;
CREATE POLICY "Public read work-order-photos"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'work-order-photos');

NOTIFY pgrst, 'reload schema';
