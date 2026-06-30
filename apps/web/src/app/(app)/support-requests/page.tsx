'use client';

import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { StatusBadge } from '@/components/ui/Badge';
import { Pagination } from '@/components/Pagination';
import { SearchFilterBar } from '@/components/SearchFilterBar';
import { FilterChipLink } from '@/components/ui/FilterChipLink';
import { ListTableRow } from '@/components/ui/ListTableRow';
import { DismissibleHint } from '@/components/ui/DismissibleHint';
import { DataTableShell, PageHeader } from '@/components/ui/PageStates';
import { usePagination } from '@/hooks/usePagination';
import { supabase } from '@/lib/supabase';
import {
  SUPPORT_REQUESTS_LIST_QUERY_KEY,
  fetchSupportRequestsList,
} from '@/lib/queries/support-requests';
import {
  SUPPORT_REQUEST_STATUSES,
  SUPPORT_REQUEST_TYPES,
  filterSupportRequests,
  formatSupportLabel,
} from '@/lib/support-requests';
import { LifeBuoy } from 'lucide-react';

export default function SupportRequestsPage() {
  const searchParams = useSearchParams();
  const statusFromUrl = searchParams.get('status') ?? '';
  const [search, setSearch] = useState('');
  const [companyFilter, setCompanyFilter] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');

  const { data: requests, isLoading, error, refetch } = useQuery({
    queryKey: SUPPORT_REQUESTS_LIST_QUERY_KEY,
    staleTime: 60 * 1000,
    queryFn: fetchSupportRequestsList,
  });

  const { data: companies } = useQuery({
    queryKey: ['companies'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { data } = await supabase.from('companies').select('id, name').order('name');
      return (data ?? []) as { id: string; name: string }[];
    },
  });

  const statusFilter = statusFromUrl;

  const statusCounts = useMemo(() => {
    const counts: Record<string, number> = {};
    for (const request of requests ?? []) {
      const status = request.status ?? 'submitted';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }, [requests]);

  const filtered = useMemo(
    () =>
      filterSupportRequests(requests ?? [], {
        search,
        status: statusFilter || undefined,
        companyId: companyFilter || undefined,
        type: typeFilter || undefined,
        dateFrom: dateFrom || undefined,
        dateTo: dateTo || undefined,
      }),
    [requests, search, statusFilter, companyFilter, typeFilter, dateFrom, dateTo]
  );

  const { page, setPage, pageSize, setPageSize, paginatedItems, totalItems } =
    usePagination(filtered);

  useEffect(() => {
    setPage(1);
  }, [search, statusFilter, companyFilter, typeFilter, dateFrom, dateTo, setPage]);

  const hasData = !isLoading && !error && (requests?.length ?? 0) > 0;
  const showEmptySearch = hasData && filtered.length === 0;
  const hasAdvancedFilters =
    !!search.trim() || !!companyFilter || !!typeFilter || !!dateFrom || !!dateTo;

  return (
    <div className="space-y-4 sm:space-y-6">
      <PageHeader
        title="Support Inbox"
        description="Know How and Commissioning requests from the mobile app — reply here so requestors see your answer."
      />

      <DismissibleHint hintKey="support-inbox-overview" title="Support inbox workflow">
        <p>
          Requests arrive from the requestor mobile app. Filter by{' '}
          <strong className="font-medium text-foreground">Submitted</strong> to see what needs review,
          open a row to read details and send a staff reply. Status chips show counts at a glance.
        </p>
      </DismissibleHint>

      <div className="flex flex-wrap gap-2">
        <FilterChipLink href="/support-requests" active={!statusFilter} count={requests?.length}>
          All
        </FilterChipLink>
        {SUPPORT_REQUEST_STATUSES.map((status) => (
          <FilterChipLink
            key={status}
            href={`/support-requests?status=${status}`}
            active={statusFilter === status}
            count={statusCounts[status] ?? 0}
          >
            <StatusBadge status={status}>{formatSupportLabel(status)}</StatusBadge>
          </FilterChipLink>
        ))}
      </div>

      <SearchFilterBar
        search={search}
        onSearchChange={setSearch}
        placeholder="Search summary, requester, email..."
      >
        <div className="flex w-full flex-col gap-2 lg:flex-row lg:flex-wrap lg:items-end">
          <label className="flex min-w-[160px] flex-col gap-1 text-xs text-muted-foreground">
            Company
            <select
              value={companyFilter}
              onChange={(e) => setCompanyFilter(e.target.value)}
              className="rounded-lg border border-border bg-background px-3 py-2 text-sm text-foreground"
            >
              <option value="">All companies</option>
              {companies?.map((company) => (
                <option key={company.id} value={company.id}>
                  {company.name}
                </option>
              ))}
            </select>
          </label>
          <label className="flex min-w-[140px] flex-col gap-1 text-xs text-muted-foreground">
            Type
            <select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
              className="rounded-lg border border-border bg-background px-3 py-2 text-sm text-foreground"
            >
              <option value="">All types</option>
              {SUPPORT_REQUEST_TYPES.map((type) => (
                <option key={type} value={type}>
                  {formatSupportLabel(type)}
                </option>
              ))}
            </select>
          </label>
          <label className="flex min-w-[150px] flex-col gap-1 text-xs text-muted-foreground">
            From
            <input
              type="date"
              value={dateFrom}
              onChange={(e) => setDateFrom(e.target.value)}
              className="rounded-lg border border-border bg-background px-3 py-2 text-sm text-foreground"
            />
          </label>
          <label className="flex min-w-[150px] flex-col gap-1 text-xs text-muted-foreground">
            To
            <input
              type="date"
              value={dateTo}
              onChange={(e) => setDateTo(e.target.value)}
              className="rounded-lg border border-border bg-background px-3 py-2 text-sm text-foreground"
            />
          </label>
        </div>
      </SearchFilterBar>

      <Card>
        <CardContent className="p-0">
          <DataTableShell
            isLoading={isLoading}
            error={error}
            isEmpty={!isLoading && !error && (requests?.length ?? 0) === 0}
            emptyTitle="No support requests yet"
            emptyDescription="When requestors submit Know How or Commissioning requests in the mobile app, they appear here."
            emptyAction={
              <Link href="/dashboard">
                <Button variant="outline">Back to command center</Button>
              </Link>
            }
            emptyIcon={LifeBuoy}
            emptyIconClassName="bg-teal-100 text-teal-800"
            onRetry={() => refetch()}
          >
            {showEmptySearch ? (
              <div className="flex flex-col items-center px-6 py-14 text-center">
                <div className="mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-teal-100 text-teal-800">
                  <LifeBuoy className="h-7 w-7" aria-hidden />
                </div>
                <p className="font-medium text-foreground">No matching support requests</p>
                <p className="mt-1 max-w-sm text-sm text-muted-foreground">
                  Try different search terms or filters.
                </p>
                {(hasAdvancedFilters || statusFilter) && (
                  <Link href="/support-requests" className="mt-4">
                    <Button variant="outline">Clear all filters</Button>
                  </Link>
                )}
              </div>
            ) : (
              <div className="table-scroll overflow-x-auto">
                <table className="table-modern">
                  <thead>
                    <tr>
                      <th>Summary</th>
                      <th>Type</th>
                      <th>Status</th>
                      <th>Requester</th>
                      <th>Company</th>
                      <th>Submitted</th>
                      <th className="w-12">
                        <span className="sr-only">Actions</span>
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {paginatedItems.map((request) => (
                      <ListTableRow key={request.id} href={`/support-requests/${request.id}`}>
                        <td className="max-w-xs truncate font-medium text-foreground">
                          {request.summary ?? '—'}
                        </td>
                        <td className="text-sm">{formatSupportLabel(request.type)}</td>
                        <td>
                          <StatusBadge status={request.status} />
                        </td>
                        <td className="text-sm">
                          {request.requester?.name ?? request.requester?.email ?? '—'}
                        </td>
                        <td className="text-sm">{request.company?.name ?? '—'}</td>
                        <td className="text-sm text-muted-foreground">
                          {new Date(request.createdAt).toLocaleString()}
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
