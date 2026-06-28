-- Be Electric Support Inbox (admin portal + mobile requestor submissions)

CREATE TABLE IF NOT EXISTS public.support_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "ticketNumber" text NOT NULL,
  type text NOT NULL DEFAULT 'general',
  status text NOT NULL DEFAULT 'open',
  subject text NOT NULL,
  description text,
  "requesterId" text REFERENCES public.users(id) ON DELETE SET NULL,
  "requesterName" text,
  "requesterEmail" text,
  "requesterPhone" text,
  "companyId" text REFERENCES public.companies(id) ON DELETE SET NULL,
  "submittedFields" jsonb NOT NULL DEFAULT '{}'::jsonb,
  attachments jsonb NOT NULL DEFAULT '[]'::jsonb,
  "submittedAt" timestamptz NOT NULL DEFAULT now(),
  "createdAt" timestamptz NOT NULL DEFAULT now(),
  "updatedAt" timestamptz NOT NULL DEFAULT now(),
  metadata jsonb
);

CREATE TABLE IF NOT EXISTS public.support_request_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "supportRequestId" uuid NOT NULL REFERENCES public.support_requests(id) ON DELETE CASCADE,
  kind text NOT NULL,
  body text NOT NULL,
  "authorId" text REFERENCES public.users(id) ON DELETE SET NULL,
  "authorName" text,
  "createdAt" timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT support_request_messages_kind_check
    CHECK (kind IN ('internal_note', 'customer_reply', 'status_change'))
);

CREATE INDEX IF NOT EXISTS support_requests_status_idx ON public.support_requests (status);
CREATE INDEX IF NOT EXISTS support_requests_type_idx ON public.support_requests (type);
CREATE INDEX IF NOT EXISTS support_requests_company_idx ON public.support_requests ("companyId");
CREATE INDEX IF NOT EXISTS support_requests_submitted_at_idx ON public.support_requests ("submittedAt" DESC);
CREATE INDEX IF NOT EXISTS support_request_messages_request_idx
  ON public.support_request_messages ("supportRequestId", "createdAt" DESC);

ALTER TABLE public.support_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_request_messages ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.support_requests TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.support_request_messages TO authenticated;

CREATE POLICY "Admins manage support_requests"
  ON public.support_requests FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'))
  WITH CHECK (public.get_my_role() IN ('admin', 'manager'));

CREATE POLICY "Requestors read own support_requests"
  ON public.support_requests FOR SELECT TO authenticated
  USING ("requesterId"::text = auth.uid()::text);

CREATE POLICY "Requestors insert own support_requests"
  ON public.support_requests FOR INSERT TO authenticated
  WITH CHECK ("requesterId"::text = auth.uid()::text);

CREATE POLICY "Admins manage support_request_messages"
  ON public.support_request_messages FOR ALL TO authenticated
  USING (public.get_my_role() IN ('admin', 'manager'))
  WITH CHECK (public.get_my_role() IN ('admin', 'manager'));

CREATE POLICY "Requestors read own non-internal support messages"
  ON public.support_request_messages FOR SELECT TO authenticated
  USING (
    kind <> 'internal_note'
    AND EXISTS (
      SELECT 1
      FROM public.support_requests sr
      WHERE sr.id = "supportRequestId"
        AND sr."requesterId"::text = auth.uid()::text
    )
  );
