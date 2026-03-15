'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useAuthStore } from '@/stores/auth-store';
import { useUsersMap } from '@/hooks/useUsersMap';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge, StatusBadge } from '@/components/ui/Badge';
import { Modal, ModalActions } from '@/components/ui/Modal';

type WorkOrderActivityEntry = {
  at: string;
  type: string;
  note?: string;
};

/** Reopen fields stored in metadata by Flutter (see docs/WORK_ORDER_REOPEN.md). */
type ReopenMetadata = {
  reopenedAt?: string;
  reopenedBy?: string;
  reopenReason?: string;
  reopenCount?: number;
  previousCompletionDate?: string;
  previousStatus?: string;
};

type WorkOrderMetadata = {
  completionPhotoPaths?: string[];
} & ReopenMetadata;

type WorkOrderDetail = {
  id: string;
  ticketNumber: string;
  status: string;
  priority: string;
  problemDescription: string;
  requestorId: string;
  requestorName?: string | null;
  assetId?: string | null;
  asset?: { name?: string; location?: string };
  location?: string | null;
  createdAt: string;
  correctiveActions?: string | null;
  recommendations?: string | null;
  photoPath?: string | null;
  completionPhotoPath?: string | null;
  beforePhotoPath?: string | null;
  afterPhotoPath?: string | null;
  assignedTechnicianIds?: string[] | null;
  startedAt?: string | null;
  completedAt?: string | null;
  closedAt?: string | null;
  nextMaintenanceDate?: string | null;
  requestorSignature?: string | null;
  technicianSignature?: string | null;
  laborCost?: number | null;
  partsCost?: number | null;
  totalCost?: number | null;
  activityHistory?: WorkOrderActivityEntry[] | null;
  metadata?: WorkOrderMetadata | null;
};

function parsePhotoPaths(value: string | null | undefined): string[] {
  if (!value) return [];
  if (value.startsWith('http')) return [value];
  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed : [value];
  } catch {
    return [value];
  }
}

function formatCurrency(value: number): string {
  return new Intl.NumberFormat(undefined, { style: 'currency', currency: 'QAR' }).format(value);
}

