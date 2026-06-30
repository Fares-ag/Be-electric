'use client';

import { useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';
import { isLowStockItem, type InventoryItemRow } from '@/lib/inventory';
import { Pagination } from '@/components/Pagination';
import { SearchFilterBar } from '@/components/SearchFilterBar';
import { usePagination } from '@/hooks/usePagination';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Modal, ModalActions } from '@/components/ui/Modal';
import { FilterChipLink } from '@/components/ui/FilterChipLink';
import { DismissibleHint } from '@/components/ui/DismissibleHint';
import { DataTableShell, PageHeader } from '@/components/ui/PageStates';
import { Boxes } from 'lucide-react';

type InventoryItem = InventoryItemRow;

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
  const searchParams = useSearchParams();
  const stockFilter = searchParams.get('filter') ?? undefined;
  const queryClient = useQueryClient();
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<InventoryItem | null>(null);
  const [form, setForm] = useState(emptyForm);
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  const { data: items, isLoading, error: queryError, refetch } = useQuery({
    queryKey: ['inventory'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { data, error: err } = await supabase
        .from('inventory_items')
        .select('*')
        .order('name');
      if (err) throw err;
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
    onError: (err: Error) => setFormError(err.message),
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
    onError: (err: Error) => setFormError(err.message),
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      const { error: e } = await supabase.from('inventory_items').delete().eq('id', id);
      if (e) throw e;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['inventory'] }),
    onError: (err: Error) => setFormError(err.message),
  });

  const openAdd = () => {
    setEditing(null);
    setForm(emptyForm);
    setFormError(null);
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
    setFormError(null);
    setModalOpen(true);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (submitting) return;
    setFormError(null);
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

  const lowStock = items?.filter(isLowStockItem) ?? [];

  const [search, setSearch] = useState('');
  const filtered = useMemo(() => {
    let list = items ?? [];
    if (stockFilter === 'lowStock') {
      list = list.filter(isLowStockItem);
    }
    if (!search.trim()) return list;
    const q = search.trim().toLowerCase();
    return list.filter(
      (i) =>
        i.name.toLowerCase().includes(q) ||
        (i.category ?? '').toLowerCase().includes(q) ||
        (i.sku ?? '').toLowerCase().includes(q) ||
        (i.location ?? '').toLowerCase().includes(q)
    );
  }, [items, search, stockFilter]);

  const { page, setPage, pageSize, setPageSize, paginatedItems, totalItems } =
    usePagination(filtered);

  useEffect(() => setPage(1), [search, stockFilter, setPage]);

  const hasActiveFilters = !!search.trim() || stockFilter === 'lowStock';
  const showEmptySearch = !isLoading && !queryError && (items?.length ?? 0) > 0 && filtered.length === 0;

  return (
    <div className="space-y-4 sm:space-y-6">
      <PageHeader
        title="Inventory"
        description="Spare parts and consumables — low-stock items link from the dashboard KPI."
        actions={
          <>
            <SearchFilterBar
              search={search}
              onSearchChange={setSearch}
              placeholder="Search name, category, SKU..."
              className="sm:min-w-[220px]"
            />
            {lowStock.length > 0 && (
              <span className="text-sm font-medium text-amber-600">{lowStock.length} low stock</span>
            )}
            <Button onClick={openAdd} className="shrink-0">
              Add Item
            </Button>
          </>
        }
      />

      <DismissibleHint hintKey="inventory-overview" title="Inventory quick guide">
        <p>
          Set a <strong className="font-medium text-foreground">minimum stock</strong> on each item — when
          quantity falls at or below it, the item appears in{' '}
          <Link href="/inventory?filter=lowStock" className="text-primary underline-offset-2 hover:underline">
            Low stock
          </Link>{' '}
          and on the dashboard KPI. Update quantities after parts are used or received.
        </p>
      </DismissibleHint>

      <div className="flex flex-wrap gap-2">
        <FilterChipLink href="/inventory" active={!stockFilter} count={items?.length}>
          All items
        </FilterChipLink>
        <FilterChipLink
          href="/inventory?filter=lowStock"
          active={stockFilter === 'lowStock'}
          count={lowStock.length}
        >
          Low stock
        </FilterChipLink>
      </div>
      {stockFilter === 'lowStock' && (
        <p className="text-sm text-muted-foreground">
          Showing items at or below minimum stock level.
        </p>
      )}

      <Card>
        <CardContent className="p-0">
          <DataTableShell
            isLoading={isLoading}
            error={queryError}
            isEmpty={!isLoading && !queryError && (items?.length ?? 0) === 0}
            emptyTitle="No inventory items yet"
            emptyDescription="Track spare parts and consumables used in maintenance."
            emptyAction={
              <Button type="button" onClick={openAdd}>
                Add Item
              </Button>
            }
            emptyIcon={Boxes}
            emptyIconClassName="bg-amber-100 text-amber-800"
            onRetry={() => refetch()}
          >
            {showEmptySearch ? (
              <div className="flex flex-col items-center px-6 py-14 text-center">
                <div className="mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-amber-100 text-amber-800">
                  <Boxes className="h-7 w-7" aria-hidden />
                </div>
                <p className="font-medium text-foreground">No matching items</p>
                <p className="mt-1 max-w-sm text-sm text-muted-foreground">
                  Try a different search term or stock filter.
                </p>
                {hasActiveFilters && (
                  <Link href="/inventory" className="mt-4">
                    <Button variant="outline">Clear filters</Button>
                  </Link>
                )}
              </div>
            ) : (
              <div className="table-scroll overflow-x-auto">
                <table className="table-modern">
                  <thead>
                    <tr>
                      <th>Name</th>
                      <th>Category</th>
                      <th>Quantity</th>
                      <th>Unit</th>
                      <th>Min</th>
                      <th>Status</th>
                      <th className="w-40" />
                    </tr>
                  </thead>
                  <tbody>
                    {paginatedItems.map((i) => {
                      const qty = i.currentStock ?? 0;
                      const min = i.minStock;
                      const isLow = isLowStockItem(i);
                      return (
                        <tr key={i.id} className="transition-colors hover:bg-muted/40">
                          <td className="font-medium">{i.name}</td>
                          <td>{i.category ?? '—'}</td>
                          <td className={isLow ? 'font-medium text-amber-600' : ''}>{String(qty)}</td>
                          <td>{i.unit ?? '—'}</td>
                          <td>{min != null ? String(min) : '—'}</td>
                          <td>{isLow ? 'Low' : 'OK'}</td>
                          <td>
                            <div className="flex gap-2">
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
                            </div>
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

      <Modal
        open={modalOpen}
        onClose={() => { setModalOpen(false); setFormError(null); }}
        title={editing ? 'Edit Item' : 'Add Item'}
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          {formError && (
            <p className="text-sm text-destructive bg-destructive/10 p-2 rounded">{formError}</p>
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
