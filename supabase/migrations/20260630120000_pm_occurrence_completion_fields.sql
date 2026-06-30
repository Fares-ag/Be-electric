-- PM occurrence completion, cancellation, and audit fields (admin web + future Flutter).

ALTER TABLE public.pm_task_occurrences
  ADD COLUMN IF NOT EXISTS "completedById" text REFERENCES public.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS "completionNotes" text,
  ADD COLUMN IF NOT EXISTS "cancelledAt" timestamptz,
  ADD COLUMN IF NOT EXISTS "cancelledById" text REFERENCES public.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS "cancelReason" text;

CREATE INDEX IF NOT EXISTS pm_task_occurrences_upcoming_idx
  ON public.pm_task_occurrences ("dueDate")
  WHERE status NOT IN ('completed', 'cancelled');
