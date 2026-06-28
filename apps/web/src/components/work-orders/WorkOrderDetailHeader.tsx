'use client';

import { Badge, StatusBadge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { allowedAdminStatuses, type WorkOrderDetail } from '@/lib/work-order-detail';

type Props = {
  wo: WorkOrderDetail;
  isAdminOrManager: boolean;
  canReopen: boolean;
  statusPending: boolean;
  onStatusChange: (status: string) => void;
  onReopenClick: () => void;
};

export function WorkOrderDetailHeader({
  wo,
  isAdminOrManager,
  canReopen,
  statusPending,
  onStatusChange,
  onReopenClick,
}: Props) {
  const statusOptions = allowedAdminStatuses(wo.status);

  return (
    <div className="mb-8 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:gap-4">
        <h1 className="text-2xl font-semibold tracking-tight text-foreground">{wo.ticketNumber}</h1>
        <div className="flex flex-wrap items-center gap-2">
          <StatusBadge status={wo.status} />
          {isAdminOrManager && (
            <select
              value={wo.status}
              onChange={(e) => onStatusChange(e.target.value)}
              disabled={statusPending}
              className="rounded-md border border-input bg-background px-3 py-1.5 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-primary/20"
              aria-label="Work order status"
            >
              {statusOptions.map((s) => (
                <option key={s} value={s}>
                  {s.replace(/([A-Z])/g, ' $1').trim()}
                </option>
              ))}
            </select>
          )}
          <Badge>{wo.priority}</Badge>
          {wo.category && (
            <span className="rounded-md border border-border px-2 py-0.5 text-xs text-muted-foreground">
              {wo.category}
            </span>
          )}
          {canReopen && (
            <Button type="button" variant="outline" size="sm" onClick={onReopenClick}>
              Reopen work order
            </Button>
          )}
        </div>
      </div>
    </div>
  );
}
