'use client';

import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { Card } from '@/components/ui/Card';
import { ExportCsvButton } from '@/components/ui/ExportCsvButton';
import { PageHeader } from '@/components/ui/PageStates';
import {
  fetchWorkOrdersForExport,
  WORK_ORDER_EXPORT_HEADERS,
} from '@/lib/queries/work-orders';

export default function ReportsPage() {
  const { data: summary } = useQuery({
    queryKey: ['reports-summary'],
    staleTime: 60_000,
    queryFn: async () => {
      const { count, error } = await supabase
        .from('work_orders')
        .select('id', { count: 'exact', head: true });
      if (error) throw error;
      return { workOrderCount: count ?? 0 };
    },
  });

  return (
    <div className="space-y-6">
      <PageHeader
        title="Reports"
        description="Export operational data for analysis and compliance."
      />

      <Card className="space-y-4 p-6">
        <div>
          <h2 className="text-base font-semibold text-foreground">Work orders</h2>
          <p className="mt-1 text-sm text-muted-foreground">
            Download all work orders as CSV ({summary?.workOrderCount ?? '…'} records).
          </p>
        </div>
        <ExportCsvButton
          filename={`work-orders-${new Date().toISOString().slice(0, 10)}.csv`}
          headers={WORK_ORDER_EXPORT_HEADERS}
          getRows={() => fetchWorkOrdersForExport()}
          label="Export Work Orders (CSV)"
          size="md"
        />
      </Card>
    </div>
  );
}
