'use client';

import { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { LoadingSpinner, PageHeader, QueryErrorState } from '@/components/ui/PageStates';
import {
  computeAnalyticsMetrics,
  type AnalyticsPmTask,
  type AnalyticsWorkOrder,
} from '@/lib/analytics-metrics';
import { AnalyticsCharts } from './AnalyticsCharts';
import { Wrench, CheckCircle, Clock, AlertTriangle, TrendingUp } from 'lucide-react';
import Link from 'next/link';

export default function AnalyticsPage() {
  const woQuery = useQuery({
    queryKey: ['analytics-work-orders'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('work_orders')
        .select('id, status, priority, createdAt, completedAt, closedAt');
      if (error) throw error;
      return (data ?? []) as AnalyticsWorkOrder[];
    },
    staleTime: 60 * 1000,
  });

  const pmQuery = useQuery({
    queryKey: ['analytics-pm-tasks'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('pm_tasks')
        .select('id, status, nextDueDate');
      if (error) throw error;
      return (data ?? []) as AnalyticsPmTask[];
    },
    staleTime: 60 * 1000,
  });

  const isLoading = woQuery.isLoading || pmQuery.isLoading;
  const queryError = woQuery.error ?? pmQuery.error;

  const metrics = useMemo(
    () => computeAnalyticsMetrics(woQuery.data ?? [], pmQuery.data ?? []),
    [woQuery.data, pmQuery.data]
  );

  if (isLoading) return <LoadingSpinner label="Loading analytics" />;

  if (queryError) {
    return (
      <QueryErrorState
        title="Failed to load analytics"
        message={queryError instanceof Error ? queryError.message : String(queryError)}
        onRetry={() => {
          woQuery.refetch();
          pmQuery.refetch();
        }}
      />
    );
  }

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
  } = metrics;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Analytics"
        description="Work order and preventive maintenance performance."
      />

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Link href="/work-orders">
          <Card className="cursor-pointer transition-all hover:border-primary/30">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                Total Work Orders
              </CardTitle>
              <Wrench className="h-4 w-4 text-muted-foreground" aria-hidden />
            </CardHeader>
            <CardContent>
              <p className="font-display text-2xl font-bold text-foreground">{totalWorkOrders}</p>
            </CardContent>
          </Card>
        </Link>
        <Link href="/work-orders?status=open">
          <Card className="cursor-pointer transition-all hover:border-primary/30">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">Open</CardTitle>
              <Clock className="h-4 w-4 text-muted-foreground" aria-hidden />
            </CardHeader>
            <CardContent>
              <p className="font-display text-2xl font-bold text-foreground">{openCount}</p>
            </CardContent>
          </Card>
        </Link>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Completion Rate
            </CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" aria-hidden />
          </CardHeader>
          <CardContent>
            <p className="font-display text-2xl font-bold text-foreground">{completionRate}%</p>
            <p className="mt-0.5 text-xs text-muted-foreground">
              {completedCount} of {totalWorkOrders} closed/completed
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Mean Time to Resolve
            </CardTitle>
            <CheckCircle className="h-4 w-4 text-muted-foreground" aria-hidden />
          </CardHeader>
          <CardContent>
            <p className="font-display text-2xl font-bold text-foreground">{mttrDays} days</p>
            <p className="mt-0.5 text-xs text-muted-foreground">Avg. from create to complete/close</p>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <Link href="/work-orders?status=inProgress">
          <Card className="cursor-pointer transition-all hover:border-primary/30">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">In Progress</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="font-display text-2xl font-bold text-foreground">{inProgressCount}</p>
            </CardContent>
          </Card>
        </Link>
        <Link href="/pm-tasks">
          <Card className="cursor-pointer transition-all hover:border-primary/30">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                Overdue PM Tasks
              </CardTitle>
              <AlertTriangle className="h-4 w-4 text-amber-600" aria-hidden />
            </CardHeader>
            <CardContent>
              <p className="font-display text-2xl font-bold text-foreground">{overduePmCount}</p>
            </CardContent>
          </Card>
        </Link>
      </div>

      {totalWorkOrders === 0 && pmQuery.data?.length === 0 ? (
        <Card>
          <CardContent className="py-10 text-center text-sm text-muted-foreground">
            No work orders or PM tasks yet. Data will appear here as your team uses the system.
          </CardContent>
        </Card>
      ) : (
        <AnalyticsCharts statusData={statusData} priorityData={priorityData} pmStatusData={pmStatusData} />
      )}
    </div>
  );
}
