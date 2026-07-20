-- Fix update_work_order_assignees for text id / text[] assignedTechnicianIds.
-- Replaces broken uuid signature that caused: operator does not exist: text = uuid

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
