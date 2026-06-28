'use client';

import { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';
import { useAuthStore } from '@/stores/auth-store';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { LoadingSpinner, PageHeader, QueryErrorState } from '@/components/ui/PageStates';

export default function RequestorAnalyticsPage() {
  const user = useAuthStore((s) => s.user);

  const { data: workOrders, isLoading, error, refetch } = useQuery({
    queryKey: ['requestor-analytics', user?.id],
    staleTime: 60 * 1000,
    queryFn: async (): Promise<{ status: string }[]> => {
      if (!user) return [];
      const { data, error: err } = await supabase
        .from('work_orders')
        .select('status, createdAt')
        .eq('requestorId', user.id);
      if (err) throw err;
      return (data ?? []) as { status: string }[];
    },
    enabled: !!user?.id,
  });

  const stats = useMemo(() => {
    const total = workOrders?.length ?? 0;
    const completed =
      workOrders?.filter((wo) => wo.status === 'completed' || wo.status === 'closed').length ?? 0;
    const open =
      workOrders?.filter(
        (wo) => wo.status === 'open' || wo.status === 'assigned' || wo.status === 'inProgress'
      ).length ?? 0;
    const completionRate = total > 0 ? Math.round((completed / total) * 100) : 0;
    return { total, completed, open, completionRate };
  }, [workOrders]);

  if (isLoading) return <LoadingSpinner label="Loading analytics" />;

  if (error) {
    return (
      <QueryErrorState
        title="Failed to load analytics"
        message={error instanceof Error ? error.message : String(error)}
        onRetry={() => refetch()}
      />
    );
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="My Analytics"
        description="Summary of your maintenance requests."
        actions={
          <Link href="/request">
            <Button type="button" size="sm">
              New request
            </Button>
          </Link>
        }
      />

      <div className="mb-6 grid gap-4 sm:grid-cols-2 md:grid-cols-4">
        <Card className="p-0">
          <CardContent className="p-5">
            <p className="text-sm font-medium text-muted-foreground">Total Requests</p>
            <p className="mt-1 text-2xl font-bold text-foreground md:text-3xl">{stats.total}</p>
          </CardContent>
        </Card>
        <Card className="p-0">
          <CardContent className="p-5">
            <p className="text-sm font-medium text-muted-foreground">Completed</p>
            <p className="mt-1 text-2xl font-bold text-foreground md:text-3xl">{stats.completed}</p>
          </CardContent>
        </Card>
        <Card className="p-0">
          <CardContent className="p-5">
            <p className="text-sm font-medium text-muted-foreground">Open</p>
            <p className="mt-1 text-2xl font-bold text-foreground md:text-3xl">{stats.open}</p>
          </CardContent>
        </Card>
        <Card className="p-0">
          <CardContent className="p-5">
            <p className="text-sm font-medium text-muted-foreground">Completion rate</p>
            <p className="mt-1 text-2xl font-bold text-foreground md:text-3xl">{stats.completionRate}%</p>
          </CardContent>
        </Card>
      </div>

      {stats.total === 0 ? (
        <Card className="p-0">
          <CardContent className="space-y-3 p-6 text-center">
            <p className="text-sm text-muted-foreground">You have not submitted any requests yet.</p>
            <Link href="/request">
              <Button type="button">Submit your first request</Button>
            </Link>
          </CardContent>
        </Card>
      ) : (
        <Card className="p-0">
          <CardContent className="p-5">
            <p className="text-sm text-muted-foreground">
              {stats.open > 0
                ? `${stats.open} request${stats.open === 1 ? '' : 's'} still in progress.`
                : 'All of your submitted requests are completed or closed.'}{' '}
              <Link href="/my-requests" className="text-primary underline underline-offset-2">
                View my requests
              </Link>
            </p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
