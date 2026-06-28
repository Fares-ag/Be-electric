'use client';

import { useState, useMemo, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import Link from 'next/link';
import { Pagination } from '@/components/Pagination';
import { SearchFilterBar } from '@/components/SearchFilterBar';
import { usePagination } from '@/hooks/usePagination';
import { supabase } from '@/lib/supabase';
import { useAuthStore } from '@/stores/auth-store';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { StatusBadge } from '@/components/ui/Badge';
import { Modal, ModalActions } from '@/components/ui/Modal';
import { DataTableShell, PageHeader } from '@/components/ui/PageStates';
import { MAX_REOPEN_COUNT, getReopenCount } from '@/lib/work-order-detail';
import { ChevronRight } from 'lucide-react';

type MyWorkOrderRow = {
  id: string;
  ticketNumber: string | null;
  problemDescription: string | null;
  status: string | null;
  priority: string | null;
  createdAt: string | null;
  completedAt: string | null;
  closedAt: string | null;
  metadata: unknown;
};

export default function MyRequestsPage() {
  const user = useAuthStore((s) => s.user);
  const queryClient = useQueryClient();

  const { data: workOrders, isLoading, error: queryError, refetch } = useQuery({
    queryKey: ['my-work-orders', user?.id],
    staleTime: 60 * 1000,
    queryFn: async () => {
      if (!user) return [];
      const { data, error: err } = await supabase
        .from('work_orders')
        .select('id, ticketNumber, problemDescription, status, priority, createdAt, completedAt, closedAt, metadata')
        .eq('requestorId', user.id)
        .order('createdAt', { ascending: false });
      if (err) throw err;
      return (data ?? []) as MyWorkOrderRow[];
    },
    enabled: !!user?.id,
  });

  const [reopenWo, setReopenWo] = useState<MyWorkOrderRow | null>(null);
  const [reopenReason, setReopenReason] = useState('');
  const [reopenDescription, setReopenDescription] = useState('');
  const [reopenError, setReopenError] = useState<string | null>(null);

  const reopenMutation = useMutation({
    mutationFn: async () => {
      if (!user?.id || !reopenWo) throw new Error('Not allowed');
      if (reopenReason.trim().length < 10) throw new Error('Reason must be at least 10 characters');
      const rawMeta = reopenWo.metadata as Record<string, unknown> | undefined;
      const reopenCount = getReopenCount(rawMeta);
      const now = new Date().toISOString();
      const previousCompletion = reopenWo.completedAt ?? reopenWo.closedAt ?? null;
      const newMeta = {
        ...(typeof reopenWo.metadata === 'object' && reopenWo.metadata !== null
          ? (reopenWo.metadata as Record<string, unknown>)
          : {}),
        reopenedAt: now,
        reopenedBy: user.id,
        reopenReason: reopenReason.trim(),
        reopenCount: reopenCount + 1,
        previousCompletionDate: previousCompletion,
        previousStatus: String(reopenWo.status ?? ''),
      };
      const { error } = await supabase
        .from('work_orders')
        .update({
          status: 'reopened',
          problemDescription:
            reopenDescription.trim().length >= 10
              ? reopenDescription.trim()
              : (reopenWo.problemDescription ?? ''),
          assignedTechnicianIds: [],
          primaryTechnicianId: null,
          assignedAt: null,
          startedAt: null,
          completedAt: null,
          closedAt: null,
          metadata: newMeta,
          updatedAt: now,
        })
        .eq('id', reopenWo.id);
      if (error) throw error;
    },
    onSuccess: () => {
      setReopenWo(null);
      setReopenReason('');
      setReopenDescription('');
      setReopenError(null);
      queryClient.invalidateQueries({ queryKey: ['my-work-orders', user?.id] });
    },
    onError: (err: Error) => setReopenError(err.message),
  });

  const [search, setSearch] = useState('');
  const filtered = useMemo(() => {
    const list = workOrders ?? [];
    if (!search.trim()) return list;
    const q = search.trim().toLowerCase();
    return list.filter(
      (wo) =>
        String(wo.ticketNumber ?? '').toLowerCase().includes(q) ||
        String(wo.problemDescription ?? '').toLowerCase().includes(q)
    );
  }, [workOrders, search]);

  const { page, setPage, pageSize, setPageSize, paginatedItems, totalItems } =
    usePagination(filtered);

  useEffect(() => setPage(1), [search, setPage]);

  function canReopen(wo: MyWorkOrderRow): boolean {
    if (wo.status !== 'completed') return false;
    const rawMeta = wo.metadata as Record<string, unknown> | undefined;
    return getReopenCount(rawMeta) < MAX_REOPEN_COUNT;
  }

  return (
    <div className="space-y-4 sm:space-y-6">
      <PageHeader
        title="My Requests"
        actions={
          <SearchFilterBar
            search={search}
            onSearchChange={setSearch}
            placeholder="Search ticket, description..."
            className="max-w-md"
          />
        }
      />

      <Card>
        <CardContent className="p-0">
          <DataTableShell
            isLoading={isLoading}
            error={queryError}
            isEmpty={!isLoading && !queryError && (workOrders?.length ?? 0) === 0}
            emptyTitle="No requests yet"
            emptyDescription="Submit a maintenance request to track charger issues here."
            emptyAction={
              <Link href="/request">
                <Button type="button">New request</Button>
              </Link>
            }
            onRetry={() => refetch()}
          >
            {filtered.length === 0 && (workOrders?.length ?? 0) > 0 ? (
              <div className="px-6 py-12 text-center">
                <p className="font-medium text-foreground">No matching requests</p>
                <p className="mt-1 text-sm text-muted-foreground">Try a different search term.</p>
              </div>
            ) : (
              <>
                <div className="divide-y divide-border md:hidden">
                  {paginatedItems.map((wo) => (
                    <div key={wo.id} className="p-4">
                      <Link
                        href={`/work-orders/${wo.id}`}
                        className="block transition-colors active:bg-muted/50"
                      >
                        <div className="flex items-start justify-between gap-3">
                          <div className="min-w-0 flex-1">
                            <p className="font-medium text-foreground">{wo.ticketNumber}</p>
                            <p className="mt-0.5 line-clamp-2 text-sm text-muted-foreground">
                              {wo.problemDescription}
                            </p>
                            <div className="mt-2 flex flex-wrap items-center gap-2">
                              <StatusBadge status={wo.status ?? ''} />
                              <span className="text-xs capitalize text-muted-foreground">{wo.priority}</span>
                              <span className="text-xs text-muted-foreground">
                                {wo.createdAt ? new Date(wo.createdAt).toLocaleDateString() : '—'}
                              </span>
                            </div>
                          </div>
                          <ChevronRight className="mt-0.5 h-5 w-5 shrink-0 text-muted-foreground" aria-hidden />
                        </div>
                      </Link>
                      {canReopen(wo) && (
                        <Button
                          variant="outline"
                          size="sm"
                          className="mt-2 w-full sm:w-auto"
                          onClick={() => {
                            setReopenWo(wo);
                            setReopenError(null);
                          }}
                        >
                          Reopen
                        </Button>
                      )}
                    </div>
                  ))}
                </div>

                <div className="table-scroll hidden overflow-x-auto md:block">
                  <table className="table-modern">
                    <thead>
                      <tr>
                        <th>Ticket</th>
                        <th>Description</th>
                        <th>Status</th>
                        <th>Priority</th>
                        <th>Created</th>
                        <th className="w-40" />
                      </tr>
                    </thead>
                    <tbody>
                      {paginatedItems.map((wo) => (
                        <tr key={wo.id}>
                          <td className="font-medium">{wo.ticketNumber}</td>
                          <td className="max-w-xs truncate text-sm text-muted-foreground">
                            {wo.problemDescription}
                          </td>
                          <td>
                            <StatusBadge status={wo.status ?? ''} />
                          </td>
                          <td className="text-sm capitalize">{wo.priority}</td>
                          <td className="text-sm text-muted-foreground">
                            {wo.createdAt ? new Date(wo.createdAt).toLocaleDateString() : '—'}
                          </td>
                          <td>
                            <div className="flex items-center gap-2">
                              {canReopen(wo) && (
                                <Button
                                  variant="outline"
                                  size="sm"
                                  onClick={() => {
                                    setReopenWo(wo);
                                    setReopenError(null);
                                  }}
                                >
                                  Reopen
                                </Button>
                              )}
                              <Link href={`/work-orders/${wo.id}`}>
                                <Button variant="ghost" size="sm" className="gap-1">
                                  View
                                  <ChevronRight className="h-4 w-4" aria-hidden />
                                </Button>
                              </Link>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

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
          </DataTableShell>
        </CardContent>
      </Card>

      <Modal
        open={!!reopenWo}
        onClose={() => {
          setReopenWo(null);
          setReopenError(null);
        }}
        title="Reopen work order"
      >
        {reopenWo && (() => {
          const raw = reopenWo.metadata as Record<string, unknown> | undefined;
          const count = getReopenCount(raw);
          const left = MAX_REOPEN_COUNT - count;
          return (
            <>
              <div className="space-y-4">
                <p className="text-sm text-muted-foreground">
                  This will set the work order back to &quot;Reopened&quot; and clear assignments. You have {left}{' '}
                  reopen{left === 1 ? '' : 's'} left.
                </p>
                <div>
                  <label className="mb-1.5 block text-sm font-medium text-foreground">
                    Reason for reopening <span className="text-destructive">*</span>
                  </label>
                  <textarea
                    value={reopenReason}
                    onChange={(e) => setReopenReason(e.target.value)}
                    placeholder="At least 10 characters"
                    rows={3}
                    className="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary/20"
                  />
                </div>
                <div>
                  <label className="mb-1.5 block text-sm font-medium text-foreground">
                    Updated problem description (optional)
                  </label>
                  <textarea
                    value={reopenDescription}
                    onChange={(e) => setReopenDescription(e.target.value)}
                    placeholder="Leave blank to keep current description"
                    rows={2}
                    className="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary/20"
                  />
                </div>
                {reopenError && <p className="text-sm text-destructive">{reopenError}</p>}
              </div>
              <ModalActions>
                <Button variant="outline" onClick={() => setReopenWo(null)}>
                  Cancel
                </Button>
                <Button
                  onClick={() => reopenMutation.mutate()}
                  disabled={reopenReason.trim().length < 10 || reopenMutation.isPending}
                >
                  {reopenMutation.isPending ? 'Reopening…' : 'Reopen'}
                </Button>
              </ModalActions>
            </>
          );
        })()}
      </Modal>
    </div>
  );
}
