-- Batch B: Requestor direct UPDATE field guard (BEFORE UPDATE trigger).
-- Preserves Flutter reopen flow (docs/WORK_ORDER_REOPEN.md): status -> reopened, clear assignees/timestamps.
-- Blocks privilege escalation via direct UPDATE (assignees, completion fields, status spoofing).
-- Admins, managers, and assigned technicians are unaffected.
-- Reversible: DROP TRIGGER + DROP FUNCTION.

CREATE OR REPLACE FUNCTION public.enforce_requestor_work_order_update()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_role text := public.get_my_role();
  v_uid text := auth.uid()::text;
  v_is_reopen boolean := false;
BEGIN
  IF v_uid IS NULL THEN
    RETURN NEW;
  END IF;

  IF v_role IN ('admin', 'manager') THEN
    RETURN NEW;
  END IF;

  IF v_uid = ANY(COALESCE(OLD."assignedTechnicianIds", ARRAY[]::text[])) THEN
    RETURN NEW;
  END IF;

  IF OLD."requestorId"::text IS DISTINCT FROM v_uid THEN
    RETURN NEW;
  END IF;

  v_is_reopen := OLD.status IN ('completed', 'closed', 'cancelled')
    AND NEW.status = 'reopened';

  IF NEW.status IS DISTINCT FROM OLD.status AND NOT v_is_reopen THEN
    RAISE EXCEPTION 'Requestors may only reopen completed, closed, or cancelled work orders to status reopened';
  END IF;

  IF COALESCE(array_length(NEW."assignedTechnicianIds", 1), 0) > 0 THEN
    RAISE EXCEPTION 'Requestors cannot assign technicians';
  END IF;

  IF NEW."primaryTechnicianId" IS NOT NULL THEN
    RAISE EXCEPTION 'Requestors cannot set primary technician';
  END IF;

  IF NEW."requestorId" IS DISTINCT FROM OLD."requestorId" THEN
    RAISE EXCEPTION 'Requestors cannot change requestorId';
  END IF;

  IF NEW."completionPhotoPath" IS DISTINCT FROM OLD."completionPhotoPath"
     OR NEW."beforePhotoPath" IS DISTINCT FROM OLD."beforePhotoPath"
     OR NEW."afterPhotoPath" IS DISTINCT FROM OLD."afterPhotoPath"
     OR NEW."correctiveActions" IS DISTINCT FROM OLD."correctiveActions"
     OR NEW."recommendations" IS DISTINCT FROM OLD."recommendations"
     OR NEW."technicianNotes" IS DISTINCT FROM OLD."technicianNotes"
     OR NEW."technicianSignature" IS DISTINCT FROM OLD."technicianSignature"
     OR NEW."requestorSignature" IS DISTINCT FROM OLD."requestorSignature"
     OR NEW."customerSignature" IS DISTINCT FROM OLD."customerSignature"
  THEN
    RAISE EXCEPTION 'Requestors cannot modify technician completion fields';
  END IF;

  IF NEW."actualCost" IS DISTINCT FROM OLD."actualCost"
     OR NEW."estimatedCost" IS DISTINCT FROM OLD."estimatedCost"
     OR NEW."laborCost" IS DISTINCT FROM OLD."laborCost"
     OR NEW."partsCost" IS DISTINCT FROM OLD."partsCost"
     OR NEW."totalCost" IS DISTINCT FROM OLD."totalCost"
     OR NEW."laborHours" IS DISTINCT FROM OLD."laborHours"
     OR NEW."technicianEffortMinutes" IS DISTINCT FROM OLD."technicianEffortMinutes"
  THEN
    RAISE EXCEPTION 'Requestors cannot modify cost or labor fields';
  END IF;

  IF NOT v_is_reopen THEN
    IF NEW."assignedAt" IS DISTINCT FROM OLD."assignedAt"
       OR NEW."startedAt" IS DISTINCT FROM OLD."startedAt"
       OR NEW."completedAt" IS DISTINCT FROM OLD."completedAt"
       OR NEW."closedAt" IS DISTINCT FROM OLD."closedAt"
    THEN
      RAISE EXCEPTION 'Requestors cannot modify assignment or completion timestamps';
    END IF;

    IF NEW."isPaused" IS DISTINCT FROM OLD."isPaused"
       OR NEW."pausedAt" IS DISTINCT FROM OLD."pausedAt"
       OR NEW."pauseReason" IS DISTINCT FROM OLD."pauseReason"
       OR NEW."resumedAt" IS DISTINCT FROM OLD."resumedAt"
       OR NEW."pauseHistory" IS DISTINCT FROM OLD."pauseHistory"
    THEN
      RAISE EXCEPTION 'Requestors cannot modify pause state';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS enforce_requestor_work_order_update ON public.work_orders;
CREATE TRIGGER enforce_requestor_work_order_update
  BEFORE UPDATE ON public.work_orders
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_requestor_work_order_update();

NOTIFY pgrst, 'reload schema';
