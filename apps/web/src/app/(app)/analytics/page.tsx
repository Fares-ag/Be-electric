'use client';

import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { Card } from '@/components/ui/Card';
import { AnalyticsCharts } from './AnalyticsCharts';

export default function AnalyticsPage() {
  const { data: workOrders } = useQuery({
    queryKey: ['analytics-work-orders'],
    queryFn: async () => {
      const { data } = await supabase.from('work_orders').select('status, priority');
      return data ?? [];
    },
    staleTime: 60 * 1000,
  });

  const statusCounts =
    workOrders?.reduce((acc: Record<string, number>, wo: { status?: string }) => {
      const s = wo.status ?? 'unknown';
      acc[s] = (acc[s] ?? 0) + 1;
      return acc;
    }, {}) ?? {};
  const statusData = Object.entries(statusCounts).map(([name, value]) => ({
    name: name.replace(/([A-Z])/g, ' $1').trim(),
    value,
  }));

  return (
    <div>
      <h1 className="text-2xl font-bold text-[#000] mb-6">Analytics</h1>
      <AnalyticsCharts statusData={statusData} />
      <Card>
        <h2 className="text-lg font-semibold mb-4">Summary</h2>
        <p className="text-sm text-[#757575]">
          MTTR, completion rate, and other metrics coming soon.
        </p>
      </Card>
    </div>
  );
}
