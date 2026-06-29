'use client';

import { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import Link from 'next/link';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { LoadingSpinner, PageHeader, QueryErrorState } from '@/components/ui/PageStates';
import { Wrench, AlertTriangle, Package, Activity, LifeBuoy } from 'lucide-react';
import {
  ACTIVE_WORK_ORDER_STATUSES,
  parseActivityHistory,
  type WorkOrderActivityEntry,
} from '@/lib/work-order-detail';
import { countOverduePmOccurrences, fetchRecentCompletedPmOccurrences } from '@/lib/queries/pm-schedules';

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

  const pmQuery = useQuery({
    queryKey: ['pm-occurrences-overdue'],
    staleTime: 60 * 1000,
    queryFn: () => countOverduePmOccurrences(),
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
    pmQuery.isLoading ||
    inventoryQuery.isLoading ||
    supportQuery.isLoading ||
    activityQuery.isLoading;
  const queryError =
    summaryQuery.error ??
    pmQuery.error ??
    inventoryQuery.error ??
    supportQuery.error ??
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
  const pmTasks = pmQuery.data;
  const inventory = inventoryQuery.data;

  const openCount = workOrders?.filter((wo) => wo.status === 'open').length ?? 0;
  const inProgressCount =
    workOrders?.filter((wo) =>
      (ACTIVE_WORK_ORDER_STATUSES as readonly string[]).includes(wo.status)
    ).length ?? 0;
  const overdueCount = pmTasks ?? 0;
  const lowStockCount =
    inventory?.filter((i) => i.minStock != null && i.currentStock <= i.minStock).length ?? 0;
  const supportSubmittedCount = supportQuery.data ?? 0;

  const cards = [
    { label: 'Open Work Orders', value: openCount, href: '/work-orders?status=open', icon: Wrench },
    { label: 'In Progress', value: inProgressCount, href: '/work-orders?status=active', icon: Wrench },
    { label: 'Overdue PM Occurrences', value: overdueCount, href: '/pm-schedules?status=overdue', icon: AlertTriangle },
    { label: 'Low Stock Items', value: lowStockCount, href: '/inventory?filter=lowStock', icon: Package },
    {
      label: 'Support Inbox (New)',
      value: supportSubmittedCount,
      href: '/support-requests?status=submitted',
      icon: LifeBuoy,
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

  if (isLoading) return <LoadingSpinner label="Loading dashboard" />;

  if (queryError) {
    return (
      <QueryErrorState
        title="Failed to load dashboard"
        message={queryError instanceof Error ? queryError.message : String(queryError)}
        onRetry={() => {
          summaryQuery.refetch();
          pmQuery.refetch();
          inventoryQuery.refetch();
          supportQuery.refetch();
          activityQuery.refetch();
        }}
      />
    );
  }

  return (
    <div className="space-y-6 sm:space-y-8">
      <PageHeader title="Dashboard" description="Operational overview and recent activity." actions={
        <Link href="/analytics" className="text-sm font-medium text-primary underline underline-offset-2 hover:text-primary-hover">
          View analytics
        </Link>
      } />

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">
        {cards.map(({ href, label, value, icon: Icon }) => (
          <Link key={href} href={href}>
            <Card className="cursor-pointer transition-all duration-200 hover:border-primary/30">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">{label}</CardTitle>
                <span className="flex h-9 w-9 items-center justify-center rounded-lg bg-accent text-accent-foreground">
                  <Icon className="h-4 w-4" aria-hidden />
                </span>
              </CardHeader>
              <CardContent>
                <p className="font-display text-2xl font-bold text-foreground">{value}</p>
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>Recent Activity</CardTitle>
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
