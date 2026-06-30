import { supabase } from './supabase';
import {
  STORAGE_BUCKETS,
  pmOccurrenceCompletionPath,
  pmTaskCompletionPath,
  requestPhotoStoragePath,
} from './storage-config';

const MAX_SIZE_MB = 2;
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

function validateImageFile(file: File): void {
  if (file.size > MAX_SIZE_MB * 1024 * 1024) {
    throw new Error(`Image must be under ${MAX_SIZE_MB}MB`);
  }
  if (!ALLOWED_TYPES.includes(file.type)) {
    throw new Error('Only JPEG, PNG, and WebP images are allowed');
  }
}

function fileExtension(file: File): string {
  return file.name.split('.').pop() || 'jpg';
}

async function uploadToBucket(path: string, file: File): Promise<string> {
  const { error } = await supabase.storage.from(STORAGE_BUCKETS.primary).upload(path, file, {
    cacheControl: '3600',
    upsert: false,
  });
  if (error) throw error;

  const { data } = supabase.storage.from(STORAGE_BUCKETS.primary).getPublicUrl(path);
  return data.publicUrl;
}

export async function uploadWorkOrderPhoto(
  file: File,
  workOrderId: string,
  type: 'request' | 'completion',
  index = 0
): Promise<string> {
  validateImageFile(file);
  const ext = fileExtension(file);
  const path =
    type === 'request'
      ? requestPhotoStoragePath(workOrderId, index, ext)
      : `work_orders/completion_photos/completion_${workOrderId}_${Date.now()}_${index}.${ext}`;

  return uploadToBucket(path, file);
}

export async function uploadRequestPhotos(
  files: File[],
  workOrderId: string
): Promise<string[]> {
  const urls: string[] = [];
  for (let i = 0; i < files.length; i++) {
    const url = await uploadWorkOrderPhoto(files[i], workOrderId, 'request', i);
    urls.push(url);
  }
  return urls;
}

export async function uploadPmOccurrenceCompletionPhoto(
  file: File,
  occurrenceId: string
): Promise<string> {
  validateImageFile(file);
  const ext = fileExtension(file);
  return uploadToBucket(pmOccurrenceCompletionPath(occurrenceId, ext), file);
}

export async function uploadPmTaskCompletionPhoto(file: File, taskId: string): Promise<string> {
  validateImageFile(file);
  const ext = fileExtension(file);
  return uploadToBucket(pmTaskCompletionPath(taskId, ext), file);
}
