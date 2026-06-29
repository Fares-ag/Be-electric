'use client';

import { useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';
import { Card } from '@/components/ui/Card';
import { ExportCsvButton } from '@/components/ui/ExportCsvButton';
import { PageHeader } from '@/components/ui/PageStates';
import {
  fetchWorkOrdersForExport,
  WORK_ORDER_EXPORT_HEADERS,
} from '@/lib/queries/work-orders';
import { fetchPmOccurrencesForExport } from '@/lib/queries/pm-schedules';
import { fetchSupportRequestsForExport } from '@/lib/queries/support-requests';
import {
  PM_OCCURRENCE_EXPORT_HEADERS,
  SUPPORT_REQUEST_EXPORT_HEADERS,
} from '@/lib/reports';

export default function ReportsPage() {
  const { data: summary } = useQuery({
    queryKey: ['reports-summary'],
    staleTime: 60_000,
    queryFn: async () => {
      const [woRes, pmRes, supportRes] = await Promise.all([
        supabase.from('work_orders').select('id', { count: 'exact', head: true }),
        supabase.from('pm_task_occurrences').select('id', { count: 'exact', head: true }),
        supabase.from('support_requests').select('id', { count: 'exact', head: true }),
      ]);
      if (woRes.error) throw woRes.error;
      if (pmRes.error) throw pmRes.error;
      if (supportRes.error) throw supportRes.error;
      return {
        workOrderCount: woRes.count ?? 0,
        pmOccurrenceCount: pmRes.count ?? 0,
        supportRequestCount: supportRes.count ?? 0,
      };
    },
  });

  return (
    <div className="space-y-6">
      <PageHeader
        title="Reports"
        description="Export operational data for analysis and compliance."
        actions={
          <Link href="/analytics" className="text-sm font-medium text-primary underline underline-offset-2">
            View analytics
          </Link>
        }
      />

      <Card className="space-y-4 p-6">
        <div>
          <h2 className="text-base font-semibold text-foreground">Work orders</h2>
          <p className="mt-1 text-sm text-muted-foreground">
            Download all work orders you can access as CSV ({summary?.workOrderCount ?? '…'} records).
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

      <Card className="space-y-4 p-6">
        <div>
          <h2 className="text-base font-semibold text-foreground">PM schedule occurrences</h2>
          <p className="mt-1 text-sm text-muted-foreground">
            Export due dates with derived status (pending, overdue, completed) for{' '}
            {summary?.pmOccurrenceCount ?? '…'} occurrence(s).
          </p>
        </div>
        <ExportCsvButton
          filename={`pm-occurrences-${new Date().toISOString().slice(0, 10)}.csv`}
          headers={PM_OCCURRENCE_EXPORT_HEADERS}
          getRows={() => fetchPmOccurrencesForExport()}
          label="Export PM Occurrences (CSV)"
          size="md"
        />
      </Card>

      <Card className="space-y-4 p-6">
        <div>
          <h2 className="text-base font-semibold text-foreground">Support requests</h2>
          <p className="mt-1 text-sm text-muted-foreground">
            Export support inbox submissions ({summary?.supportRequestCount ?? '…'} records).
          </p>
        </div>
        <ExportCsvButton
          filename={`support-requests-${new Date().toISOString().slice(0, 10)}.csv`}
          headers={SUPPORT_REQUEST_EXPORT_HEADERS}
          getRows={() => fetchSupportRequestsForExport()}
          label="Export Support Requests (CSV)"
          size="md"
        />
      </Card>
    </div>
  );
}
