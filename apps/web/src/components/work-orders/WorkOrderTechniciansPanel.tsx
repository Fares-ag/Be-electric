'use client';

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';

type AssignableUser = { id: string; name: string; role?: string };

type Props = {
  assignedUsers: AssignableUser[];
  assignableUsers: AssignableUser[];
  assignedIds: string[];
  assignError: string | null;
  pushWarning: string | null;
  isCompletionLocked: boolean;
  pending: boolean;
  onAdd: (userId: string) => void;
  onRemove: (userId: string) => void;
};

export function WorkOrderTechniciansPanel({
  assignedUsers,
  assignableUsers,
  assignedIds,
  assignError,
  pushWarning,
  isCompletionLocked,
  pending,
  onAdd,
  onRemove,
}: Props) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Assigned technicians</CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        {assignError && (
          <p className="rounded bg-destructive/10 px-2 py-1.5 text-sm text-destructive" role="alert">
            {assignError}
          </p>
        )}
        {pushWarning && (
          <p className="rounded border border-amber-500/30 bg-amber-500/10 px-2 py-1.5 text-sm text-amber-700 dark:text-amber-400">
            {pushWarning}
          </p>
        )}
        {assignedUsers.length > 0 ? (
          <ul className="space-y-1.5">
            {assignedUsers.map((u) => (
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
                    onClick={() => onRemove(u.id)}
                    disabled={pending}
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
        {!isCompletionLocked && assignableUsers.length > 0 && (
          <div className="flex flex-wrap gap-2 border-t border-border pt-2">
            <p className="mb-1 w-full text-xs text-muted-foreground">Assign technician:</p>
            {assignableUsers
              .filter((u) => !assignedIds.includes(u.id))
              .slice(0, 12)
              .map((u) => (
                <Button
                  key={u.id}
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={() => onAdd(u.id)}
                  disabled={pending}
                >
                  + {u.name}
                </Button>
              ))}
            {assignableUsers.filter((u) => !assignedIds.includes(u.id)).length === 0 && (
              <p className="text-xs text-muted-foreground">
                No other technicians to assign. Add users with role Technician in Users.
              </p>
            )}
          </div>
        )}
        {isCompletionLocked && (
          <p className="border-t border-border pt-2 text-xs text-muted-foreground">
            Assignments cannot be changed after the work order is completed.
          </p>
        )}
      </CardContent>
    </Card>
  );
}
