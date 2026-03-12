-- Notifications: allow app to create notifications for users; users read/update own
GRANT SELECT, INSERT, UPDATE ON notifications TO authenticated;

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users can read their own notifications
DROP POLICY IF EXISTS "Users can read own notifications" ON notifications;
CREATE POLICY "Users can read own notifications"
  ON notifications FOR SELECT TO authenticated
  USING ("userId"::text = auth.uid()::text);

-- Authenticated users can insert (e.g. admin creating notification for requestor)
DROP POLICY IF EXISTS "Authenticated can insert notifications" ON notifications;
CREATE POLICY "Authenticated can insert notifications"
  ON notifications FOR INSERT TO authenticated
  WITH CHECK (true);

-- Users can update their own (e.g. mark as read)
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE TO authenticated
  USING ("userId"::text = auth.uid()::text);
