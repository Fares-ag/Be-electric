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

/** Aligns with Flutter work order model + Supabase work_orders; metadata may hold app-only fields. */
type WorkOrderDetail = {
  id: string;
  ticketNumber: string;
  idempotencyKey?: string | null;
  problemDescription: string;
  requestorId: string;
  requestorName?: string | null;
  assetId?: string | null;
  asset?: { name?: string; location?: string; manufacturer?: string | null; id?: string } | null;
  location?: string | null;
  companyId?: string | null;
  company?: { name?: string | null; id?: string } | null;
  primaryTechnicianId?: string | null;
  assignedTechnicianId?: string | null;
  assignedTechnicianIds?: string[] | null;
  assignedAt?: string | null;
  technicianEffortMinutes?: Record<string, number> | unknown | null;
  status: string;
  priority: string;
  category?: string | null;
  createdAt: string;
  updatedAt?: string;
  startedAt?: string | null;
  completedAt?: string | null;
  closedAt?: string | null;
  nextMaintenanceDate?: string | null;
  notes?: string | null;
  correctiveActions?: string | null;
  recommendations?: string | null;
  technicianNotes?: string | null;
  photoPath?: string | null;
  completionPhotoPath?: string | null;
  beforePhotoPath?: string | null;
  afterPhotoPath?: string | null;
  requestorSignature?: string | null;
  technicianSignature?: string | null;
  customerName?: string | null;
  customerPhone?: string | null;
  customerEmail?: string | null;
  customerSignature?: string | null;
  laborCost?: number | null;
  partsCost?: number | null;
  totalCost?: number | null;
  estimatedCost?: number | null;
  actualCost?: number | null;
  laborHours?: number | null;
  partsUsed?: string[] | null;
  isPaused?: boolean | null;
  pausedAt?: string | null;
  pauseReason?: string | null;
  resumedAt?: string | null;
  pauseHistory?: unknown;
  isOffline?: boolean | null;
  lastSyncedAt?: string | null;
  activityHistory?: WorkOrderActivityEntry[] | null;
  metadata?: WorkOrderMetadata | null;
};

function readMetaString(meta: Record<string, unknown> | null | undefined, ...keys: string[]): string | null {
  if (!meta) return null;
  for (const k of keys) {
    const v = meta[k];
    if (v != null && String(v).trim() !== '') return String(v);
  }
  return null;
}

function formatMaybeIso(value: string | null | undefined): string {
  if (!value) return '—';
  const t = Date.parse(value);
  if (Number.isNaN(t)) return value;
  return new Date(value).toLocaleString();
}

