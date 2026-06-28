'use client';

import { useState, useMemo, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Pagination } from '@/components/Pagination';
import { SearchFilterBar } from '@/components/SearchFilterBar';
import { usePagination } from '@/hooks/usePagination';
import { supabase } from '@/lib/supabase';
import { useAuthStore } from '@/stores/auth-store';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Modal, ModalActions } from '@/components/ui/Modal';
import { StatusBadge } from '@/components/ui/Badge';
import { DataTableShell, PageHeader } from '@/components/ui/PageStates';

export default function PurchaseOrdersPage() {
  const queryClient = useQueryClient();
  const user = useAuthStore((s) => s.user);
  const [modalOpen, setModalOpen] = useState(false);
  const [viewPo, setViewPo] = useState<Record<string, unknown> | null>(null);
  const [orderNumber, setOrderNumber] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  const { data: pos, isLoading, error: queryError, refetch } = useQuery({
    queryKey: ['purchase-orders'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { data, error: err } = await supabase
        .from('purchase_orders')
        .select('*')
        .order('createdAt', { ascending: false });
      if (err) throw err;
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
    onError: (err: Error) => setFormError(err.message),
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
    if (submitting) return;
    setFormError(null);
    setSubmitting(true);
    createMutation.mutate(orderNumber, { onSettled: () => setSubmitting(false) });
  };

  return (
    <div className="space-y-4 sm:space-y-6">
      <PageHeader
        title="Purchase Orders"
        actions={
          <>
            <SearchFilterBar
              search={search}
              onSearchChange={setSearch}
              placeholder="Search PO #, status..."
              className="sm:min-w-[220px]"
            />
            <Button
              onClick={() => {
                setModalOpen(true);
                setFormError(null);
                setOrderNumber('');
              }}
              className="shrink-0"
            >
              Create PO
            </Button>
          </>
        }
      />
      <Card>
        <CardContent className="p-0">
          <DataTableShell
            isLoading={isLoading}
            error={queryError}
            isEmpty={!isLoading && !queryError && (pos?.length ?? 0) === 0}
            emptyTitle="No purchase orders yet"
            emptyDescription="Create a purchase order to track parts and supplies procurement."
            emptyAction={
              <Button
                type="button"
                onClick={() => {
                  setModalOpen(true);
                  setFormError(null);
                  setOrderNumber('');
                }}
              >
                Create PO
              </Button>
            }
            onRetry={() => refetch()}
          >
            {filtered.length === 0 && (pos?.length ?? 0) > 0 ? (
              <div className="px-6 py-12 text-center">
                <p className="font-medium text-foreground">No matching purchase orders</p>
                <p className="mt-1 text-sm text-muted-foreground">Try a different search term.</p>
              </div>
            ) : (
              <div className="table-scroll overflow-x-auto">
                <table className="table-modern">
                  <thead>
                    <tr>
                      <th>PO #</th>
                      <th>Status</th>
                      <th>Date</th>
                      <th className="w-24" />
                    </tr>
                  </thead>
                  <tbody>
                    {paginatedItems.map((po: Record<string, unknown>) => (
                      <tr key={po.id as string}>
                        <td className="font-medium">
                          {String(po.orderNumber ?? po.poNumber ?? po.id)}
                        </td>
                        <td>
                          <StatusBadge status={po.status != null ? String(po.status) : undefined} />
                        </td>
                        <td>
                          {po.createdAt
                            ? new Date(po.createdAt as string).toLocaleDateString()
                            : '—'}
                        </td>
                        <td>
                          <Button variant="outline" size="sm" onClick={() => setViewPo(po)}>
                            View
                          </Button>
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

      <Modal
        open={modalOpen}
        onClose={() => { setModalOpen(false); setFormError(null); }}
        title="Create Purchase Order"
      >
        <form onSubmit={handleCreate} className="space-y-4">
          {formError && (
            <p className="text-sm text-destructive bg-destructive/10 p-2 rounded">{formError}</p>
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

      <Modal
        open={!!viewPo}
        onClose={() => setViewPo(null)}
        title={viewPo ? `PO ${String(viewPo.orderNumber ?? viewPo.poNumber ?? viewPo.id)}` : 'Purchase order'}
      >
        {viewPo && (
          <dl className="space-y-3 text-sm">
            <div>
              <dt className="text-muted-foreground">Status</dt>
              <dd className="mt-0.5 font-medium capitalize">{String(viewPo.status ?? '—')}</dd>
            </div>
            <div>
              <dt className="text-muted-foreground">Created</dt>
              <dd className="mt-0.5 font-medium">
                {viewPo.createdAt
                  ? new Date(viewPo.createdAt as string).toLocaleString()
                  : '—'}
              </dd>
            </div>
            <div>
              <dt className="text-muted-foreground">Ordered items</dt>
              <dd className="mt-0.5 font-medium">
                {Array.isArray(viewPo.orderedItems) && viewPo.orderedItems.length > 0
                  ? `${viewPo.orderedItems.length} line item(s)`
                  : 'No items yet'}
              </dd>
            </div>
          </dl>
        )}
        <ModalActions>
          <Button type="button" variant="outline" onClick={() => setViewPo(null)}>
            Close
          </Button>
        </ModalActions>
      </Modal>
    </div>
  );
}
