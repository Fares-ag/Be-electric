'use client';

import { useParams } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useRef } from 'react';
import { supabase } from '@/lib/supabase';
import { uploadPmTaskCompletionPhoto } from '@/lib/storage';
import { useUsersMap } from '@/hooks/useUsersMap';
import { useFormSubmitLock } from '@/hooks/useFormSubmitLock';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge, StatusBadge } from '@/components/ui/Badge';
import { LoadingSpinner, PageHeader, QueryErrorState } from '@/components/ui/PageStates';

type PMTaskDetail = {
  id: string;
  taskName: string;
  status: string;
  frequency: string;
  nextDueDate: string;
  description: string | null;
  assignedTechnicianIds: string[] | null;
  completionPhotoPath: string | null;
  lastCompletedDate: string | null;
  assetId: string;
  asset?: { name?: string };
};

export default function PMTaskDetailPage() {
  const params = useParams();
  const id = params.id as string;
  const queryClient = useQueryClient();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const { submitting: completing, runSubmit: runComplete } = useFormSubmitLock();

  const { data: task, isLoading, error: queryError, refetch } = useQuery({
    queryKey: ['pm-task', id],
    staleTime: 60 * 1000,
    queryFn: async (): Promise<PMTaskDetail | null> => {
      const { data } = await supabase
        .from('pm_tasks')
        .select(
          'id, taskName, status, frequency, nextDueDate, description, assignedTechnicianIds, completionPhotoPath, lastCompletedDate, assetId, asset:assets(name)'
        )
        .eq('id', id)
        .single();
      return data as PMTaskDetail | null;
    },
  });

  const assignedIds = task?.assignedTechnicianIds ?? [];
  const { users: allUsers } = useUsersMap(!!task);
  const assignedUsers = allUsers.filter((u) => assignedIds.includes(u.id));

  const updateAssigneesMutation = useMutation({
    mutationFn: async (technicianIds: string[]) => {
      const { error } = await supabase
        .from('pm_tasks')
        .update({ assignedTechnicianIds: technicianIds, updatedAt: new Date().toISOString() })
        .eq('id', id);
      if (error) throw error;
      if (technicianIds.length > 0 && task) {
        const { data: { session } } = await supabase.auth.getSession();
        const token = session?.access_token;
        if (token) {
          fetch('/api/notifications/push', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${token}`,
            },
            body: JSON.stringify({
              type: 'pm_task_assigned',
              external_user_ids: technicianIds,
              title: 'PM task assigned',
              message: `"${task.taskName}" has been assigned to you.`,
              data: { pm_task_id: id, task_name: task.taskName },
            }),
          }).catch(() => { /* best-effort */ });
        }
      }
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['pm-task', id] }),
  });

  const completeTaskMutation = useMutation({
    mutationFn: async (photoFile: File | null) => {
      let completionPhotoPath: string | null = null;
      if (photoFile) {
        completionPhotoPath = await uploadPmTaskCompletionPhoto(photoFile, id);
      }
      const { error } = await supabase
        .from('pm_tasks')
        .update({
          status: 'completed',
          lastCompletedDate: new Date().toISOString(),
          completionPhotoPath: completionPhotoPath ?? undefined,
          updatedAt: new Date().toISOString(),
        })
        .eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['pm-task', id] });
      queryClient.invalidateQueries({ queryKey: ['pm-tasks'] });
    },
  });

  const addTechnician = (userId: string) => {
    const current = task?.assignedTechnicianIds ?? [];
    if (current.includes(userId)) return;
    updateAssigneesMutation.mutate([...current, userId]);
  };

  const removeTechnician = (userId: string) => {
    const current = task?.assignedTechnicianIds ?? [];
    updateAssigneesMutation.mutate(current.filter((id) => id !== userId));
  };

  const handleCompleteWithPhoto = () => fileInputRef.current?.click();

  const onFileSelected = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    void runComplete(async () => {
      await completeTaskMutation.mutateAsync(file ?? null);
    });
    e.target.value = '';
  };

  if (isLoading) return <LoadingSpinner label="Loading PM task" />;

  if (queryError || !task) {
    return (
      <QueryErrorState
        title="PM task unavailable"
        message={
          queryError instanceof Error
            ? queryError.message
            : 'This PM task may have been removed or you may not have permission to view it.'
        }
        onRetry={() => refetch()}
      />
    );
  }

  return (
    <div>
      <PageHeader
        title={task.taskName}
        actions={
          <>
            <StatusBadge status={task.status} />
            <Badge>{task.frequency}</Badge>
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
                <dt className="text-muted-foreground">Next due</dt>
                <dd>{new Date(task.nextDueDate).toLocaleDateString()}</dd>
              </div>
              <div>
                <dt className="text-muted-foreground">Charger</dt>
                <dd>{(task.asset as { name?: string })?.name ?? task.assetId}</dd>
              </div>
              {task.lastCompletedDate && (
                <div>
                  <dt className="text-muted-foreground">Last completed</dt>
                  <dd>{new Date(task.lastCompletedDate).toLocaleDateString()}</dd>
                </div>
              )}
            </dl>
            {task.description && (
              <p className="text-sm text-muted-foreground pt-2 border-t border-border">
                {task.description}
              </p>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Assigned technicians</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {assignedUsers && assignedUsers.length > 0 ? (
              <ul className="space-y-1.5">
                {(assignedUsers as { id: string; name: string }[]).map((u) => (
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
            {allUsers && (allUsers as { id: string; name: string }[]).length > 0 && (
              <div className="flex flex-wrap gap-2 pt-2 border-t border-border">
                {(allUsers as { id: string; name: string }[])
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
          {task.completionPhotoPath && (
            <div>
              <p className="text-sm font-medium text-muted-foreground mb-2">Completion photo</p>
              <a
                href={task.completionPhotoPath}
                target="_blank"
                rel="noopener noreferrer"
                className="block rounded-lg overflow-hidden border border-border w-48 h-32"
              >
                <img
                  src={task.completionPhotoPath}
                  alt="Completion"
                  className="w-full h-full object-cover"
                />
              </a>
            </div>
          )}
          {task.status !== 'completed' && (
            <div className="flex flex-wrap items-center gap-2">
              <Button
                onClick={handleCompleteWithPhoto}
                disabled={completeTaskMutation.isPending || completing}
              >
                Mark complete with photo
              </Button>
              <Button
                variant="outline"
                onClick={() =>
                  void runComplete(async () => {
                    await completeTaskMutation.mutateAsync(null);
                  })
                }
                disabled={completeTaskMutation.isPending || completing}
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
