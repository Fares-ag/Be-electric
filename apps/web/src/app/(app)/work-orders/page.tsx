'use client';

import { useEffect, useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { StatusBadge } from '@/components/ui/Badge';
import { Pagination } from '@/components/Pagination';
import { SearchFilterBar } from '@/components/SearchFilterBar';
import { ExportCsvButton } from '@/components/ui/ExportCsvButton';
import { DataTableShell, PageHeader } from '@/components/ui/PageStates';
import { usePagination } from '@/hooks/usePagination';
import { useUsersMap } from '@/hooks/useUsersMap';
import {
  fetchWorkOrdersList,
  WORK_ORDER_EXPORT_HEADERS,
  workOrdersListQueryKey,
  type WorkOrderListRow,
} from '@/lib/queries/work-orders';
import { ChevronRight } from 'lucide-react';

const STATUS_FILTERS = [
  'open',
  'assigned',
  'inProgress',
  'completed',
  'closed',
  'cancelled',
  'reopened',
] as const;

export default function WorkOrdersPage() {
  const searchParams = useSearchParams();
  const statusFilter = searchParams.get('status') ?? undefined;

  const { data: workOrders, isLoading, error, refetch } = useQuery({
    queryKey: workOrdersListQueryKey(statusFilter),
    staleTime: 60 * 1000,
    queryFn: () => fetchWorkOrdersList(statusFilter),
  });

  const { usersMap } = useUsersMap();

  const [search, setSearch] = useState('');
  const filtered = useMemo(() => {
    const list = workOrders ?? [];
    if (!search.trim()) return list;
    const q = search.trim().toLowerCase();
    return list.filter(
      (wo) =>
        String(wo.ticketNumber ?? '').toLowerCase().includes(q) ||
        String(wo.problemDescription ?? '').toLowerCase().includes(q) ||
        String(wo.requestorName ?? '').toLowerCase().includes(q)
    );
  }, [workOrders, search]);

  function assignedTechnicianNames(wo: WorkOrderListRow): string {
    const ids = wo.assignedTechnicianIds;
    if (!ids?.length) return '—';
    const names = ids.map((id) => usersMap.get(id)?.name).filter(Boolean) as string[];
    return names.length ? names.join(', ') : '—';
  }

  const { page, setPage, pageSize, setPageSize, paginatedItems, totalItems } =
    usePagination(filtered);

  useEffect(() => {
    setPage(1);
  }, [statusFilter, search, setPage]);

  const hasData = !isLoading && !error && (workOrders?.length ?? 0) > 0;
  const showEmptySearch = !isLoading && !error && (workOrders?.length ?? 0) > 0 && filtered.length === 0;

  return (
    <div className="space-y-4 sm:space-y-6">
      <PageHeader
        title="Work Orders"
        actions={
          <ExportCsvButton
            filename={`work-orders-${new Date().toISOString().slice(0, 10)}.csv`}
            headers={WORK_ORDER_EXPORT_HEADERS}
            disabled={!hasData}
            getRows={() =>
              filtered.map((wo) => ({
                ticketNumber: wo.ticketNumber,
                status: wo.status,
                priority: wo.priority,
                problemDescription: wo.problemDescription,
                requestorName: wo.requestorName,
                createdAt: wo.createdAt,
                updatedAt: wo.updatedAt ?? '',
                completedAt: wo.completedAt ?? '',
              }))
            }
            label="Export filtered"
          />
        }
      />
      <SearchFilterBar
        search={search}
        onSearchChange={setSearch}
        placeholder="Search ticket, description, requestor..."
      >
        <div className="flex shrink-0 flex-wrap gap-2">
          <Link href="/work-orders">
            <Button variant={!statusFilter ? 'primary' : 'outline'} size="sm">
              All
            </Button>
          </Link>
          <Link href="/work-orders?status=active">
            <Button variant={statusFilter === 'active' ? 'primary' : 'outline'} size="sm">
              Active
            </Button>
          </Link>
          {STATUS_FILTERS.map((s) => (
            <Link key={s} href={`/work-orders?status=${s}`}>
              <Button variant={statusFilter === s ? 'primary' : 'outline'} size="sm">
                {s.replace(/([A-Z])/g, ' $1').trim()}
              </Button>
            </Link>
          ))}
        </div>
      </SearchFilterBar>
      {statusFilter === 'active' && (
        <p className="text-sm text-muted-foreground">
          Showing assigned, in progress, and reopened work orders.
        </p>
      )}

      <Card>
        <CardContent className="p-0">
          <DataTableShell
            isLoading={isLoading}
            error={error}
            isEmpty={!isLoading && !error && (workOrders?.length ?? 0) === 0}
            emptyTitle="No work orders yet"
            emptyDescription="Work orders created by requestors will appear here."
            onRetry={() => refetch()}
            errorHint="If this is a permission error, ensure your user is in public.admin_users and run supabase/ensure-admin-sees-work-orders.sql in the SQL Editor."
          >
            {showEmptySearch ? (
              <div className="px-6 py-12 text-center">
                <p className="font-medium text-foreground">No matching work orders</p>
                <p className="mt-1 text-sm text-muted-foreground">Try a different search or status filter.</p>
              </div>
            ) : (
              <div className="table-scroll overflow-x-auto">
                <table className="table-modern">
                  <thead>
                    <tr>
                      <th>Ticket</th>
                      <th>Description</th>
                      <th>Status</th>
                      <th>Priority</th>
                      <th>Requestor</th>
                      <th>Assigned</th>
                      <th>Created</th>
                      <th className="w-12" />
                    </tr>
                  </thead>
                  <tbody>
                    {paginatedItems.map((wo) => (
                      <tr key={wo.id}>
                        <td className="font-medium text-foreground">{wo.ticketNumber}</td>
                        <td className="max-w-xs truncate text-sm text-muted-foreground">
                          {wo.problemDescription}
                        </td>
                        <td>
                          <StatusBadge status={wo.status ?? ''} />
                        </td>
                        <td className="text-sm capitalize">{wo.priority}</td>
                        <td className="text-sm">{wo.requestorName ?? '—'}</td>
                        <td
                          className="max-w-[180px] truncate text-sm text-muted-foreground"
                          title={assignedTechnicianNames(wo)}
                        >
                          {assignedTechnicianNames(wo)}
                        </td>
                        <td className="text-sm text-muted-foreground">
                          {wo.createdAt ? new Date(wo.createdAt).toLocaleDateString() : '—'}
                        </td>
                        <td>
                          <Link href={`/work-orders/${wo.id}`}>
                            <Button variant="ghost" size="sm" className="gap-1">
                              View
                              <ChevronRight className="h-4 w-4" aria-hidden />
                            </Button>
                          </Link>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </DataTableShell>
        </CardContent>
        {hasData && totalItems > 0 && !showEmptySearch && (
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
