'use client';

import dynamic from 'next/dynamic';
import { Card } from '@/components/ui/Card';

const RechartsSection = dynamic(
  () =>
    import('./AnalyticsChartsInner').then((m) => m.AnalyticsChartsInner),
  {
    ssr: false,
    loading: () => (
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3 mb-8">
        <Card>
          <div className="h-48 animate-pulse bg-muted rounded" />
        </Card>
        <Card className="md:col-span-2">
          <div className="h-48 animate-pulse bg-muted rounded" />
        </Card>
      </div>
    ),
  }
);

type ChartData = { name: string; value: number }[];

export function AnalyticsCharts({
  statusData,
  priorityData,
  pmStatusData,
}: {
  statusData: ChartData;
  priorityData: ChartData;
  pmStatusData: ChartData;
}) {
  return (
    <RechartsSection
      statusData={statusData}
      priorityData={priorityData}
      pmStatusData={pmStatusData}
    />
  );
}
