'use client';

import { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import Link from 'next/link';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { LoadingSpinner, PageHeader, QueryErrorState } from '@/components/ui/PageStates';
import {
  Wrench,
  AlertTriangle,
  Package,
  Activity,
  LifeBuoy,
  CalendarClock,
  ArrowRight,
  CheckCircle2,
} from 'lucide-react';
import {
  ACTIVE_WORK_ORDER_STATUSES,
  parseActivityHistory,
  type WorkOrderActivityEntry,
} from '@/lib/work-order-detail';
import { fetchDashboardAttentionItems } from '@/lib/queries/dashboard-attention';
import {
  countOverduePmOccurrences,
  countUpcomingPmOccurrences,
  fetchRecentCompletedPmOccurrences,
} from '@/lib/queries/pm-schedules';
import { DismissibleHint } from '@/components/ui/DismissibleHint';
import { cn } from '@/lib/utils';

type WorkOrderRow = {
  id: string;
  ticketNumber: string;
  status: string;
  createdAt: string;
  updatedAt: string;
  activityHistory?: WorkOrderActivityEntry[] | string | null;
};

type FeedItem =
  | { kind: 'wo_created'; at: string; id: string; ticketNumber: string; status: string }
  | { kind: 'wo_activity'; at: string; id: string; ticketNumber: string; type: string; note?: string }
  | {
      kind: 'pm_occ_completed';
      at: string;
      occurrenceId: string;
      scheduleId: string;
      taskName: string;
    };

type KpiCard = {
  label: string;
  value: number;
  href: string;
  icon: typeof Wrench;
  iconClassName: string;
  hint?: string;
};

export default function DashboardPage() {
  const summaryQuery = useQuery({
    queryKey: ['work-orders-summary'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('work_orders')
        .select('id, status')
        .in('status', ['open', ...ACTIVE_WORK_ORDER_STATUSES]);
      if (error) throw error;
      return (data ?? []) as { id: string; status: string }[];
    },
  });

  const pmOverdueQuery = useQuery({
    queryKey: ['pm-occurrences-overdue'],
    staleTime: 60 * 1000,
    queryFn: () => countOverduePmOccurrences(),
  });

  const pmUpcomingQuery = useQuery({
    queryKey: ['pm-occurrences-upcoming-count'],
    staleTime: 60 * 1000,
    queryFn: () => countUpcomingPmOccurrences(),
  });

  const inventoryQuery = useQuery({
    queryKey: ['inventory-low-stock'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('inventory_items')
        .select('id, name, currentStock, minStock');
      if (error) throw error;
      return (data ?? []) as { currentStock: number; minStock: number | null }[];
    },
  });

  const supportQuery = useQuery({
    queryKey: ['support-requests-submitted-count'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { count, error } = await supabase
        .from('support_requests')
        .select('id', { count: 'exact', head: true })
        .eq('status', 'submitted');
      if (error) throw error;
      return count ?? 0;
    },
  });

  const attentionQuery = useQuery({
    queryKey: ['dashboard-attention'],
    staleTime: 60 * 1000,
    queryFn: () => fetchDashboardAttentionItems(8),
  });

  const activityQuery = useQuery({
    queryKey: ['dashboard-recent-activity'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      const [woRes, pmRes] = await Promise.all([
        supabase
          .from('work_orders')
          .select('id, ticketNumber, status, createdAt, updatedAt, activityHistory')
          .order('updatedAt', { ascending: false })
          .limit(25),
        fetchRecentCompletedPmOccurrences(15),
      ]);
      if (woRes.error) throw woRes.error;
      return {
        workOrders: (woRes.data ?? []) as WorkOrderRow[],
        pmOccurrences: pmRes,
      };
    },
  });

  const isLoading =
    summaryQuery.isLoading ||
    pmOverdueQuery.isLoading ||
    pmUpcomingQuery.isLoading ||
    inventoryQuery.isLoading ||
    supportQuery.isLoading ||
    attentionQuery.isLoading ||
    activityQuery.isLoading;
  const queryError =
    summaryQuery.error ??
    pmOverdueQuery.error ??
    pmUpcomingQuery.error ??
    inventoryQuery.error ??
    supportQuery.error ??
    attentionQuery.error ??
    activityQuery.error;

  const recentActivity = useMemo(() => {
    const items: FeedItem[] = [];
    const raw = activityQuery.data;
    if (!raw) return items;

    for (const wo of raw.workOrders) {
      items.push({
        kind: 'wo_created',
        at: wo.createdAt,
        id: wo.id,
        ticketNumber: wo.ticketNumber,
        status: wo.status,
      });
      const history = parseActivityHistory(wo.activityHistory);
      for (const entry of history) {
        if (entry?.at && entry?.type) {
          items.push({
            kind: 'wo_activity',
            at: entry.at,
            id: wo.id,
            ticketNumber: wo.ticketNumber,
            type: entry.type,
            note: entry.note,
          });
        }
      }
    }

    for (const pm of raw.pmOccurrences) {
      if (pm.completedAt) {
        items.push({
          kind: 'pm_occ_completed',
          at: pm.completedAt,
          occurrenceId: pm.id,
          scheduleId: pm.scheduleId,
          taskName: pm.taskName,
        });
      }
    }

    items.sort((a, b) => new Date(b.at).getTime() - new Date(a.at).getTime());
    return items.slice(0, 25);
  }, [activityQuery.data]);

  const workOrders = summaryQuery.data;
  const openCount = workOrders?.filter((wo) => wo.status === 'open').length ?? 0;
  const inProgressCount =
    workOrders?.filter((wo) =>
      (ACTIVE_WORK_ORDER_STATUSES as readonly string[]).includes(wo.status)
    ).length ?? 0;
  const activeWorkOrders = openCount + inProgressCount;
  const overdueCount = pmOverdueQuery.data ?? 0;
  const upcomingCount = pmUpcomingQuery.data ?? 0;
  const lowStockCount =
    inventoryQuery.data?.filter((i) => i.minStock != null && i.currentStock <= i.minStock).length ??
    0;
  const supportSubmittedCount = supportQuery.data ?? 0;
  const attentionItems = attentionQuery.data ?? [];

  const kpiCards: KpiCard[] = [
    {
      label: 'Active work orders',
      value: activeWorkOrders,
      href: '/work-orders?status=active',
      icon: Wrench,
      iconClassName: 'bg-blue-600 text-white',
      hint: `${openCount} open · ${inProgressCount} in progress`,
    },
    {
      label: 'Overdue PM',
      value: overdueCount,
      href: '/pm-schedules?status=overdue',
      icon: AlertTriangle,
      iconClassName: 'bg-red-600 text-white',
      hint: 'Past due and not completed',
    },
    {
      label: 'Upcoming PM',
      value: upcomingCount,
      href: '/pm-schedules?view=upcoming',
      icon: CalendarClock,
      iconClassName: 'bg-blue-600 text-white',
      hint: 'Due today or later',
    },
    {
      label: 'Support inbox',
      value: supportSubmittedCount,
      href: '/support-requests?status=submitted',
      icon: LifeBuoy,
      iconClassName: 'bg-teal-600 text-white',
      hint: 'Awaiting staff review',
    },
    {
      label: 'Low stock',
      value: lowStockCount,
      href: '/inventory?filter=lowStock',
      icon: Package,
      iconClassName: 'bg-amber-600 text-white',
      hint: 'At or below minimum',
    },
  ];

  function labelFor(item: FeedItem): string {
    switch (item.kind) {
      case 'wo_created':
        return `Work order #${item.ticketNumber} created`;
      case 'wo_activity':
        return `Work order #${item.ticketNumber} — ${item.type}${item.note ? `: ${item.note}` : ''}`;
      case 'pm_occ_completed':
        return `PM "${item.taskName}" occurrence completed`;
      default:
        return '';
    }
  }

  function hrefFor(item: FeedItem): string {
    switch (item.kind) {
      case 'wo_created':
      case 'wo_activity':
        return `/work-orders/${item.id}`;
      case 'pm_occ_completed':
        return `/pm-schedules/${item.scheduleId}/occurrences/${item.occurrenceId}`;
      default:
        return '#';
    }
  }

  function feedItemKey(item: FeedItem, index: number): string {
    if (item.kind === 'pm_occ_completed') {
      return `${item.kind}-${item.occurrenceId}-${item.at}-${index}`;
    }
    return `${item.kind}-${item.id}-${item.at}-${index}`;
  }

  function attentionIcon(kind: string) {
    switch (kind) {
      case 'pm_overdue':
        return AlertTriangle;
      case 'support_submitted':
        return LifeBuoy;
      default:
        return Wrench;
    }
  }

  function attentionIconClass(kind: string) {
    switch (kind) {
      case 'pm_overdue':
        return 'bg-red-100 text-red-700';
      case 'support_submitted':
        return 'bg-teal-100 text-teal-800';
      default:
        return 'bg-blue-100 text-blue-700';
    }
  }

  if (isLoading) return <LoadingSpinner label="Loading dashboard" />;

  if (queryError) {
    return (
      <QueryErrorState
        title="Failed to load dashboard"
        message={queryError instanceof Error ? queryError.message : String(queryError)}
        onRetry={() => {
          summaryQuery.refetch();
          pmOverdueQuery.refetch();
          pmUpcomingQuery.refetch();
          inventoryQuery.refetch();
          supportQuery.refetch();
          attentionQuery.refetch();
          activityQuery.refetch();
        }}
      />
    );
  }

  return (
    <div className="space-y-6 sm:space-y-8">
      <PageHeader
        title="Command center"
        description="What needs attention now — work orders, preventive maintenance, and support."
        actions={
          <Link
            href="/analytics"
            className="text-sm font-medium text-primary underline underline-offset-2 hover:text-primary-hover"
          >
            View analytics
          </Link>
        }
      />

      <DismissibleHint hintKey="dashboard-command-center" title="Using the command center">
        <p>
          KPI cards link straight to filtered lists. Start with <strong className="font-medium text-foreground">Needs attention</strong> for overdue PM, open work orders, and new support — then use the sidebar groups to drill into operations, inventory, or organization.
        </p>
      </DismissibleHint>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">
        {kpiCards.map(({ href, label, value, icon: Icon, iconClassName, hint }) => (
          <Link key={href} href={href} className="group block">
            <Card className="h-full cursor-pointer transition-all duration-200 hover:border-primary/40 hover:shadow-sm">
              <CardHeader className="flex flex-row items-start justify-between gap-2 pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">{label}</CardTitle>
                <span
                  className={cn(
                    'flex h-9 w-9 shrink-0 items-center justify-center rounded-lg',
                    iconClassName
                  )}
                >
                  <Icon className="h-4 w-4" aria-hidden />
                </span>
              </CardHeader>
              <CardContent>
                <p className="font-display text-2xl font-bold text-foreground">{value}</p>
                {hint ? <p className="mt-1 text-xs text-muted-foreground">{hint}</p> : null}
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>

      <p className="text-xs text-muted-foreground">
        <strong className="font-medium text-foreground">PM tip:</strong> Overdue means the due date
        has passed. Upcoming includes today and all future due dates that are still open.
      </p>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between gap-2">
          <div>
            <CardTitle>Needs attention</CardTitle>
            <p className="mt-1 text-sm text-muted-foreground">
              Overdue PM, open work orders, and new support requests
            </p>
          </div>
          <Link
            href="/pm-schedules?view=upcoming"
            className="hidden text-sm font-medium text-primary hover:underline sm:inline"
          >
            All upcoming PM
          </Link>
        </CardHeader>
        <CardContent>
          {attentionItems.length === 0 ? (
            <div className="flex items-center gap-3 rounded-lg border border-border bg-muted/30 px-4 py-6">
              <CheckCircle2 className="h-8 w-8 shrink-0 text-green-600" aria-hidden />
              <div>
                <p className="font-medium text-foreground">All clear for now</p>
                <p className="text-sm text-muted-foreground">
                  No overdue PM, open work orders, or new support tickets in the queue.
                </p>
              </div>
            </div>
          ) : (
            <ul className="divide-y divide-border">
              {attentionItems.map((item) => {
                const Icon = attentionIcon(item.kind);
                return (
                  <li key={`${item.kind}-${item.id}`}>
                    <Link
                      href={item.href}
                      className="-mx-2 flex items-center gap-3 rounded-lg px-2 py-3 transition-colors hover:bg-muted/60"
                    >
                      <span
                        className={cn(
                          'flex h-9 w-9 shrink-0 items-center justify-center rounded-lg',
                          attentionIconClass(item.kind)
                        )}
                      >
                        <Icon className="h-4 w-4" aria-hidden />
                      </span>
                      <span className="min-w-0 flex-1">
                        <span className="block truncate text-sm font-medium text-foreground">
                          {item.label}
                        </span>
                        <span className="block truncate text-xs text-muted-foreground">
                          {item.meta}
                        </span>
                      </span>
                      <ArrowRight className="h-4 w-4 shrink-0 text-muted-foreground" aria-hidden />
                    </Link>
                  </li>
                );
              })}
            </ul>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>Recent activity</CardTitle>
          <Activity className="h-5 w-5 text-muted-foreground" aria-hidden />
        </CardHeader>
        <CardContent>
          {recentActivity.length === 0 ? (
            <p className="text-sm text-muted-foreground">No recent activity yet.</p>
          ) : (
            <ul className="space-y-3">
              {recentActivity.map((item, i) => (
                <li key={feedItemKey(item, i)}>
                  <Link
                    href={hrefFor(item)}
                    className="-mx-2 flex flex-wrap items-baseline gap-2 rounded-lg px-2 py-2 text-left transition-colors hover:bg-muted/60"
                  >
                    <time className="shrink-0 text-xs tabular-nums text-muted-foreground">
                      {new Date(item.at).toLocaleString(undefined, {
                        dateStyle: 'short',
                        timeStyle: 'short',
                      })}
                    </time>
                    <span className="text-sm font-medium text-foreground">{labelFor(item)}</span>
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
