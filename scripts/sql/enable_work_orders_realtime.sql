-- P0-A: Enable Supabase Realtime for public.work_orders
--
-- Apply ONLY after explicit approval:
--   ./scripts/db.sh run scripts/sql/enable_work_orders_realtime.sql
--
-- Verify:
--   ./scripts/db.sh query "SELECT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename='work_orders') AS work_orders_in_realtime;"

BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'work_orders'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.work_orders;
  END IF;
END $$;

COMMIT;
