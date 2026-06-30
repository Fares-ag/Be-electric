import { ACTIVE_WORK_ORDER_STATUSES } from '@/lib/work-order-detail';
import { supabase } from '@/lib/supabase';
import { fetchAllPages } from '@/lib/supabase-pagination';

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

const ANALYTICS_SELECT = 'id, status, priority, createdAt, completedAt, closedAt';

function applyStatusFilter<T extends { in: (col: string, vals: string[]) => T; eq: (col: string, val: string) => T }>(
  q: T,
  statusFilter?: string
): T {
  if (statusFilter === 'active') {
    return q.in('status', [...ACTIVE_WORK_ORDER_STATUSES]);
  }
  if (statusFilter) {
    return q.eq('status', statusFilter);
  }
  return q;
}

export async function fetchWorkOrdersList(statusFilter?: string): Promise<WorkOrderListRow[]> {
  return fetchAllPages<WorkOrderListRow>(async (from, to) => {
    let q = supabase
      .from('work_orders')
      .select(LIST_SELECT)
      .order('createdAt', { ascending: false })
      .range(from, to);
    q = applyStatusFilter(q, statusFilter);
    const { data, error } = await q;
    return { data: data as WorkOrderListRow[] | null, error: error ? new Error(error.message) : null };
  });
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
  return fetchAllPages<Record<string, unknown>>(async (from, to) => {
    let q = supabase
      .from('work_orders')
      .select(EXPORT_SELECT)
      .order('createdAt', { ascending: false })
      .range(from, to);
    q = applyStatusFilter(q, statusFilter);
    const { data, error } = await q;
    return { data: data as Record<string, unknown>[] | null, error: error ? new Error(error.message) : null };
  });
}

export type AnalyticsWorkOrderRow = {
  id: string;
  status: string;
  priority: string;
  createdAt: string;
  completedAt: string | null;
  closedAt: string | null;
};

export async function fetchWorkOrdersForAnalytics(): Promise<AnalyticsWorkOrderRow[]> {
  return fetchAllPages<AnalyticsWorkOrderRow>(async (from, to) => {
    const { data, error } = await supabase
      .from('work_orders')
      .select(ANALYTICS_SELECT)
      .range(from, to);
    return {
      data: data as AnalyticsWorkOrderRow[] | null,
      error: error ? new Error(error.message) : null,
    };
  });
}

export function workOrdersListQueryKey(statusFilter?: string) {
  return statusFilter ? (['work-orders', statusFilter] as const) : (['work-orders', undefined] as const);
}
