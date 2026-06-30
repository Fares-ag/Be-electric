import { STORAGE_BUCKETS } from '@/lib/storage-config';

function publicBase(bucket: string): string {
  const base = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (!base) return '';
  return `${base}/storage/v1/object/public/${bucket}`;
}

/** Resolve bucket from a relative storage path (not a full URL). */
export function resolveStorageBucketForPath(path: string): string {
  if (
    path.startsWith('work_orders/') ||
    path.startsWith('pm_occurrences/') ||
    path.startsWith('pm_tasks/')
  ) {
    return STORAGE_BUCKETS.primary;
  }
  return STORAGE_BUCKETS.legacy;
}

/** Build a public URL for a storage path or pass through absolute URLs unchanged. */
export function toPhotoUrl(raw: string): string {
  if (raw.startsWith('http')) return raw;
  const clean = raw.startsWith('/') ? raw.slice(1) : raw;
  const bucket = resolveStorageBucketForPath(clean);
  const base = publicBase(bucket);
  return base ? `${base}/${clean}` : raw;
}
