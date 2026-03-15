'use client';

import { useState, useMemo, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { Pagination } from '@/components/Pagination';
import { SearchFilterBar } from '@/components/SearchFilterBar';
import { usePagination } from '@/hooks/usePagination';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Modal, ModalActions } from '@/components/ui/Modal';

type InventoryItem = {
  id: string;
  name: string;
  category: string | null;
  currentStock: number;
  minStock: number;
  unit: string | null;
  sku: string | null;
  location: string | null;
  description: string | null;
};

const emptyForm = {
  name: '',
  category: '',
  currentStock: 0,
  minStock: 0,
  unit: '',
  sku: '',
  location: '',
  description: '',
};

export default function InventoryPage() {
  const queryClient = useQueryClient();
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<InventoryItem | null>(null);
  const [form, setForm] = useState(emptyForm);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const { data: items, isLoading } = useQuery({
    queryKey: ['inventory'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { data } = await supabase
        .from('inventory_items')
        .select('*')
        .order('name');
      return (data ?? []) as InventoryItem[];
    },
  });

  const createMutation = useMutation({
    mutationFn: async (payload: typeof emptyForm) => {
      const { error: e } = await supabase.from('inventory_items').insert({
        id: crypto.randomUUID(),
        name: payload.name.trim(),
        category: payload.category.trim() || null,
        currentStock: Number(payload.currentStock) || 0,
        minStock: Number(payload.minStock) || 0,
        unit: payload.unit.trim() || null,
        sku: payload.sku.trim() || null,
        location: payload.location.trim() || null,
        description: payload.description.trim() || null,
        updatedAt: new Date().toISOString(),
      });
      if (e) throw e;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['inventory'] });
      setModalOpen(false);
      setForm(emptyForm);
      setEditing(null);
    },
    onError: (err: Error) => setError(err.message),
  });

  const updateMutation = useMutation({
    mutationFn: async ({ id, ...payload }: InventoryItem & typeof emptyForm) => {
      const { error: e } = await supabase
        .from('inventory_items')
        .update({
          name: payload.name.trim(),
          category: payload.category.trim() || null,
          currentStock: Number(payload.currentStock) || 0,
          minStock: Number(payload.minStock) || 0,
          unit: payload.unit.trim() || null,
          sku: payload.sku.trim() || null,
          location: payload.location.trim() || null,
          description: payload.description.trim() || null,
          updatedAt: new Date().toISOString(),
        })
        .eq('id', id);
      if (e) throw e;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['inventory'] });
      setModalOpen(false);
      setForm(emptyForm);
      setEditing(null);
    },
    onError: (err: Error) => setError(err.message),
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      const { error: e } = await supabase.from('inventory_items').delete().eq('id', id);
      if (e) throw e;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['inventory'] }),
    onError: (err: Error) => setError(err.message),
  });

  const openAdd = () => {
    setEditing(null);
    setForm(emptyForm);
    setError(null);
    setModalOpen(true);
  };

  const openEdit = (item: InventoryItem) => {
    setEditing(item);
    setForm({
      name: item.name,
      category: item.category ?? '',
      currentStock: item.currentStock ?? 0,
      minStock: item.minStock ?? 0,
      unit: item.unit ?? '',
      sku: item.sku ?? '',
      location: item.location ?? '',
      description: item.description ?? '',
    });
    setError(null);
    setModalOpen(true);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    if (editing) {
      updateMutation.mutate(
        { ...editing, ...form },
        { onSettled: () => setSubmitting(false) }
      );
    } else {
      createMutation.mutate(form, { onSettled: () => setSubmitting(false) });
    }
  };

  const handleDelete = (item: InventoryItem) => {
    if (window.confirm(`Delete item "${item.name}"?`)) deleteMutation.mutate(item.id);
  };

  const stock = (i: InventoryItem) => (i as Record<string, unknown>).quantity ?? i.currentStock;
  const minS = (i: InventoryItem) => (i as Record<string, unknown>).minimumStock ?? i.minStock;
  const lowStock = items?.filter((i) => minS(i) != null && Number(stock(i)) <= Number(minS(i))) ?? [];

  const [search, setSearch] = useState('');
  const filtered = useMemo(() => {
    const list = items ?? [];
    if (!search.trim()) return list;
    const q = search.trim().toLowerCase();
    return list.filter(
      (i) =>
        i.name.toLowerCase().includes(q) ||
        (i.category ?? '').toLowerCase().includes(q) ||
        (i.sku ?? '').toLowerCase().includes(q) ||
        (i.location ?? '').toLowerCase().includes(q)
    );
  }, [items, search]);

  const { page, setPage, pageSize, setPageSize, paginatedItems, totalItems } =
    usePagination(filtered);

  useEffect(() => setPage(1), [search, setPage]);

  return (
    <div className="space-y-4 sm:space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <h1 className="font-display text-2xl font-semibold tracking-tight text-foreground">Inventory</h1>
        <div className="flex flex-col sm:flex-row gap-3 sm:items-center">
          <SearchFilterBar
            search={search}
            onSearchChange={setSearch}
            placeholder="Search name, category, SKU..."
            className="sm:min-w-[220px]"
          />
          {lowStock.length > 0 && (
          <span className="text-sm text-amber-600 font-medium">
            {lowStock.length} low stock
          </span>
          )}
          <Button onClick={openAdd} className="shrink-0">Add Item</Button>
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
                  <th className="text-left py-3 px-4 font-semibold">Name</th>
                  <th className="text-left py-3 px-4 font-semibold">Category</th>
                  <th className="text-left py-3 px-4 font-semibold">Quantity</th>
                  <th className="text-left py-3 px-4 font-semibold">Unit</th>
                  <th className="text-left py-3 px-4 font-semibold">Min</th>
                  <th className="text-left py-3 px-4 font-semibold">Status</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {paginatedItems.map((i) => {
                  const qty = Number(stock(i));
                  const min = minS(i) != null ? Number(minS(i)) : null;
                  const isLow = min != null && qty <= min;
                  return (
                    <tr key={i.id} className="border-b border-[#E0E0E0]">
                      <td className="py-3 px-4 font-medium">{i.name}</td>
                      <td className="py-3 px-4">{i.category ?? '-'}</td>
                      <td className={`py-3 px-4 ${isLow ? 'text-[#F57C00] font-medium' : ''}`}>
                        {String(qty)}
                      </td>
                      <td className="py-3 px-4">{i.unit ?? '-'}</td>
                      <td className="py-3 px-4">{min != null ? String(min) : '-'}</td>
                      <td className="py-3 px-4">{isLow ? 'Low' : 'OK'}</td>
                      <td className="py-3 px-4 flex gap-2">
                        <Button variant="outline" size="sm" onClick={() => openEdit(i)}>
                          Edit
                        </Button>
                        <Button
                          variant="destructive"
                          size="sm"
                          onClick={() => handleDelete(i)}
                          disabled={deleteMutation.isPending}
                        >
                          Delete
                        </Button>
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

      <Modal
        open={modalOpen}
        onClose={() => { setModalOpen(false); setError(null); }}
        title={editing ? 'Edit Item' : 'Add Item'}
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          {error && (
            <p className="text-sm text-destructive bg-destructive/10 p-2 rounded">{error}</p>
          )}
          <div>
            <label className="block text-sm font-medium text-foreground mb-1">Name *</label>
            <input
              type="text"
              required
              value={form.name}
              onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground mb-1">Category</label>
            <input
              type="text"
              value={form.category}
              onChange={(e) => setForm((f) => ({ ...f, category: e.target.value }))}
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-foreground mb-1">Current stock</label>
              <input
                type="number"
                min={0}
                value={form.currentStock}
                onChange={(e) => setForm((f) => ({ ...f, currentStock: Number(e.target.value) || 0 }))}
                className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-foreground mb-1">Min stock</label>
              <input
                type="number"
                min={0}
                value={form.minStock}
                onChange={(e) => setForm((f) => ({ ...f, minStock: Number(e.target.value) || 0 }))}
                className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
              />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground mb-1">Unit</label>
            <input
              type="text"
              value={form.unit}
              onChange={(e) => setForm((f) => ({ ...f, unit: e.target.value }))}
              placeholder="e.g. each, box"
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground mb-1">SKU</label>
            <input
              type="text"
              value={form.sku}
              onChange={(e) => setForm((f) => ({ ...f, sku: e.target.value }))}
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground mb-1">Location</label>
            <input
              type="text"
              value={form.location}
              onChange={(e) => setForm((f) => ({ ...f, location: e.target.value }))}
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground mb-1">Description</label>
            <textarea
              value={form.description}
              onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))}
              rows={2}
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
            />
          </div>
          <ModalActions>
            <Button type="button" variant="outline" onClick={() => setModalOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={submitting}>
              {submitting ? 'Saving...' : editing ? 'Save' : 'Add Item'}
            </Button>
          </ModalActions>
        </form>
      </Modal>
    </div>
  );
}
