-- Fix: operator does not exist: text = uuid when assigning technicians
-- via update_work_order_assignees (React admin).
--
-- Root cause (live 2026-07-20):
--   work_orders.id                  = text
--   work_orders.assignedTechnicianIds = text[]
--   RPC still declared p_work_order_id uuid and cast assignees to uuid[]
--
-- Apply (after approval):
--   ./scripts/db.sh run scripts/sql/fix_update_work_order_assignees_text_id.sql
--
-- Verify:
--   ./scripts/db.sh query "SELECT pg_get_function_identity_arguments(p.oid) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='update_work_order_assignees';"

BEGIN;

-- Drop old uuid-typed signature (CREATE OR REPLACE cannot change arg types)
DROP FUNCTION IF EXISTS public.update_work_order_assignees(uuid, text[]);

CREATE OR REPLACE FUNCTION public.update_work_order_assignees(
  p_work_order_id text,
  p_technician_ids text[]
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
SET row_security TO 'off'
AS $$
DECLARE
  v_ids text[];
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF public.get_my_role() NOT IN ('admin', 'manager') THEN
    RAISE EXCEPTION 'Forbidden: admin or manager role required';
  END IF;

  -- Normalize: drop nulls/blanks, keep order
  SELECT COALESCE(array_agg(x), ARRAY[]::text[])
  INTO v_ids
  FROM (
    SELECT btrim(t) AS x
    FROM unnest(COALESCE(p_technician_ids, ARRAY[]::text[])) AS t
    WHERE t IS NOT NULL AND btrim(t) <> ''
  ) s;

  UPDATE public.work_orders
  SET
    "assignedTechnicianIds" = v_ids,
    "primaryTechnicianId" = CASE
      WHEN array_length(v_ids, 1) IS NOT NULL THEN v_ids[1]
      ELSE NULL
    END,
    "assignedTechnicianId" = CASE
      WHEN array_length(v_ids, 1) IS NOT NULL THEN v_ids[1]
      ELSE NULL
    END,
    "assignedAt" = CASE
      WHEN array_length(v_ids, 1) IS NOT NULL THEN now()
      ELSE NULL
    END,
    "updatedAt" = now()
  WHERE id = p_work_order_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Work order not found: %', p_work_order_id;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.update_work_order_assignees(text, text[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_work_order_assignees(text, text[]) FROM anon;
GRANT EXECUTE ON FUNCTION public.update_work_order_assignees(text, text[]) TO authenticated;

NOTIFY pgrst, 'reload schema';

COMMIT;
