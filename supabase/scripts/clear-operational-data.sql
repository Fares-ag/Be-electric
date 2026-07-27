-- One-off: clear operational CMMS data; KEEP companies, assets (chargers), users, admin_users.
-- Approved: keep users, reset asset maintenance dates, production linked DB.
-- Run manually via scripts/clear-operational-data.mjs (preferred) or SQL editor with service role.
-- NOT a migration — do not commit as schema change.

BEGIN;

-- Child tables first (FK-safe order)
DELETE FROM public.pm_task_occurrences;
DELETE FROM public.pm_schedules;
DELETE FROM public.pm_tasks;
DELETE FROM public.parts_requests;
DELETE FROM public.work_orders;
DELETE FROM public.support_requests;
DELETE FROM public.notifications;
DELETE FROM public.purchase_orders;
DELETE FROM public.inventory_items;
DELETE FROM public.vendors;
DELETE FROM public.audit_events;
DELETE FROM public.escalation_events;
DELETE FROM public.workflows;

-- Reset ops-derived fields on preserved chargers
UPDATE public.assets
SET
  "lastMaintenanceDate" = NULL,
  "nextMaintenanceDate" = NULL,
  "updatedAt" = now();

COMMIT;
