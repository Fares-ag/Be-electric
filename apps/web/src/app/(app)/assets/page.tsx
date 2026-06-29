'use client';

import { useState, useMemo, useEffect } from 'react';
import { useSearchParams } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';
import { Pagination } from '@/components/Pagination';
import { SearchFilterBar } from '@/components/SearchFilterBar';
import { usePagination } from '@/hooks/usePagination';
import { useFormSubmitLock } from '@/hooks/useFormSubmitLock';
import { ASSET_STATUSES, validateAssetForm } from '@/lib/assets';
import { manufacturerFromChargerName } from '@/lib/charger-manufacturer';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Modal, ModalActions } from '@/components/ui/Modal';
import { StatusBadge } from '@/components/ui/Badge';
import { DataTableShell, PageHeader } from '@/components/ui/PageStates';

type Asset = {
  id: string;
  name: string;
  location: string | null;
  assetType: string | null;
  status: string | null;
  companyId: string | null;
  manufacturer: string | null;
  model: string | null;
  serialNumber: string | null;
  company?: { name: string } | null;
};

const emptyForm = {
  name: '',
  location: '',
  assetType: '',
  status: 'active',
  companyId: '',
  manufacturer: '',
  model: '',
  serialNumber: '',
};

export default function AssetsPage() {
  const queryClient = useQueryClient();
  const searchParams = useSearchParams();
  const companyIdFromUrl = searchParams.get('companyId');
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Asset | null>(null);
  const [form, setForm] = useState(emptyForm);
  const { submitting, runSubmit } = useFormSubmitLock();
  const [formError, setFormError] = useState<string | null>(null);

  const { data: assets, isLoading, error: queryError, refetch } = useQuery({
    queryKey: ['assets'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { data, error: err } = await supabase
        .from('assets')
        .select('*, company:companies(name)')
        .order('name');
      if (err) throw err;
      return (data ?? []) as Asset[];
    },
  });

  const { data: companies } = useQuery({
    queryKey: ['companies'],
    queryFn: async () => {
      const { data } = await supabase.from('companies').select('id, name').order('name');
      return (data ?? []) as { id: string; name: string }[];
    },
  });

  const [search, setSearch] = useState('');
  const filtered = useMemo(() => {
    let list = assets ?? [];
    if (companyIdFromUrl) {
      list = list.filter((a) => (a.companyId ?? null) === companyIdFromUrl);
    }
    if (!search.trim()) return list;
    const q = search.trim().toLowerCase();
    return list.filter(
      (a) =>
        a.name.toLowerCase().includes(q) ||
        (a.location ?? '').toLowerCase().includes(q) ||
        (a.company?.name ?? '').toLowerCase().includes(q) ||
        (a.assetType ?? '').toLowerCase().includes(q)
    );
  }, [assets, search, companyIdFromUrl]);

  const filteredByCompanyName = companyIdFromUrl
    ? companies?.find((c) => c.id === companyIdFromUrl)?.name
    : null;

  const { page, setPage, pageSize, setPageSize, paginatedItems, totalItems } =
    usePagination(filtered);

  useEffect(() => setPage(1), [search, companyIdFromUrl, setPage]);

  const createMutation = useMutation({
    mutationFn: async (payload: typeof emptyForm) => {
      const manufacturer = manufacturerFromChargerName(payload.name.trim());
      const { error: e } = await supabase.from('assets').insert({
        id: crypto.randomUUID(),
        name: payload.name.trim(),
        location: payload.location.trim() || null,
        assetType: payload.assetType.trim() || null,
        status: payload.status.trim() || null,
        companyId: payload.companyId.trim() || null,
        manufacturer,
        model: payload.model.trim() || null,
        serialNumber: payload.serialNumber.trim() || null,
        updatedAt: new Date().toISOString(),
      });
      if (e) throw e;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['assets'] });
      queryClient.invalidateQueries({ queryKey: ['assets', 'charger-count-by-company'] });
      setModalOpen(false);
      setForm(emptyForm);
      setEditing(null);
    },
    onError: (err: Error) => setFormError(err.message),
  });

  const updateMutation = useMutation({
    mutationFn: async ({ id, ...payload }: Asset & typeof emptyForm) => {
      const manufacturer = manufacturerFromChargerName(payload.name.trim());
      const { error: e } = await supabase
        .from('assets')
        .update({
          name: payload.name.trim(),
          location: payload.location.trim() || null,
          assetType: payload.assetType.trim() || null,
          status: payload.status.trim() || null,
          companyId: payload.companyId.trim() || null,
          manufacturer,
          model: payload.model.trim() || null,
          serialNumber: payload.serialNumber.trim() || null,
          updatedAt: new Date().toISOString(),
        })
        .eq('id', id);
      if (e) throw e;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['assets'] });
      queryClient.invalidateQueries({ queryKey: ['assets', 'charger-count-by-company'] });
      setModalOpen(false);
      setForm(emptyForm);
      setEditing(null);
    },
    onError: (err: Error) => setFormError(err.message),
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      const { error: e } = await supabase.from('assets').delete().eq('id', id);
      if (e) throw e;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['assets'] });
      queryClient.invalidateQueries({ queryKey: ['assets', 'charger-count-by-company'] });
    },
    onError: (err: Error) => setFormError(err.message),
  });

  const openAdd = () => {
    setEditing(null);
    setForm({
      ...emptyForm,
      companyId: companyIdFromUrl ?? '',
    });
    setFormError(null);
    setModalOpen(true);
  };

  const openEdit = (a: Asset) => {
    setEditing(a);
    setForm({
      name: a.name,
      location: a.location ?? '',
      assetType: a.assetType ?? '',
      status: a.status ?? 'active',
      companyId: a.companyId ?? '',
      manufacturer: a.manufacturer ?? '',
      model: a.model ?? '',
      serialNumber: a.serialNumber ?? '',
    });
    setFormError(null);
    setModalOpen(true);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    void runSubmit(async () => {
      setFormError(null);
      const validationError = validateAssetForm({
        name: form.name,
        status: form.status,
      });
      if (validationError) {
        setFormError(validationError);
        return;
      }
      if (editing) {
        await updateMutation.mutateAsync({ ...editing, ...form });
      } else {
        await createMutation.mutateAsync(form);
      }
    });
  };

  const handleDelete = (a: Asset) => {
    if (window.confirm(`Delete charger "${a.name}"?`)) deleteMutation.mutate(a.id);
  };

  return (
    <div className="space-y-4 sm:space-y-6">
      <PageHeader
        title="Chargers"
        actions={
          <>
            <SearchFilterBar
              search={search}
              onSearchChange={setSearch}
              placeholder="Search name, location, company..."
              className="sm:min-w-[220px]"
            />
            <Button onClick={openAdd} className="shrink-0">
              Add Charger
            </Button>
          </>
        }
      />
      {filteredByCompanyName && (
        <p className="text-sm text-muted-foreground">
          Showing chargers for <span className="font-medium text-foreground">{filteredByCompanyName}</span>
          {' · '}
          <Link href="/assets" className="text-primary hover:underline">
            Show all
          </Link>
        </p>
      )}
      <Card>
        <CardContent className="p-0">
          <DataTableShell
            isLoading={isLoading}
            error={queryError}
            isEmpty={!isLoading && !queryError && (assets?.length ?? 0) === 0}
            emptyTitle="No chargers yet"
            emptyDescription="Register EV chargers to link them to work orders and PM tasks."
            emptyAction={
              <Button type="button" onClick={openAdd}>
                Add Charger
              </Button>
            }
            onRetry={() => refetch()}
          >
            {filtered.length === 0 && (assets?.length ?? 0) > 0 ? (
              <div className="px-6 py-12 text-center">
                <p className="font-medium text-foreground">No matching chargers</p>
                <p className="mt-1 text-sm text-muted-foreground">Try a different search or company filter.</p>
              </div>
            ) : (
              <div className="table-scroll overflow-x-auto">
                <table className="table-modern">
                  <thead>
                    <tr>
                      <th>Name</th>
                      <th>Company</th>
                      <th>Location</th>
                      <th>Type</th>
                      <th>Status</th>
                      <th className="w-40" />
                    </tr>
                  </thead>
                  <tbody>
                    {paginatedItems.map((a) => (
                      <tr key={a.id}>
                        <td className="font-medium">{a.name}</td>
                        <td>{a.company?.name ?? '—'}</td>
                        <td>{a.location ?? '—'}</td>
                        <td>{a.assetType ?? '—'}</td>
                        <td>
                          <StatusBadge status={a.status} />
                        </td>
                        <td>
                          <div className="flex gap-2">
                            <Button variant="outline" size="sm" onClick={() => openEdit(a)}>
                              Edit
                            </Button>
                            <Button
                              variant="destructive"
                              size="sm"
                              onClick={() => handleDelete(a)}
                              disabled={deleteMutation.isPending}
                            >
                              Delete
                            </Button>
                          </div>
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
        title={editing ? 'Edit Charger' : 'Add Charger'}
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
            <label className="block text-sm font-medium text-foreground mb-1">Location</label>
            <input
              type="text"
              value={form.location}
              onChange={(e) => setForm((f) => ({ ...f, location: e.target.value }))}
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground mb-1">Type / Category</label>
            <input
              type="text"
              value={form.assetType}
              onChange={(e) => setForm((f) => ({ ...f, assetType: e.target.value }))}
              placeholder="e.g. HVAC, Electrical"
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground mb-1">Status</label>
            <select
              value={form.status}
              onChange={(e) => setForm((f) => ({ ...f, status: e.target.value }))}
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
            >
              {ASSET_STATUSES.map((status) => (
                <option key={status} value={status}>
                  {status.charAt(0).toUpperCase() + status.slice(1)}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground mb-1">Company</label>
            <select
              value={form.companyId}
              onChange={(e) => setForm((f) => ({ ...f, companyId: e.target.value }))}
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
            >
              <option value="">— None —</option>
              {companies?.map((c) => (
                <option key={c.id} value={c.id}>{c.name}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground mb-1">Manufacturer</label>
            <input
              type="text"
              readOnly
              value={manufacturerFromChargerName(form.name) ?? '—'}
              className="w-full rounded-lg border border-border bg-muted px-3 py-2 text-sm text-muted-foreground"
              aria-describedby="manufacturer-hint"
            />
            <p id="manufacturer-hint" className="mt-1 text-xs text-muted-foreground">
              KOS* names → Kostad; all other chargers → Siemens
            </p>
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground mb-1">Model</label>
            <input
              type="text"
              value={form.model}
              onChange={(e) => setForm((f) => ({ ...f, model: e.target.value }))}
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground mb-1">Serial number</label>
            <input
              type="text"
              value={form.serialNumber}
              onChange={(e) => setForm((f) => ({ ...f, serialNumber: e.target.value }))}
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
            />
          </div>
          <ModalActions>
            <Button type="button" variant="outline" onClick={() => setModalOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={submitting}>
              {submitting ? 'Saving...' : editing ? 'Save' : 'Add Charger'}
            </Button>
          </ModalActions>
        </form>
      </Modal>
    </div>
  );
}
