-- Create storage bucket for work order / request photos (request form and PM task completion).
-- If the bucket already exists (e.g. created in Dashboard), the insert is skipped.

INSERT INTO storage.buckets (id, name, public)
VALUES ('work-order-photos', 'work-order-photos', true)
ON CONFLICT (id) DO NOTHING;

-- In Supabase Dashboard → Storage → work-order-photos: ensure "Public bucket" is on
-- and that authenticated users are allowed to upload (Storage policies).
