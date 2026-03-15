'use client';

import { useState, useMemo, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Pagination } from '@/components/Pagination';
import { SearchFilterBar } from '@/components/SearchFilterBar';
import { usePagination } from '@/hooks/usePagination';
import { supabase } from '@/lib/supabase';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Modal, ModalActions } from '@/components/ui/Modal';

type UserRow = {
  id: string;
  name: string;
  email: string;
  role: string;
  isActive: boolean;
  companyId: string | null;
  department: string | null;
};

// Normalize DB row (Supabase may return camelCase or snake_case depending on schema)
function toUserRow(r: Record<string, unknown>): UserRow {
  return {
    id: String(r.id ?? ''),
    name: String(r.name ?? ''),
    email: String(r.email ?? ''),
    role: String(r.role ?? 'requestor'),
    isActive: r.isActive !== false && r.is_active !== false,
    companyId: r.companyId != null ? String(r.companyId) : r.company_id != null ? String(r.company_id) : null,
    department: r.department != null ? String(r.department) : null,
  };
}

const emptyForm = {
  name: '',
  email: '',
  role: 'requestor',
  isActive: true,
  companyId: '',
  department: '',
  password: '',
};

export default function UsersPage() {
  const queryClient = useQueryClient();
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<UserRow | null>(null);
  const [form, setForm] = useState(emptyForm);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [createdTempPassword, setCreatedTempPassword] = useState<string | null>(null);
  const [createdWithCustomPassword, setCreatedWithCustomPassword] = useState(false);

  const {
    data: users,
    isLoading,
    error: queryError,
    refetch,
  } = useQuery({
    queryKey: ['users'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any -- get_users_list exists in DB, may not be in generated types
      const { data, error: e } = await (supabase as any).rpc('get_users_list');
      if (e) throw e;
      return ((data ?? []) as Record<string, unknown>[]).map(toUserRow);
    },
  });

  const { data: companies } = useQuery({
    queryKey: ['companies'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { data } = await supabase.from('companies').select('id, name').order('name');
      return (data ?? []) as { id: string; name: string }[];
    },
  });

  const [search, setSearch] = useState('');
  const filtered = useMemo(() => {
    const list = users ?? [];
    if (!search.trim()) return list;
    const q = search.trim().toLowerCase();
    return list.filter(
      (u) =>
        u.name.toLowerCase().includes(q) ||
        u.email.toLowerCase().includes(q) ||
        u.role.toLowerCase().includes(q)
    );
  }, [users, search]);

  const { page, setPage, pageSize, setPageSize, paginatedItems, totalItems } =
    usePagination(filtered);

  useEffect(() => setPage(1), [search, setPage]);

  const createMutation = useMutation({
    mutationFn: async (payload: typeof emptyForm) => {
      const { data: { session } } = await supabase.auth.getSession();
      const token = session?.access_token;
      if (!token) throw new Error('Not signed in');
      const res = await fetch('/api/users/create', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          email: payload.email.trim().toLowerCase(),
          name: payload.name.trim(),
          role: payload.role,
          companyId: payload.companyId.trim() || null,
          department: payload.role === 'requestor' ? null : (payload.department?.trim() || null),
          password: payload.password?.trim() || undefined,
        }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data.error ?? res.statusText);
      return data as { tempPassword?: string };
    },
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      setForm(emptyForm);
      setEditing(null);
      if (data?.tempPassword) {
        setCreatedTempPassword(data.tempPassword);
      } else {
        setCreatedWithCustomPassword(true);
      }
    },
    onError: (err: Error) => {
      setError(err.message);
    },
  });

  const updateMutation = useMutation({
    mutationFn: async ({ id, ...payload }: UserRow & { companyId?: string; department?: string }) => {
      const { data: { session } } = await supabase.auth.getSession();
      const token = session?.access_token;
      if (!token) throw new Error('Not signed in');
      const dept = payload.role === 'requestor' ? null : (payload.department?.trim() || null);
      const res = await fetch('/api/users/update', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          id,
          name: payload.name.trim(),
          role: payload.role,
          isActive: payload.isActive,
          companyId: payload.companyId?.trim() || null,
          department: dept,
        }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data.error ?? res.statusText);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      setModalOpen(false);
      setEditing(null);
    },
    onError: (err: Error) => setError(err.message),
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      const { data: { session } } = await supabase.auth.getSession();
      const token = session?.access_token;
      if (!token) throw new Error('Not signed in');
      const res = await fetch('/api/users/delete', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ id }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data.error ?? res.statusText);
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['users'] }),
    onError: (err: Error) => setError(err.message),
  });

  const handleCloseModal = () => {
    setModalOpen(false);
    setError(null);
    setCreatedTempPassword(null);
    setCreatedWithCustomPassword(false);
  };

  const openAdd = () => {
    setEditing(null);
    setForm(emptyForm);
    setError(null);
    setModalOpen(true);
  };

  const openEdit = (u: UserRow) => {
    setEditing(u);
    setForm({
      name: u.name,
      email: u.email,
      role: u.role,
      isActive: u.isActive,
      companyId: u.companyId ?? '',
      department: u.department ?? '',
      password: '',
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

  const handleDelete = (u: UserRow) => {
    if (window.confirm(`Remove "${u.name}"? This will delete them from Supabase Auth and the app.`)) {
      deleteMutation.mutate(u.id);
    }
  };

  const isAdd = !editing;

  return (
    <div className="space-y-4 sm:space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <h1 className="font-display text-2xl font-semibold tracking-tight text-foreground">Users</h1>
        <div className="flex flex-col sm:flex-row gap-3 sm:items-center">
          <SearchFilterBar
            search={search}
            onSearchChange={setSearch}
            placeholder="Search name, email, role..."
            className="sm:min-w-[220px]"
          />
          <Button onClick={openAdd} className="shrink-0">Add User</Button>
        </div>
      </div>
      <Card>
        {queryError && (
          <div className="mb-4 p-3 rounded-lg bg-destructive/10 text-destructive text-sm">
            <p className="font-medium">Failed to load users.</p>
            <p className="mt-1 text-xs opacity-90">{String(queryError.message)}</p>
            <p className="mt-2 text-xs">Ensure you’re logged in as admin and run the RLS script in Supabase.</p>
            <Button variant="outline" size="sm" className="mt-2" onClick={() => refetch()}>
              Retry
            </Button>
          </div>
        )}
        {isLoading ? (
          <div className="flex items-center justify-center py-12">
            <div className="h-6 w-6 animate-spin rounded-full border-2 border-primary border-t-transparent" />
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="table-modern">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Email</th>
                  <th>Role</th>
                  <th>Status</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {paginatedItems.map((u) => (
                  <tr key={u.id}>
                    <td className="font-medium text-foreground">{u.name}</td>
                    <td className="text-sm">{u.email}</td>
                    <td className="capitalize">{u.role}</td>
                    <td>{u.isActive ? 'Active' : 'Inactive'}</td>
                    <td className="flex gap-2">
                      <Button variant="outline" size="sm" onClick={() => openEdit(u)}>
                        Edit
                      </Button>
                      <Button
                        variant="destructive"
                        size="sm"
                        onClick={() => handleDelete(u)}
                        disabled={deleteMutation.isPending}
                      >
                        Delete
                      </Button>
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
        onClose={handleCloseModal}
        title={isAdd ? 'Add User' : 'Edit User'}
      >
        {createdTempPassword ? (
          <div className="space-y-4">
            <p className="text-sm text-foreground">
              User created in Supabase Auth and in the app. They will appear under Authentication → Users in the Supabase Dashboard and can sign in.
            </p>
            <div>
              <p className="text-xs font-medium text-muted-foreground mb-1">One-time password (share securely):</p>
              <div className="flex items-center gap-2">
                <code className="flex-1 rounded bg-muted px-2 py-2 text-sm font-mono break-all">
                  {createdTempPassword}
                </code>
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={() => {
                    navigator.clipboard.writeText(createdTempPassword);
                  }}
                >
                  Copy
                </Button>
              </div>
            </div>
            <p className="text-xs text-muted-foreground">They should sign in and change their password after first login.</p>
            <ModalActions>
              <Button type="button" onClick={handleCloseModal}>
                Done
              </Button>
            </ModalActions>
          </div>
        ) : createdWithCustomPassword ? (
          <div className="space-y-4">
            <p className="text-sm text-foreground">
              User created. They can sign in with the password you set.
            </p>
            <ModalActions>
              <Button type="button" onClick={handleCloseModal}>
                Done
              </Button>
            </ModalActions>
          </div>
        ) : (
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
            <label className="block text-sm font-medium text-foreground mb-1">Email *</label>
            <input
              type="email"
              required={isAdd}
              value={form.email}
              disabled={!isAdd}
              onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm disabled:bg-muted disabled:cursor-not-allowed"
            />
            {!isAdd && (
              <p className="text-xs text-muted-foreground mt-1">Email is managed in Auth; change in Supabase Dashboard if needed.</p>
            )}
            {isAdd && (
              <p className="text-xs text-muted-foreground mt-1">Creates the user in Supabase Auth and in the app. Set a password below or leave blank to auto-generate one to share.</p>
            )}
          </div>
          {isAdd && (
            <div>
              <label className="block text-sm font-medium text-foreground mb-1">Password (optional)</label>
              <input
                type="password"
                autoComplete="new-password"
                value={form.password}
                onChange={(e) => setForm((f) => ({ ...f, password: e.target.value }))}
                placeholder="Leave blank to auto-generate"
                className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
              />
            </div>
          )}
          <div>
            <label className="block text-sm font-medium text-foreground mb-1">Role</label>
            <select
              value={form.role}
              onChange={(e) => setForm((f) => ({ ...f, role: e.target.value }))}
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
            >
              <option value="requestor">Requestor</option>
              <option value="technician">Technician</option>
              <option value="manager">Manager</option>
              <option value="admin">Admin</option>
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
          {form.role !== 'requestor' && (
            <div>
              <label className="block text-sm font-medium text-foreground mb-1">Department</label>
              <input
                type="text"
                value={form.department}
                onChange={(e) => setForm((f) => ({ ...f, department: e.target.value }))}
                className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
              />
            </div>
          )}
          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="isActive"
              checked={form.isActive}
              onChange={(e) => setForm((f) => ({ ...f, isActive: e.target.checked }))}
              className="rounded border-border"
            />
            <label htmlFor="isActive" className="text-sm font-medium text-foreground">Active</label>
          </div>
          <ModalActions>
            <Button type="button" variant="outline" onClick={() => setModalOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={submitting}>
              {submitting ? 'Saving...' : isAdd ? 'Add User' : 'Save'}
            </Button>
          </ModalActions>
        </form>
        )}
      </Modal>
    </div>
  );
}
