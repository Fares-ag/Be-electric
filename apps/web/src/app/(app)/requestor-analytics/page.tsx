'use client';

import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useAuthStore } from '@/stores/auth-store';
import { Card, CardContent } from '@/components/ui/Card';

export default function RequestorAnalyticsPage() {
  const user = useAuthStore((s) => s.user);
  const { data: workOrders } = useQuery({
    queryKey: ['requestor-analytics', user?.id],
    staleTime: 60 * 1000,
    queryFn: async (): Promise<{ status: string }[]> => {
      if (!user) return [];
      const { data } = await supabase
        .from('work_orders')
        .select('status, createdAt')
        .eq('requestorId', user.id);
      return (data ?? []) as { status: string }[];
    },
    enabled: !!user?.id,
  });

  const total = workOrders?.length ?? 0;
  const completed =
    workOrders?.filter((wo) => wo.status === 'completed' || wo.status === 'closed')
      .length ?? 0;
  const open =
    workOrders?.filter(
      (wo) => wo.status === 'open' || wo.status === 'assigned' || wo.status === 'inProgress'
    ).length ?? 0;

  return (
    <div>
      <h1 className="text-2xl font-semibold tracking-tight text-foreground mb-6 md:mb-8">
        My Analytics
      </h1>
      <div className="grid gap-4 sm:grid-cols-2 md:grid-cols-3 mb-6 md:mb-8">
        <Card className="p-0">
          <CardContent className="p-5">
            <p className="text-sm font-medium text-muted-foreground">Total Requests</p>
            <p className="text-2xl md:text-3xl font-bold text-foreground mt-1">{total}</p>
          </CardContent>
        </Card>
        <Card className="p-0">
          <CardContent className="p-5">
            <p className="text-sm font-medium text-muted-foreground">Completed</p>
            <p className="text-2xl md:text-3xl font-bold text-foreground mt-1">{completed}</p>
          </CardContent>
        </Card>
        <Card className="p-0 sm:col-span-2 md:col-span-1">
          <CardContent className="p-5">
            <p className="text-sm font-medium text-muted-foreground">Open</p>
            <p className="text-2xl md:text-3xl font-bold text-foreground mt-1">{open}</p>
          </CardContent>
        </Card>
      </div>
      <Card className="p-0">
        <CardContent className="p-5">
          <p className="text-sm text-muted-foreground">More metrics coming soon.</p>
        </CardContent>
      </Card>
    </div>
  );
}
