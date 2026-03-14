'use client';

import { useEffect, useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { StatusBadge } from '@/components/ui/Badge';
import { Pagination } from '@/components/Pagination';
import { SearchFilterBar } from '@/components/SearchFilterBar';
import { usePagination } from '@/hooks/usePagination';
import { ChevronRight } from 'lucide-react';

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

  const [search, setSearch] = useState('');
  const filtered = useMemo(() => {
    const list = workOrders ?? [];
    if (!search.trim()) return list;
    const q = search.trim().toLowerCase();
    return list.filter(
      (wo: Record<string, unknown>) =>
        String(wo.ticketNumber ?? '').toLowerCase().includes(q) ||
        String(wo.problemDescription ?? '').toLowerCase().includes(q) ||
        String(wo.requestorName ?? '').toLowerCase().includes(q)
    );
  }, [workOrders, search]);

  const { page, setPage, pageSize, setPageSize, paginatedItems, totalItems } =
    usePagination(filtered);

  useEffect(() => {
    setPage(1);
  }, [statusFilter, search, setPage]);

  const filters = ['open', 'assigned', 'inProgress', 'completed', 'closed'];

  return (
    <div className="space-y-4 sm:space-y-6">
      <div className="flex flex-col gap-4 sm:gap-6">
        <h1 className="font-display text-2xl font-semibold tracking-tight text-foreground">
          Work Orders
        </h1>
        <SearchFilterBar
          search={search}
          onSearchChange={setSearch}
          placeholder="Search ticket, description, requestor..."
        >
          <div className="flex flex-wrap gap-2 shrink-0">
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
        </SearchFilterBar>
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
                  {paginatedItems.map((wo: Record<string, unknown>) => (
                    <tr key={wo.id as string}>
                      <td className="font-medium text-foreground">
                        {wo.ticketNumber as string}
                      </td>
                      <td className="max-w-xs truncate text-sm text-muted-foreground">
                        {wo.problemDescription as string}
                      </td>
                      <td>
                        <StatusBadge status={wo.status as string} />
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
        {!isLoading && !error && totalItems > 0 && (
          <Pagination
            page={page}
            pageSize={pageSize}
            totalItems={totalItems}
            onPageChange={setPage}
            onPageSizeChange={setPageSize}
          />
        )}
      </Card>
    </div>
  );
}
