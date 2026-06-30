'use client';

import { useMemo, useState } from 'react';
import Link from 'next/link';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { AlertTriangle, RefreshCw, UserX } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Card, CardContent } from '@/components/ui/Card';
import { EmptyState, LoadingSpinner, PageHeader } from '@/components/ui/PageStates';
import { entityTypeLabel } from '@/lib/orphan-assignments';
import {
  ORPHAN_ASSIGNMENTS_QUERY_KEY,
  fetchOrphanAssignments,
  orphanSummaryByType,
  resolveOrphanAssignment,
} from '@/lib/queries/orphan-assignments';
import { fetchUsersList } from '@/lib/queries/users';
import { cn } from '@/lib/utils';

export default function OrphanAssignmentsPage() {
  const queryClient = useQueryClient();
  const [replacementByRow, setReplacementByRow] = useState<Record<string, string>>({});
  const [actionError, setActionError] = useState<string | null>(null);

  const { data: orphans, isLoading, error, refetch, isFetching } = useQuery({
    queryKey: ORPHAN_ASSIGNMENTS_QUERY_KEY,
    staleTime: 30 * 1000,
    queryFn: fetchOrphanAssignments,
  });

  const { data: users } = useQuery({
    queryKey: ['users-list'],
    staleTime: 60 * 1000,
    queryFn: fetchUsersList,
  });

  const technicians = useMemo(
    () =>
      (users ?? []).filter(
        (u) => u.isActive && (u.role === 'technician' || u.role === 'manager' || u.role === 'admin')
      ),
    [users]
  );

  const summary = useMemo(() => orphanSummaryByType(orphans ?? []), [orphans]);

  const resolveMutation = useMutation({
    mutationFn: async ({
      rowKey,
      row,
      replacementId,
    }: {
      rowKey: string;
      row: NonNullable<typeof orphans>[number];
      replacementId?: string | null;
    }) => {
      setActionError(null);
      await resolveOrphanAssignment(row, replacementId);
      setReplacementByRow((prev) => {
        const next = { ...prev };
        delete next[rowKey];
        return next;
      });
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ORPHAN_ASSIGNMENTS_QUERY_KEY });
      void queryClient.invalidateQueries({ queryKey: ['work-orders'] });
      void queryClient.invalidateQueries({ queryKey: ['pm-schedules'] });
    },
    onError: (err: Error) => setActionError(err.message),
  });

  const rowKey = (row: NonNullable<typeof orphans>[number]) =>
    `${row.entityType}:${row.entityId}:${row.orphanUserIds.join(',')}`;

  return (
    <div className="space-y-6 sm:space-y-8">
      <PageHeader
        title="Orphan assignments"
        description="Records still assigned to deleted users. Remove stale IDs or reassign to an active technician."
        actions={
          <div className="flex flex-wrap items-center gap-2">
            <Button
              type="button"
              variant="outline"
              size="sm"
              disabled={isFetching}
              onClick={() => void refetch()}
            >
              <RefreshCw className={cn('mr-2 h-4 w-4', isFetching && 'animate-spin')} />
              Refresh scan
            </Button>
            <Link
              href="/users"
              className="inline-flex h-8 items-center justify-center rounded-lg border border-border bg-background px-3 text-xs font-medium hover:bg-muted"
            >
              Back to users
            </Link>
          </div>
        }
      />

      {actionError ? (
        <div className="rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3 text-sm text-destructive">
          {actionError}
        </div>
      ) : null}

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        {(
          [
            ['work_order', 'Work orders'],
            ['pm_schedule', 'PM schedules'],
            ['pm_occurrence', 'PM occurrences'],
            ['pm_task', 'Legacy PM tasks'],
          ] as const
        ).map(([key, label]) => (
          <Card key={key}>
            <CardContent className="flex items-center gap-3 p-4">
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-amber-500/10 text-amber-700 dark:text-amber-400">
                <UserX className="h-5 w-5" />
              </div>
              <div>
                <p className="text-xs text-muted-foreground">{label}</p>
                <p className="text-2xl font-semibold tabular-nums">{summary[key]}</p>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {isLoading ? (
        <LoadingSpinner label="Scanning assignments" />
      ) : error ? (
        <EmptyState
          icon={AlertTriangle}
          title="Scan failed"
          description={error instanceof Error ? error.message : 'Unable to load orphan assignments.'}
          action={
            <Button type="button" onClick={() => void refetch()}>
              Retry
            </Button>
          }
        />
      ) : !orphans?.length ? (
        <EmptyState
          icon={UserX}
          title="No orphan assignments"
          description="Every assignment references an existing user profile. Run refresh after deleting users to verify."
        />
      ) : (
        <Card>
          <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[720px] text-sm">
              <thead>
                <tr className="border-b border-border text-left text-xs uppercase tracking-wide text-muted-foreground">
                  <th className="px-4 py-3 font-medium">Record</th>
                  <th className="px-4 py-3 font-medium">Type</th>
                  <th className="px-4 py-3 font-medium">Missing user IDs</th>
                  <th className="px-4 py-3 font-medium">Reassign to</th>
                  <th className="px-4 py-3 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {orphans.map((row) => {
                  const key = rowKey(row);
                  const replacement = replacementByRow[key] ?? '';
                  const busy =
                    resolveMutation.isPending && resolveMutation.variables?.rowKey === key;
                  return (
                    <tr key={key} className="border-b border-border transition-colors hover:bg-muted/40">
                      <td className="px-4 py-3">
                        <Link
                          href={row.href}
                          className="font-medium text-primary underline-offset-2 hover:underline"
                        >
                          {row.entityLabel}
                        </Link>
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">
                        {entityTypeLabel(row.entityType)}
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex flex-wrap gap-1">
                          {row.orphanUserIds.map((id) => (
                            <code
                              key={id}
                              className="rounded bg-muted px-1.5 py-0.5 text-xs font-mono"
                              title={id}
                            >
                              {id.slice(0, 8)}…
                            </code>
                          ))}
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <select
                          className="w-full max-w-[220px] rounded-lg border border-input bg-background px-3 py-2 text-sm min-h-[40px]"
                          value={replacement}
                          onChange={(e) =>
                            setReplacementByRow((prev) => ({ ...prev, [key]: e.target.value }))
                          }
                          disabled={busy}
                        >
                          <option value="">Remove only (no replacement)</option>
                          {technicians.map((t) => (
                            <option key={t.id} value={t.id}>
                              {t.name} ({t.role})
                            </option>
                          ))}
                        </select>
                      </td>
                      <td className="px-4 py-3 text-right">
                        <Button
                          type="button"
                          size="sm"
                          disabled={busy}
                          onClick={() =>
                            resolveMutation.mutate({
                              rowKey: key,
                              row,
                              replacementId: replacement || null,
                            })
                          }
                        >
                          {busy ? 'Saving…' : 'Apply fix'}
                        </Button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