function parseActivityHistory(
  value: WorkOrderActivityEntry[] | string | null | undefined
): WorkOrderActivityEntry[] {
  if (!value) return [];
  if (Array.isArray(value)) return value;
  try {
    const parsed = typeof value === 'string' ? JSON.parse(value) : value;
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

/** Renders signature stored as data URL or base64 (from Flutter signature pad). */
function SignatureImage({ value, alt }: { value: string; alt: string }) {
  const src =
    value.startsWith('data:') ? value : `data:image/png;base64,${value}`;
  return (
    <img
      src={src}
      alt={alt}
      className="max-h-24 w-auto border border-border rounded bg-muted/30 object-contain"
    />
  );
}

const MAX_REOPEN_COUNT = 3;

const WORK_ORDER_STATUSES = [
  'open',
  'assigned',
  'inProgress',
  'completed',
  'closed',
  'cancelled',
  'reopened',
] as const;

const STATUSES_REQUIRING_REASON = ['completed', 'closed', 'cancelled', 'reopened'] as const;

export default function WorkOrderDetailPage() {
  const params = useParams();
  const router = useRouter();
  const id = params.id as string;
  const queryClient = useQueryClient();
  const user = useAuthStore((s) => s.user);
  const isRequestor = user?.role === 'requestor';
  const isAdminOrManager = user?.role === 'admin' || user?.role === 'manager';

  const { data: wo, isLoading } = useQuery({
    queryKey: ['work-order', id],
    staleTime: 60 * 1000,
    queryFn: async (): Promise<WorkOrderDetail | null> => {
      const { data } = await supabase
        .from('work_orders')
        .select(
          'id, ticketNumber, status, priority, problemDescription, requestorId, requestorName, assetId, location, createdAt, correctiveActions, recommendations, photoPath, completionPhotoPath, beforePhotoPath, afterPhotoPath, assignedTechnicianIds, startedAt, completedAt, closedAt, nextMaintenanceDate, requestorSignature, technicianSignature, laborCost, partsCost, totalCost, activityHistory, metadata, asset:assets(name, location)'
        )
        .eq('id', id)
        .single();
      return data as WorkOrderDetail | null;
    },
  });

  const [assignError, setAssignError] = useState<string | null>(null);
  const assignedIds = wo?.assignedTechnicianIds ?? [];
  const { users: allUsers } = useUsersMap(!!wo);
  const assignedUsers = allUsers.filter((u) => assignedIds.includes(u.id));

  const updateAssignees = useMutation({
    mutationFn: async (technicianIds: string[]) => {
      setAssignError(null);
      const { error } = await supabase
        .from('work_orders')
        .update({
          assignedTechnicianIds: technicianIds,
          assignedAt: technicianIds.length > 0 ? new Date().toISOString() : null,
          updatedAt: new Date().toISOString(),
        })
        .eq('id', id);
      if (error) throw error;
      if (technicianIds.length > 0) {
        const ticketNumber = wo?.ticketNumber ?? id;
        const { data: { session } } = await supabase.auth.getSession();
        const token = session?.access_token;
        if (token) {
          try {
            const pushRes = await fetch('/api/notifications/push', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${token}`,
              },
              body: JSON.stringify({
                type: 'work_order_assigned',
                external_user_ids: technicianIds,
                title: 'New Work Order Assigned',
                message: `Work order #${ticketNumber} has been assigned to you.`,
                data: { work_order_id: id, ticket_number: String(ticketNumber) },
              }),
            });
            if (!pushRes.ok) {
              console.warn('[push] notification failed:', pushRes.status, await pushRes.text());
            }
          } catch (e) {
            console.warn('[push] notification error:', e);
          }
        }
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['work-order', id] });
      setAssignError(null);
    },
    onError: (err: Error) => {
      setAssignError(err.message);
    },
  });

  const addTechnician = (userId: string) => {
    const current = wo?.assignedTechnicianIds ?? [];
    if (current.includes(userId)) return;
    updateAssignees.mutate([...current, userId]);
  };

  const removeTechnician = (userId: string) => {
    const current = wo?.assignedTechnicianIds ?? [];
    updateAssignees.mutate(current.filter((id) => id !== userId));
  };

  const [statusModalOpen, setStatusModalOpen] = useState(false);
  const [statusModalTarget, setStatusModalTarget] = useState<string | null>(null);
  const [statusReason, setStatusReason] = useState('');
  const [statusReasonError, setStatusReasonError] = useState<string | null>(null);

  const updateStatusMutation = useMutation({
    mutationFn: async ({
      newStatus,
      reason,
    }: {
      newStatus: string;
      reason?: string;
    }) => {
      const now = new Date().toISOString();
      const updates: Record<string, unknown> = {
        status: newStatus,
        updatedAt: now,
      };
      if (['completed', 'closed'].includes(newStatus)) {
        updates.completedAt = now;
        if (newStatus === 'closed') updates.closedAt = now;
      }
      if (newStatus === 'reopened') {
        updates.assignedTechnicianIds = [];
        updates.primaryTechnicianId = null;
        updates.assignedAt = null;
        updates.startedAt = null;
        updates.completedAt = null;
        updates.closedAt = null;
        if (reason) {
          const raw = wo?.metadata as Record<string, unknown> | undefined;
          const prevMeta = typeof raw === 'object' && raw !== null ? raw : {};
          const count = Number(prevMeta.reopenCount ?? prevMeta.reopen_count ?? 0);
          updates.metadata = {
            ...prevMeta,
            reopenedAt: now,
            reopenedBy: user?.id ?? null,
            reopenReason: reason,
            reopenCount: count + 1,
            previousCompletionDate: wo?.completedAt ?? wo?.closedAt ?? null,
            previousStatus: wo?.status,
          };
        }
      }
      if (reason) {
        const existing = parseActivityHistory(wo?.activityHistory);
        updates.activityHistory = [
          ...existing,
          { at: now, type: newStatus, note: reason },
        ];
      }
      const { error } = await supabase.from('work_orders').update(updates).eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => {
      setStatusModalOpen(false);
      setStatusModalTarget(null);
      setStatusReason('');
      setStatusReasonError(null);
      queryClient.invalidateQueries({ queryKey: ['work-order', id] });
      queryClient.invalidateQueries({ queryKey: ['work-orders'] });
      queryClient.invalidateQueries({ queryKey: ['my-work-orders'] });
    },
    onError: (err: Error) => {
      setStatusReasonError(err.message);
    },
  });

  const isCompletionLocked = ['completed', 'closed', 'cancelled'].includes(wo?.status ?? '');
  const rawMeta = wo?.metadata as Record<string, unknown> | undefined;
  const reopenCount = Number(rawMeta?.reopenCount ?? rawMeta?.reopen_count ?? 0);
  const canReopen =
    isRequestor &&
    user?.id &&
    wo?.requestorId === user.id &&
    ['completed', 'closed', 'cancelled'].includes(wo?.status ?? '') &&
    reopenCount < MAX_REOPEN_COUNT;

  const [reopenOpen, setReopenOpen] = useState(false);
  const [reopenReason, setReopenReason] = useState('');
  const [reopenDescription, setReopenDescription] = useState('');
  const [reopenError, setReopenError] = useState<string | null>(null);

  const reopenMutation = useMutation({
    mutationFn: async () => {
      if (!user?.id || !wo) throw new Error('Not allowed');
      if (reopenReason.trim().length < 10) throw new Error('Reason must be at least 10 characters');
      const now = new Date().toISOString();
      const previousCompletion = wo.completedAt ?? wo.closedAt ?? null;
      const newMeta = {
        ...(typeof wo.metadata === 'object' && wo.metadata !== null ? (wo.metadata as Record<string, unknown>) : {}),
        reopenedAt: now,
        reopenedBy: user.id,
        reopenReason: reopenReason.trim(),
        reopenCount: reopenCount + 1,
        previousCompletionDate: previousCompletion,
        previousStatus: wo.status,
      };
      const { error } = await supabase
        .from('work_orders')
        .update({
          status: 'reopened',
          problemDescription: reopenDescription.trim().length >= 10 ? reopenDescription.trim() : wo.problemDescription,
          assignedTechnicianIds: [],
          primaryTechnicianId: null,
          assignedAt: null,
          startedAt: null,
          completedAt: null,
          closedAt: null,
          metadata: newMeta,
          updatedAt: now,
        })
        .eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => {
      setReopenOpen(false);
      setReopenReason('');
      setReopenDescription('');
      setReopenError(null);
      queryClient.invalidateQueries({ queryKey: ['work-order', id] });
      router.refresh();
    },
    onError: (err: Error) => {
      setReopenError(err.message);
    },
  });

  const handleReopenSubmit = () => {
    setReopenError(null);
    reopenMutation.mutate();
  };
  const requestPhotos = parsePhotoPaths(wo?.photoPath);
  // Flutter stores all completion photo URLs in metadata.completionPhotoPaths; first URL in completionPhotoPath
  const completionPhotos =
    (Array.isArray(wo?.metadata?.completionPhotoPaths) && wo.metadata.completionPhotoPaths.length > 0
      ? wo.metadata.completionPhotoPaths
      : parsePhotoPaths(wo?.completionPhotoPath)) as string[];
  const beforePhotos = parsePhotoPaths(wo?.beforePhotoPath);
  const afterPhotos = parsePhotoPaths(wo?.afterPhotoPath);
  const hasAnyPhotos =
    requestPhotos.length > 0 ||
    completionPhotos.length > 0 ||
    beforePhotos.length > 0 ||
    afterPhotos.length > 0;

  if (isLoading || !wo) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="h-6 w-6 animate-spin rounded-full border-2 border-primary border-t-transparent" />
      </div>
    );
  }

  return (
    <div>
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between mb-8">
        <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:gap-4">
          <h1 className="text-2xl font-semibold tracking-tight text-foreground">
            {wo.ticketNumber}
          </h1>
          <div className="flex flex-wrap items-center gap-2">
            <StatusBadge status={wo.status} />
            {isAdminOrManager && (
              <select
                value={wo.status}
                onChange={(e) => {
                  const val = e.target.value;
                  if (STATUSES_REQUIRING_REASON.includes(val as typeof STATUSES_REQUIRING_REASON[number])) {
                    setStatusModalTarget(val);
                    setStatusReason('');
                    setStatusReasonError(null);
                    setStatusModalOpen(true);
                  } else {
                    updateStatusMutation.mutate({ newStatus: val });
                  }
                }}
                disabled={updateStatusMutation.isPending}
                className="rounded-md border border-input bg-background px-3 py-1.5 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-primary/20"
              >
                {WORK_ORDER_STATUSES.map((s) => (
                  <option key={s} value={s}>
                    {s.replace(/([A-Z])/g, ' $1').trim()}
                  </option>
                ))}
              </select>
            )}
            <Badge>{wo.priority}</Badge>
            {canReopen && (
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => setReopenOpen(true)}
              >
                Reopen work order
              </Button>
            )}
          </div>
        </div>
      </div>

      <Modal
        open={statusModalOpen}
        onClose={() => {
          setStatusModalOpen(false);
          setStatusModalTarget(null);
          setStatusReason('');
          setStatusReasonError(null);
        }}
        title={statusModalTarget ? `Reason for ${statusModalTarget.replace(/([A-Z])/g, ' $1').trim()}` : ''}
      >
        {statusModalTarget && (
          <div className="space-y-4">
            <p className="text-sm text-muted-foreground">
              Please provide a reason for changing the status to &quot;{statusModalTarget.replace(/([A-Z])/g, ' $1').trim()}&quot;.
            </p>
            <div>
              <label className="block text-sm font-medium text-foreground mb-1.5">
                Reason <span className="text-destructive">*</span>
              </label>
              <textarea
                value={statusReason}
                onChange={(e) => setStatusReason(e.target.value)}
                placeholder="At least 10 characters"
                rows={3}
                className="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary/20"
              />
            </div>
            {statusReasonError && (
              <p className="text-sm text-destructive">{statusReasonError}</p>
            )}
          </div>
        )}
        {statusModalTarget && (
          <ModalActions>
            <Button
              variant="outline"
              onClick={() => {
                setStatusModalOpen(false);
                setStatusModalTarget(null);
                setStatusReason('');
                setStatusReasonError(null);
              }}
            >
              Cancel
            </Button>
            <Button
              onClick={() => {
                setStatusReasonError(null);
                if (statusReason.trim().length < 10) {
                  setStatusReasonError('Reason must be at least 10 characters');
                  return;
                }
                updateStatusMutation.mutate({
                  newStatus: statusModalTarget!,
                  reason: statusReason.trim(),
                });
              }}
              disabled={updateStatusMutation.isPending || statusReason.trim().length < 10}
            >
              {updateStatusMutation.isPending ? 'Updating…' : 'Update status'}
            </Button>
          </ModalActions>
        )}
      </Modal>

      <Modal
        open={reopenOpen}
        onClose={() => {
          setReopenOpen(false);
          setReopenError(null);
        }}
        title="Reopen work order"
      >
        <div className="space-y-4">
          <p className="text-sm text-muted-foreground">
            This will set the work order back to &quot;Reopened&quot; and clear assignments. You have {MAX_REOPEN_COUNT - reopenCount} reopen{MAX_REOPEN_COUNT - reopenCount === 1 ? '' : 's'} left.
          </p>
          <div>
            <label className="block text-sm font-medium text-foreground mb-1.5">
              Reason for reopening <span className="text-destructive">*</span>
            </label>
            <textarea
              value={reopenReason}
              onChange={(e) => setReopenReason(e.target.value)}
              placeholder="At least 10 characters"
              rows={3}
              className="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary/20"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground mb-1.5">
              Updated problem description (optional)
            </label>
            <textarea
              value={reopenDescription}
              onChange={(e) => setReopenDescription(e.target.value)}
              placeholder="Leave blank to keep current description"
              rows={2}
              className="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary/20"
            />
          </div>
          {reopenError && (
            <p className="text-sm text-destructive">{reopenError}</p>
          )}
        </div>
        <ModalActions>
          <Button variant="outline" onClick={() => setReopenOpen(false)}>
            Cancel
          </Button>
          <Button
            onClick={handleReopenSubmit}
            disabled={reopenReason.trim().length < 10 || reopenMutation.isPending}
          >
            {reopenMutation.isPending ? 'Reopening…' : 'Reopen'}
          </Button>
        </ModalActions>
      </Modal>
      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Details</CardTitle>
          </CardHeader>
          <CardContent>
            <dl className="space-y-4 text-sm">
              <div>
                <dt className="text-muted-foreground mb-0.5">Description</dt>
                <dd className="font-medium">{wo.problemDescription}</dd>
              </div>
              <div>
                <dt className="text-muted-foreground mb-0.5">Requestor</dt>
                <dd>{wo.requestorName ?? wo.requestorId}</dd>
              </div>
              <div>
                <dt className="text-muted-foreground mb-0.5">Charger</dt>
                <dd>{(wo.asset as { name?: string })?.name ?? wo.assetId ?? '-'}</dd>
              </div>
              <div>
                <dt className="text-muted-foreground mb-0.5">Location</dt>
                <dd>{wo.location ?? '-'}</dd>
              </div>
              <div>
                <dt className="text-muted-foreground mb-0.5">Created</dt>
                <dd>{new Date(wo.createdAt).toLocaleString()}</dd>
              </div>
            </dl>
          </CardContent>
        </Card>
        {isAdminOrManager && (
          <Card>
            <CardHeader>
              <CardTitle>Assigned technicians</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              {assignError && (
                <p className="text-sm text-destructive bg-destructive/10 px-2 py-1.5 rounded">
                  {assignError}
                </p>
              )}
              {assignedUsers && assignedUsers.length > 0 ? (
                <ul className="space-y-1.5">
                  {(assignedUsers as { id: string; name: string }[]).map((u) => (
                    <li
                      key={u.id}
                      className="flex items-center justify-between rounded-md bg-muted/50 px-2 py-1.5 text-sm"
                    >
                      <span>{u.name}</span>
                      {!isCompletionLocked && (
                        <Button
                          type="button"
                          variant="ghost"
                          size="sm"
                          className="h-7 text-muted-foreground hover:text-destructive"
                          onClick={() => removeTechnician(u.id)}
                          disabled={updateAssignees.isPending}
                        >
                          Remove
                        </Button>
                      )}
                    </li>
                  ))}
                </ul>
              ) : (
                <p className="text-sm text-muted-foreground">No one assigned yet.</p>
              )}
              {!isCompletionLocked && allUsers.length > 0 && (
                <div className="flex flex-wrap gap-2 pt-2 border-t border-border">
                  <p className="w-full text-xs text-muted-foreground mb-1">Assign technician:</p>
                  {allUsers
                    .filter((u) => !assignedIds.includes(u.id) && (u.role === 'technician' || u.role === 'manager' || u.role === 'admin'))
                    .slice(0, 12)
                    .map((u) => (
                      <Button
                        key={u.id}
                        type="button"
                        variant="outline"
                        size="sm"
                        onClick={() => addTechnician(u.id)}
                        disabled={updateAssignees.isPending}
                      >
                        + {u.name}
                      </Button>
                    ))}
                  {allUsers.filter((u) => !assignedIds.includes(u.id) && (u.role === 'technician' || u.role === 'manager' || u.role === 'admin')).length === 0 && (
                    <p className="text-xs text-muted-foreground">No other technicians to assign. Add users with role Technician in Users.</p>
                  )}
                </div>
              )}
              {isCompletionLocked && (
                <p className="text-xs text-muted-foreground pt-2 border-t border-border">
                  Assignments cannot be changed after the work order is completed.
                </p>
              )}
            </CardContent>
          </Card>
        )}
      </div>

      {(() => {
        const raw = wo?.metadata as Record<string, unknown> | undefined;
        if (!raw) return null;
        const count = Number(raw.reopenCount ?? raw.reopen_count ?? 0);
        if (count < 1) return null;
        const reopenedAt = String(raw.reopenedAt ?? raw.reopened_at ?? '').trim() || null;
        const reopenedBy = String(raw.reopenedBy ?? raw.reopened_by ?? '').trim() || null;
        const reopenReason = String(raw.reopenReason ?? raw.reopen_reason ?? '').trim() || null;
        const previousStatus = String(raw.previousStatus ?? raw.previous_status ?? '').trim() || null;
        const previousCompletionDate = String(raw.previousCompletionDate ?? raw.previous_completion_date ?? '').trim() || null;
        const reopenedByName = reopenedBy ? (allUsers.find((u) => u.id === reopenedBy) as { name?: string } | undefined)?.name : null;
        return (
          <Card className="mt-4">
            <CardHeader>
              <CardTitle>Reopen history</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3 text-sm">
              <p className="font-medium text-foreground">
                Reopened {count} time{count !== 1 ? 's' : ''}
              </p>
              {reopenedAt && (
                <div>
                  <span className="text-muted-foreground">Last reopened: </span>
                  {new Date(reopenedAt).toLocaleString()}
                  {reopenedByName && (
                    <span className="text-muted-foreground"> by {reopenedByName}</span>
                  )}
                </div>
              )}
              {reopenReason && (
                <div>
                  <span className="text-muted-foreground">Reason: </span>
                  <span className="text-foreground">{reopenReason}</span>
                </div>
              )}
              {previousStatus && (
                <div>
                  <span className="text-muted-foreground">Previous status: </span>
                  <StatusBadge status={previousStatus} />
                </div>
              )}
              {previousCompletionDate && (
                <div>
                  <span className="text-muted-foreground">Previous completion: </span>
                  {new Date(previousCompletionDate).toLocaleString()}
                </div>
              )}
            </CardContent>
          </Card>
        );
      })()}

      {hasAnyPhotos && (
        <Card className="mt-4">
          <CardHeader>
            <CardTitle>Photos</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {requestPhotos.length > 0 && (
              <div>
                <p className="text-sm font-medium text-muted-foreground mb-2">Request</p>
                <div className="flex flex-wrap gap-2">
                  {requestPhotos.map((src, i) => (
                    <a
                      key={i}
                      href={src}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="block rounded-lg overflow-hidden border border-border w-32 h-32"
                    >
                      <img src={src} alt={`Request ${i + 1}`} className="w-full h-full object-cover" />
                    </a>
                  ))}
                </div>
              </div>
            )}
            {beforePhotos.length > 0 && (
              <div>
                <p className="text-sm font-medium text-muted-foreground mb-2">Before</p>
                <div className="flex flex-wrap gap-2">
                  {beforePhotos.map((src, i) => (
                    <a
                      key={i}
                      href={src}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="block rounded-lg overflow-hidden border border-border w-32 h-32"
                    >
                      <img src={src} alt={`Before ${i + 1}`} className="w-full h-full object-cover" />
                    </a>
                  ))}
                </div>
              </div>
            )}
            {afterPhotos.length > 0 && (
              <div>
                <p className="text-sm font-medium text-muted-foreground mb-2">After</p>
                <div className="flex flex-wrap gap-2">
                  {afterPhotos.map((src, i) => (
                    <a
                      key={i}
                      href={src}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="block rounded-lg overflow-hidden border border-border w-32 h-32"
                    >
                      <img src={src} alt={`After ${i + 1}`} className="w-full h-full object-cover" />
                    </a>
                  ))}
                </div>
              </div>
            )}
            {completionPhotos.length > 0 && (
              <div>
                <p className="text-sm font-medium text-muted-foreground mb-2">Completion</p>
                <div className="flex flex-wrap gap-2">
                  {completionPhotos.map((src, i) => (
                    <a
                      key={i}
                      href={src}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="block rounded-lg overflow-hidden border border-border w-32 h-32"
                    >
                      <img src={src} alt={`Completion ${i + 1}`} className="w-full h-full object-cover" />
                    </a>
                  ))}
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {((wo.startedAt || wo.closedAt || wo.completedAt || wo.nextMaintenanceDate) ||
        (!isRequestor && (wo.laborCost != null || wo.partsCost != null || wo.totalCost != null))) && (
        <Card className="mt-4">
          <CardHeader>
            <CardTitle>Completion summary</CardTitle>
          </CardHeader>
          <CardContent>
            <dl className="grid gap-3 text-sm sm:grid-cols-2">
              {wo.startedAt && (
                <>
                  <dt className="text-muted-foreground">Started</dt>
                  <dd className="font-medium">{new Date(wo.startedAt).toLocaleString()}</dd>
                </>
              )}
              {(wo.completedAt || wo.closedAt) && (
                <>
                  <dt className="text-muted-foreground">Completed</dt>
                  <dd className="font-medium">
                    {new Date(wo.completedAt || wo.closedAt!).toLocaleString()}
                  </dd>
                </>
              )}
              {wo.nextMaintenanceDate && (
                <>
                  <dt className="text-muted-foreground">Next maintenance</dt>
                  <dd className="font-medium">
                    {new Date(wo.nextMaintenanceDate).toLocaleDateString(undefined, {
                      dateStyle: 'medium',
                    })}
                  </dd>
                </>
              )}
              {!isRequestor && wo.laborCost != null && (
                <>
                  <dt className="text-muted-foreground">Labor cost</dt>
                  <dd className="font-medium">{formatCurrency(wo.laborCost)}</dd>
                </>
              )}
              {!isRequestor && wo.partsCost != null && (
                <>
                  <dt className="text-muted-foreground">Parts cost</dt>
                  <dd className="font-medium">{formatCurrency(wo.partsCost)}</dd>
                </>
              )}
              {!isRequestor && wo.totalCost != null && (
                <>
                  <dt className="text-muted-foreground">Total cost</dt>
                  <dd className="font-semibold">{formatCurrency(wo.totalCost)}</dd>
                </>
              )}
            </dl>
          </CardContent>
        </Card>
      )}

      {(() => {
        const activity = parseActivityHistory(wo?.activityHistory);
        return activity.length > 0 ? (
          <Card className="mt-4">
            <CardHeader>
              <CardTitle>Activity history</CardTitle>
            </CardHeader>
            <CardContent>
              <ul className="space-y-2 text-sm">
                {activity.map((entry, i) => (
                  <li key={i} className="flex flex-wrap items-baseline gap-2 border-b border-border pb-2 last:border-0 last:pb-0">
                    <time className="text-muted-foreground shrink-0">
                      {new Date(entry.at).toLocaleString()}
                    </time>
                    <span className="font-medium capitalize">{entry.type}</span>
                    {entry.note && <span className="text-muted-foreground">— {entry.note}</span>}
                  </li>
                ))}
              </ul>
            </CardContent>
          </Card>
        ) : null;
      })()}

      {wo.correctiveActions && (
        <Card className="mt-4">
          <CardHeader>
            <CardTitle>Corrective actions</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-foreground whitespace-pre-wrap">{wo.correctiveActions}</p>
          </CardContent>
        </Card>
      )}

      {wo.recommendations && (
        <Card className="mt-4">
          <CardHeader>
            <CardTitle>Recommendations</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-foreground whitespace-pre-wrap">{wo.recommendations}</p>
          </CardContent>
        </Card>
      )}

      {(wo.requestorSignature || wo.technicianSignature) && (
        <Card className="mt-4">
          <CardHeader>
            <CardTitle>Signatures</CardTitle>
          </CardHeader>
          <CardContent className="grid gap-4 sm:grid-cols-2">
            {wo.requestorSignature && (
              <div>
                <p className="text-xs text-muted-foreground mb-1">Requestor</p>
                <SignatureImage value={wo.requestorSignature} alt="Requestor signature" />
              </div>
            )}
            {wo.technicianSignature && (
              <div>
                <p className="text-xs text-muted-foreground mb-1">Technician</p>
                <SignatureImage value={wo.technicianSignature} alt="Technician signature" />
              </div>
            )}
          </CardContent>
        </Card>
      )}
    </div>
  );
}
