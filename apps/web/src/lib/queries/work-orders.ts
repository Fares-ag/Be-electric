import { supabase } from '@/lib/supabase';

export const WORK_ORDERS_LIST_QUERY_KEY = ['work-orders'] as const;

export type WorkOrderListRow = {
  id: string;
  ticketNumber: string | null;
  problemDescription: string | null;
  status: string | null;
  priority: string | null;
  createdAt: string | null;
  requestorName: string | null;
  requestorId: string | null;
  assignedTechnicianIds: string[] | null;
  updatedAt?: string | null;
  completedAt?: string | null;
};

const LIST_SELECT =
  'id, ticketNumber, problemDescription, status, priority, createdAt, updatedAt, completedAt, requestorName, requestorId, assignedTechnicianIds';

const EXPORT_SELECT =
  'ticketNumber, status, priority, problemDescription, requestorName, createdAt, updatedAt, completedAt';

export async function fetchWorkOrdersList(statusFilter?: string): Promise<WorkOrderListRow[]> {
  let q = supabase.from('work_orders').select(LIST_SELECT).order('createdAt', { ascending: false });
  if (statusFilter === 'active') {
    q = q.in('status', ['assigned', 'inProgress']);
  } else if (statusFilter) {
    q = q.eq('status', statusFilter);
  }
  const { data, error } = await q;
  if (error) throw error;
  return (data ?? []) as WorkOrderListRow[];
}

export const WORK_ORDER_EXPORT_HEADERS = [
  'ticketNumber',
  'status',
  'priority',
  'problemDescription',
  'requestorName',
  'createdAt',
  'updatedAt',
  'completedAt',
] as const;

export async function fetchWorkOrdersForExport(statusFilter?: string): Promise<Record<string, unknown>[]> {
  let q = supabase.from('work_orders').select(EXPORT_SELECT).order('createdAt', { ascending: false });
  if (statusFilter === 'active') {
    q = q.in('status', ['assigned', 'inProgress']);
  } else if (statusFilter) {
    q = q.eq('status', statusFilter);
  }
  const { data, error } = await q;
  if (error) throw error;
  return (data ?? []) as Record<string, unknown>[];
}

export function workOrdersListQueryKey(statusFilter?: string) {
  return statusFilter ? (['work-orders', statusFilter] as const) : (['work-orders', undefined] as const);
}
