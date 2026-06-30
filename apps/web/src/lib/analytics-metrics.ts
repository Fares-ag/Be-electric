import { ACTIVE_WORK_ORDER_STATUSES } from '@/lib/work-order-detail';

export type AnalyticsWorkOrder = {
  id: string;
  status: string;
  priority: string;
  createdAt: string;
  completedAt: string | null;
  closedAt: string | null;
};

export type AnalyticsPmTask = {
  id: string;
  status: string;
  nextDueDate: string;
};

export type AnalyticsPmOccurrence = {
  status: string;
  dueDate: string;
};

export type ChartDatum = { name: string; value: number };

export type AnalyticsMetrics = {
  statusData: ChartDatum[];
  priorityData: ChartDatum[];
  pmStatusData: ChartDatum[];
  totalWorkOrders: number;
  openCount: number;
  inProgressCount: number;
  completedCount: number;
  completionRate: number;
  mttrDays: number;
  overduePmCount: number;
};

export function formatAnalyticsLabel(value: string): string {
  return value.replace(/([A-Z])/g, ' $1').trim();
}

/** PM schedule occurrence counts by derived status (upcoming / overdue / completed / cancelled). */
export function computePmOccurrenceStatusData(
  occurrences: AnalyticsPmOccurrence[],
  deriveStatus: (storedStatus: string, dueDate: string, todayIso?: string) => string,
  todayIsoDate = new Date().toISOString().slice(0, 10)
): ChartDatum[] {
  const counts = occurrences.reduce<Record<string, number>>((acc, row) => {
    const derived = deriveStatus(row.status, row.dueDate, todayIsoDate);
    acc[derived] = (acc[derived] ?? 0) + 1;
    return acc;
  }, {});
  return Object.entries(counts).map(([name, value]) => ({
    name: formatAnalyticsLabel(name),
    value,
  }));
}

export function computeAnalyticsMetrics(
  workOrders: AnalyticsWorkOrder[],
  pmTasks: AnalyticsPmTask[],
  todayIsoDate = new Date().toISOString().slice(0, 10)
): AnalyticsMetrics {
  const statusCounts = workOrders.reduce<Record<string, number>>((acc, wo) => {
    const s = wo.status ?? 'unknown';
    acc[s] = (acc[s] ?? 0) + 1;
    return acc;
  }, {});
  const statusData = Object.entries(statusCounts).map(([name, value]) => ({
    name: formatAnalyticsLabel(name),
    value,
  }));

  const priorityCounts = workOrders.reduce<Record<string, number>>((acc, wo) => {
    const p = wo.priority ?? 'medium';
    acc[p] = (acc[p] ?? 0) + 1;
    return acc;
  }, {});
  const priorityData = Object.entries(priorityCounts).map(([name, value]) => ({
    name: formatAnalyticsLabel(name),
    value,
  }));

  const pmStatusCounts = pmTasks.reduce<Record<string, number>>((acc, t) => {
    const s = t.status ?? 'pending';
    acc[s] = (acc[s] ?? 0) + 1;
    return acc;
  }, {});
  const pmStatusData = Object.entries(pmStatusCounts).map(([name, value]) => ({
    name: formatAnalyticsLabel(name),
    value,
  }));

  const totalWorkOrders = workOrders.length;
  const openCount = workOrders.filter((wo) => wo.status === 'open').length;
  const inProgressCount = workOrders.filter((wo) =>
    (ACTIVE_WORK_ORDER_STATUSES as readonly string[]).includes(wo.status)
  ).length;
  const completedCount = workOrders.filter((wo) =>
    ['completed', 'closed'].includes(wo.status)
  ).length;
  const nonCancelled = workOrders.filter((wo) => wo.status !== 'cancelled');
  const completionRate =
    nonCancelled.length > 0 ? Math.round((completedCount / nonCancelled.length) * 100) : 0;

  const completedWithDate = workOrders.filter(
    (wo) => (wo.completedAt || wo.closedAt) && wo.createdAt
  );
  const mttrMs =
    completedWithDate.length > 0
      ? completedWithDate.reduce((sum, wo) => {
          const end = wo.completedAt || wo.closedAt || wo.createdAt;
          return sum + (new Date(end).getTime() - new Date(wo.createdAt).getTime());
        }, 0) / completedWithDate.length
      : 0;
  const mttrDays = Math.round((mttrMs / (24 * 60 * 60 * 1000)) * 10) / 10;

  const overduePmCount = pmTasks.filter(
    (t) => t.status !== 'completed' && t.nextDueDate < todayIsoDate
  ).length;

  return {
    statusData,
    priorityData,
    pmStatusData,
    totalWorkOrders,
    openCount,
    inProgressCount,
    completedCount,
    completionRate,
    mttrDays,
    overduePmCount,
  };
}
