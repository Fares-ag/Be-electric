-- ============================================================
-- RPCs required by Flutter app (sync with docs/FLUTTER_USER_FLOW.md)
-- ============================================================

DROP FUNCTION IF EXISTS public.get_user_by_email(text);
-- Flutter resolves user after login by email (getUserByEmail)
CREATE OR REPLACE FUNCTION public.get_user_by_email(p_email text)
RETURNS SETOF public.users
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
  SELECT * FROM public.users WHERE email = p_email LIMIT 1;
$$;

DROP FUNCTION IF EXISTS public.upsert_work_order(jsonb);
-- Flutter requestor creates work orders via this RPC only (no direct INSERT)
CREATE OR REPLACE FUNCTION public.upsert_work_order(p_row jsonb)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.work_orders (
    id, "ticketNumber", "problemDescription", status, priority, "createdAt",
    "requestorId", "companyId", "assetId", "assignedTechnicianIds",
    "requestorName", "primaryTechnicianId", "updatedAt"
  )
  VALUES (
    COALESCE(nullif(trim(p_row->>'id'), '')::uuid, gen_random_uuid()),
    COALESCE(p_row->>'ticketNumber', 'WO-' || to_char(now(), 'YYYYMMDD') || '-' || substr(md5(random()::text), 1, 4)),
    p_row->>'problemDescription',
    COALESCE(p_row->>'status', 'open'),
    COALESCE(p_row->>'priority', 'medium'),
    COALESCE((p_row->>'createdAt')::timestamptz, now()),
    (p_row->>'requestorId')::uuid,
    (p_row->>'companyId')::uuid,
    (p_row->>'assetId')::uuid,
    CASE WHEN p_row ? 'assignedTechnicianIds' THEN ARRAY(SELECT jsonb_array_elements_text(p_row->'assignedTechnicianIds')) ELSE NULL END,
    p_row->>'requestorName',
    (p_row->>'primaryTechnicianId')::uuid,
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    "problemDescription" = COALESCE(EXCLUDED."problemDescription", work_orders."problemDescription"),
    status = COALESCE(EXCLUDED.status, work_orders.status),
    priority = COALESCE(EXCLUDED.priority, work_orders.priority),
    "requestorId" = COALESCE(EXCLUDED."requestorId", work_orders."requestorId"),
    "companyId" = COALESCE(EXCLUDED."companyId", work_orders."companyId"),
    "assetId" = COALESCE(EXCLUDED."assetId", work_orders."assetId"),
    "assignedTechnicianIds" = COALESCE(EXCLUDED."assignedTechnicianIds", work_orders."assignedTechnicianIds"),
    "requestorName" = COALESCE(EXCLUDED."requestorName", work_orders."requestorName"),
    "primaryTechnicianId" = COALESCE(EXCLUDED."primaryTechnicianId", work_orders."primaryTechnicianId"),
    "updatedAt" = now();
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_by_email(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_by_email(text) TO anon;
GRANT EXECUTE ON FUNCTION public.upsert_work_order(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_work_order(jsonb) TO anon;

NOTIFY pgrst, 'reload schema';
