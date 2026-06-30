-- RC1 P0-1: Manual trigger verification (run on staging, not production).
-- Requires test auth users: requestor, technician (assigned), admin.
-- Replace placeholders before running.

-- Verify RC1 sign-off fix is applied
SELECT pg_get_functiondef('public.enforce_requestor_work_order_update()'::regprocedure) LIKE '%v_is_sign_off%'
  AS rc1_signoff_fix_applied;

-- ALLOW: sign-off (run as requestor JWT)
/*
UPDATE work_orders SET
  "requestorSignature" = 'data:image/png;base64,TEST',
  status = 'closed',
  "closedAt" = now(),
  "updatedAt" = now()
WHERE id = '<wo-id>' AND "requestorId" = auth.uid()::text;
*/

-- DENY: assign technicians as requestor
/*
UPDATE work_orders SET
  "assignedTechnicianIds" = ARRAY['<tech-id>']
WHERE id = '<wo-id>' AND "requestorId" = auth.uid()::text;
*/

-- ALLOW: reopen
/*
UPDATE work_orders SET
  status = 'reopened',
  "assignedTechnicianIds" = '{}',
  "primaryTechnicianId" = NULL,
  "assignedAt" = NULL,
  "startedAt" = NULL,
  "completedAt" = NULL,
  "closedAt" = NULL,
  metadata = COALESCE(metadata, '{}'::jsonb) || '{"reopenReason":"RC1 staging test"}'::jsonb,
  "updatedAt" = now()
WHERE id = '<wo-id>' AND status IN ('completed','closed','cancelled');
*/
