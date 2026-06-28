-- Fix upsert_work_order RPC:
-- 1. Remove incorrect ::uuid casts for assetId and companyId — those tables use string IDs.
-- 2. Accept and persist photoPath, metadata, location, category, and notes from the Flutter payload.
-- 3. On conflict: merge metadata (new fields win) instead of ignoring it.

CREATE OR REPLACE FUNCTION public.upsert_work_order(p_row jsonb)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.work_orders (
    id,
    "ticketNumber",
    "problemDescription",
    status,
    priority,
    "createdAt",
    "requestorId",
    "companyId",
    "assetId",
    "assignedTechnicianIds",
    "requestorName",
    "primaryTechnicianId",
    "updatedAt",
    "photoPath",
    "location",
    "category",
    "notes",
    "metadata"
  )
  VALUES (
    COALESCE(nullif(trim(p_row->>'id'), '')::uuid, gen_random_uuid()),
    COALESCE(
      p_row->>'ticketNumber',
      'WO-' || to_char(now(), 'YYYYMMDD') || '-' || substr(md5(random()::text), 1, 4)
    ),
    p_row->>'problemDescription',
    COALESCE(p_row->>'status', 'open'),
    COALESCE(p_row->>'priority', 'medium'),
    COALESCE((p_row->>'createdAt')::timestamptz, now()),
    -- requestorId is always a UUID (auth.uid())
    nullif(trim(p_row->>'requestorId'), '')::uuid,
    -- companyId and assetId are string IDs in this project, NOT necessarily UUIDs
    nullif(trim(p_row->>'companyId'), ''),
    nullif(trim(p_row->>'assetId'), ''),
    CASE
      WHEN p_row ? 'assignedTechnicianIds'
        THEN ARRAY(SELECT jsonb_array_elements_text(p_row->'assignedTechnicianIds'))
      ELSE NULL
    END,
    p_row->>'requestorName',
    nullif(trim(p_row->>'primaryTechnicianId'), '')::uuid,
    now(),
    -- Accept photos, location, category, notes and metadata from Flutter payload
    nullif(trim(p_row->>'photoPath'), ''),
    nullif(trim(p_row->>'location'), ''),
    nullif(trim(p_row->>'category'), ''),
    nullif(trim(p_row->>'notes'), ''),
    CASE WHEN p_row ? 'metadata' THEN p_row->'metadata' ELSE NULL END
  )
  ON CONFLICT (id) DO UPDATE SET
    "problemDescription"    = COALESCE(EXCLUDED."problemDescription",    work_orders."problemDescription"),
    status                  = COALESCE(EXCLUDED.status,                  work_orders.status),
    priority                = COALESCE(EXCLUDED.priority,                work_orders.priority),
    "requestorId"           = COALESCE(EXCLUDED."requestorId",           work_orders."requestorId"),
    "companyId"             = COALESCE(EXCLUDED."companyId",             work_orders."companyId"),
    "assetId"               = COALESCE(EXCLUDED."assetId",               work_orders."assetId"),
    "assignedTechnicianIds" = COALESCE(EXCLUDED."assignedTechnicianIds", work_orders."assignedTechnicianIds"),
    "requestorName"         = COALESCE(EXCLUDED."requestorName",         work_orders."requestorName"),
    "primaryTechnicianId"   = COALESCE(EXCLUDED."primaryTechnicianId",   work_orders."primaryTechnicianId"),
    "updatedAt"             = now(),
    "photoPath"             = COALESCE(EXCLUDED."photoPath",             work_orders."photoPath"),
    "location"              = COALESCE(EXCLUDED."location",              work_orders."location"),
    "category"              = COALESCE(EXCLUDED."category",              work_orders."category"),
    "notes"                 = COALESCE(EXCLUDED."notes",                 work_orders."notes"),
    -- Merge metadata: existing fields kept, new fields from Flutter overwrite on conflict
    "metadata"              = CASE
      WHEN EXCLUDED."metadata" IS NOT NULL
        THEN COALESCE(work_orders."metadata", '{}'::jsonb) || EXCLUDED."metadata"
      ELSE work_orders."metadata"
    END;
END;
$$;

GRANT EXECUTE ON FUNCTION public.upsert_work_order(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_work_order(jsonb) TO anon;

NOTIFY pgrst, 'reload schema';
