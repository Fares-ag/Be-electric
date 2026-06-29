'use client';

import { useState, useMemo, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';
import { Pagination } from '@/components/Pagination';
import { SearchFilterBar } from '@/components/SearchFilterBar';
import { usePagination } from '@/hooks/usePagination';
import { useFormSubmitLock } from '@/hooks/useFormSubmitLock';
import {
  companyDeleteBlockReason,
  countRowsByCompanyId,
  validateCompanyForm,
} from '@/lib/companies';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Modal, ModalActions } from '@/components/ui/Modal';
import { DataTableShell, PageHeader } from '@/components/ui/PageStates';

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
  const { submitting, runSubmit } = useFormSubmitLock();
  const [formError, setFormError] = useState<string | null>(null);

  const { data: companies, isLoading, error: queryError, refetch } = useQuery({
    queryKey: ['companies'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { data, error: err } = await supabase.from('companies').select('*').order('name');
      if (err) throw err;
      return (data ?? []) as Company[];
    },
  });

  const { data: chargerCountByCompany } = useQuery({
    queryKey: ['assets', 'charger-count-by-company'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { data } = await supabase.from('assets').select('companyId');
      return countRowsByCompanyId((data ?? []) as { companyId: string | null }[]);
    },
  });

  const { data: userCountByCompany } = useQuery({
    queryKey: ['users', 'count-by-company'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { data } = await supabase.from('users').select('companyId');
      return countRowsByCompanyId((data ?? []) as { companyId: string | null }[]);
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
      queryClient.invalidateQueries({ queryKey: ['assets', 'charger-count-by-company'] });
      setModalOpen(false);
      setForm(emptyForm);
      setEditing(null);
    },
    onError: (err: Error) => setFormError(err.message),
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
      queryClient.invalidateQueries({ queryKey: ['assets', 'charger-count-by-company'] });
      setModalOpen(false);
      setForm(emptyForm);
      setEditing(null);
    },
    onError: (err: Error) => setFormError(err.message),
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      const { error: e } = await supabase.from('companies').delete().eq('id', id);
      if (e) throw e;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['companies'] });
      queryClient.invalidateQueries({ queryKey: ['assets', 'charger-count-by-company'] });
    },
    onError: (err: Error) => setFormError(err.message),
  });

  const openAdd = () => {
    setEditing(null);
    setForm(emptyForm);
    setFormError(null);
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
    setFormError(null);
    setModalOpen(true);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    void runSubmit(async () => {
      setFormError(null);
      const validationError = validateCompanyForm({
        name: form.name,
        contactEmail: form.contactEmail,
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

  const handleDelete = (c: Company) => {
    setFormError(null);
    const blockReason = companyDeleteBlockReason({
      users: userCountByCompany?.[c.id] ?? 0,
      assets: chargerCountByCompany?.[c.id] ?? 0,
    });
    if (blockReason) {
      setFormError(blockReason);
      return;
    }
    if (window.confirm(`Delete company "${c.name}"? This cannot be undone.`)) {
      deleteMutation.mutate(c.id);
    }
  };

  return (
    <div className="space-y-4 sm:space-y-6">
      <PageHeader
        title="Companies"
        actions={
          <>
            <SearchFilterBar
              search={search}
              onSearchChange={setSearch}
              placeholder="Search name, email, phone, address..."
              className="sm:min-w-[220px]"
            />
            <Button onClick={openAdd} className="shrink-0">
              Add Company
            </Button>
          </>
        }
      />
      {formError && !modalOpen ? (
        <p className="text-sm text-destructive bg-destructive/10 p-2 rounded" role="alert">
          {formError}
        </p>
      ) : null}
      <Card>
        <CardContent className="p-0">
          <DataTableShell
            isLoading={isLoading}
            error={queryError}
            isEmpty={!isLoading && !queryError && (companies?.length ?? 0) === 0}
            emptyTitle="No companies yet"
            emptyDescription="Add your first company to associate chargers and work orders."
            emptyAction={
              <Button type="button" onClick={openAdd}>
                Add Company
              </Button>
            }
            onRetry={() => refetch()}
          >
            {filtered.length === 0 && (companies?.length ?? 0) > 0 ? (
              <div className="px-6 py-12 text-center">
                <p className="font-medium text-foreground">No matching companies</p>
                <p className="mt-1 text-sm text-muted-foreground">Try a different search term.</p>
              </div>
            ) : (
              <div className="table-scroll overflow-x-auto">
                <table className="table-modern">
                  <thead>
                    <tr>
                      <th>Name</th>
                      <th>Chargers</th>
                      <th>Email</th>
                      <th>Phone</th>
                      <th>Address</th>
                      <th className="w-40" />
                    </tr>
                  </thead>
                  <tbody>
                    {paginatedItems.map((c) => {
                      const chargerCount = chargerCountByCompany?.[c.id] ?? 0;
                      return (
                        <tr key={c.id}>
                          <td className="font-medium">{c.name}</td>
                          <td>
                            <Link
                              href={chargerCount > 0 ? `/assets?companyId=${c.id}` : '/assets'}
                              className="font-medium text-primary hover:underline"
                            >
                              {chargerCount}
                            </Link>
                          </td>
                          <td>{c.contactEmail ?? '—'}</td>
                          <td>{c.contactPhone ?? '—'}</td>
                          <td className="max-w-[200px] truncate">{c.address ?? '—'}</td>
                          <td>
                            <div className="flex gap-2">
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
        title={editing ? 'Edit Company' : 'Add Company'}
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
