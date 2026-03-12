-- RPC to set work order assigned technicians (bypasses RLS; used by admin portal)
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
    "assignedTechnicianIds" = p_technician_ids,
    "assignedAt" = CASE WHEN array_length(p_technician_ids, 1) > 0 THEN now() ELSE NULL END,
    "updatedAt" = now()
  WHERE id = p_work_order_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_work_order_assignees(uuid, text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_work_order_assignees(uuid, text[]) TO anon;

NOTIFY pgrst, 'reload schema';
