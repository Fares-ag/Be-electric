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
import { DataTableShell, PageHeader } from '@/components/ui/PageStates';

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

      <Card>
        <CardContent className="p-0">
          <DataTableShell
            isLoading={isLoading}
            error={queryError}
            isEmpty={!isLoading && !queryError && (pmTasks?.length ?? 0) === 0}
            emptyTitle="No legacy PM tasks"
            emptyDescription="Use PM Schedules to create new preventive maintenance work."
            onRetry={() => refetch()}
          >
            {filtered.length === 0 && (pmTasks?.length ?? 0) > 0 ? (
              <div className="px-6 py-12 text-center">
                <p className="font-medium text-foreground">No matching PM tasks</p>
                <p className="mt-1 text-sm text-muted-foreground">Try a different search term.</p>
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
                      <th className="w-24" />
                    </tr>
                  </thead>
                  <tbody>
                    {paginatedItems.map((t: Record<string, unknown>) => (
                      <tr key={t.id as string}>
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
                        <td>
                          <Link href={`/pm-tasks/${t.id}`}>
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
