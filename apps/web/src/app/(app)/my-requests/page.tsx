'use client';

import { useState, useMemo, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Pagination } from '@/components/Pagination';
import { SearchFilterBar } from '@/components/SearchFilterBar';
import { usePagination } from '@/hooks/usePagination';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';
import { useAuthStore } from '@/stores/auth-store';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { StatusBadge } from '@/components/ui/Badge';
import { Modal, ModalActions } from '@/components/ui/Modal';
import { ChevronRight } from 'lucide-react';

const MAX_REOPEN_COUNT = 3;

export default function MyRequestsPage() {
  const user = useAuthStore((s) => s.user);
  const queryClient = useQueryClient();
  const { data: workOrders, isLoading } = useQuery({
    queryKey: ['my-work-orders', user?.id],
    queryFn: async () => {
      if (!user) return [];
      const { data } = await supabase
        .from('work_orders')
        .select('id, ticketNumber, problemDescription, status, priority, createdAt, completedAt, closedAt, metadata')
        .eq('requestorId', user.id)
        .order('createdAt', { ascending: false });
      return data ?? [];
    },
    enabled: !!user?.id,
  });

  const [reopenWo, setReopenWo] = useState<Record<string, unknown> | null>(null);
  const [reopenReason, setReopenReason] = useState('');
  const [reopenDescription, setReopenDescription] = useState('');
  const [reopenError, setReopenError] = useState<string | null>(null);

  const reopenMutation = useMutation({
    mutationFn: async () => {
      if (!user?.id || !reopenWo) throw new Error('Not allowed');
      if (reopenReason.trim().length < 10) throw new Error('Reason must be at least 10 characters');
      const rawMeta = reopenWo.metadata as Record<string, unknown> | undefined;
      const reopenCount = Number(rawMeta?.reopenCount ?? rawMeta?.reopen_count ?? 0);
      const now = new Date().toISOString();
      const previousCompletion = (reopenWo.completedAt ?? reopenWo.closedAt) as string | null ?? null;
      const newMeta = {
        ...(typeof reopenWo.metadata === 'object' && reopenWo.metadata !== null ? (reopenWo.metadata as Record<string, unknown>) : {}),
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
          problemDescription: reopenDescription.trim().length >= 10 ? reopenDescription.trim() : (reopenWo.problemDescription as string) ?? '',
          assignedTechnicianIds: [],
          primaryTechnicianId: null,
          assignedAt: null,
          startedAt: null,
          completedAt: null,
          closedAt: null,
          metadata: newMeta,
          updatedAt: now,
        })
        .eq('id', reopenWo.id as string);
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
      (wo: Record<string, unknown>) =>
        String(wo.ticketNumber ?? '').toLowerCase().includes(q) ||
        String(wo.problemDescription ?? '').toLowerCase().includes(q)
    );
  }, [workOrders, search]);

  const { page, setPage, pageSize, setPageSize, paginatedItems, totalItems } =
    usePagination(filtered);

  useEffect(() => setPage(1), [search, setPage]);

  function canReopen(wo: Record<string, unknown>): boolean {
    const status = wo.status as string;
    if (status !== 'completed') return false;
    const rawMeta = wo.metadata as Record<string, unknown> | undefined;
    const count = Number(rawMeta?.reopenCount ?? rawMeta?.reopen_count ?? 0);
    return count < MAX_REOPEN_COUNT;
  }

  return (
    <div className="space-y-4 sm:space-y-6">
      <div className="flex flex-col gap-4">
        <h1 className="font-display text-2xl font-semibold tracking-tight text-foreground">
          My Requests
        </h1>
        <SearchFilterBar
          search={search}
          onSearchChange={setSearch}
          placeholder="Search ticket, description..."
          className="max-w-md"
        />
      </div>
      <Card>
        <CardContent className="p-0">
          {isLoading ? (
            <div className="flex items-center justify-center py-12">
              <div className="h-6 w-6 animate-spin rounded-full border-2 border-primary border-t-transparent" />
            </div>
          ) : workOrders?.length === 0 ? (
            <div className="py-12 text-center px-4">
              <p className="text-muted-foreground">No requests yet.</p>
            </div>
          ) : (
            <>
              {/* Mobile: card list */}
              <div className="md:hidden divide-y divide-border">
                {paginatedItems.map((wo: Record<string, unknown>) => (
                  <div key={wo.id as string} className="p-4">
                    <Link href={`/work-orders/${wo.id}`} className="block active:bg-muted/50 transition-colors">
                      <div className="flex items-start justify-between gap-3">
                        <div className="min-w-0 flex-1">
                          <p className="font-medium text-foreground">{wo.ticketNumber as string}</p>
                          <p className="text-sm text-muted-foreground line-clamp-2 mt-0.5">
                            {wo.problemDescription as string}
                          </p>
                          <div className="flex flex-wrap items-center gap-2 mt-2">
                            <StatusBadge status={wo.status as string} />
                            <span className="text-xs text-muted-foreground capitalize">{wo.priority as string}</span>
                            <span className="text-xs text-muted-foreground">
                              {new Date(wo.createdAt as string).toLocaleDateString()}
                            </span>
                          </div>
                        </div>
                        <ChevronRight className="h-5 w-5 text-muted-foreground shrink-0 mt-0.5" />
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
              {/* Desktop: table */}
              <div className="hidden md:block overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="border-b border-border">
                      <th className="text-left py-4 px-6 text-sm font-medium text-muted-foreground">Ticket</th>
                      <th className="text-left py-4 px-6 text-sm font-medium text-muted-foreground">Description</th>
                      <th className="text-left py-4 px-6 text-sm font-medium text-muted-foreground">Status</th>
                      <th className="text-left py-4 px-6 text-sm font-medium text-muted-foreground">Priority</th>
                      <th className="text-left py-4 px-6 text-sm font-medium text-muted-foreground">Created</th>
                      <th className="w-12" />
                    </tr>
                  </thead>
                  <tbody>
                    {paginatedItems.map((wo: Record<string, unknown>) => (
                      <tr
                        key={wo.id as string}
                        className="border-b border-border last:border-0 hover:bg-muted/50 transition-colors"
                      >
                        <td className="py-4 px-6 font-medium">{wo.ticketNumber as string}</td>
                        <td className="py-4 px-6 max-w-xs truncate text-sm text-muted-foreground">
                          {wo.problemDescription as string}
                        </td>
                        <td className="py-4 px-6">
                          <StatusBadge status={wo.status as string} />
                        </td>
                        <td className="py-4 px-6 text-sm capitalize">{wo.priority as string}</td>
                        <td className="py-4 px-6 text-sm text-muted-foreground">
                          {new Date(wo.createdAt as string).toLocaleDateString()}
                        </td>
                        <td className="py-4 px-6">
                          <div className="flex items-center gap-2">
                            {canReopen(wo) && (
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={(e) => {
                                  e.preventDefault();
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
                                <ChevronRight className="h-4 w-4" />
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
          const count = Number(raw?.reopenCount ?? raw?.reopen_count ?? 0);
          const left = MAX_REOPEN_COUNT - count;
          return (
          <>
            <div className="space-y-4">
              <p className="text-sm text-muted-foreground">
                This will set the work order back to &quot;Reopened&quot; and clear assignments. You have {left} reopen{left === 1 ? '' : 's'} left.
              </p>
              <div>
                <label className="block text-sm font-medium text-foreground mb-1.5">
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
                <label className="block text-sm font-medium text-foreground mb-1.5">
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
