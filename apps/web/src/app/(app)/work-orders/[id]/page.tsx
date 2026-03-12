'use client';

import { useState } from 'react';
import { useParams } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useUsersMap } from '@/hooks/useUsersMap';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';

type WorkOrderActivityEntry = {
  at: string;
  type: string;
  note?: string;
};

type WorkOrderMetadata = {
  completionPhotoPaths?: string[];
};

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
  return new Intl.NumberFormat(undefined, { style: 'currency', currency: 'USD' }).format(value);
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

export default function WorkOrderDetailPage() {
  const params = useParams();
  const id = params.id as string;
  const queryClient = useQueryClient();

  const { data: wo, isLoading } = useQuery({
    queryKey: ['work-order', id],
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

  const isCompletionLocked = ['completed', 'closed', 'cancelled'].includes(wo?.status ?? '');
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
        <h1 className="text-2xl font-semibold tracking-tight text-foreground">
          {wo.ticketNumber}
        </h1>
        <div className="flex gap-2">
          <Badge variant="secondary">{wo.status}</Badge>
          <Badge>{wo.priority}</Badge>
        </div>
      </div>
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
                <dt className="text-muted-foreground mb-0.5">Asset</dt>
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
      </div>

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

      {(wo.startedAt || wo.closedAt || wo.completedAt || wo.nextMaintenanceDate || wo.laborCost != null || wo.partsCost != null || wo.totalCost != null) && (
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
              {wo.laborCost != null && (
                <>
                  <dt className="text-muted-foreground">Labor cost</dt>
                  <dd className="font-medium">{formatCurrency(wo.laborCost)}</dd>
                </>
              )}
              {wo.partsCost != null && (
                <>
                  <dt className="text-muted-foreground">Parts cost</dt>
                  <dd className="font-medium">{formatCurrency(wo.partsCost)}</dd>
                </>
              )}
              {wo.totalCost != null && (
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
