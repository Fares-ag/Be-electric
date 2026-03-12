import { supabase } from './supabase';

const BUCKET = 'work-order-photos';
const MAX_SIZE_MB = 2;
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

export async function uploadWorkOrderPhoto(
  file: File,
  workOrderId: string,
  type: 'request' | 'completion'
): Promise<string> {
  if (file.size > MAX_SIZE_MB * 1024 * 1024) {
    throw new Error(`Image must be under ${MAX_SIZE_MB}MB`);
  }
  if (!ALLOWED_TYPES.includes(file.type)) {
    throw new Error('Only JPEG, PNG, and WebP images are allowed');
  }
  const ext = file.name.split('.').pop() || 'jpg';
  const path = `${workOrderId}/${type}/${Date.now()}_${Math.random().toString(36).slice(2)}.${ext}`;

  const { error } = await supabase.storage.from(BUCKET).upload(path, file, {
    cacheControl: '3600',
    upsert: false,
  });
  if (error) throw error;

  const { data } = supabase.storage.from(BUCKET).getPublicUrl(path);
  return data.publicUrl;
}

export async function uploadRequestPhotos(
  files: File[],
  workOrderId: string
): Promise<string[]> {
  const urls: string[] = [];
  for (const file of files) {
    const url = await uploadWorkOrderPhoto(file, workOrderId, 'request');
    urls.push(url);
  }
  return urls;
}

export async function uploadPmTaskCompletionPhoto(file: File, taskId: string): Promise<string> {
  if (file.size > MAX_SIZE_MB * 1024 * 1024) {
    throw new Error(`Image must be under ${MAX_SIZE_MB}MB`);
  }
  if (!ALLOWED_TYPES.includes(file.type)) {
    throw new Error('Only JPEG, PNG, and WebP images are allowed');
  }
  const ext = file.name.split('.').pop() || 'jpg';
  const path = `pm-tasks/${taskId}/completion/${Date.now()}_${Math.random().toString(36).slice(2)}.${ext}`;

  const { error } = await supabase.storage.from(BUCKET).upload(path, file, {
    cacheControl: '3600',
    upsert: false,
  });
  if (error) throw error;

  const { data } = supabase.storage.from(BUCKET).getPublicUrl(path);
  return data.publicUrl;
}
