'use client';

import { useState, useMemo, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Pagination } from '@/components/Pagination';
import { SearchFilterBar } from '@/components/SearchFilterBar';
import { usePagination } from '@/hooks/usePagination';
import { supabase } from '@/lib/supabase';
import { useAuthStore } from '@/stores/auth-store';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Modal, ModalActions } from '@/components/ui/Modal';
import { StatusBadge } from '@/components/ui/Badge';

export default function PurchaseOrdersPage() {
  const queryClient = useQueryClient();
  const user = useAuthStore((s) => s.user);
  const [modalOpen, setModalOpen] = useState(false);
  const [orderNumber, setOrderNumber] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const { data: pos, isLoading } = useQuery({
    queryKey: ['purchase-orders'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { data } = await supabase
        .from('purchase_orders')
        .select('*')
        .order('createdAt', { ascending: false });
      return data ?? [];
    },
  });

  const createMutation = useMutation({
    mutationFn: async (poNumber: string) => {
      const { error: e } = await supabase.from('purchase_orders').insert({
        requestedBy: user!.id,
        orderNumber: poNumber.trim() || null,
        orderedItems: [],
        status: 'draft',
        orderedAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      });
      if (e) throw e;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['purchase-orders'] });
      setModalOpen(false);
      setOrderNumber('');
    },
    onError: (err: Error) => setError(err.message),
  });

  const [search, setSearch] = useState('');
  const filtered = useMemo(() => {
    const list = pos ?? [];
    if (!search.trim()) return list;
    const q = search.trim().toLowerCase();
    return list.filter(
      (po: Record<string, unknown>) =>
        String(po.orderNumber ?? po.poNumber ?? po.id ?? '').toLowerCase().includes(q) ||
        String(po.status ?? '').toLowerCase().includes(q)
    );
  }, [pos, search]);

  const { page, setPage, pageSize, setPageSize, paginatedItems, totalItems } =
    usePagination(filtered);

  useEffect(() => setPage(1), [search, setPage]);

  const handleCreate = (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    createMutation.mutate(orderNumber, { onSettled: () => setSubmitting(false) });
  };

  return (
    <div className="space-y-4 sm:space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <h1 className="font-display text-2xl font-semibold tracking-tight text-foreground">Purchase Orders</h1>
        <div className="flex flex-col sm:flex-row gap-3 sm:items-center">
          <SearchFilterBar
            search={search}
            onSearchChange={setSearch}
            placeholder="Search PO #, status..."
            className="sm:min-w-[220px]"
          />
          <Button onClick={() => { setModalOpen(true); setError(null); setOrderNumber(''); }} className="shrink-0">Create PO</Button>
        </div>
      </div>
      <Card>
        {isLoading ? (
          <p className="text-[#757575]">Loading...</p>
        ) : !pos?.length ? (
          <p className="text-[#757575]">No purchase orders yet.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="table-modern">
              <thead>
                <tr className="border-b border-[#E0E0E0]">
                  <th className="text-left py-3 px-4 font-semibold">PO #</th>
                  <th className="text-left py-3 px-4 font-semibold">Status</th>
                  <th className="text-left py-3 px-4 font-semibold">Date</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {paginatedItems.map((po: Record<string, unknown>) => (
                  <tr key={po.id as string} className="border-b border-[#E0E0E0]">
                    <td className="py-3 px-4 font-medium">{String(po.orderNumber ?? po.poNumber ?? po.id)}</td>
                    <td className="py-3 px-4">
                      <StatusBadge status={po.status != null ? String(po.status) : undefined} />
                    </td>
                    <td className="py-3 px-4">
                      {po.createdAt
                        ? new Date(po.createdAt as string).toLocaleDateString()
                        : '-'}
                    </td>
                    <td className="py-3 px-4">
                      <Button variant="outline">View</Button>
                    </td>
                  </tr>
                ))}
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

      <Modal
        open={modalOpen}
        onClose={() => { setModalOpen(false); setError(null); }}
        title="Create Purchase Order"
      >
        <form onSubmit={handleCreate} className="space-y-4">
          {error && (
            <p className="text-sm text-destructive bg-destructive/10 p-2 rounded">{error}</p>
          )}
          <div>
            <label className="block text-sm font-medium text-foreground mb-1">PO / Order number (optional)</label>
            <input
              type="text"
              value={orderNumber}
              onChange={(e) => setOrderNumber(e.target.value)}
              placeholder="e.g. PO-2024-001"
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
            />
          </div>
          <ModalActions>
            <Button type="button" variant="outline" onClick={() => setModalOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={submitting || !user?.id}>
              {submitting ? 'Creating...' : 'Create PO'}
            </Button>
          </ModalActions>
        </form>
      </Modal>
    </div>
  );
}
