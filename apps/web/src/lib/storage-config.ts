/** Primary bucket shared with Flutter apps; legacy bucket kept for older web uploads. */
export const STORAGE_BUCKETS = {
  primary: 'files',
  legacy: 'work-order-photos',
} as const;

/** Handbook path: work_orders/request_photos/request_{workOrderId}_{timestamp}_{index}.jpg */
export function requestPhotoStoragePath(
  workOrderId: string,
  index: number,
  ext: string
): string {
  return `work_orders/request_photos/request_${workOrderId}_${Date.now()}_${index}.${ext}`;
}

export function completionPhotoStoragePath(
  workOrderId: string,
  index: number,
  ext: string
): string {
  return `work_orders/completion_photos/completion_${workOrderId}_${Date.now()}_${index}.${ext}`;
}

export function pmOccurrenceCompletionPath(occurrenceId: string, ext: string): string {
  return `pm_occurrences/${occurrenceId}/completion/${Date.now()}_${Math.random().toString(36).slice(2)}.${ext}`;
}

export function pmTaskCompletionPath(taskId: string, ext: string): string {
  return `pm_tasks/${taskId}/completion/${Date.now()}_${Math.random().toString(36).slice(2)}.${ext}`;
}
