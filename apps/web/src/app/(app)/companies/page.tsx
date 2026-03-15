'use client';

import { useState, useMemo, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';
import { Pagination } from '@/components/Pagination';
import { SearchFilterBar } from '@/components/SearchFilterBar';
import { usePagination } from '@/hooks/usePagination';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Modal, ModalActions } from '@/components/ui/Modal';

type Company = {
  id: string;
  name: string;
  contactEmail: string | null;
  contactPhone: string | null;
  address: string | null;
};

const emptyForm = {
  name: '',
  contactEmail: '',
  contactPhone: '',
  address: '',
};

export default function CompaniesPage() {
  const queryClient = useQueryClient();
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Company | null>(null);
  const [form, setForm] = useState(emptyForm);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const { data: companies, isLoading } = useQuery({
    queryKey: ['companies'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { data } = await supabase
        .from('companies')
        .select('*')
        .order('name');
      return (data ?? []) as Company[];
    },
  });

  const { data: chargerCountByCompany } = useQuery({
    queryKey: ['assets', 'charger-count-by-company'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { data } = await supabase
        .from('assets')
        .select('companyId');
      const list = (data ?? []) as { companyId: string | null }[];
      return list.reduce<Record<string, number>>((acc, a) => {
        const id = a.companyId ?? '_none';
        acc[id] = (acc[id] ?? 0) + 1;
        return acc;
      }, {});
    },
  });

  const [search, setSearch] = useState('');
  const filtered = useMemo(() => {
    const list = companies ?? [];
    if (!search.trim()) return list;
    const q = search.trim().toLowerCase();
    return list.filter(
      (c) =>
        c.name.toLowerCase().includes(q) ||
        (c.contactEmail ?? '').toLowerCase().includes(q) ||
        (c.contactPhone ?? '').toLowerCase().includes(q) ||
        (c.address ?? '').toLowerCase().includes(q)
    );
  }, [companies, search]);

  const { page, setPage, pageSize, setPageSize, paginatedItems, totalItems } =
    usePagination(filtered);

  useEffect(() => setPage(1), [search, setPage]);

  const createMutation = useMutation({
    mutationFn: async (payload: typeof emptyForm) => {
      const { error: e } = await supabase.from('companies').insert({
        name: payload.name.trim(),
        contactEmail: payload.contactEmail.trim() || null,
        contactPhone: payload.contactPhone.trim() || null,
        address: payload.address.trim() || null,
        updatedAt: new Date().toISOString(),
      });
      if (e) throw e;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['companies'] });
      setModalOpen(false);
      setForm(emptyForm);
      setEditing(null);
    },
    onError: (err: Error) => setError(err.message),
  });

  const updateMutation = useMutation({
    mutationFn: async ({ id, ...payload }: Company & { contactEmail?: string; contactPhone?: string; address?: string }) => {
      const { error: e } = await supabase
        .from('companies')
        .update({
          name: payload.name.trim(),
          contactEmail: payload.contactEmail?.trim() || null,
          contactPhone: payload.contactPhone?.trim() || null,
          address: payload.address?.trim() || null,
          updatedAt: new Date().toISOString(),
        })
        .eq('id', id);
      if (e) throw e;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['companies'] });
      setModalOpen(false);
      setForm(emptyForm);
      setEditing(null);
    },
    onError: (err: Error) => setError(err.message),
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      const { error: e } = await supabase.from('companies').delete().eq('id', id);
      if (e) throw e;
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['companies'] }),
    onError: (err: Error) => setError(err.message),
  });

  const openAdd = () => {
    setEditing(null);
    setForm(emptyForm);
    setError(null);
    setModalOpen(true);
  };

  const openEdit = (c: Company) => {
    setEditing(c);
    setForm({
      name: c.name,
      contactEmail: c.contactEmail ?? '',
      contactPhone: c.contactPhone ?? '',
      address: c.address ?? '',
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

  const handleDelete = (c: Company) => {
    if (window.confirm(`Delete company "${c.name}"?`)) {
      deleteMutation.mutate(c.id);
    }
  };

  return (
    <div className="space-y-4 sm:space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <h1 className="font-display text-2xl font-semibold tracking-tight text-foreground">Companies</h1>
        <div className="flex flex-col sm:flex-row gap-3 sm:items-center">
          <SearchFilterBar
            search={search}
            onSearchChange={setSearch}
            placeholder="Search name, email, phone, address..."
            className="sm:min-w-[220px]"
          />
          <Button onClick={openAdd} className="shrink-0">Add Company</Button>
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
                  <th className="text-left py-3 px-4 font-semibold">Chargers</th>
                  <th className="text-left py-3 px-4 font-semibold">Email</th>
                  <th className="text-left py-3 px-4 font-semibold">Phone</th>
                  <th className="text-left py-3 px-4 font-semibold">Address</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {paginatedItems.map((c) => {
                  const chargerCount = chargerCountByCompany?.[c.id] ?? 0;
                  return (
                  <tr key={c.id} className="border-b border-[#E0E0E0]">
                    <td className="py-3 px-4 font-medium">{c.name}</td>
                    <td className="py-3 px-4">
                      <Link
                        href={chargerCount > 0 ? `/assets?companyId=${c.id}` : '/assets'}
                        className="text-primary hover:underline font-medium"
                      >
                        {chargerCount}
                      </Link>
                    </td>
                    <td className="py-3 px-4">{c.contactEmail ?? '-'}</td>
                    <td className="py-3 px-4">{c.contactPhone ?? '-'}</td>
                    <td className="py-3 px-4 max-w-[200px] truncate">{c.address ?? '-'}</td>
                    <td className="py-3 px-4 flex gap-2">
                      <Button variant="outline" size="sm" onClick={() => openEdit(c)}>
                        Edit
                      </Button>
                      <Button
                        variant="destructive"
                        size="sm"
                        onClick={() => handleDelete(c)}
                        disabled={deleteMutation.isPending}
                      >
                        Delete
                      </Button>
                    </td>
                  </tr>
                );})}
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
        title={editing ? 'Edit Company' : 'Add Company'}
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
            <label className="block text-sm font-medium text-foreground mb-1">Contact email</label>
            <input
              type="email"
              value={form.contactEmail}
              onChange={(e) => setForm((f) => ({ ...f, contactEmail: e.target.value }))}
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground mb-1">Contact phone</label>
            <input
              type="tel"
              value={form.contactPhone}
              onChange={(e) => setForm((f) => ({ ...f, contactPhone: e.target.value }))}
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground mb-1">Address</label>
            <textarea
              value={form.address}
              onChange={(e) => setForm((f) => ({ ...f, address: e.target.value }))}
              rows={2}
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
            />
          </div>
          <ModalActions>
            <Button type="button" variant="outline" onClick={() => setModalOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={submitting}>
              {submitting ? 'Saving...' : editing ? 'Save' : 'Add Company'}
            </Button>
          </ModalActions>
        </form>
      </Modal>
    </div>
  );
}
