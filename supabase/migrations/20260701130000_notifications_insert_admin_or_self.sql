-- Batch A: Restrict notification INSERT to admin/manager or self-target only.
-- Preserves React admin parts-request approve/reject (insert for requestor userId).
-- Reversible: restore policy from 20250311120001_notifications_rls.sql

DROP POLICY IF EXISTS "Authenticated can insert notifications" ON notifications;

CREATE POLICY "Authenticated can insert notifications"
  ON notifications FOR INSERT TO authenticated
  WITH CHECK (
    public.get_my_role() IN ('admin', 'manager')
    OR "userId"::text = auth.uid()::text
  );

NOTIFY pgrst, 'reload schema';
