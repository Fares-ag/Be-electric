-- Option A: PM schedules (template) + materialized occurrences per asset × due date.
-- Legacy public.pm_tasks is unchanged for Flutter until mobile apps migrate.

CREATE TABLE IF NOT EXISTS public.pm_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "taskName" text NOT NULL,
  description text,
  frequency text NOT NULL,
  "frequencyValue" integer NOT NULL DEFAULT 0,
  "scheduleStartDate" date NOT NULL,
  "scheduleEndDate" date NOT NULL,
  "companyId" text REFERENCES public.companies(id) ON DELETE SET NULL,
  "assignedTechnicianIds" text[],
  "createdById" text REFERENCES public.users(id) ON DELETE SET NULL,
  "createdAt" timestamptz NOT NULL DEFAULT now(),
  "updatedAt" timestamptz NOT NULL DEFAULT now(),
  metadata jsonb,
  CONSTRAINT pm_schedules_end_after_start CHECK ("scheduleEndDate" >= "scheduleStartDate")
);

CREATE TABLE IF NOT EXISTS public.pm_task_occurrences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "scheduleId" uuid NOT NULL REFERENCES public.pm_schedules(id) ON DELETE CASCADE,
  "assetId" text NOT NULL REFERENCES public.assets(id) ON DELETE CASCADE,
  "dueDate" date NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  "completedAt" timestamptz,
  "completionPhotoPath" text,
  "assignedTechnicianIds" text[],
  metadata jsonb,
  "createdAt" timestamptz NOT NULL DEFAULT now(),
  "updatedAt" timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pm_task_occurrences_status_check
    CHECK (status IN ('pending', 'completed', 'overdue', 'cancelled')),
  CONSTRAINT pm_task_occurrences_unique_slot
    UNIQUE ("scheduleId", "assetId", "dueDate")
);

CREATE INDEX IF NOT EXISTS pm_schedules_company_idx ON public.pm_schedules ("companyId");
CREATE INDEX IF NOT EXISTS pm_schedules_start_idx ON public.pm_schedules ("scheduleStartDate");
CREATE INDEX IF NOT EXISTS pm_task_occurrences_schedule_idx ON public.pm_task_occurrences ("scheduleId");
CREATE INDEX IF NOT EXISTS pm_task_occurrences_due_idx ON public.pm_task_occurrences ("dueDate");
CREATE INDEX IF NOT EXISTS pm_task_occurrences_status_idx ON public.pm_task_occurrences (status);

ALTER TABLE public.pm_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pm_task_occurrences ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.pm_schedules TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.pm_task_occurrences TO authenticated;

-- Admins / managers: full access
CREATE POLICY "Admins manage pm_schedules"
  ON public.pm_schedules FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'))
  WITH CHECK (public.get_my_role() IN ('admin', 'manager'));

CREATE POLICY "Admins manage pm_task_occurrences"
  ON public.pm_task_occurrences FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'))
  WITH CHECK (public.get_my_role() IN ('admin', 'manager'));

-- Technicians: read assigned occurrences
CREATE POLICY "Technicians read assigned pm_task_occurrences"
  ON public.pm_task_occurrences FOR SELECT TO authenticated
  USING (auth.uid()::text = ANY ("assignedTechnicianIds"));

-- Technicians: complete assigned occurrences (status + completion fields only enforced in app)
CREATE POLICY "Technicians update assigned pm_task_occurrences"
  ON public.pm_task_occurrences FOR UPDATE TO authenticated
  USING (auth.uid()::text = ANY ("assignedTechnicianIds"))
  WITH CHECK (auth.uid()::text = ANY ("assignedTechnicianIds"));

-- Technicians can read parent schedule when they have an assigned occurrence
CREATE POLICY "Technicians read pm_schedules via occurrences"
  ON public.pm_schedules FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.pm_task_occurrences o
      WHERE o."scheduleId" = pm_schedules.id
        AND auth.uid()::text = ANY (o."assignedTechnicianIds")
    )
  );

CREATE OR REPLACE FUNCTION public.create_pm_schedule_with_occurrences(
  p_schedule jsonb,
  p_asset_ids text[],
  p_occurrences jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_schedule_id uuid;
  v_count integer := 0;
  v_occ jsonb;
BEGIN
  IF public.get_my_role() NOT IN ('admin', 'manager') THEN
    RAISE EXCEPTION 'Forbidden: admin or manager role required';
  END IF;

  IF p_asset_ids IS NULL OR array_length(p_asset_ids, 1) IS NULL THEN
    RAISE EXCEPTION 'At least one asset is required';
  END IF;

  IF p_occurrences IS NULL OR jsonb_typeof(p_occurrences) <> 'array' OR jsonb_array_length(p_occurrences) < 1 THEN
    RAISE EXCEPTION 'At least one occurrence is required';
  END IF;

  INSERT INTO public.pm_schedules (
    "taskName",
    description,
    frequency,
    "frequencyValue",
    "scheduleStartDate",
    "scheduleEndDate",
    "companyId",
    "assignedTechnicianIds",
    "createdById",
    metadata,
    "updatedAt"
  )
  VALUES (
    p_schedule->>'taskName',
    nullif(trim(p_schedule->>'description'), ''),
    p_schedule->>'frequency',
    COALESCE((p_schedule->>'frequencyValue')::integer, 0),
    (p_schedule->>'scheduleStartDate')::date,
    (p_schedule->>'scheduleEndDate')::date,
    nullif(trim(p_schedule->>'companyId'), ''),
    CASE
      WHEN p_schedule ? 'assignedTechnicianIds'
        THEN ARRAY(SELECT jsonb_array_elements_text(p_schedule->'assignedTechnicianIds'))
      ELSE NULL
    END,
    nullif(trim(p_schedule->>'createdById'), ''),
    CASE WHEN p_schedule ? 'metadata' THEN p_schedule->'metadata' ELSE NULL END,
    now()
  )
  RETURNING id INTO v_schedule_id;

  FOR v_occ IN SELECT jsonb_array_elements(p_occurrences)
  LOOP
    INSERT INTO public.pm_task_occurrences (
      "scheduleId",
      "assetId",
      "dueDate",
      status,
      "assignedTechnicianIds",
      metadata
    )
    VALUES (
      v_schedule_id,
      v_occ->>'assetId',
      (v_occ->>'dueDate')::date,
      COALESCE(nullif(trim(v_occ->>'status'), ''), 'pending'),
      CASE
        WHEN v_occ ? 'assignedTechnicianIds'
          THEN ARRAY(SELECT jsonb_array_elements_text(v_occ->'assignedTechnicianIds'))
        WHEN p_schedule ? 'assignedTechnicianIds'
          THEN ARRAY(SELECT jsonb_array_elements_text(p_schedule->'assignedTechnicianIds'))
        ELSE NULL
      END,
      CASE WHEN v_occ ? 'metadata' THEN v_occ->'metadata' ELSE NULL END
    );
    v_count := v_count + 1;
  END LOOP;

  RETURN jsonb_build_object('scheduleId', v_schedule_id, 'occurrenceCount', v_count);
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_pm_schedule_with_occurrences(jsonb, text[], jsonb) TO authenticated;

NOTIFY pgrst, 'reload schema';
