'use client';

import { useState, useMemo, useEffect } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Pagination } from '@/components/Pagination';
import { SearchFilterBar } from '@/components/SearchFilterBar';
import { usePagination } from '@/hooks/usePagination';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { StatusBadge } from '@/components/ui/Badge';
import { DismissibleHint } from '@/components/ui/DismissibleHint';
import { ListTableRow } from '@/components/ui/ListTableRow';
import { DataTableShell, PageHeader } from '@/components/ui/PageStates';
import { ClipboardList } from 'lucide-react';

/** Legacy pm_tasks list — new schedules use /pm-schedules (Option A). Do not create rows here. */
export default function PMTasksPage() {
  const { data: pmTasks, isLoading, error: queryError, refetch } = useQuery({
    queryKey: ['pm-tasks'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { data, error: err } = await supabase
        .from('pm_tasks')
        .select('id, taskName, status, frequency, nextDueDate, assignedTechnicianIds, asset:assets(name)')
        .order('nextDueDate', { ascending: true });
      if (err) throw err;
      return data ?? [];
    },
  });

  const [search, setSearch] = useState('');
  const filtered = useMemo(() => {
    const list = pmTasks ?? [];
    if (!search.trim()) return list;
    const q = search.trim().toLowerCase();
    return list.filter(
      (t: Record<string, unknown>) =>
        String(t.taskName ?? '').toLowerCase().includes(q) ||
        String((t.asset as { name?: string })?.name ?? '').toLowerCase().includes(q) ||
        String(t.frequency ?? '').toLowerCase().includes(q)
    );
  }, [pmTasks, search]);

  const { page, setPage, pageSize, setPageSize, paginatedItems, totalItems } =
    usePagination(filtered);

  useEffect(() => setPage(1), [search, setPage]);

  const showEmptySearch = !isLoading && !queryError && (pmTasks?.length ?? 0) > 0 && filtered.length === 0;

  return (
    <div className="space-y-4 sm:space-y-6">
      <PageHeader
        title="PM Tasks (legacy)"
        description="Historical single-row PM tasks from before schedule-based scheduling."
        actions={
          <>
            <SearchFilterBar
              search={search}
              onSearchChange={setSearch}
              placeholder="Search task, charger, frequency..."
              className="sm:min-w-[220px]"
            />
            <Link href="/pm-schedules">
              <Button>Create PM Schedule</Button>
            </Link>
          </>
        }
      />

      <DismissibleHint hintKey="pm-tasks-legacy" title="Legacy PM tasks">
        <p>
          <strong className="font-medium text-foreground">New PM work uses PM Schedules</strong> — one schedule
          generates many occurrences per charger. This list is read-only legacy data; technicians may still
          complete old tasks in the mobile app until migration finishes.{' '}
          <Link href="/pm-schedules" className="text-primary underline-offset-2 hover:underline">
            Go to PM Schedules
          </Link>
        </p>
      </DismissibleHint>

      <Card>
        <CardContent className="p-0">
          <DataTableShell
            isLoading={isLoading}
            error={queryError}
            isEmpty={!isLoading && !queryError && (pmTasks?.length ?? 0) === 0}
            emptyTitle="No legacy PM tasks"
            emptyDescription="Use PM Schedules to create new preventive maintenance work."
            emptyAction={
              <Link href="/pm-schedules">
                <Button>Create PM Schedule</Button>
              </Link>
            }
            emptyIcon={ClipboardList}
            emptyIconClassName="bg-blue-100 text-blue-700"
            onRetry={() => refetch()}
          >
            {showEmptySearch ? (
              <div className="flex flex-col items-center px-6 py-14 text-center">
                <div className="mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-blue-100 text-blue-700">
                  <ClipboardList className="h-7 w-7" aria-hidden />
                </div>
                <p className="font-medium text-foreground">No matching PM tasks</p>
                <p className="mt-1 max-w-sm text-sm text-muted-foreground">Try a different search term.</p>
                {search.trim() && (
                  <Button variant="outline" className="mt-4" onClick={() => setSearch('')}>
                    Clear search
                  </Button>
                )}
              </div>
            ) : (
              <div className="table-scroll overflow-x-auto">
                <table className="table-modern">
                  <thead>
                    <tr>
                      <th>Task</th>
                      <th>Status</th>
                      <th>Frequency</th>
                      <th>Next Due</th>
                      <th>Charger</th>
                      <th>Assigned</th>
                      <th className="w-12">
                        <span className="sr-only">Actions</span>
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {paginatedItems.map((t: Record<string, unknown>) => (
                      <ListTableRow key={t.id as string} href={`/pm-tasks/${t.id as string}`}>
                        <td className="font-medium">{t.taskName as string}</td>
                        <td>
                          <StatusBadge status={t.status as string} />
                        </td>
                        <td>{t.frequency as string}</td>
                        <td>
                          {t.nextDueDate
                            ? new Date(t.nextDueDate as string).toLocaleDateString()
                            : '—'}
                        </td>
                        <td>{(t.asset as { name?: string })?.name ?? '—'}</td>
                        <td className="text-sm text-muted-foreground">
                          {(t.assignedTechnicianIds as string[] | undefined)?.length
                            ? `${(t.assignedTechnicianIds as string[]).length} technician(s)`
                            : '—'}
                        </td>
                      </ListTableRow>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </DataTableShell>
        </CardContent>
        {!isLoading && !queryError && totalItems > 0 && filtered.length > 0 && (
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
