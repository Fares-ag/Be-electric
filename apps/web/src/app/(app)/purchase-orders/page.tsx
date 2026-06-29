'use client';

import { useEffect, useMemo, useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Pagination } from '@/components/Pagination';
import { SearchFilterBar } from '@/components/SearchFilterBar';
import { usePagination } from '@/hooks/usePagination';
import { useFormSubmitLock } from '@/hooks/useFormSubmitLock';
import { supabase } from '@/lib/supabase';
import { useAuthStore } from '@/stores/auth-store';
import { isAdminRole } from '@/lib/roles';
import {
  allowedPurchaseOrderStatuses,
  formatPurchaseOrderLabel,
  isAllowedPurchaseOrderStatusTransition,
  type PurchaseOrderRow,
  type PurchaseOrderStatus,
} from '@/lib/purchase-orders';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Modal, ModalActions } from '@/components/ui/Modal';
import { StatusBadge } from '@/components/ui/Badge';
import { DataTableShell, PageHeader } from '@/components/ui/PageStates';

export default function PurchaseOrdersPage() {
  const queryClient = useQueryClient();
  const user = useAuthStore((s) => s.user);
  const canManage = isAdminRole(user?.role);
  const [modalOpen, setModalOpen] = useState(false);
  const [viewPo, setViewPo] = useState<PurchaseOrderRow | null>(null);
  const [orderNumber, setOrderNumber] = useState('');
  const [statusError, setStatusError] = useState<string | null>(null);
  const [formError, setFormError] = useState<string | null>(null);
  const { submitting, runSubmit } = useFormSubmitLock();

  const { data: pos, isLoading, error: queryError, refetch } = useQuery({
    queryKey: ['purchase-orders'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { data, error: err } = await supabase
        .from('purchase_orders')
        .select('id, orderNumber, status, orderedItems, requestedBy, createdAt, orderedAt, receivedAt, updatedAt')
        .order('createdAt', { ascending: false });
      if (err) throw err;
      return (data ?? []) as PurchaseOrderRow[];
    },
  });

  const createMutation = useMutation({
    mutationFn: async (poNumber: string) => {
      if (!user?.id) throw new Error('Not signed in');
      const now = new Date().toISOString();
      const { error: e } = await supabase.from('purchase_orders').insert({
        id: crypto.randomUUID(),
        requestedBy: user.id,
        orderNumber: poNumber.trim() || null,
        orderedItems: [],
        status: 'draft',
        orderedAt: now,
        updatedAt: now,
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

  const updateStatusMutation = useMutation({
    mutationFn: async ({ id, status, current }: { id: string; status: PurchaseOrderStatus; current: string }) => {
      if (!isAllowedPurchaseOrderStatusTransition(current, status)) {
        throw new Error(
          `Cannot change status from ${formatPurchaseOrderLabel(current)} to ${formatPurchaseOrderLabel(status)}.`
        );
      }
      const now = new Date().toISOString();
      const updates: Record<string, unknown> = { status, updatedAt: now };
      if (status === 'ordered') updates.orderedAt = now;
      if (status === 'received') updates.receivedAt = now;
      const { error } = await supabase.from('purchase_orders').update(updates).eq('id', id);
      if (error) throw error;
    },
    onSuccess: (_, { id, status }) => {
      setStatusError(null);
      queryClient.invalidateQueries({ queryKey: ['purchase-orders'] });
      setViewPo((prev) => (prev?.id === id ? { ...prev, status } : prev));
    },
    onError: (err: Error) => setStatusError(err.message),
  });

  const [search, setSearch] = useState('');
  const filtered = useMemo(() => {
    const list = pos ?? [];
    if (!search.trim()) return list;
    const q = search.trim().toLowerCase();
    return list.filter(
      (po) =>
        String(po.orderNumber ?? po.id).toLowerCase().includes(q) ||
        po.status.toLowerCase().includes(q)
    );
  }, [pos, search]);

  const { page, setPage, pageSize, setPageSize, paginatedItems, totalItems } =
    usePagination(filtered);

  useEffect(() => setPage(1), [search, setPage]);

  const handleCreate = (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);
    void runSubmit(async () => createMutation.mutateAsync(orderNumber));
  };

  const statusOptions = viewPo ? allowedPurchaseOrderStatuses(viewPo.status) : [];

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
            {canManage && (
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
            )}
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
              canManage ? (
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
              ) : undefined
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
                    {paginatedItems.map((po) => (
                      <tr key={po.id}>
                        <td className="font-medium">{po.orderNumber ?? po.id.slice(0, 8)}</td>
                        <td>
                          <StatusBadge status={po.status} />
                        </td>
                        <td>
                          {po.createdAt ? new Date(po.createdAt).toLocaleDateString() : '—'}
                        </td>
                        <td>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => {
                              setViewPo(po);
                              setStatusError(null);
                            }}
                          >
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
        onClose={() => {
          setModalOpen(false);
          setFormError(null);
        }}
        title="Create Purchase Order"
      >
        <form onSubmit={handleCreate} className="space-y-4">
          {formError && (
            <p className="rounded bg-destructive/10 p-2 text-sm text-destructive">{formError}</p>
          )}
          <div>
            <label className="mb-1 block text-sm font-medium text-foreground">
              PO / Order number (optional)
            </label>
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
              {submitting ? 'Creating…' : 'Create PO'}
            </Button>
          </ModalActions>
        </form>
      </Modal>

      <Modal
        open={!!viewPo}
        onClose={() => {
          setViewPo(null);
          setStatusError(null);
        }}
        title={viewPo ? `PO ${viewPo.orderNumber ?? viewPo.id.slice(0, 8)}` : 'Purchase order'}
      >
        {viewPo && (
          <dl className="space-y-3 text-sm">
            <div>
              <dt className="text-muted-foreground">Status</dt>
              <dd className="mt-0.5">
                {canManage ? (
                  <select
                    value={viewPo.status}
                    disabled={updateStatusMutation.isPending}
                    onChange={(e) =>
                      updateStatusMutation.mutate({
                        id: viewPo.id,
                        status: e.target.value as PurchaseOrderStatus,
                        current: viewPo.status,
                      })
                    }
                    className="mt-1 rounded-lg border border-border bg-background px-3 py-2 text-sm capitalize"
                  >
                    {statusOptions.map((value) => (
                      <option key={value} value={value}>
                        {formatPurchaseOrderLabel(value)}
                      </option>
                    ))}
                  </select>
                ) : (
                  <StatusBadge status={viewPo.status} />
                )}
              </dd>
            </div>
            {statusError && (
              <p className="text-sm text-destructive" role="alert">
                {statusError}
              </p>
            )}
            <div>
              <dt className="text-muted-foreground">Created</dt>
              <dd className="mt-0.5 font-medium">
                {viewPo.createdAt ? new Date(viewPo.createdAt).toLocaleString() : '—'}
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
            {viewPo.status === 'draft' && (
              <p className="text-xs text-muted-foreground">
                Move to Submitted when the PO is ready for approval, then Ordered and Received as procurement progresses.
              </p>
            )}
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
