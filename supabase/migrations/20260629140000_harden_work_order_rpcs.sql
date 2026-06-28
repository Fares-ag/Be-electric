-- Harden work-order RPCs: require authentication, scope upsert to owner (or admin), admin-only assignees.
-- Revoke anon EXECUTE — mobile clients use authenticated JWT.

CREATE OR REPLACE FUNCTION public.upsert_work_order(p_row jsonb)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid text := auth.uid()::text;
  v_role text := public.get_my_role();
  v_requestor_id text := nullif(trim(p_row->>'requestorId'), '');
  v_work_order_id uuid := nullif(trim(p_row->>'id'), '')::uuid;
  v_existing_requestor text;
  v_photo_path text;
  v_completion_photo_path text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF v_role NOT IN ('admin', 'manager') THEN
    IF v_requestor_id IS NULL OR v_requestor_id <> v_uid THEN
      RAISE EXCEPTION 'Forbidden: requestorId must match authenticated user';
    END IF;
    IF v_work_order_id IS NOT NULL THEN
      SELECT "requestorId" INTO v_existing_requestor
      FROM public.work_orders
      WHERE id = v_work_order_id;
      IF FOUND AND v_existing_requestor IS DISTINCT FROM v_uid THEN
        RAISE EXCEPTION 'Forbidden: cannot modify another user''s work order';
      END IF;
    END IF;
  END IF;

  v_photo_path := nullif(trim(p_row->>'photoPath'), '');
  IF v_photo_path IS NULL
    AND jsonb_typeof(p_row->'photoPaths') = 'array'
    AND jsonb_array_length(p_row->'photoPaths') > 0
  THEN
    v_photo_path := (p_row->'photoPaths')::text;
  END IF;

  v_completion_photo_path := nullif(trim(p_row->>'completionPhotoPath'), '');
  IF v_completion_photo_path IS NULL
    AND jsonb_typeof(p_row->'completionPhotoPaths') = 'array'
    AND jsonb_array_length(p_row->'completionPhotoPaths') > 0
  THEN
    v_completion_photo_path := (p_row->'completionPhotoPaths')::text;
  END IF;

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
    "completionPhotoPath",
    "beforePhotoPath",
    "afterPhotoPath",
    "location",
    "category",
    "notes",
    "metadata"
  )
  VALUES (
    COALESCE(v_work_order_id, gen_random_uuid()),
    COALESCE(
      p_row->>'ticketNumber',
      'WO-' || to_char(now(), 'YYYYMMDD') || '-' || substr(md5(random()::text), 1, 4)
    ),
    p_row->>'problemDescription',
    COALESCE(p_row->>'status', 'open'),
    COALESCE(p_row->>'priority', 'medium'),
    COALESCE((p_row->>'createdAt')::timestamptz, now()),
    v_requestor_id,
    nullif(trim(p_row->>'companyId'), ''),
    nullif(trim(p_row->>'assetId'), ''),
    CASE
      WHEN p_row ? 'assignedTechnicianIds'
        THEN ARRAY(SELECT jsonb_array_elements_text(p_row->'assignedTechnicianIds'))
      ELSE NULL
    END,
    p_row->>'requestorName',
    nullif(trim(p_row->>'primaryTechnicianId'), ''),
    now(),
    v_photo_path,
    v_completion_photo_path,
    nullif(trim(p_row->>'beforePhotoPath'), ''),
    nullif(trim(p_row->>'afterPhotoPath'), ''),
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
    "completionPhotoPath"   = COALESCE(EXCLUDED."completionPhotoPath",   work_orders."completionPhotoPath"),
    "beforePhotoPath"       = COALESCE(EXCLUDED."beforePhotoPath",       work_orders."beforePhotoPath"),
    "afterPhotoPath"        = COALESCE(EXCLUDED."afterPhotoPath",        work_orders."afterPhotoPath"),
    "location"              = COALESCE(EXCLUDED."location",              work_orders."location"),
    "category"              = COALESCE(EXCLUDED."category",              work_orders."category"),
    "notes"                 = COALESCE(EXCLUDED."notes",                 work_orders."notes"),
    "metadata"              = CASE
      WHEN EXCLUDED."metadata" IS NOT NULL
        THEN COALESCE(work_orders."metadata", '{}'::jsonb) || EXCLUDED."metadata"
      ELSE work_orders."metadata"
    END;
END;
$$;

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
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF public.get_my_role() NOT IN ('admin', 'manager') THEN
    RAISE EXCEPTION 'Forbidden: admin or manager role required';
  END IF;

  UPDATE public.work_orders
  SET
    "assignedTechnicianIds" = ARRAY(SELECT unnest(p_technician_ids)::uuid),
    "assignedAt" = CASE WHEN array_length(p_technician_ids, 1) > 0 THEN now() ELSE NULL END,
    "updatedAt" = now()
  WHERE id = p_work_order_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.upsert_work_order(jsonb) FROM anon;
REVOKE EXECUTE ON FUNCTION public.update_work_order_assignees(uuid, text[]) FROM anon;
GRANT EXECUTE ON FUNCTION public.upsert_work_order(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_work_order_assignees(uuid, text[]) TO authenticated;

NOTIFY pgrst, 'reload schema';
