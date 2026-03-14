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

  const { data: requests, isLoading } = useQuery({
    queryKey: ['parts-requests'],
    queryFn: async () => {
      const { data } = await supabase
        .from('parts_requests')
        .select(
          'id, status, requestedBy, requestedAt, requestedParts, workOrderId, workOrder:work_orders(ticketNumber)'
        )
        .order('requestedAt', { ascending: false });
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
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <h1 className="font-display text-2xl font-semibold tracking-tight text-foreground">Parts Requests</h1>
        <div className="flex flex-col sm:flex-row gap-3 sm:items-center">
          <SearchFilterBar
            search={search}
            onSearchChange={setSearch}
            placeholder="Search WO, requester, status..."
            className="sm:min-w-[220px]"
          />
          {pending.length > 0 && (
            <span className="text-sm text-primary font-medium">
              {pending.length} pending
            </span>
          )}
        </div>
      </div>
      <Card>
        {isLoading ? (
          <p className="text-[#757575]">Loading...</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="table-modern">
              <thead>
                <tr className="border-b border-[#E0E0E0]">
                  <th className="text-left py-3 px-4 font-semibold">WO</th>
                  <th className="text-left py-3 px-4 font-semibold">Requested by</th>
                  <th className="text-left py-3 px-4 font-semibold">Parts</th>
                  <th className="text-left py-3 px-4 font-semibold">Requested</th>
                  <th className="text-left py-3 px-4 font-semibold">Status</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {paginatedItems.map((r) => {
                  const parts = r.requestedParts as Array<{ name?: string; quantity?: number; unit?: string }> | undefined;
                  const partsSummary = Array.isArray(parts)
                    ? parts.map((p) => `${p.name ?? '?'} (×${p.quantity ?? 0})`).join(', ') || '-'
                    : typeof parts === 'object' && parts !== null
                      ? JSON.stringify(parts)
                      : '-';
                  return (
                    <tr key={r.id} className="border-b border-[#E0E0E0]">
                      <td className="py-3 px-4">
                        {r.workOrderId ? (
                          <Link href={`/work-orders/${r.workOrderId}`} className="text-primary hover:underline">
                            {r.workOrder?.ticketNumber ?? r.workOrderId.slice(0, 8)}
                          </Link>
                        ) : (
                          r.workOrder?.ticketNumber ?? '-'
                        )}
                      </td>
                      <td className="py-3 px-4">{usersMap.get(r.requestedBy)?.name ?? '-'}</td>
                      <td className="py-3 px-4 max-w-[200px] truncate" title={partsSummary}>
                        {partsSummary}
                      </td>
                      <td className="py-3 px-4 text-muted-foreground text-sm">
                        {r.requestedAt ? new Date(r.requestedAt).toLocaleDateString() : '-'}
                      </td>
                      <td className="py-3 px-4">
                        <StatusBadge status={r.status} />
                      </td>
                      <td className="py-3 px-4">
                        {r.status === 'pending' && (
                          <div className="flex gap-2">
                            <Button
                              onClick={() => handleApprove(r)}
                              disabled={approveMutation.isPending || rejectMutation.isPending}
                            >
                              Approve
                            </Button>
                            <Button
                              variant="destructive"
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
        {!isLoading && totalItems > 0 && (
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
