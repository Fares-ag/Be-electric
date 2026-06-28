'use client';

import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { StatusBadge } from '@/components/ui/Badge';
import { Pagination } from '@/components/Pagination';
import { LoadingSpinner, PageHeader, QueryErrorState } from '@/components/ui/PageStates';
import { usePagination } from '@/hooks/usePagination';
import { useUsersMap } from '@/hooks/useUsersMap';
import {
  PM_OCCURRENCE_STATUSES,
  formatPmFrequency,
  type PmOccurrenceStatus,
} from '@/lib/pm-schedule';
import {
  fetchPmScheduleDetail,
  fetchPmScheduleOccurrences,
  pmScheduleDetailQueryKey,
  pmScheduleOccurrencesQueryKey,
} from '@/lib/queries/pm-schedules';

export default function PmScheduleDetailPage() {
  const params = useParams();
  const scheduleId = params.id as string;
  const [assetFilter, setAssetFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');

  const { data: schedule, isLoading, error, refetch } = useQuery({
    queryKey: pmScheduleDetailQueryKey(scheduleId),
    staleTime: 60 * 1000,
    queryFn: () => fetchPmScheduleDetail(scheduleId),
  });

  const { data: occurrences, isLoading: occLoading } = useQuery({
    queryKey: pmScheduleOccurrencesQueryKey(scheduleId),
    staleTime: 60 * 1000,
    queryFn: () => fetchPmScheduleOccurrences(scheduleId),
  });

  const assignedIds = schedule?.assignedTechnicianIds ?? [];
  const { users: allUsers } = useUsersMap(!!schedule);
  const assignedUsers = allUsers.filter((u) => assignedIds.includes(u.id));

  const assetOptions = useMemo(() => {
    const map = new Map<string, string>();
    for (const row of occurrences ?? []) {
      map.set(row.assetId, row.asset?.name ?? row.assetId);
    }
    return [...map.entries()].sort((a, b) => a[1].localeCompare(b[1]));
  }, [occurrences]);

  const filtered = useMemo(() => {
    return (occurrences ?? []).filter((row) => {
      if (assetFilter && row.assetId !== assetFilter) return false;
      const displayStatus = row.derivedStatus ?? row.status;
      if (statusFilter && displayStatus !== statusFilter) return false;
      if (dateFrom && row.dueDate < dateFrom) return false;
      if (dateTo && row.dueDate > dateTo) return false;
      return true;
    });
  }, [occurrences, assetFilter, statusFilter, dateFrom, dateTo]);

  const { page, setPage, pageSize, setPageSize, paginatedItems, totalItems } =
    usePagination(filtered);

  useEffect(() => setPage(1), [assetFilter, statusFilter, dateFrom, dateTo, setPage]);

  if (isLoading) return <LoadingSpinner label="Loading PM schedule" />;

  if (error || !schedule) {
    return (
      <QueryErrorState
        title="PM schedule unavailable"
        message={
          error instanceof Error
            ? error.message
            : 'This schedule may have been removed or you may not have permission to view it.'
        }
        onRetry={() => refetch()}
      />
    );
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title={schedule.taskName}
        description="Schedule template — technicians complete individual occurrences."
        actions={
          <Link href="/pm-schedules">
            <Button variant="outline" size="sm">
              Back to schedules
            </Button>
          </Link>
        }
      />

      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Schedule summary</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3 text-sm">
            <dl className="space-y-2">
              <div>
                <dt className="text-muted-foreground">Frequency</dt>
                <dd>{formatPmFrequency(schedule.frequency)}</dd>
              </div>
              <div>
                <dt className="text-muted-foreground">Window</dt>
                <dd>
                  {new Date(schedule.scheduleStartDate).toLocaleDateString()} –{' '}
                  {new Date(schedule.scheduleEndDate).toLocaleDateString()}
                </dd>
              </div>
              <div>
                <dt className="text-muted-foreground">Company</dt>
                <dd>{schedule.company?.name ?? '—'}</dd>
              </div>
              <div>
                <dt className="text-muted-foreground">Occurrences</dt>
                <dd>{occurrences?.length ?? 0}</dd>
              </div>
            </dl>
            {schedule.description && (
              <p className="border-t border-border pt-3 text-muted-foreground">{schedule.description}</p>
            )}
            <p className="border-t border-border pt-3 text-xs text-muted-foreground">
              Schedules are read-only after creation in v1. Edit/delete is not supported yet.
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Assigned technicians</CardTitle>
          </CardHeader>
          <CardContent>
            {assignedUsers.length > 0 ? (
              <ul className="space-y-1 text-sm">
                {assignedUsers.map((u) => (
                  <li key={u.id}>{u.name}</li>
                ))}
              </ul>
            ) : (
              <p className="text-sm text-muted-foreground">No technicians assigned at schedule level.</p>
            )}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Occurrences</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4 p-0 sm:p-6 sm:pt-0">
          <div className="flex flex-wrap gap-3 px-6 pt-6 sm:px-0 sm:pt-0">
            <label className="flex min-w-[140px] flex-col gap-1 text-xs text-muted-foreground">
              Charger
              <select
                value={assetFilter}
                onChange={(e) => setAssetFilter(e.target.value)}
                className="rounded-lg border border-border bg-background px-3 py-2 text-sm"
              >
                <option value="">All chargers</option>
                {assetOptions.map(([id, name]) => (
                  <option key={id} value={id}>
                    {name}
                  </option>
                ))}
              </select>
            </label>
            <label className="flex min-w-[120px] flex-col gap-1 text-xs text-muted-foreground">
              Status
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="rounded-lg border border-border bg-background px-3 py-2 text-sm"
              >
                <option value="">All statuses</option>
                {PM_OCCURRENCE_STATUSES.map((status) => (
                  <option key={status} value={status}>
                    {status}
                  </option>
                ))}
              </select>
            </label>
            <label className="flex min-w-[130px] flex-col gap-1 text-xs text-muted-foreground">
              Due from
              <input
                type="date"
                value={dateFrom}
                onChange={(e) => setDateFrom(e.target.value)}
                className="rounded-lg border border-border bg-background px-3 py-2 text-sm"
              />
            </label>
            <label className="flex min-w-[130px] flex-col gap-1 text-xs text-muted-foreground">
              Due to
              <input
                type="date"
                value={dateTo}
                onChange={(e) => setDateTo(e.target.value)}
                className="rounded-lg border border-border bg-background px-3 py-2 text-sm"
              />
            </label>
          </div>

          {occLoading ? (
            <LoadingSpinner label="Loading occurrences" />
          ) : (
            <>
              <div className="table-scroll overflow-x-auto">
                <table className="table-modern">
                  <thead>
                    <tr>
                      <th>Charger</th>
                      <th>Due date</th>
                      <th>Status</th>
                      <th className="w-24" />
                    </tr>
                  </thead>
                  <tbody>
                    {paginatedItems.map((row) => (
                      <tr key={row.id}>
                        <td>{row.asset?.name ?? row.assetId}</td>
                        <td>{new Date(row.dueDate).toLocaleDateString()}</td>
                        <td>
                          <StatusBadge status={(row.derivedStatus ?? row.status) as PmOccurrenceStatus} />
                        </td>
                        <td>
                          <Link href={`/pm-schedules/${scheduleId}/occurrences/${row.id}`}>
                            <Button variant="outline" size="sm">
                              View
                            </Button>
                          </Link>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              {filtered.length === 0 && (
                <p className="px-6 pb-6 text-center text-sm text-muted-foreground">
                  No occurrences match the current filters.
                </p>
              )}
              {totalItems > 0 && (
                <Pagination
                  page={page}
                  pageSize={pageSize}
                  totalItems={totalItems}
                  onPageChange={setPage}
                  onPageSizeChange={setPageSize}
                />
              )}
            </>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
