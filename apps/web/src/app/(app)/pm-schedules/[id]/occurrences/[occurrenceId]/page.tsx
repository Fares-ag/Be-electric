'use client';

import { useParams } from 'next/navigation';
import Link from 'next/link';
import { useRef, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge, StatusBadge } from '@/components/ui/Badge';
import { Modal, ModalActions } from '@/components/ui/Modal';
import { LoadingSpinner, PageHeader, QueryErrorState } from '@/components/ui/PageStates';
import { useFormSubmitLock } from '@/hooks/useFormSubmitLock';
import { useUsersMap } from '@/hooks/useUsersMap';
import { useAuthStore } from '@/stores/auth-store';
import {
  formatPmFrequency,
  parseScheduleChecklist,
  validateCancelReason,
  validateCompletionNotes,
  validateRescheduleDueDate,
} from '@/lib/pm-schedule';
import {
  PM_SCHEDULES_LIST_QUERY_KEY,
  UPCOMING_PM_OCCURRENCES_QUERY_KEY,
  cancelPmOccurrence,
  completePmOccurrence,
  fetchPmOccurrenceDetail,
  pmOccurrenceDetailQueryKey,
  pmScheduleOccurrencesQueryKey,
  reschedulePmOccurrence,
  updatePmOccurrenceAssignees,
} from '@/lib/queries/pm-schedules';
import { uploadPmOccurrenceCompletionPhoto } from '@/lib/storage';

