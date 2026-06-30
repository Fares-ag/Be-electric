'use client';

import { useEffect, useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { Card, CardContent } from '@/components/ui/Card';
import { Badge, StatusBadge } from '@/components/ui/Badge';
import { Pagination } from '@/components/Pagination';
import { SearchFilterBar } from '@/components/SearchFilterBar';
import { ExportCsvButton } from '@/components/ui/ExportCsvButton';
import { FilterChipLink } from '@/components/ui/FilterChipLink';
import { ListTableRow } from '@/components/ui/ListTableRow';
import { DataTableShell, PageHeader } from '@/components/ui/PageStates';
import { usePagination } from '@/hooks/usePagination';
import { useUsersMap } from '@/hooks/useUsersMap';
import {
  fetchWorkOrdersList,
  WORK_ORDER_EXPORT_HEADERS,
  workOrdersListQueryKey,
  type WorkOrderListRow,
} from '@/lib/queries/work-orders';
import { formatWorkOrderPriority, workOrderPriorityVariant } from '@/lib/work-order-list';
import { Wrench } from 'lucide-react';
import { Button } from '@/components/ui/Button';

const COMMON_STATUS_FILTERS = [
  'open',
  'assigned',
  'inProgress',
  'reopened',
  'completed',
  'closed',
  'cancelled',
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
  const hasActiveFilters = !!statusFilter || !!search.trim();

  return (
    <div className="space-y-4 sm:space-y-6">
      <PageHeader
        title="Work Orders"
        description="Track maintenance requests from submission through completion."
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

      <div className="flex flex-wrap gap-2">
        <FilterChipLink href="/work-orders" active={!statusFilter}>
          All
        </FilterChipLink>
        <FilterChipLink href="/work-orders?status=active" active={statusFilter === 'active'}>
          <StatusBadge status="inProgress">Active</StatusBadge>
        </FilterChipLink>
        {COMMON_STATUS_FILTERS.map((status) => (
          <FilterChipLink
            key={status}
            href={`/work-orders?status=${status}`}
            active={statusFilter === status}
          >
            <StatusBadge status={status} />
          </FilterChipLink>
        ))}
      </div>

      {statusFilter === 'active' && (
        <p className="text-sm text-muted-foreground">
          Assigned, in progress, and reopened work orders that still need field work.
        </p>
      )}

      <SearchFilterBar
        search={search}
        onSearchChange={setSearch}
        placeholder="Search ticket, description, requestor..."
      />

      <Card>
        <CardContent className="p-0">
          <DataTableShell
            isLoading={isLoading}
            error={error}
            isEmpty={!isLoading && !error && (workOrders?.length ?? 0) === 0}
            emptyTitle="No work orders yet"
            emptyDescription="When requestors submit maintenance requests from the mobile app, they appear here for assignment and tracking."
            emptyAction={
              <Link href="/dashboard">
                <Button variant="outline">Back to command center</Button>
              </Link>
            }
            emptyIcon={Wrench}
            emptyIconClassName="bg-blue-100 text-blue-700"
            onRetry={() => refetch()}
            errorHint="If this is a permission error, ensure your user is in public.admin_users and run supabase/ensure-admin-sees-work-orders.sql in the SQL Editor."
          >
            {showEmptySearch ? (
              <div className="flex flex-col items-center px-6 py-14 text-center">
                <div className="mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-muted text-muted-foreground">
                  <Wrench className="h-7 w-7" aria-hidden />
                </div>
                <p className="font-medium text-foreground">No matching work orders</p>
                <p className="mt-1 max-w-sm text-sm text-muted-foreground">
                  Try a different search term or status filter.
                </p>
                {hasActiveFilters && (
                  <Link href="/work-orders" className="mt-4">
                    <Button variant="outline">Clear filters</Button>
                  </Link>
                )}
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
                      <th className="w-12">
                        <span className="sr-only">Actions</span>
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {paginatedItems.map((wo) => (
                      <ListTableRow key={wo.id} href={`/work-orders/${wo.id}`}>
                        <td className="font-medium text-foreground">{wo.ticketNumber}</td>
                        <td className="max-w-xs truncate text-sm text-muted-foreground">
                          {wo.problemDescription}
                        </td>
                        <td>
                          <StatusBadge status={wo.status ?? ''} />
                        </td>
                        <td>
                          <Badge variant={workOrderPriorityVariant(wo.priority)}>
                            {formatWorkOrderPriority(wo.priority)}
                          </Badge>
                        </td>
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
                      </ListTableRow>
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
