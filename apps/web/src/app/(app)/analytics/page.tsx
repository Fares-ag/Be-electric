'use client';

import { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { LoadingSpinner, PageHeader, QueryErrorState } from '@/components/ui/PageStates';
import {
  computeAnalyticsMetrics,
  computePmOccurrenceStatusData,
  type AnalyticsWorkOrder,
} from '@/lib/analytics-metrics';
import { deriveOccurrenceStatus } from '@/lib/pm-schedule';
import {
  countOverduePmOccurrences,
  fetchPmOccurrencesForAnalytics,
} from '@/lib/queries/pm-schedules';
import { AnalyticsCharts } from './AnalyticsCharts';
import { Wrench, CheckCircle, Clock, AlertTriangle, TrendingUp } from 'lucide-react';
import Link from 'next/link';
import { Button } from '@/components/ui/Button';

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

  const pmOccAnalyticsQuery = useQuery({
    queryKey: ['analytics-pm-occurrences'],
    queryFn: fetchPmOccurrencesForAnalytics,
    staleTime: 60 * 1000,
  });

  const pmOccOverdueQuery = useQuery({
    queryKey: ['pm-occurrences-overdue'],
    queryFn: () => countOverduePmOccurrences(),
    staleTime: 60 * 1000,
  });

  const isLoading = woQuery.isLoading || pmOccAnalyticsQuery.isLoading || pmOccOverdueQuery.isLoading;
  const queryError = woQuery.error ?? pmOccAnalyticsQuery.error ?? pmOccOverdueQuery.error;

  const metrics = useMemo(
    () => computeAnalyticsMetrics(woQuery.data ?? [], []),
    [woQuery.data]
  );

  const pmStatusData = useMemo(
    () =>
      computePmOccurrenceStatusData(
        pmOccAnalyticsQuery.data ?? [],
        deriveOccurrenceStatus
      ),
    [pmOccAnalyticsQuery.data]
  );

  if (isLoading) return <LoadingSpinner label="Loading analytics" />;

  if (queryError) {
    return (
      <QueryErrorState
        title="Failed to load analytics"
        message={queryError instanceof Error ? queryError.message : String(queryError)}
        onRetry={() => {
          woQuery.refetch();
          pmOccAnalyticsQuery.refetch();
          pmOccOverdueQuery.refetch();
        }}
      />
    );
  }

  const {
    statusData,
    priorityData,
    totalWorkOrders,
    openCount,
    inProgressCount,
    completedCount,
    completionRate,
    mttrDays,
  } = metrics;
  const overduePmCount = pmOccOverdueQuery.data ?? 0;
  const hasPmOccurrenceData = (pmOccAnalyticsQuery.data?.length ?? 0) > 0;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Analytics"
        description="Work order and preventive maintenance performance."
        actions={
          <Link href="/reports">
            <Button type="button" variant="outline" size="sm">
              Export reports
            </Button>
          </Link>
        }
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
              {completedCount} completed or closed · rate excludes cancelled
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
        <Link href="/work-orders?status=active">
          <Card className="cursor-pointer transition-all hover:border-primary/30">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                Active Work Orders
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="font-display text-2xl font-bold text-foreground">{inProgressCount}</p>
            </CardContent>
          </Card>
        </Link>
        <Link href="/pm-schedules?status=overdue">
          <Card className="cursor-pointer transition-all hover:border-primary/30">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                Overdue PM Occurrences
              </CardTitle>
              <AlertTriangle className="h-4 w-4 text-amber-600" aria-hidden />
            </CardHeader>
            <CardContent>
              <p className="font-display text-2xl font-bold text-foreground">{overduePmCount}</p>
            </CardContent>
          </Card>
        </Link>
      </div>

      {totalWorkOrders === 0 && !hasPmOccurrenceData ? (
        <Card>
          <CardContent className="py-10 text-center text-sm text-muted-foreground">
            No work orders or PM schedule occurrences yet. Data will appear here as your team uses the system.
          </CardContent>
        </Card>
      ) : (
        <AnalyticsCharts statusData={statusData} priorityData={priorityData} pmStatusData={pmStatusData} />
      )}
    </div>
  );
}
