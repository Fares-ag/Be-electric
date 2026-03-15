'use client';

import { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { AnalyticsCharts } from './AnalyticsCharts';
import { Wrench, CheckCircle, Clock, AlertTriangle, TrendingUp } from 'lucide-react';
import Link from 'next/link';

type WO = { id: string; status: string; priority: string; createdAt: string; completedAt: string | null; closedAt: string | null };
type PM = { id: string; status: string; nextDueDate: string };

function formatLabel(s: string): string {
  return s.replace(/([A-Z])/g, ' $1').trim();
}

export default function AnalyticsPage() {
  const { data: workOrders } = useQuery({
    queryKey: ['analytics-work-orders'],
    queryFn: async () => {
      const { data } = await supabase
        .from('work_orders')
        .select('id, status, priority, createdAt, completedAt, closedAt');
      return (data ?? []) as WO[];
    },
    staleTime: 60 * 1000,
  });

  const { data: pmTasks } = useQuery({
    queryKey: ['analytics-pm-tasks'],
    queryFn: async () => {
      const { data } = await supabase
        .from('pm_tasks')
        .select('id, status, nextDueDate');
      return (data ?? []) as PM[];
    },
    staleTime: 60 * 1000,
  });

  const {
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
  } = useMemo(() => {
    const wos = workOrders ?? [];
    const pms = pmTasks ?? [];

    const statusCounts = wos.reduce((acc: Record<string, number>, wo) => {
      const s = wo.status ?? 'unknown';
      acc[s] = (acc[s] ?? 0) + 1;
      return acc;
    }, {});
    const statusData = Object.entries(statusCounts).map(([name, value]) => ({
      name: formatLabel(name),
      value,
    }));

    const priorityCounts = wos.reduce((acc: Record<string, number>, wo) => {
      const p = wo.priority ?? 'medium';
      acc[p] = (acc[p] ?? 0) + 1;
      return acc;
    }, {});
    const priorityData = Object.entries(priorityCounts).map(([name, value]) => ({
      name: formatLabel(name),
      value,
    }));

    const pmStatusCounts = pms.reduce((acc: Record<string, number>, t) => {
      const s = t.status ?? 'pending';
      acc[s] = (acc[s] ?? 0) + 1;
      return acc;
    }, {});
    const pmStatusData = Object.entries(pmStatusCounts).map(([name, value]) => ({
      name: formatLabel(name),
      value,
    }));

    const totalWorkOrders = wos.length;
    const openCount = wos.filter((wo) => wo.status === 'open').length;
    const inProgressCount = wos.filter((wo) =>
      ['assigned', 'inProgress'].includes(wo.status)
    ).length;
    const completedCount = wos.filter((wo) =>
      ['completed', 'closed'].includes(wo.status)
    ).length;
    const completionRate =
      totalWorkOrders > 0
        ? Math.round((completedCount / totalWorkOrders) * 100)
        : 0;

    const completedWithDate = wos.filter(
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

    const today = new Date().toISOString().slice(0, 10);
    const overduePmCount = pms.filter(
      (t) => t.status !== 'completed' && t.nextDueDate < today
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
  }, [workOrders, pmTasks]);

  return (
    <div className="space-y-6">
      <h1 className="font-display text-2xl font-semibold tracking-tight text-foreground">
        Analytics
      </h1>

      {/* Summary cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Link href="/work-orders">
          <Card className="cursor-pointer transition-all hover:border-primary/30">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                Total Work Orders
              </CardTitle>
              <Wrench className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <p className="font-display text-2xl font-bold text-foreground">
                {totalWorkOrders}
              </p>
            </CardContent>
          </Card>
        </Link>
        <Link href="/work-orders?status=open">
          <Card className="cursor-pointer transition-all hover:border-primary/30">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                Open
              </CardTitle>
              <Clock className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <p className="font-display text-2xl font-bold text-foreground">
                {openCount}
              </p>
            </CardContent>
          </Card>
        </Link>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Completion Rate
            </CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <p className="font-display text-2xl font-bold text-foreground">
              {completionRate}%
            </p>
            <p className="text-xs text-muted-foreground mt-0.5">
              {completedCount} of {totalWorkOrders} closed/completed
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Mean Time to Resolve
            </CardTitle>
            <CheckCircle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <p className="font-display text-2xl font-bold text-foreground">
              {mttrDays} days
            </p>
            <p className="text-xs text-muted-foreground mt-0.5">
              Avg. from create to complete/close
            </p>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <Link href="/work-orders?status=inProgress">
          <Card className="cursor-pointer transition-all hover:border-primary/30">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                In Progress
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="font-display text-2xl font-bold text-foreground">
                {inProgressCount}
              </p>
            </CardContent>
          </Card>
        </Link>
        <Link href="/pm-tasks">
          <Card className="cursor-pointer transition-all hover:border-primary/30">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                Overdue PM Tasks
              </CardTitle>
              <AlertTriangle className="h-4 w-4 text-amber-600" />
            </CardHeader>
            <CardContent>
              <p className="font-display text-2xl font-bold text-foreground">
                {overduePmCount}
              </p>
            </CardContent>
          </Card>
        </Link>
      </div>

      {/* Charts */}
      <AnalyticsCharts
        statusData={statusData}
        priorityData={priorityData}
        pmStatusData={pmStatusData}
      />
    </div>
  );
}
