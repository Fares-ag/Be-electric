-- Fix: "operator does not exist: text = uuid" — use helper so comparison is always text = ANY(text[])
-- whether assignedTechnicianIds is text[] or uuid[].

-- Helper: return text[] for uuid[] or text[] column
CREATE OR REPLACE FUNCTION public.assigned_ids_as_text(ids uuid[])
RETURNS text[]
LANGUAGE sql STABLE PARALLEL SAFE
AS $$
  SELECT COALESCE(
    (SELECT array_agg(t::text) FROM unnest(COALESCE(ids, ARRAY[]::uuid[])) AS t),
    ARRAY[]::text[]
  );
$$;

CREATE OR REPLACE FUNCTION public.assigned_ids_as_text(ids text[])
RETURNS text[]
LANGUAGE sql STABLE PARALLEL SAFE
AS $$
  SELECT COALESCE(ids, ARRAY[]::text[]);
$$;

-- work_orders: Technicians can update assigned
DROP POLICY IF EXISTS "Technicians can update assigned work orders" ON public.work_orders;
CREATE POLICY "Technicians can update assigned work orders"
  ON public.work_orders FOR UPDATE TO authenticated
  USING (
    auth.uid()::text = ANY(public.assigned_ids_as_text("assignedTechnicianIds"))
  );

-- work_orders: Technicians can read assigned
DROP POLICY IF EXISTS "Technicians can read assigned work orders" ON public.work_orders;
CREATE POLICY "Technicians can read assigned work orders"
  ON public.work_orders FOR SELECT TO authenticated
  USING (
    auth.uid()::text = ANY(public.assigned_ids_as_text("assignedTechnicianIds"))
  );

-- pm_tasks: Technicians can read assigned
DROP POLICY IF EXISTS "Technicians can read assigned pm_tasks" ON public.pm_tasks;
CREATE POLICY "Technicians can read assigned pm_tasks"
  ON public.pm_tasks FOR SELECT TO authenticated
  USING (
    auth.uid()::text = ANY(public.assigned_ids_as_text("assignedTechnicianIds"))
  );

-- RPC: client sends text[] (UUID strings). Cast to uuid[] for column (column is uuid[]).
CREATE OR REPLACE FUNCTION public.update_work_order_assignees(
  p_work_order_id uuid,
  p_technician_ids text[]
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
BEGIN
  UPDATE public.work_orders
  SET
    "assignedTechnicianIds" = ARRAY(SELECT unnest(p_technician_ids)::uuid),
    "assignedAt" = CASE WHEN array_length(p_technician_ids, 1) > 0 THEN now() ELSE NULL END,
    "updatedAt" = now()
  WHERE id = p_work_order_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_work_order_assignees(uuid, text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_work_order_assignees(uuid, text[]) TO anon;

NOTIFY pgrst, 'reload schema';
