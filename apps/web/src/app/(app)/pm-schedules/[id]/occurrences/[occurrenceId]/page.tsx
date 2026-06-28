'use client';

import { useParams } from 'next/navigation';
import Link from 'next/link';
import { useRef } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge, StatusBadge } from '@/components/ui/Badge';
import { LoadingSpinner, PageHeader, QueryErrorState } from '@/components/ui/PageStates';
import { useFormSubmitLock } from '@/hooks/useFormSubmitLock';
import { useUsersMap } from '@/hooks/useUsersMap';
import { formatPmFrequency } from '@/lib/pm-schedule';
import {
  completePmOccurrence,
  fetchPmOccurrenceDetail,
  pmOccurrenceDetailQueryKey,
  pmScheduleOccurrencesQueryKey,
  updatePmOccurrenceAssignees,
} from '@/lib/queries/pm-schedules';
import { uploadPmOccurrenceCompletionPhoto } from '@/lib/storage';

export default function PmOccurrenceDetailPage() {
  const params = useParams();
  const scheduleId = params.id as string;
  const occurrenceId = params.occurrenceId as string;
  const queryClient = useQueryClient();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const { submitting: completing, runSubmit: runComplete } = useFormSubmitLock();

  const { data: occurrence, isLoading, error, refetch } = useQuery({
    queryKey: pmOccurrenceDetailQueryKey(occurrenceId),
    staleTime: 60 * 1000,
    queryFn: () => fetchPmOccurrenceDetail(occurrenceId),
  });

  const assignedIds = occurrence?.assignedTechnicianIds ?? [];
  const { users: allUsers } = useUsersMap(!!occurrence);
  const assignedUsers = allUsers.filter((u) => assignedIds.includes(u.id));

  const updateAssigneesMutation = useMutation({
    mutationFn: (technicianIds: string[]) =>
      updatePmOccurrenceAssignees(occurrenceId, technicianIds),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: pmOccurrenceDetailQueryKey(occurrenceId) });
      queryClient.invalidateQueries({ queryKey: pmScheduleOccurrencesQueryKey(scheduleId) });
    },
  });

  const completeMutation = useMutation({
    mutationFn: async (photoFile: File | null) => {
      let completionPhotoPath: string | null = null;
      if (photoFile) {
        completionPhotoPath = await uploadPmOccurrenceCompletionPhoto(photoFile, occurrenceId);
      }
      await completePmOccurrence({ id: occurrenceId, completionPhotoPath });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: pmOccurrenceDetailQueryKey(occurrenceId) });
      queryClient.invalidateQueries({ queryKey: pmScheduleOccurrencesQueryKey(scheduleId) });
    },
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

  return (
    <div>
      <PageHeader
        title={schedule?.taskName ?? 'PM occurrence'}
        description="Complete this occurrence individually — other due dates stay pending."
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
            <CardTitle>Details</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <dl className="space-y-2 text-sm">
              <div>
                <dt className="text-muted-foreground">Due date</dt>
                <dd>{new Date(occurrence.dueDate).toLocaleDateString()}</dd>
              </div>
              <div>
                <dt className="text-muted-foreground">Charger</dt>
                <dd>{occurrence.asset?.name ?? occurrence.assetId}</dd>
              </div>
              {occurrence.completedAt && (
                <div>
                  <dt className="text-muted-foreground">Completed</dt>
                  <dd>{new Date(occurrence.completedAt).toLocaleDateString()}</dd>
                </div>
              )}
            </dl>
            {schedule?.description && (
              <p className="text-sm text-muted-foreground pt-2 border-t border-border">
                {schedule.description}
              </p>
            )}
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
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-sm text-muted-foreground">No one assigned.</p>
            )}
            {allUsers.length > 0 && (
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
          {displayStatus !== 'completed' && displayStatus !== 'cancelled' && (
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
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
