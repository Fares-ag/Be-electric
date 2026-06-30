-- Primary storage bucket used by Flutter apps (handbook: bucket "files").
-- Legacy work-order-photos bucket remains for older web uploads.

INSERT INTO storage.buckets (id, name, public)
VALUES ('files', 'files', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Authenticated can upload files" ON storage.objects;
CREATE POLICY "Authenticated can upload files"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'files');

DROP POLICY IF EXISTS "Public read files" ON storage.objects;
CREATE POLICY "Public read files"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'files');

NOTIFY pgrst, 'reload schema';
