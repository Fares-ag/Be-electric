'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';
import { useAuthStore } from '@/stores/auth-store';
import { useUsersMap } from '@/hooks/useUsersMap';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { StatusBadge } from '@/components/ui/Badge';
import { Modal, ModalActions } from '@/components/ui/Modal';

const FREQUENCIES = [
  { value: 'daily', label: 'Daily', days: 1 },
  { value: 'weekly', label: 'Weekly', days: 7 },
  { value: 'monthly', label: 'Monthly', days: 30 },
  { value: 'quarterly', label: 'Quarterly', days: 90 },
  { value: 'semiAnnually', label: 'Semi-annually', days: 180 },
  { value: 'annually', label: 'Annually', days: 365 },
  { value: 'asNeeded', label: 'As needed', days: 0 },
] as const;

const emptyForm = {
  taskName: '',
  assetId: '',
  description: '',
  frequency: 'monthly' as const,
  nextDueDate: '',
  assignedTechnicianIds: [] as string[],
};

export default function PMTasksPage() {
  const queryClient = useQueryClient();
  const user = useAuthStore((s) => s.user);
  const [modalOpen, setModalOpen] = useState(false);
  const [form, setForm] = useState(emptyForm);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const { data: pmTasks, isLoading } = useQuery({
    queryKey: ['pm-tasks'],
    queryFn: async () => {
      const { data } = await supabase
        .from('pm_tasks')
        .select('id, taskName, status, frequency, nextDueDate, assignedTechnicianIds, asset:assets(name)')
        .order('nextDueDate', { ascending: true });
      return data ?? [];
    },
  });

  const { data: assets } = useQuery({
    queryKey: ['assets'],
    queryFn: async () => {
      const { data } = await supabase.from('assets').select('id, name').order('name');
      return (data ?? []) as { id: string; name: string }[];
    },
  });

  const { users: allUsers } = useUsersMap(!!modalOpen);

  const createMutation = useMutation({
    mutationFn: async (payload: typeof emptyForm) => {
      const freq = FREQUENCIES.find((f) => f.value === payload.frequency) ?? FREQUENCIES[2];
      const { error: e } = await supabase.from('pm_tasks').insert({
        id: crypto.randomUUID(),
        taskName: payload.taskName.trim().slice(0, 50),
        assetId: payload.assetId.trim(),
        description: payload.description.trim() || null,
        frequency: payload.frequency,
        frequencyValue: freq.days,
        nextDueDate: payload.nextDueDate || new Date().toISOString().slice(0, 10),
        status: 'pending',
        assignedTechnicianIds: payload.assignedTechnicianIds.length > 0 ? payload.assignedTechnicianIds : null,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        metadata: user?.id ? { createdById: user.id } : null,
      });
      if (e) throw e;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['pm-tasks'] });
      setModalOpen(false);
      setForm(emptyForm);
      setError(null);
    },
    onError: (err: Error) => setError(err.message),
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    createMutation.mutate(form, { onSettled: () => setSubmitting(false) });
  };

  const toggleTechnician = (userId: string) => {
    setForm((f) => ({
      ...f,
      assignedTechnicianIds: f.assignedTechnicianIds.includes(userId)
        ? f.assignedTechnicianIds.filter((id) => id !== userId)
        : [...f.assignedTechnicianIds, userId],
    }));
  };

  const technicians = allUsers.filter(
    (u) => u.role === 'technician' || u.role === 'manager' || u.role === 'admin'
  );

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-[#000]">PM Tasks</h1>
        <Button
          onClick={() => {
            setModalOpen(true);
            setError(null);
            const in30 = new Date();
            in30.setDate(in30.getDate() + 30);
            setForm({
              ...emptyForm,
              nextDueDate: in30.toISOString().slice(0, 10),
            });
          }}
        >
          Create PM Task
        </Button>
      </div>
      <Card>
        {isLoading ? (
          <p className="text-[#757575]">Loading...</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[#E0E0E0]">
                  <th className="text-left py-3 px-4 font-semibold">Task</th>
                  <th className="text-left py-3 px-4 font-semibold">Status</th>
                  <th className="text-left py-3 px-4 font-semibold">Frequency</th>
                  <th className="text-left py-3 px-4 font-semibold">Next Due</th>
                  <th className="text-left py-3 px-4 font-semibold">Charger</th>
                  <th className="text-left py-3 px-4 font-semibold">Assigned</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {pmTasks?.map((t: Record<string, unknown>) => (
                  <tr key={t.id as string} className="border-b border-[#E0E0E0]">
                    <td className="py-3 px-4 font-medium">{t.taskName as string}</td>
                    <td className="py-3 px-4">
                      <StatusBadge status={t.status as string} />
                    </td>
                    <td className="py-3 px-4">{t.frequency as string}</td>
                    <td className="py-3 px-4">
                      {t.nextDueDate
                        ? new Date(t.nextDueDate as string).toLocaleDateString()
                        : '-'}
                    </td>
                    <td className="py-3 px-4">
                      {(t.asset as { name?: string })?.name ?? '-'}
                    </td>
                    <td className="py-3 px-4 text-muted-foreground text-sm">
                      {(t.assignedTechnicianIds as string[] | undefined)?.length
                        ? `${(t.assignedTechnicianIds as string[]).length} technician(s)`
                        : '-'}
                    </td>
                    <td className="py-3 px-4">
                      <Link href={`/pm-tasks/${t.id}`}>
                        <Button variant="outline">View</Button>
                      </Link>
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
        title="Create PM Task"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          {error && (
            <p className="text-sm text-destructive bg-destructive/10 p-2 rounded">{error}</p>
          )}
          <div>
            <label className="block text-sm font-medium text-foreground mb-1">Task name *</label>
            <input
              type="text"
              required
              maxLength={50}
              value={form.taskName}
              onChange={(e) => setForm((f) => ({ ...f, taskName: e.target.value }))}
              placeholder="e.g. Inspect HVAC unit"
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground mb-1">Charger *</label>
            <select
              required
              value={form.assetId}
              onChange={(e) => setForm((f) => ({ ...f, assetId: e.target.value }))}
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
            >
              <option value="">— Select charger —</option>
              {assets?.map((a) => (
                <option key={a.id} value={a.id}>{a.name}</option>
              ))}
            </select>
            {assets?.length === 0 && (
              <p className="text-xs text-muted-foreground mt-1">Create a charger first in Chargers.</p>
            )}
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground mb-1">Description</label>
            <textarea
              value={form.description}
              onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))}
              rows={2}
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm resize-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground mb-1">Frequency *</label>
            <select
              value={form.frequency}
              onChange={(e) => setForm((f) => ({ ...f, frequency: e.target.value as typeof form.frequency }))}
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
            >
              {FREQUENCIES.map((f) => (
                <option key={f.value} value={f.value}>{f.label}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground mb-1">Next due date *</label>
            <input
              type="date"
              required
              value={form.nextDueDate}
              onChange={(e) => setForm((f) => ({ ...f, nextDueDate: e.target.value }))}
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground mb-1">Assigned technicians</label>
            <div className="flex flex-wrap gap-2 max-h-32 overflow-y-auto py-1">
              {technicians.slice(0, 20).map((u) => (
                <button
                  key={u.id}
                  type="button"
                  onClick={() => toggleTechnician(u.id)}
                  className={form.assignedTechnicianIds.includes(u.id)
                    ? 'rounded-md border border-primary bg-primary/10 px-2 py-1 text-xs font-medium text-primary'
                    : 'rounded-md border border-border bg-muted/50 px-2 py-1 text-xs text-muted-foreground hover:bg-muted'}
                >
                  {u.name}
                </button>
              ))}
            </div>
          </div>
          <ModalActions>
            <Button type="button" variant="outline" onClick={() => setModalOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={submitting || !form.assetId.trim()}>
              {submitting ? 'Creating...' : 'Create PM Task'}
            </Button>
          </ModalActions>
        </form>
      </Modal>
    </div>
  );
}
