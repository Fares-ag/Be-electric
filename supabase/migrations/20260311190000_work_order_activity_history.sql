-- Add activity history for work orders (start, pause, resume, complete events from technician app)
ALTER TABLE public.work_orders
  ADD COLUMN IF NOT EXISTS "activityHistory" jsonb DEFAULT '[]'::jsonb;

COMMENT ON COLUMN public.work_orders."activityHistory" IS
  'Array of { at: iso8601, type: started|paused|resumed|completed, note?: string } from technician app';
