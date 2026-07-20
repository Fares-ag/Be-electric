-- RC1 P0-1: Allow requestor sign-off (requestorSignature + optional close) without weakening escalation guards.
-- Fixes over-restrictive Batch B trigger that blocked FLUTTER_USER_FLOW.md §4.3 sign-off.
-- Reversible: re-apply function from 20260702120000_requestor_work_order_update_guard.sql

CREATE OR REPLACE FUNCTION public.enforce_requestor_work_order_update()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_role text := public.get_my_role();
  v_uid text := auth.uid()::text;
  v_is_reopen boolean := false;
  v_is_sign_off boolean := false;
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

  v_is_sign_off := OLD.status IN ('completed', 'inProgress')
    AND NEW."requestorSignature" IS NOT NULL
    AND (
      OLD."requestorSignature" IS NULL
      OR NEW."requestorSignature" IS DISTINCT FROM OLD."requestorSignature"
    );

  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF v_is_reopen THEN
      NULL;
    ELSIF v_is_sign_off AND OLD.status IN ('completed', 'inProgress') AND NEW.status = 'closed' THEN
      NULL;
    ELSE
      RAISE EXCEPTION 'Requestors may only reopen to reopened or close a completed work order during sign-off';
    END IF;
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

  IF v_is_sign_off THEN
    IF NEW."completionPhotoPath" IS DISTINCT FROM OLD."completionPhotoPath"
       OR NEW."beforePhotoPath" IS DISTINCT FROM OLD."beforePhotoPath"
       OR NEW."afterPhotoPath" IS DISTINCT FROM OLD."afterPhotoPath"
       OR NEW."correctiveActions" IS DISTINCT FROM OLD."correctiveActions"
       OR NEW."recommendations" IS DISTINCT FROM OLD."recommendations"
       OR NEW."technicianNotes" IS DISTINCT FROM OLD."technicianNotes"
       OR NEW."technicianSignature" IS DISTINCT FROM OLD."technicianSignature"
    THEN
      RAISE EXCEPTION 'Requestors cannot modify technician completion fields during sign-off';
    END IF;
  ELSE
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
      RAISE EXCEPTION 'Requestors cannot modify completion or signature fields';
    END IF;
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

  IF v_is_reopen THEN
    NULL;
  ELSIF v_is_sign_off THEN
    IF NEW."assignedAt" IS DISTINCT FROM OLD."assignedAt"
       OR NEW."startedAt" IS DISTINCT FROM OLD."startedAt"
       OR NEW."completedAt" IS DISTINCT FROM OLD."completedAt"
    THEN
      RAISE EXCEPTION 'Requestors cannot modify work timestamps during sign-off';
    END IF;
    IF NEW."closedAt" IS DISTINCT FROM OLD."closedAt"
       AND NEW.status IS DISTINCT FROM 'closed'
    THEN
      RAISE EXCEPTION 'Requestors may only set closedAt when closing the work order';
    END IF;
  ELSE
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

NOTIFY pgrst, 'reload schema';
