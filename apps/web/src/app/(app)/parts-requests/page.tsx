'use client';

import { useState, useMemo, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Pagination } from '@/components/Pagination';
import { SearchFilterBar } from '@/components/SearchFilterBar';
import { usePagination } from '@/hooks/usePagination';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';
import { useAuthStore } from '@/stores/auth-store';
import { useUsersMap } from '@/hooks/useUsersMap';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { StatusBadge } from '@/components/ui/Badge';
import { DataTableShell, PageHeader } from '@/components/ui/PageStates';

type PartsRequestRow = {
  id: string;
  status: string;
  requestedBy: string;
  requestedAt: string;
  requestedParts: unknown;
  workOrderId: string | null;
  workOrder?: { ticketNumber?: string };
};

async function notifyPartsRequest(
  userId: string,
  title: string,
  message: string,
  relatedId: string,
  relatedType: string
) {
  await supabase.from('notifications').insert({
    userId,
    title,
    message,
    type: 'parts_request',
    channel: 'in_app',
    priority: 'normal',
    relatedId,
    relatedType,
  });
}

export default function PartsRequestsPage() {
  const queryClient = useQueryClient();
  const currentUser = useAuthStore((s) => s.user);

  const { usersMap } = useUsersMap();

  const { data: requests, isLoading, error: queryError, refetch } = useQuery({
    queryKey: ['parts-requests'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { data, error: err } = await supabase
        .from('parts_requests')
        .select(
          'id, status, requestedBy, requestedAt, requestedParts, workOrderId, workOrder:work_orders(ticketNumber)'
        )
        .order('requestedAt', { ascending: false });
      if (err) throw err;
      return (data ?? []) as PartsRequestRow[];
    },
  });

  const approveMutation = useMutation({
    mutationFn: async (req: PartsRequestRow) => {
      if (!currentUser?.id) throw new Error('Not signed in');
      const { error: updateError } = await supabase
        .from('parts_requests')
        .update({
          status: 'approved',
          approvedBy: currentUser.id,
          approvedAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        })
        .eq('id', req.id);
      if (updateError) throw updateError;
      await notifyPartsRequest(
        req.requestedBy,
        'Parts request approved',
        `Your parts request has been approved.`,
        req.id,
        'parts_request'
      );
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['parts-requests'] }),
  });

  const rejectMutation = useMutation({
    mutationFn: async ({ req, reason }: { req: PartsRequestRow; reason?: string }) => {
      if (!currentUser?.id) throw new Error('Not signed in');
      const { error: updateError } = await supabase
        .from('parts_requests')
        .update({
          status: 'rejected',
          rejectedBy: currentUser.id,
          rejectedAt: new Date().toISOString(),
          rejectionReason: reason ?? null,
          updatedAt: new Date().toISOString(),
        })
        .eq('id', req.id);
      if (updateError) throw updateError;
      await notifyPartsRequest(
        req.requestedBy,
        'Parts request rejected',
        reason ? `Your parts request was rejected: ${reason}` : 'Your parts request was rejected.',
        req.id,
        'parts_request'
      );
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['parts-requests'] }),
  });

  const handleApprove = (req: PartsRequestRow) => approveMutation.mutate(req);
  const handleReject = (req: PartsRequestRow) => {
    const reason = typeof window !== 'undefined' ? window.prompt('Rejection reason (optional):') ?? undefined : undefined;
    rejectMutation.mutate({ req, reason });
  };

  const pending = requests?.filter((r) => r.status === 'pending') ?? [];
  const [search, setSearch] = useState('');
  const filtered = useMemo(() => {
    const list = requests ?? [];
    if (!search.trim()) return list;
    const q = search.trim().toLowerCase();
    return list.filter(
      (r) =>
        (r.workOrder?.ticketNumber ?? '').toLowerCase().includes(q) ||
        (usersMap.get(r.requestedBy)?.name ?? '').toLowerCase().includes(q) ||
        r.status.toLowerCase().includes(q)
    );
  }, [requests, search, usersMap]);

  const { page, setPage, pageSize, setPageSize, paginatedItems, totalItems } =
    usePagination(filtered);

  useEffect(() => setPage(1), [search, setPage]);

  return (
    <div className="space-y-4 sm:space-y-6">
      <PageHeader
        title="Parts Requests"
        actions={
          <>
            <SearchFilterBar
              search={search}
              onSearchChange={setSearch}
              placeholder="Search WO, requester, status..."
              className="sm:min-w-[220px]"
            />
            {pending.length > 0 && (
              <span className="text-sm font-medium text-primary">{pending.length} pending</span>
            )}
          </>
        }
      />
      <Card>
        <CardContent className="p-0">
          <DataTableShell
            isLoading={isLoading}
            error={queryError}
            isEmpty={!isLoading && !queryError && (requests?.length ?? 0) === 0}
            emptyTitle="No parts requests yet"
            emptyDescription="Technicians submit parts requests from the mobile app when work orders need supplies."
            onRetry={() => refetch()}
          >
            {filtered.length === 0 && (requests?.length ?? 0) > 0 ? (
              <div className="px-6 py-12 text-center">
                <p className="font-medium text-foreground">No matching requests</p>
                <p className="mt-1 text-sm text-muted-foreground">Try a different search term.</p>
              </div>
            ) : (
              <div className="table-scroll overflow-x-auto">
                <table className="table-modern">
                  <thead>
                    <tr>
                      <th>WO</th>
                      <th>Requested by</th>
                      <th>Parts</th>
                      <th>Requested</th>
                      <th>Status</th>
                      <th className="w-48" />
                    </tr>
                  </thead>
                  <tbody>
                    {paginatedItems.map((r) => {
                      const parts = r.requestedParts as
                        | Array<{ name?: string; quantity?: number; unit?: string }>
                        | undefined;
                      const partsSummary = Array.isArray(parts)
                        ? parts.map((p) => `${p.name ?? '?'} (×${p.quantity ?? 0})`).join(', ') || '—'
                        : typeof parts === 'object' && parts !== null
                          ? JSON.stringify(parts)
                          : '—';
                      return (
                        <tr key={r.id}>
                          <td>
                            {r.workOrderId ? (
                              <Link
                                href={`/work-orders/${r.workOrderId}`}
                                className="text-primary hover:underline"
                              >
                                {r.workOrder?.ticketNumber ?? r.workOrderId.slice(0, 8)}
                              </Link>
                            ) : (
                              r.workOrder?.ticketNumber ?? '—'
                            )}
                          </td>
                          <td>{usersMap.get(r.requestedBy)?.name ?? '—'}</td>
                          <td className="max-w-[200px] truncate" title={partsSummary}>
                            {partsSummary}
                          </td>
                          <td className="text-sm text-muted-foreground">
                            {r.requestedAt ? new Date(r.requestedAt).toLocaleDateString() : '—'}
                          </td>
                          <td>
                            <StatusBadge status={r.status} />
                          </td>
                          <td>
                            {r.status === 'pending' && (
                              <div className="flex gap-2">
                                <Button
                                  size="sm"
                                  onClick={() => handleApprove(r)}
                                  disabled={approveMutation.isPending || rejectMutation.isPending}
                                >
                                  Approve
                                </Button>
                                <Button
                                  variant="destructive"
                                  size="sm"
                                  onClick={() => handleReject(r)}
                                  disabled={approveMutation.isPending || rejectMutation.isPending}
                                >
                                  Reject
                                </Button>
                              </div>
                            )}
                          </td>
                        </tr>
                      );
                    })}
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
