-- Align support_requests with Flutter requestor schema (Know How / Commissioning).
-- Replaces admin-inbox ticket/subject model; requestors use createdBy + staffReply.

DROP TABLE IF EXISTS public.support_request_messages CASCADE;

DROP POLICY IF EXISTS "Admins manage support_requests" ON public.support_requests;
DROP POLICY IF EXISTS "Requestors read own support_requests" ON public.support_requests;
DROP POLICY IF EXISTS "Requestors insert own support_requests" ON public.support_requests;

ALTER TABLE public.support_requests
  ADD COLUMN IF NOT EXISTS summary text,
  ADD COLUMN IF NOT EXISTS topic text,
  ADD COLUMN IF NOT EXISTS question text,
  ADD COLUMN IF NOT EXISTS details text,
  ADD COLUMN IF NOT EXISTS "chargerModel" text,
  ADD COLUMN IF NOT EXISTS "chargerSerialNumber" text,
  ADD COLUMN IF NOT EXISTS address text,
  ADD COLUMN IF NOT EXISTS country text,
  ADD COLUMN IF NOT EXISTS "scheduledDate" timestamptz,
  ADD COLUMN IF NOT EXISTS "staffReply" text,
  ADD COLUMN IF NOT EXISTS "createdBy" text REFERENCES public.users(id) ON DELETE SET NULL;

-- Best-effort backfill from legacy admin-inbox columns when present.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'support_requests' AND column_name = 'subject'
  ) THEN
    EXECUTE $sql$
      UPDATE public.support_requests
      SET
        summary = COALESCE(summary, subject),
        "createdBy" = COALESCE("createdBy", "requesterId")
      WHERE summary IS NULL OR "createdBy" IS NULL
    $sql$;
  END IF;
END $$;

ALTER TABLE public.support_requests
  DROP COLUMN IF EXISTS "ticketNumber",
  DROP COLUMN IF EXISTS subject,
  DROP COLUMN IF EXISTS description,
  DROP COLUMN IF EXISTS "requesterId",
  DROP COLUMN IF EXISTS "requesterName",
  DROP COLUMN IF EXISTS "requesterEmail",
  DROP COLUMN IF EXISTS "requesterPhone",
  DROP COLUMN IF EXISTS "submittedFields",
  DROP COLUMN IF EXISTS "submittedAt",
  DROP COLUMN IF EXISTS metadata,
  DROP COLUMN IF EXISTS "updatedAt";

ALTER TABLE public.support_requests
  ALTER COLUMN type SET DEFAULT 'knowHow',
  ALTER COLUMN status SET DEFAULT 'submitted';

CREATE INDEX IF NOT EXISTS support_requests_created_by_idx ON public.support_requests ("createdBy");
CREATE INDEX IF NOT EXISTS support_requests_created_at_idx ON public.support_requests ("createdAt" DESC);

CREATE POLICY "Admins manage support_requests"
  ON public.support_requests FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'))
  WITH CHECK (public.get_my_role() IN ('admin', 'manager'));

CREATE POLICY "Requestors read own support_requests"
  ON public.support_requests FOR SELECT TO authenticated
  USING ("createdBy" = auth.uid()::text);

CREATE POLICY "Requestors insert own support_requests"
  ON public.support_requests FOR INSERT TO authenticated
  WITH CHECK ("createdBy" = auth.uid()::text);

NOTIFY pgrst, 'reload schema';
