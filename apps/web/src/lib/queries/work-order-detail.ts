import { supabase } from '@/lib/supabase';
import type { WorkOrderDetail } from '@/lib/work-order-detail';

export const WORK_ORDER_DETAIL_QUERY_KEY = (id: string) => ['work-order', id] as const;

const DETAIL_SELECT = [
  'id',
  'ticketNumber',
  'idempotencyKey',
  'status',
  'priority',
  'category',
  'problemDescription',
  'requestorId',
  'requestorName',
  'assetId',
  'location',
  'companyId',
  'primaryTechnicianId',
  'assignedTechnicianId',
  'assignedTechnicianIds',
  'assignedAt',
  'technicianEffortMinutes',
  'createdAt',
  'updatedAt',
  'startedAt',
  'completedAt',
  'closedAt',
  'nextMaintenanceDate',
  'notes',
  'correctiveActions',
  'recommendations',
  'technicianNotes',
  'photoPath',
  'completionPhotoPath',
  'beforePhotoPath',
  'afterPhotoPath',
  'requestorSignature',
  'technicianSignature',
  'customerName',
  'customerPhone',
  'customerEmail',
  'customerSignature',
  'laborCost',
  'partsCost',
  'totalCost',
  'estimatedCost',
  'actualCost',
  'laborHours',
  'partsUsed',
  'isPaused',
  'pausedAt',
  'pauseReason',
  'resumedAt',
  'pauseHistory',
  'isOffline',
  'lastSyncedAt',
  'activityHistory',
  'metadata',
  'asset:assets(name,location,manufacturer)',
  'company:companies(name)',
].join(',');

export async function fetchWorkOrderDetail(id: string): Promise<WorkOrderDetail | null> {
  const { data, error } = await supabase.from('work_orders').select(DETAIL_SELECT).eq('id', id).single();
  if (error) throw error;
  return data as unknown as WorkOrderDetail | null;
}
