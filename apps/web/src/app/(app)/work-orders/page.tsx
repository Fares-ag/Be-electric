'use client';

import { useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { ChevronRight } from 'lucide-react';

const statusVariants: Record<string, 'default' | 'success' | 'warning' | 'destructive' | 'secondary'> = {
  open: 'secondary',
  assigned: 'default',
  inProgress: 'default',
  completed: 'success',
  closed: 'secondary',
};

export default function WorkOrdersPage() {
  const searchParams = useSearchParams();
  const statusFilter = searchParams.get('status') ?? undefined;

  const { data: workOrders, isLoading, error } = useQuery({
    queryKey: ['work-orders', statusFilter],
    queryFn: async () => {
      // Select requestorName directly from work_orders (no join needed, avoids permission issues on users table)
      let q = supabase
        .from('work_orders')
        .select('id, ticketNumber, problemDescription, status, priority, createdAt, requestorName, requestorId')
        .order('createdAt', { ascending: false });
      if (statusFilter) q = q.eq('status', statusFilter);
      const { data, error: err } = await q;
      if (err) throw err;
      return data ?? [];
    },
  });

  const filters = ['open', 'assigned', 'inProgress', 'completed', 'closed'];

  return (
    <div>
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between mb-8">
        <h1 className="font-display text-2xl font-semibold tracking-tight text-foreground">
          Work Orders
        </h1>
        <div className="flex flex-wrap gap-2">
          {filters.map((s) => (
            <Link
              key={s}
              href={s === 'open' ? '/work-orders' : `?status=${s}`}
            >
              <Button
                variant={statusFilter === s ? 'primary' : 'outline'}
                size="sm"
              >
                {s.replace(/([A-Z])/g, ' $1').trim()}
              </Button>
            </Link>
          ))}
        </div>
      </div>
      <Card>
        <CardContent className="p-0">
          {error ? (
            <div className="py-12 px-6 text-center">
              <p className="text-destructive font-medium">Failed to load work orders</p>
              <p className="text-sm text-muted-foreground mt-1">{String((error as Error).message)}</p>
              <p className="text-xs text-muted-foreground mt-2">If this is a permission error, ensure your user is in public.admin_users and run supabase/ensure-admin-sees-work-orders.sql in the SQL Editor.</p>
            </div>
          ) : isLoading ? (
            <div className="flex items-center justify-center py-12">
              <div className="h-6 w-6 animate-spin rounded-full border-2 border-primary border-t-transparent" />
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="table-modern">
                <thead>
                  <tr>
                    <th>Ticket</th>
                    <th>Description</th>
                    <th>Status</th>
                    <th>Priority</th>
                    <th>Requestor</th>
                    <th>Created</th>
                    <th className="w-12" />
                  </tr>
                </thead>
                <tbody>
                  {workOrders?.map((wo: Record<string, unknown>) => (
                    <tr key={wo.id as string}>
                      <td className="font-medium text-foreground">
                        {wo.ticketNumber as string}
                      </td>
                      <td className="max-w-xs truncate text-sm text-muted-foreground">
                        {wo.problemDescription as string}
                      </td>
                      <td>
                        <Badge variant={statusVariants[wo.status as string] ?? 'default'}>
                          {String(wo.status).replace(/([A-Z])/g, ' $1').trim()}
                        </Badge>
                      </td>
                      <td className="text-sm capitalize">
                        {wo.priority as string}
                      </td>
                      <td className="text-sm">
                        {(wo.requestorName as string) ?? '-'}
                      </td>
                      <td className="text-sm text-muted-foreground">
                        {new Date(wo.createdAt as string).toLocaleDateString()}
                      </td>
                      <td>
                        <Link href={`/work-orders/${wo.id}`}>
                          <Button variant="ghost" size="sm" className="gap-1">
                            View
                            <ChevronRight className="h-4 w-4" />
                          </Button>
                        </Link>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
