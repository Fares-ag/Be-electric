'use client';

import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useAuthStore } from '@/stores/auth-store';
import { useFormSubmitLock } from '@/hooks/useFormSubmitLock';
import { useUsersMap } from '@/hooks/useUsersMap';
import { isAdminRole } from '@/lib/roles';
import {
  HISTORICAL_WORK_ORDER_PRIORITIES,
  HISTORICAL_WORK_ORDER_STATUSES,
  type HistoricalWorkOrderStatus,
  validateHistoricalWorkOrderInput,
} from '@/lib/historical-work-order';
import { insertHistoricalWorkOrder } from '@/lib/queries/historical-work-order';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { PageHeader } from '@/components/ui/PageStates';
import { cn } from '@/lib/utils';

const inputClass = cn(
  'w-full rounded-lg border border-input bg-background px-4 py-3 text-sm min-h-[44px]',
  'placeholder:text-muted-foreground',
  'focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary',
  'transition-colors touch-manipulation'
);

export default function RecordHistoricalWorkOrderPage() {
  const router = useRouter();
  const user = useAuthStore((s) => s.user);
  const { submitting, runSubmit } = useFormSubmitLock();

  const [problemDescription, setProblemDescription] = useState('');
  const [status, setStatus] = useState<HistoricalWorkOrderStatus>('closed');
  const [priority, setPriority] = useState<string>('medium');
  const [requestorId, setRequestorId] = useState('');
  const [companyId, setCompanyId] = useState('');
  const [assetId, setAssetId] = useState('');
  const [ticketNumber, setTicketNumber] = useState('');
  const [createdAtLocal, setCreatedAtLocal] = useState('');
  const [completedAtLocal, setCompletedAtLocal] = useState('');
  const [closedAtLocal, setClosedAtLocal] = useState('');
  const [location, setLocation] = useState('');
  const [category, setCategory] = useState('');
  const [notes, setNotes] = useState('');
  const [correctiveActions, setCorrectiveActions] = useState('');
  const [recommendations, setRecommendations] = useState('');
  const [assignedTechnicianIds, setAssignedTechnicianIds] = useState<string[]>([]);
  const [error, setError] = useState('');

  const isAdmin = isAdminRole(user?.role);

  useEffect(() => {
    if (user && !isAdmin) {
      router.replace('/dashboard');
    }
  }, [user, isAdmin, router]);

  const { users: allUsers } = useUsersMap(isAdmin);
  const requestors = useMemo(
    () => allUsers.filter((u) => u.role === 'requestor'),
    [allUsers]
  );
  const technicians = useMemo(
    () =>
      allUsers.filter(
        (u) => u.role === 'technician' || u.role === 'manager' || u.role === 'admin'
      ),
    [allUsers]
  );

  const { data: companies } = useQuery({
    queryKey: ['companies'],
    staleTime: 60 * 1000,
    enabled: isAdmin,
    queryFn: async () => {
      const { data, error: err } = await supabase
        .from('companies')
        .select('id, name')
        .order('name');
      if (err) throw err;
      return (data ?? []) as { id: string; name: string }[];
    },
  });

  const { data: companyAssets } = useQuery({
    queryKey: ['assets', companyId],
    enabled: !!companyId,
    staleTime: 60 * 1000,
    queryFn: async () => {
      const { data, error: err } = await supabase
        .from('assets')
        .select('id, name, location')
        .eq('companyId', companyId)
        .order('name');
      if (err) throw err;
      return (data ?? []) as { id: string; name: string; location: string | null }[];
    },
  });

  const selectedRequestor = requestors.find((r) => r.id === requestorId);

  function toggleTechnician(technicianId: string) {
    setAssignedTechnicianIds((current) =>
      current.includes(technicianId)
        ? current.filter((id) => id !== technicianId)
        : [...current, technicianId]
    );
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    if (!user) return;

    const formInput = {
      problemDescription,
      status,
      priority,
      requestorId,
      requestorName: selectedRequestor?.name ?? '',
      companyId,
      assetId,
      createdAtLocal,
      completedAtLocal,
      closedAtLocal,
      ticketNumber: ticketNumber.trim() || undefined,
      location,
      category,
      notes,
      correctiveActions,
      recommendations,
      assignedTechnicianIds,
      recordedById: user.id,
    };

    const validationError = validateHistoricalWorkOrderInput(formInput);
    if (validationError) {
      setError(validationError);
      return;
    }

    await runSubmit(async () => {
      try {
        const id = await insertHistoricalWorkOrder(formInput);
        router.push(`/work-orders/${id}`);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to record historical work order');
      }
    });
  }

  if (!user || !isAdmin) {
    return null;
  }

  return (
    <div className="space-y-6 sm:space-y-8">
      <PageHeader
        title="Record Historical Work Order"
        description="Backfill a completed or closed maintenance job with past timeline dates."
        breadcrumbs={[
          { label: 'Work Orders', href: '/work-orders' },
          { label: 'Record historical' },
        ]}
        actions={
          <Link href="/work-orders">
            <Button variant="outline">Back to list</Button>
          </Link>
        }
      />

      <Card>
        <CardContent className="pt-6 px-4 sm:px-6 pb-6">
          <form onSubmit={handleSubmit} className="space-y-6 max-w-2xl">
            <div>
              <label className="mb-1.5 block text-sm font-medium text-foreground">
                Problem description *
              </label>
              <textarea
                value={problemDescription}
                onChange={(e) => setProblemDescription(e.target.value)}
                required
                rows={4}
                className={cn(inputClass, 'min-h-[100px] py-3')}
              />
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <label className="mb-1.5 block text-sm font-medium text-foreground">Status *</label>
                <select
                  value={status}
                  onChange={(e) => setStatus(e.target.value as HistoricalWorkOrderStatus)}
                  className={inputClass}
                >
                  {HISTORICAL_WORK_ORDER_STATUSES.map((s) => (
                    <option key={s} value={s}>
                      {s}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="mb-1.5 block text-sm font-medium text-foreground">
                  Priority *
                </label>
                <select
                  value={priority}
                  onChange={(e) => setPriority(e.target.value)}
                  className={inputClass}
                >
                  {HISTORICAL_WORK_ORDER_PRIORITIES.map((p) => (
                    <option key={p} value={p}>
                      {p}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div>
              <label className="mb-1.5 block text-sm font-medium text-foreground">
                Ticket number
              </label>
              <input
                type="text"
                value={ticketNumber}
                onChange={(e) => setTicketNumber(e.target.value)}
                placeholder="Auto-generated if blank"
                className={inputClass}
              />
            </div>

            <div>
              <label className="mb-1.5 block text-sm font-medium text-foreground">
                Requestor *
              </label>
              <select
                value={requestorId}
                onChange={(e) => {
                  setRequestorId(e.target.value);
                  const next = requestors.find((r) => r.id === e.target.value);
                  if (next?.companyId && !companyId) {
                    setCompanyId(next.companyId);
                    setAssetId('');
                  }
                }}
                required
                className={inputClass}
              >
                <option value="">— Select requestor —</option>
                {requestors.map((r) => (
                  <option key={r.id} value={r.id}>
                    {r.name} ({r.email})
                  </option>
                ))}
              </select>
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <label className="mb-1.5 block text-sm font-medium text-foreground">
                  Company *
                </label>
                <select
                  value={companyId}
                  onChange={(e) => {
                    setCompanyId(e.target.value);
                    setAssetId('');
                  }}
                  required
                  className={inputClass}
                >
                  <option value="">— Select company —</option>
                  {companies?.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.name}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="mb-1.5 block text-sm font-medium text-foreground">
                  Charger *
                </label>
                <select
                  value={assetId}
                  onChange={(e) => setAssetId(e.target.value)}
                  required
                  disabled={!companyId}
                  className={inputClass}
                >
                  <option value="">— Select charger —</option>
                  {companyAssets?.map((a) => (
                    <option key={a.id} value={a.id}>
                      {a.name}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              <div>
                <label className="mb-1.5 block text-sm font-medium text-foreground">
                  Created *
                </label>
                <input
                  type="datetime-local"
                  value={createdAtLocal}
                  onChange={(e) => setCreatedAtLocal(e.target.value)}
                  required
                  className={inputClass}
                />
              </div>
              <div>
                <label className="mb-1.5 block text-sm font-medium text-foreground">
                  Completed *
                </label>
                <input
                  type="datetime-local"
                  value={completedAtLocal}
                  onChange={(e) => setCompletedAtLocal(e.target.value)}
                  required
                  className={inputClass}
                />
              </div>
              {status === 'closed' && (
                <div>
                  <label className="mb-1.5 block text-sm font-medium text-foreground">
                    Closed
                  </label>
                  <input
                    type="datetime-local"
                    value={closedAtLocal}
                    onChange={(e) => setClosedAtLocal(e.target.value)}
                    className={inputClass}
                  />
                  <p className="mt-1 text-xs text-muted-foreground">
                    Defaults to completed date if left blank.
                  </p>
                </div>
              )}
            </div>

            <div>
              <label className="mb-1.5 block text-sm font-medium text-foreground">
                Assigned technicians (optional)
              </label>
              <div className="flex flex-wrap gap-2">
                {technicians.map((t) => {
                  const selected = assignedTechnicianIds.includes(t.id);
                  return (
                    <button
                      key={t.id}
                      type="button"
                      onClick={() => toggleTechnician(t.id)}
                      className={cn(
                        'rounded-full border px-3 py-1.5 text-sm transition-colors',
                        selected
                          ? 'border-primary bg-primary/10 text-primary'
                          : 'border-border text-muted-foreground hover:border-primary/40'
                      )}
                    >
                      {t.name}
                    </button>
                  );
                })}
              </div>
            </div>

            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <label className="mb-1.5 block text-sm font-medium text-foreground">
                  Location
                </label>
                <input
                  type="text"
                  value={location}
                  onChange={(e) => setLocation(e.target.value)}
                  className={inputClass}
                />
              </div>
              <div>
                <label className="mb-1.5 block text-sm font-medium text-foreground">
                  Category
                </label>
                <input
                  type="text"
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  className={inputClass}
                />
              </div>
            </div>

            <div>
              <label className="mb-1.5 block text-sm font-medium text-foreground">Notes</label>
              <textarea
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                rows={2}
                className={cn(inputClass, 'min-h-[80px] py-3')}
              />
            </div>

            <div>
              <label className="mb-1.5 block text-sm font-medium text-foreground">
                Corrective actions
              </label>
              <textarea
                value={correctiveActions}
                onChange={(e) => setCorrectiveActions(e.target.value)}
                rows={2}
                className={cn(inputClass, 'min-h-[80px] py-3')}
              />
            </div>

            <div>
              <label className="mb-1.5 block text-sm font-medium text-foreground">
                Recommendations
              </label>
              <textarea
                value={recommendations}
                onChange={(e) => setRecommendations(e.target.value)}
                rows={2}
                className={cn(inputClass, 'min-h-[80px] py-3')}
              />
            </div>

            {error && (
              <p className="text-sm text-destructive" role="alert">
                {error}
              </p>
            )}

            <Button type="submit" disabled={submitting} className="min-h-[48px]">
              {submitting ? 'Saving…' : 'Save historical work order'}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