function effortMinutesDisplay(value: unknown): string {
  if (value == null) return '—';
  if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
    return Object.entries(value as Record<string, number>)
      .map(([k, m]) => `${k.slice(0, 8)}…: ${m} min`)
      .join(', ') || '—';
  }
  return JSON.stringify(value);
}

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
      const { data, error } = await supabase
        .from('work_orders')
        .select(
          [
            'id',
            'ticketNumber',
            'idempotencyKey',
            'status',
            'priority',
            'category',
            'problemDescription',
            'requestorId',
            'requestorName',
            'assetId',
            'location',
            'companyId',
            'primaryTechnicianId',
            'assignedTechnicianId',
            'assignedTechnicianIds',
            'assignedAt',
            'technicianEffortMinutes',
            'createdAt',
            'updatedAt',
            'startedAt',
            'completedAt',
            'closedAt',
            'nextMaintenanceDate',
            'notes',
            'correctiveActions',
            'recommendations',
            'technicianNotes',
            'photoPath',
            'completionPhotoPath',
            'beforePhotoPath',
            'afterPhotoPath',
            'requestorSignature',
            'technicianSignature',
            'customerName',
            'customerPhone',
            'customerEmail',
            'customerSignature',
            'laborCost',
            'partsCost',
            'totalCost',
            'estimatedCost',
            'actualCost',
            'laborHours',
            'partsUsed',
            'isPaused',
            'pausedAt',
            'pauseReason',
            'resumedAt',
            'pauseHistory',
            'isOffline',
            'lastSyncedAt',
            'activityHistory',
            'metadata',
            'asset:assets(name,location,manufacturer)',
            'company:companies(name)',
          ].join(',')
        )
        .eq('id', id)
        .single();
      if (error) throw error;
      return data as unknown as WorkOrderDetail | null;
    },
  });

  const [assignError, setAssignError] = useState<string | null>(null);
  const [pushWarning, setPushWarning] = useState<string | null>(null);
  const assignedIds = wo?.assignedTechnicianIds ?? [];
  const { users: allUsers } = useUsersMap(!!wo);
  const assignedUsers = allUsers.filter((u) => assignedIds.includes(u.id));

  const updateAssignees = useMutation({
    mutationFn: async (technicianIds: string[]) => {
      setAssignError(null);
      setPushWarning(null);
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
        if (!token) {
          setPushWarning(
            'Assignment saved. Push notification was not sent (session unavailable). Sign in again and retry if needed.'
          );
          return;
        }
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
            const data = await pushRes.json().catch(() => ({})) as { error?: string; code?: string; hint?: string };
            const msg = data.code === 'MISSING_SERVICE_ROLE_KEY'
              ? 'Assignment saved. Push not sent: add SUPABASE_SERVICE_ROLE_KEY in Vercel → Project → Settings → Environment Variables, then redeploy.'
              : data.hint
                ? `Assignment saved. Push failed: ${data.hint}`
                : data.error ?? `Push failed (${pushRes.status}).`;
            setPushWarning(msg);
          }
        } catch (e) {
          setPushWarning('Assignment saved. Push notification request failed. Check network and try again.');
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
  const requestPhotosExtra: string[] = (() => {
    const a = rawMeta?.requestPhotoPaths ?? rawMeta?.request_photo_paths;
    if (Array.isArray(a)) return a.map((x) => String(x));
    return [];
  })();
  const requestPhotos = [
    ...new Set([...parsePhotoPaths(wo?.photoPath), ...requestPhotosExtra]),
  ];
  // Flutter may store additional URLs in metadata.*PhotoPaths; merge with column values so admin sees all
  const completionPhotosExtra: string[] = (() => {
    const a = rawMeta?.completionPhotoPaths ?? rawMeta?.completion_photo_paths;
    if (Array.isArray(a)) return a.map((x) => String(x));
    return [];
  })();
  const completionPhotos = [
    ...new Set([...parsePhotoPaths(wo?.completionPhotoPath), ...completionPhotosExtra]),
  ] as string[];
  const beforePhotosExtra: string[] = (() => {
    const a = rawMeta?.beforePhotoPaths ?? rawMeta?.before_photo_paths;
    if (Array.isArray(a)) return a.map((x) => String(x));
    return [];
  })();
  const beforePhotos = [
    ...new Set([...parsePhotoPaths(wo?.beforePhotoPath), ...beforePhotosExtra]),
  ];
  const afterPhotosExtra: string[] = (() => {
    const a = rawMeta?.afterPhotoPaths ?? rawMeta?.after_photo_paths;
    if (Array.isArray(a)) return a.map((x) => String(x));
    return [];
  })();
  const afterPhotos = [
    ...new Set([...parsePhotoPaths(wo?.afterPhotoPath), ...afterPhotosExtra]),
  ];
  const hasAnyPhotos =
    requestPhotos.length > 0 ||
    completionPhotos.length > 0 ||
    beforePhotos.length > 0 ||
    afterPhotos.length > 0;

  const primaryUser = wo?.primaryTechnicianId
    ? (allUsers.find((u) => u.id === wo.primaryTechnicianId) as { name?: string } | undefined)
    : null;
  const appCompanyIdFromMeta = readMetaString(rawMeta, 'appCompanyId', 'app_company_id');

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
            {wo.category && (
              <span className="text-xs text-muted-foreground border border-border rounded-md px-2 py-0.5">
                {wo.category}
              </span>
            )}
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
      <div className="grid gap-4 lg:grid-cols-2">
        <div className="space-y-4 min-w-0">
          <Card>
            <CardHeader>
              <CardTitle>Identity &amp; request</CardTitle>
            </CardHeader>
            <CardContent>
              <dl className="grid gap-3 text-sm sm:grid-cols-2">
                <div>
                  <dt className="text-muted-foreground mb-0.5">ID</dt>
                  <dd className="font-mono text-xs break-all">{wo.id}</dd>
                </div>
                <div>
                  <dt className="text-muted-foreground mb-0.5">Ticket</dt>
                  <dd className="font-medium">{wo.ticketNumber}</dd>
                </div>
                {wo.idempotencyKey && (
                  <div className="sm:col-span-2">
                    <dt className="text-muted-foreground mb-0.5">Idempotency key</dt>
                    <dd className="font-mono text-xs break-all">{wo.idempotencyKey}</dd>
                  </div>
                )}
                <div className="sm:col-span-2">
                  <dt className="text-muted-foreground mb-0.5">Problem</dt>
                  <dd className="text-foreground whitespace-pre-wrap">{wo.problemDescription}</dd>
                </div>
                <div>
                  <dt className="text-muted-foreground mb-0.5">Requestor</dt>
                  <dd>{wo.requestorName ?? '—'}</dd>
                </div>
                <div>
                  <dt className="text-muted-foreground mb-0.5">Requestor ID</dt>
                  <dd className="font-mono text-xs break-all">{wo.requestorId}</dd>
                </div>
              </dl>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Where / tenant</CardTitle>
            </CardHeader>
            <CardContent>
              <dl className="grid gap-3 text-sm sm:grid-cols-2">
                <div className="sm:col-span-2">
                  <dt className="text-muted-foreground mb-0.5">Charger (asset)</dt>
                  <dd>
                    {(wo.asset as { name?: string })?.name ?? '—'}
                    {wo.assetId && (
                      <span className="text-muted-foreground text-xs ml-1">({String(wo.assetId).slice(0, 8)}…)</span>
                    )}
                  </dd>
                </div>
                {(wo.asset as { manufacturer?: string | null })?.manufacturer != null && (
                  <div>
                    <dt className="text-muted-foreground mb-0.5">Manufacturer</dt>
                    <dd>{(wo.asset as { manufacturer?: string | null })?.manufacturer}</dd>
                  </div>
                )}
                <div className="sm:col-span-2">
                  <dt className="text-muted-foreground mb-0.5">Location</dt>
                  <dd>
                    {wo.location && wo.location.trim() !== ''
                      ? wo.location
                      : (wo.asset as { location?: string | null })?.location ?? '—'}
                    <span className="block text-xs text-muted-foreground mt-0.5">
                      Uses free-text when set; otherwise asset location.
                    </span>
                  </dd>
                </div>
                <div>
                  <dt className="text-muted-foreground mb-0.5">Company</dt>
                  <dd>{(wo.company as { name?: string } | null | undefined)?.name ?? '—'}</dd>
                </div>
                <div>
                  <dt className="text-muted-foreground mb-0.5">Company ID</dt>
                  <dd className="font-mono text-xs break-all">{wo.companyId ?? '—'}</dd>
                </div>
                {appCompanyIdFromMeta && (
                  <div className="sm:col-span-2">
                    <dt className="text-muted-foreground mb-0.5">appCompanyId (metadata)</dt>
                    <dd className="font-mono text-xs break-all">{appCompanyIdFromMeta}</dd>
                  </div>
                )}
                {readMetaString(rawMeta, 'appAssetId', 'app_asset_id') && (
                  <div className="sm:col-span-2">
                    <dt className="text-muted-foreground mb-0.5">appAssetId (metadata)</dt>
                    <dd className="font-mono text-xs break-all">
                      {readMetaString(rawMeta, 'appAssetId', 'app_asset_id')}
                    </dd>
                  </div>
                )}
              </dl>
            </CardContent>
          </Card>

          {Boolean(
            isAdminOrManager ||
              wo.assignedAt ||
              (wo.assignedTechnicianIds && wo.assignedTechnicianIds.length > 0) ||
              wo.primaryTechnicianId ||
              wo.technicianEffortMinutes
          ) && (
            <Card>
              <CardHeader>
                <CardTitle>Assignment &amp; effort</CardTitle>
              </CardHeader>
              <CardContent>
                <dl className="grid gap-3 text-sm sm:grid-cols-2">
                  <div>
                    <dt className="text-muted-foreground mb-0.5">Primary technician</dt>
                    <dd>{primaryUser?.name ?? (wo.primaryTechnicianId ? wo.primaryTechnicianId : '—')}</dd>
                  </div>
                  {wo.assignedTechnicianId && (
                    <div>
                      <dt className="text-muted-foreground mb-0.5">Legacy assignedTechnicianId</dt>
                      <dd className="font-mono text-xs">{wo.assignedTechnicianId}</dd>
                    </div>
                  )}
                  <div className="sm:col-span-2">
                    <dt className="text-muted-foreground mb-0.5">Technician effort (minutes)</dt>
                    <dd className="text-xs">{effortMinutesDisplay(wo.technicianEffortMinutes)}</dd>
                  </div>
                  <div>
                    <dt className="text-muted-foreground mb-0.5">Assigned at</dt>
                    <dd>{formatMaybeIso(wo.assignedAt)}</dd>
                  </div>
                </dl>
              </CardContent>
            </Card>
          )}

          <Card>
            <CardHeader>
              <CardTitle>Timeline</CardTitle>
            </CardHeader>
            <CardContent>
              <dl className="grid gap-3 text-sm sm:grid-cols-2">
                <div>
                  <dt className="text-muted-foreground mb-0.5">Created</dt>
                  <dd>{new Date(wo.createdAt).toLocaleString()}</dd>
                </div>
                <div>
                  <dt className="text-muted-foreground mb-0.5">Updated</dt>
                  <dd>{wo.updatedAt ? new Date(wo.updatedAt).toLocaleString() : '—'}</dd>
                </div>
                <div>
                  <dt className="text-muted-foreground mb-0.5">Assigned</dt>
                  <dd>{formatMaybeIso(wo.assignedAt)}</dd>
                </div>
                <div>
                  <dt className="text-muted-foreground mb-0.5">Started</dt>
                  <dd>{formatMaybeIso(wo.startedAt)}</dd>
                </div>
                <div>
                  <dt className="text-muted-foreground mb-0.5">Completed</dt>
                  <dd>{formatMaybeIso(wo.completedAt)}</dd>
                </div>
                <div>
                  <dt className="text-muted-foreground mb-0.5">Closed</dt>
                  <dd>{formatMaybeIso(wo.closedAt)}</dd>
                </div>
                <div>
                  <dt className="text-muted-foreground mb-0.5">Next maintenance</dt>
                  <dd>
                    {wo.nextMaintenanceDate
                      ? new Date(wo.nextMaintenanceDate).toLocaleDateString(undefined, { dateStyle: 'medium' })
                      : '—'}
                  </dd>
                </div>
                {readMetaString(rawMeta, 'firstResponseTime', 'first_response_time') && (
                  <div>
                    <dt className="text-muted-foreground mb-0.5">First response (metadata)</dt>
                    <dd>{readMetaString(rawMeta, 'firstResponseTime', 'first_response_time')}</dd>
                  </div>
                )}
                {readMetaString(rawMeta, 'actualStartTime', 'actual_start_time') && (
                  <div>
                    <dt className="text-muted-foreground mb-0.5">Actual start (metadata)</dt>
                    <dd>{readMetaString(rawMeta, 'actualStartTime', 'actual_start_time')}</dd>
                  </div>
                )}
                {readMetaString(rawMeta, 'actualEndTime', 'actual_end_time') && (
                  <div>
                    <dt className="text-muted-foreground mb-0.5">Actual end (metadata)</dt>
                    <dd>{readMetaString(rawMeta, 'actualEndTime', 'actual_end_time')}</dd>
                  </div>
                )}
                {readMetaString(rawMeta, 'estimatedDuration', 'estimated_duration') && (
                  <div>
                    <dt className="text-muted-foreground mb-0.5">Est. duration (metadata)</dt>
                    <dd>{readMetaString(rawMeta, 'estimatedDuration', 'estimated_duration')}</dd>
                  </div>
                )}
                {readMetaString(rawMeta, 'actualDuration', 'actual_duration') && (
                  <div>
                    <dt className="text-muted-foreground mb-0.5">Actual duration (metadata)</dt>
                    <dd>{readMetaString(rawMeta, 'actualDuration', 'actual_duration')}</dd>
                  </div>
                )}
              </dl>
            </CardContent>
          </Card>

          {(wo.notes || wo.technicianNotes) && (
            <Card>
              <CardHeader>
                <CardTitle>Notes</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3 text-sm">
                {wo.notes && (
                  <div>
                    <p className="text-muted-foreground text-xs mb-1">General</p>
                    <p className="whitespace-pre-wrap">{wo.notes}</p>
                  </div>
                )}
                {wo.technicianNotes && (
                  <div>
                    <p className="text-muted-foreground text-xs mb-1">Technician</p>
                    <p className="whitespace-pre-wrap">{wo.technicianNotes}</p>
                  </div>
                )}
              </CardContent>
            </Card>
          )}

          {(readMetaString(rawMeta, 'rootCause', 'root_cause') || readMetaString(rawMeta, 'failureMode', 'failure_mode') || readMetaString(rawMeta, 'severityLevel', 'severity_level') || readMetaString(rawMeta, 'workCategory', 'work_category') || readMetaString(rawMeta, 'isRepeatFailure', 'is_repeat_failure')) && (
            <Card>
              <CardHeader>
                <CardTitle>Root cause &amp; analytics (metadata)</CardTitle>
              </CardHeader>
              <CardContent>
                <dl className="grid gap-2 text-sm sm:grid-cols-2">
                  {readMetaString(rawMeta, 'rootCause', 'root_cause') && (
                    <>
                      <dt className="text-muted-foreground col-span-2">Root cause</dt>
                      <dd className="col-span-2 mb-1">{readMetaString(rawMeta, 'rootCause', 'root_cause')}</dd>
                    </>
                  )}
                  {readMetaString(rawMeta, 'failureMode', 'failure_mode') && (
                    <><dt className="text-muted-foreground">Failure mode</dt><dd>{readMetaString(rawMeta, 'failureMode', 'failure_mode')}</dd></>
                  )}
                  {readMetaString(rawMeta, 'severityLevel', 'severity_level') && (
                    <><dt className="text-muted-foreground">Severity</dt><dd>{readMetaString(rawMeta, 'severityLevel', 'severity_level')}</dd></>
                  )}
                  {readMetaString(rawMeta, 'workCategory', 'work_category') && (
                    <><dt className="text-muted-foreground">Work category</dt><dd>{readMetaString(rawMeta, 'workCategory', 'work_category')}</dd></>
                  )}
                  {readMetaString(rawMeta, 'isRepeatFailure', 'is_repeat_failure') && (
                    <><dt className="text-muted-foreground">Repeat failure</dt><dd>{readMetaString(rawMeta, 'isRepeatFailure', 'is_repeat_failure')}</dd></>
                  )}
                </dl>
              </CardContent>
            </Card>
          )}

          {(!isRequestor && (wo.laborCost != null || wo.partsCost != null || wo.totalCost != null || wo.estimatedCost != null || wo.actualCost != null || wo.laborHours != null || (wo.partsUsed && wo.partsUsed.length > 0))) && (
            <Card>
              <CardHeader>
                <CardTitle>Cost &amp; parts</CardTitle>
              </CardHeader>
              <CardContent>
                <dl className="grid gap-3 text-sm sm:grid-cols-2">
                  {wo.estimatedCost != null && (
                    <><dt className="text-muted-foreground">Estimated cost</dt><dd>{formatCurrency(wo.estimatedCost)}</dd></>
                  )}
                  {wo.actualCost != null && (
                    <><dt className="text-muted-foreground">Actual cost</dt><dd>{formatCurrency(wo.actualCost)}</dd></>
                  )}
                  {wo.laborCost != null && (
                    <><dt className="text-muted-foreground">Labor cost</dt><dd>{formatCurrency(wo.laborCost)}</dd></>
                  )}
                  {wo.partsCost != null && (
                    <><dt className="text-muted-foreground">Parts cost</dt><dd>{formatCurrency(wo.partsCost)}</dd></>
                  )}
                  {wo.totalCost != null && (
                    <><dt className="text-muted-foreground">Total</dt><dd className="font-semibold">{formatCurrency(wo.totalCost)}</dd></>
                  )}
                  {wo.laborHours != null && (
                    <><dt className="text-muted-foreground">Labor hours</dt><dd>{wo.laborHours}</dd></>
                  )}
                  {wo.partsUsed && wo.partsUsed.length > 0 && (
                    <div className="sm:col-span-2">
                      <dt className="text-muted-foreground mb-1">Parts used</dt>
                      <dd className="text-xs">
                        {wo.partsUsed.map((p) => (typeof p === 'string' ? p : String(p))).join(', ')}
                      </dd>
                    </div>
                  )}
                </dl>
              </CardContent>
            </Card>
          )}

          {(wo.customerName || wo.customerPhone || wo.customerEmail || wo.customerSignature) && (
            <Card>
              <CardHeader>
                <CardTitle>Customer</CardTitle>
              </CardHeader>
              <CardContent>
                <dl className="grid gap-2 text-sm sm:grid-cols-2">
                  {wo.customerName && (
                    <><dt className="text-muted-foreground">Name</dt><dd>{wo.customerName}</dd></>
                  )}
                  {wo.customerPhone && (
                    <><dt className="text-muted-foreground">Phone</dt><dd>{wo.customerPhone}</dd></>
                  )}
                  {wo.customerEmail && (
                    <><dt className="text-muted-foreground">Email</dt><dd>{wo.customerEmail}</dd></>
                  )}
                </dl>
                {wo.customerSignature && (
                  <div className="mt-3">
                    <p className="text-xs text-muted-foreground mb-1">Customer signature</p>
                    <SignatureImage value={wo.customerSignature} alt="Customer signature" />
                  </div>
                )}
              </CardContent>
            </Card>
          )}

          {Boolean(wo.isPaused || wo.pausedAt || wo.pauseReason || wo.resumedAt || wo.pauseHistory) && (
            <Card>
              <CardHeader>
                <CardTitle>Pause / resume</CardTitle>
              </CardHeader>
              <CardContent>
                <dl className="grid gap-2 text-sm sm:grid-cols-2">
                  <div>
                    <dt className="text-muted-foreground">Paused</dt>
                    <dd>{wo.isPaused ? 'Yes' : 'No'}</dd>
                  </div>
                  {wo.pausedAt && <><dt className="text-muted-foreground">Paused at</dt><dd>{formatMaybeIso(wo.pausedAt)}</dd></>}
                  {wo.pauseReason && (
                    <div className="sm:col-span-2">
                      <dt className="text-muted-foreground">Reason</dt>
                      <dd className="whitespace-pre-wrap">{wo.pauseReason}</dd>
                    </div>
                  )}
                  {wo.resumedAt && <><dt className="text-muted-foreground">Resumed at</dt><dd>{formatMaybeIso(wo.resumedAt)}</dd></>}
                  {wo.pauseHistory != null && String(wo.pauseHistory) !== '' && (
                    <div className="sm:col-span-2">
                      <dt className="text-muted-foreground mb-1">Pause history</dt>
                      <dd>
                        <pre className="text-xs bg-muted/50 p-2 rounded overflow-x-auto max-h-32">
                          {JSON.stringify(wo.pauseHistory, null, 0)}
                        </pre>
                      </dd>
                    </div>
                  )}
                </dl>
              </CardContent>
            </Card>
          )}

          {(wo.isOffline != null || wo.lastSyncedAt) && (
            <Card>
              <CardHeader>
                <CardTitle>Sync / offline</CardTitle>
              </CardHeader>
              <CardContent>
                <dl className="grid gap-2 text-sm sm:grid-cols-2">
                  {wo.isOffline != null && (
                    <div>
                      <dt className="text-muted-foreground">Offline</dt>
                      <dd>{wo.isOffline ? 'Yes' : 'No'}</dd>
                    </div>
                  )}
                  {wo.lastSyncedAt && (
                    <div>
                      <dt className="text-muted-foreground">Last synced</dt>
                      <dd>{formatMaybeIso(wo.lastSyncedAt)}</dd>
                    </div>
                  )}
                </dl>
              </CardContent>
            </Card>
          )}
        </div>
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
              {pushWarning && (
                <p className="text-sm text-amber-700 dark:text-amber-400 bg-amber-500/10 px-2 py-1.5 rounded border border-amber-500/30">
                  {pushWarning}
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
