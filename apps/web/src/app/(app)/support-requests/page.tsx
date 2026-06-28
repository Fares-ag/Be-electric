'use client';

import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import { ChevronRight } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { StatusBadge } from '@/components/ui/Badge';
import { Pagination } from '@/components/Pagination';
import { SearchFilterBar } from '@/components/SearchFilterBar';
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

export default function SupportRequestsPage() {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
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

  return (
    <div className="space-y-4 sm:space-y-6">
      <PageHeader
        title="Support Inbox"
        description="Review and respond to support requests submitted through the mobile app."
      />

      <SearchFilterBar
        search={search}
        onSearchChange={setSearch}
        placeholder="Search ticket, subject, requester, email..."
      >
        <div className="flex w-full flex-col gap-2 lg:flex-row lg:flex-wrap lg:items-end">
          <label className="flex min-w-[140px] flex-col gap-1 text-xs text-muted-foreground">
            Status
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="rounded-lg border border-border bg-background px-3 py-2 text-sm text-foreground"
            >
              <option value="">All statuses</option>
              {SUPPORT_REQUEST_STATUSES.map((status) => (
                <option key={status} value={status}>
                  {formatSupportLabel(status)}
                </option>
              ))}
            </select>
          </label>
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
            emptyDescription="New support submissions will appear here for staff review."
            onRetry={() => refetch()}
          >
            {showEmptySearch ? (
              <div className="px-6 py-12 text-center">
                <p className="font-medium text-foreground">No matching support requests</p>
                <p className="mt-1 text-sm text-muted-foreground">
                  Try different search terms or filters.
                </p>
              </div>
            ) : (
              <div className="table-scroll overflow-x-auto">
                <table className="table-modern">
                  <thead>
                    <tr>
                      <th>Ticket</th>
                      <th>Subject</th>
                      <th>Type</th>
                      <th>Status</th>
                      <th>Requester</th>
                      <th>Company</th>
                      <th>Submitted</th>
                      <th className="w-12" />
                    </tr>
                  </thead>
                  <tbody>
                    {paginatedItems.map((request) => (
                      <tr key={request.id}>
                        <td className="font-medium text-foreground">{request.ticketNumber}</td>
                        <td className="max-w-xs truncate">{request.subject}</td>
                        <td className="text-sm">{formatSupportLabel(request.type)}</td>
                        <td>
                          <StatusBadge status={request.status} />
                        </td>
                        <td className="text-sm">{request.requesterName ?? request.requesterEmail ?? '—'}</td>
                        <td className="text-sm">{request.company?.name ?? '—'}</td>
                        <td className="text-sm text-muted-foreground">
                          {new Date(request.submittedAt).toLocaleString()}
                        </td>
                        <td>
                          <Link href={`/support-requests/${request.id}`}>
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