export default function PmOccurrenceDetailPage() {
  const params = useParams();
  const scheduleId = params.id as string;
  const occurrenceId = params.occurrenceId as string;
  const queryClient = useQueryClient();
  const user = useAuthStore((s) => s.user);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const { submitting: completing, runSubmit: runComplete } = useFormSubmitLock();
  const { submitting: cancelling, runSubmit: runCancel } = useFormSubmitLock();
  const { submitting: rescheduling, runSubmit: runReschedule } = useFormSubmitLock();

  const [completionNotes, setCompletionNotes] = useState('');
  const [completionError, setCompletionError] = useState<string | null>(null);
  const [cancelOpen, setCancelOpen] = useState(false);
  const [cancelReason, setCancelReason] = useState('');
  const [cancelError, setCancelError] = useState<string | null>(null);
  const [rescheduleOpen, setRescheduleOpen] = useState(false);
  const [newDueDate, setNewDueDate] = useState('');
  const [rescheduleError, setRescheduleError] = useState<string | null>(null);

  const { data: occurrence, isLoading, error, refetch } = useQuery({
    queryKey: pmOccurrenceDetailQueryKey(occurrenceId),
    staleTime: 60 * 1000,
    queryFn: () => fetchPmOccurrenceDetail(occurrenceId),
  });

  const assignedIds = occurrence?.assignedTechnicianIds ?? [];
  const { users: allUsers } = useUsersMap(!!occurrence);
  const assignedUsers = allUsers.filter((u) => assignedIds.includes(u.id));
  const completedByUser = allUsers.find((u) => u.id === occurrence?.completedById);
  const cancelledByUser = allUsers.find((u) => u.id === occurrence?.cancelledById);

  const invalidatePmQueries = () => {
    queryClient.invalidateQueries({ queryKey: pmOccurrenceDetailQueryKey(occurrenceId) });
    queryClient.invalidateQueries({ queryKey: pmScheduleOccurrencesQueryKey(scheduleId) });
    queryClient.invalidateQueries({ queryKey: PM_SCHEDULES_LIST_QUERY_KEY });
    queryClient.invalidateQueries({ queryKey: UPCOMING_PM_OCCURRENCES_QUERY_KEY });
  };

  const updateAssigneesMutation = useMutation({
    mutationFn: (technicianIds: string[]) =>
      updatePmOccurrenceAssignees(occurrenceId, technicianIds),
    onSuccess: invalidatePmQueries,
  });

  const completeMutation = useMutation({
    mutationFn: async (photoFile: File | null) => {
      const notesError = validateCompletionNotes(completionNotes);
      if (notesError) throw new Error(notesError);
      let completionPhotoPath: string | null = null;
      if (photoFile) {
        completionPhotoPath = await uploadPmOccurrenceCompletionPhoto(photoFile, occurrenceId);
      }
      await completePmOccurrence({
        id: occurrenceId,
        completedById: user?.id ?? null,
        completionNotes: completionNotes.trim() || null,
        completionPhotoPath,
      });
    },
    onSuccess: () => {
      setCompletionError(null);
      invalidatePmQueries();
    },
    onError: (err: Error) => setCompletionError(err.message),
  });

  const cancelMutation = useMutation({
    mutationFn: async () => {
      const reasonError = validateCancelReason(cancelReason);
      if (reasonError) throw new Error(reasonError);
      await cancelPmOccurrence({
        id: occurrenceId,
        cancelledById: user?.id ?? null,
        cancelReason,
      });
    },
    onSuccess: () => {
      setCancelOpen(false);
      setCancelReason('');
      setCancelError(null);
      invalidatePmQueries();
    },
    onError: (err: Error) => setCancelError(err.message),
  });

  const rescheduleMutation = useMutation({
    mutationFn: async () => {
      const dateError = validateRescheduleDueDate(newDueDate);
      if (dateError) throw new Error(dateError);
      await reschedulePmOccurrence({ id: occurrenceId, dueDate: newDueDate });
    },
    onSuccess: () => {
      setRescheduleOpen(false);
      setNewDueDate('');
      setRescheduleError(null);
      invalidatePmQueries();
    },
    onError: (err: Error) => setRescheduleError(err.message),
  });

  const addTechnician = (userId: string) => {
    const current = occurrence?.assignedTechnicianIds ?? [];
    if (current.includes(userId)) return;
    updateAssigneesMutation.mutate([...current, userId]);
  };

  const removeTechnician = (userId: string) => {
    const current = occurrence?.assignedTechnicianIds ?? [];
    updateAssigneesMutation.mutate(current.filter((id) => id !== userId));
  };

  const handleCompleteWithPhoto = () => fileInputRef.current?.click();

  const onFileSelected = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    void runComplete(async () => {
      await completeMutation.mutateAsync(file ?? null);
    });
    e.target.value = '';
  };

  const openReschedule = () => {
    setNewDueDate(occurrence?.dueDate ?? '');
    setRescheduleError(null);
    setRescheduleOpen(true);
  };

  if (isLoading) return <LoadingSpinner label="Loading occurrence" />;

  if (error || !occurrence) {
    return (
      <QueryErrorState
        title="Occurrence unavailable"
        message={
          error instanceof Error
            ? error.message
            : 'This occurrence may have been removed or you may not have permission to view it.'
        }
        onRetry={() => refetch()}
      />
    );
  }

  const displayStatus = occurrence.derivedStatus ?? occurrence.status;
  const schedule = occurrence.schedule;
  const asset = occurrence.asset;
  const checklist = parseScheduleChecklist(schedule?.metadata);
  const canModify = displayStatus !== 'completed' && displayStatus !== 'cancelled';

  return (
    <div>
      <PageHeader
        breadcrumbs={[
          { label: 'PM Schedules', href: '/pm-schedules' },
          {
            label: schedule?.taskName ?? 'Schedule',
            href: `/pm-schedules/${scheduleId}`,
          },
          { label: new Date(occurrence.dueDate).toLocaleDateString() },
        ]}
        title={asset?.name ?? schedule?.taskName ?? 'PM occurrence'}
        description="Complete this occurrence — other due dates in the schedule stay open."
        actions={
          <>
            <StatusBadge status={displayStatus} />
            {schedule?.frequency && <Badge>{formatPmFrequency(schedule.frequency)}</Badge>}
            <Link href={`/pm-schedules/${scheduleId}`}>
              <Button variant="outline" size="sm">
                Back to schedule
              </Button>
            </Link>
          </>
        }
        className="mb-8"
      />

      <input
        ref={fileInputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        className="hidden"
        onChange={onFileSelected}
      />

      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Occurrence details</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <dl className="space-y-2 text-sm">
              <div>
                <dt className="text-muted-foreground">Due date</dt>
                <dd>{new Date(occurrence.dueDate).toLocaleDateString()}</dd>
              </div>
              {occurrence.completedAt && (
                <div>
                  <dt className="text-muted-foreground">Completed</dt>
                  <dd>
                    {new Date(occurrence.completedAt).toLocaleDateString()}
                    {completedByUser ? ` by ${completedByUser.name}` : ''}
                  </dd>
                </div>
              )}
              {occurrence.cancelledAt && (
                <div>
                  <dt className="text-muted-foreground">Cancelled</dt>
                  <dd>
                    {new Date(occurrence.cancelledAt).toLocaleDateString()}
                    {cancelledByUser ? ` by ${cancelledByUser.name}` : ''}
                  </dd>
                </div>
              )}
              {occurrence.cancelReason && (
                <div>
                  <dt className="text-muted-foreground">Cancel reason</dt>
                  <dd>{occurrence.cancelReason}</dd>
                </div>
              )}
              {occurrence.completionNotes && (
                <div>
                  <dt className="text-muted-foreground">Completion notes</dt>
                  <dd className="whitespace-pre-wrap">{occurrence.completionNotes}</dd>
                </div>
              )}
            </dl>
            {schedule?.description && (
              <p className="text-sm text-muted-foreground pt-2 border-t border-border">
                {schedule.description}
              </p>
            )}
            {checklist.length > 0 && (
              <div className="border-t border-border pt-3">
                <p className="text-sm font-medium mb-2">Checklist</p>
                <ul className="list-disc space-y-1 pl-5 text-sm text-muted-foreground">
                  {checklist.map((item) => (
                    <li key={item}>{item}</li>
                  ))}
                </ul>
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Charger / asset</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3 text-sm">
            <dl className="space-y-2">
              <div>
                <dt className="text-muted-foreground">Name</dt>
                <dd>{asset?.name ?? occurrence.assetId}</dd>
              </div>
              <div>
                <dt className="text-muted-foreground">Company</dt>
                <dd>{asset?.company?.name ?? '—'}</dd>
              </div>
              <div>
                <dt className="text-muted-foreground">Location</dt>
                <dd>{asset?.location ?? '—'}</dd>
              </div>
              <div>
                <dt className="text-muted-foreground">Manufacturer</dt>
                <dd>{asset?.manufacturer ?? '—'}</dd>
              </div>
              <div>
                <dt className="text-muted-foreground">Model</dt>
                <dd>{asset?.model ?? '—'}</dd>
              </div>
              <div>
                <dt className="text-muted-foreground">Serial number</dt>
                <dd>{asset?.serialNumber ?? '—'}</dd>
              </div>
            </dl>
            <Link
              href={
                asset?.companyId
                  ? `/assets?companyId=${encodeURIComponent(asset.companyId)}`
                  : '/assets'
              }
            >
              <Button variant="outline" size="sm">
                View in assets
              </Button>
            </Link>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Assigned technicians</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {assignedUsers.length > 0 ? (
              <ul className="space-y-1.5">
                {assignedUsers.map((u) => (
                  <li
                    key={u.id}
                    className="flex items-center justify-between rounded-md bg-muted/50 px-2 py-1.5 text-sm"
                  >
                    <span>{u.name}</span>
                    {canModify && (
                      <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        className="h-7 text-muted-foreground hover:text-destructive"
                        onClick={() => removeTechnician(u.id)}
                        disabled={updateAssigneesMutation.isPending}
                      >
                        Remove
                      </Button>
                    )}
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-sm text-muted-foreground">No one assigned.</p>
            )}
            {canModify && allUsers.length > 0 && (
              <div className="flex flex-wrap gap-2 pt-2 border-t border-border">
                {allUsers
                  .filter((u) => !assignedIds.includes(u.id))
                  .slice(0, 6)
                  .map((u) => (
                    <Button
                      key={u.id}
                      type="button"
                      variant="outline"
                      size="sm"
                      onClick={() => addTechnician(u.id)}
                      disabled={updateAssigneesMutation.isPending}
                    >
                      + {u.name}
                    </Button>
                  ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      <Card className="mt-4">
        <CardHeader>
          <CardTitle>Completion</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {occurrence.completionPhotoPath && (
            <div>
              <p className="text-sm font-medium text-muted-foreground mb-2">Completion photo</p>
              <a
                href={occurrence.completionPhotoPath}
                target="_blank"
                rel="noopener noreferrer"
                className="block rounded-lg overflow-hidden border border-border w-48 h-32"
              >
                <img
                  src={occurrence.completionPhotoPath}
                  alt="Completion"
                  className="w-full h-full object-cover"
                />
              </a>
            </div>
          )}
          {canModify && (
            <>
              <label className="block text-sm">
                <span className="font-medium text-muted-foreground">Completion notes (optional)</span>
                <textarea
                  value={completionNotes}
                  onChange={(e) => setCompletionNotes(e.target.value)}
                  rows={3}
                  className="mt-1 w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
                  placeholder="Work performed, parts replaced, observations..."
                />
              </label>
              {completionError && (
                <p className="text-sm text-destructive">{completionError}</p>
              )}
              <div className="flex flex-wrap items-center gap-2">
                <Button
                  onClick={handleCompleteWithPhoto}
                  disabled={completeMutation.isPending || completing}
                >
                  Mark complete with photo
                </Button>
                <Button
                  variant="outline"
                  onClick={() =>
                    void runComplete(async () => {
                      await completeMutation.mutateAsync(null);
                    })
                  }
                  disabled={completeMutation.isPending || completing}
                >
                  Mark complete (no photo)
                </Button>
                <Button variant="outline" onClick={openReschedule} disabled={rescheduling}>
                  Reschedule
                </Button>
                <Button
                  variant="outline"
                  className="text-destructive hover:text-destructive"
                  onClick={() => {
                    setCancelReason('');
                    setCancelError(null);
                    setCancelOpen(true);
                  }}
                >
                  Cancel occurrence
                </Button>
              </div>
            </>
          )}
        </CardContent>
      </Card>

      <Modal open={cancelOpen} onClose={() => setCancelOpen(false)} title="Cancel occurrence">
        <p className="text-sm text-muted-foreground mb-3">
          This due date will be marked cancelled. Other occurrences in the schedule are unaffected.
        </p>
        <label className="block text-sm">
          <span className="font-medium">Reason</span>
          <textarea
            value={cancelReason}
            onChange={(e) => setCancelReason(e.target.value)}
            rows={3}
            className="mt-1 w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
            placeholder="Why is this occurrence being cancelled?"
          />
        </label>
        {cancelError && <p className="mt-2 text-sm text-destructive">{cancelError}</p>}
        <ModalActions>
          <Button variant="outline" onClick={() => setCancelOpen(false)}>
            Keep occurrence
          </Button>
          <Button
            variant="destructive"
            disabled={cancelling || cancelMutation.isPending}
            onClick={() =>
              void runCancel(async () => {
                await cancelMutation.mutateAsync();
              })
            }
          >
            Cancel occurrence
          </Button>
        </ModalActions>
      </Modal>

      <Modal
        open={rescheduleOpen}
        onClose={() => setRescheduleOpen(false)}
        title="Reschedule due date"
      >
        <label className="block text-sm">
          <span className="font-medium">New due date</span>
          <input
            type="date"
            value={newDueDate}
            onChange={(e) => setNewDueDate(e.target.value)}
            className="mt-1 w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
          />
        </label>
        {rescheduleError && <p className="mt-2 text-sm text-destructive">{rescheduleError}</p>}
        <ModalActions>
          <Button variant="outline" onClick={() => setRescheduleOpen(false)}>
            Close
          </Button>
          <Button
            disabled={rescheduling || rescheduleMutation.isPending}
            onClick={() =>
              void runReschedule(async () => {
                await rescheduleMutation.mutateAsync();
              })
            }
          >
            Save new date
          </Button>
        </ModalActions>
      </Modal>
    </div>
  );
}
