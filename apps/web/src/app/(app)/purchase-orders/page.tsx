'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
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

  const handleCreate = (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    createMutation.mutate(orderNumber, { onSettled: () => setSubmitting(false) });
  };

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-[#000]">Purchase Orders</h1>
        <Button onClick={() => { setModalOpen(true); setError(null); setOrderNumber(''); }}>Create PO</Button>
      </div>
      <Card>
        {isLoading ? (
          <p className="text-[#757575]">Loading...</p>
        ) : !pos?.length ? (
          <p className="text-[#757575]">No purchase orders yet.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[#E0E0E0]">
                  <th className="text-left py-3 px-4 font-semibold">PO #</th>
                  <th className="text-left py-3 px-4 font-semibold">Status</th>
                  <th className="text-left py-3 px-4 font-semibold">Date</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {pos.map((po: Record<string, unknown>) => (
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
