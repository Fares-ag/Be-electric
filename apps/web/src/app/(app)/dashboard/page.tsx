'use client';

import { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import Link from 'next/link';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { LoadingSpinner, PageHeader, QueryErrorState } from '@/components/ui/PageStates';
import { Wrench, AlertTriangle, Package, Activity } from 'lucide-react';
import { parseActivityHistory, type WorkOrderActivityEntry } from '@/lib/work-order-detail';

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
  | { kind: 'pm_completed'; at: string; id: string; taskName: string };

export default function DashboardPage() {
  const summaryQuery = useQuery({
    queryKey: ['work-orders-summary'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('work_orders')
        .select('id, status')
        .in('status', ['open', 'assigned', 'inProgress']);
      if (error) throw error;
      return (data ?? []) as { id: string; status: string }[];
    },
  });

  const pmQuery = useQuery({
    queryKey: ['pm-tasks-overdue'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('pm_tasks')
        .select('id, status, nextDueDate')
        .eq('status', 'overdue');
      if (error) throw error;
      return (data ?? []) as { id: string }[];
    },
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
        supabase
          .from('pm_tasks')
          .select('id, taskName, status, lastCompletedDate')
          .eq('status', 'completed')
          .not('lastCompletedDate', 'is', null)
          .order('lastCompletedDate', { ascending: false })
          .limit(15),
      ]);
      if (woRes.error) throw woRes.error;
      if (pmRes.error) throw pmRes.error;
      return {
        workOrders: (woRes.data ?? []) as WorkOrderRow[],
        pmTasks: (pmRes.data ?? []) as {
          id: string;
          taskName: string;
          status: string;
          lastCompletedDate: string;
        }[],
      };
    },
  });

  const isLoading =
    summaryQuery.isLoading || pmQuery.isLoading || inventoryQuery.isLoading || activityQuery.isLoading;
  const queryError =
    summaryQuery.error ?? pmQuery.error ?? inventoryQuery.error ?? activityQuery.error;

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

    for (const pm of raw.pmTasks) {
      if (pm.lastCompletedDate) {
        items.push({
          kind: 'pm_completed',
          at: pm.lastCompletedDate,
          id: pm.id,
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
    workOrders?.filter((wo) => wo.status === 'assigned' || wo.status === 'inProgress').length ?? 0;
  const overdueCount = pmTasks?.length ?? 0;
  const lowStockCount =
    inventory?.filter((i) => i.minStock != null && i.currentStock <= i.minStock).length ?? 0;

  const cards = [
    { label: 'Open Work Orders', value: openCount, href: '/work-orders?status=open', icon: Wrench },
    { label: 'In Progress', value: inProgressCount, href: '/work-orders?status=inProgress', icon: Wrench },
    { label: 'Overdue PM Tasks', value: overdueCount, href: '/pm-tasks?status=overdue', icon: AlertTriangle },
    { label: 'Low Stock Items', value: lowStockCount, href: '/inventory', icon: Package },
  ];

  function labelFor(item: FeedItem): string {
    switch (item.kind) {
      case 'wo_created':
        return `Work order #${item.ticketNumber} created`;
      case 'wo_activity':
        return `Work order #${item.ticketNumber} — ${item.type}${item.note ? `: ${item.note}` : ''}`;
      case 'pm_completed':
        return `PM task "${item.taskName}" completed`;
      default:
        return '';
    }
  }

  function hrefFor(item: FeedItem): string {
    switch (item.kind) {
      case 'wo_created':
      case 'wo_activity':
        return `/work-orders/${item.id}`;
      case 'pm_completed':
        return `/pm-tasks/${item.id}`;
      default:
        return '#';
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
          pmQuery.refetch();
          inventoryQuery.refetch();
          activityQuery.refetch();
        }}
      />
    );
  }

  return (
    <div className="space-y-6 sm:space-y-8">
      <PageHeader title="Dashboard" description="Operational overview and recent activity." />

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
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
                <li key={`${item.kind}-${item.id}-${item.at}-${i}`}>
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
