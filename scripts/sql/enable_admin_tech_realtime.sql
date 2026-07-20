-- Enable Supabase Realtime for Admin ↔ Technician core field loop.
-- work_orders is already published; this adds the remaining tables.
--
-- Apply ONLY after explicit approval:
--   ./scripts/db.sh run scripts/sql/enable_admin_tech_realtime.sql
--
-- Verify:
--   ./scripts/db.sh query "SELECT tablename FROM pg_publication_tables WHERE pubname='supabase_realtime' AND schemaname='public' ORDER BY 1;"

BEGIN;

DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'work_orders',
    'notifications',
    'pm_tasks',
    'pm_task_occurrences',
    'parts_requests'
  ]
  LOOP
    IF to_regclass('public.' || t) IS NULL THEN
      RAISE NOTICE 'skip missing table public.%', t;
      CONTINUE;
    END IF;

    IF NOT EXISTS (
      SELECT 1
      FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = t
    ) THEN
      EXECUTE format(
        'ALTER PUBLICATION supabase_realtime ADD TABLE public.%I',
        t
      );
      RAISE NOTICE 'added public.% to supabase_realtime', t;
    ELSE
      RAISE NOTICE 'public.% already in supabase_realtime', t;
    END IF;
  END LOOP;
END $$;

COMMIT;
