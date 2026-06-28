import { StatusBadge } from '@/components/ui/Badge';
import { DetailCard, DetailField, DetailGrid } from '@/components/ui/DetailCard';
import { SignatureImage } from '@/components/work-orders/SignatureImage';
import {
  formatCurrency,
  formatMaybeIso,
  parseActivityHistory,
  parseReopenHistory,
  readMetaString,
  type WorkOrderActivityEntry,
  type WorkOrderDetail,
} from '@/lib/work-order-detail';

export function WorkOrderNotesCard({ wo }: { wo: WorkOrderDetail }) {
  if (!wo.notes && !wo.technicianNotes) return null;

  return (
    <DetailCard title="Notes">
      <div className="space-y-3 text-sm">
        {wo.notes && (
          <div>
            <p className="mb-1 text-xs text-muted-foreground">General</p>
            <p className="whitespace-pre-wrap">{wo.notes}</p>
          </div>
        )}
        {wo.technicianNotes && (
          <div>
            <p className="mb-1 text-xs text-muted-foreground">Technician</p>
            <p className="whitespace-pre-wrap">{wo.technicianNotes}</p>
          </div>
        )}
      </div>
    </DetailCard>
  );
}

export function WorkOrderRootCauseCard({
  rawMeta,
}: {
  rawMeta: Record<string, unknown> | undefined;
}) {
  const rootCause = readMetaString(rawMeta, 'rootCause', 'root_cause');
  const failureMode = readMetaString(rawMeta, 'failureMode', 'failure_mode');
  const severity = readMetaString(rawMeta, 'severityLevel', 'severity_level');
  const workCategory = readMetaString(rawMeta, 'workCategory', 'work_category');
  const repeatFailure = readMetaString(rawMeta, 'isRepeatFailure', 'is_repeat_failure');

  if (!rootCause && !failureMode && !severity && !workCategory && !repeatFailure) return null;

  return (
    <DetailCard title="Root cause & analytics (metadata)">
      <DetailGrid className="gap-2">
        {rootCause && (
          <DetailField label="Root cause" span={2}>
            {rootCause}
          </DetailField>
        )}
        {failureMode && <DetailField label="Failure mode">{failureMode}</DetailField>}
        {severity && <DetailField label="Severity">{severity}</DetailField>}
        {workCategory && <DetailField label="Work category">{workCategory}</DetailField>}
        {repeatFailure && <DetailField label="Repeat failure">{repeatFailure}</DetailField>}
      </DetailGrid>
    </DetailCard>
  );
}

export function WorkOrderCostPartsCard({
  wo,
  visible,
}: {
  wo: WorkOrderDetail;
  visible: boolean;
}) {
  if (!visible) return null;

  const hasCostData =
    wo.laborCost != null ||
    wo.partsCost != null ||
    wo.totalCost != null ||
    wo.estimatedCost != null ||
    wo.actualCost != null ||
    wo.laborHours != null ||
    (wo.partsUsed && wo.partsUsed.length > 0);

  if (!hasCostData) return null;

  return (
    <DetailCard title="Cost & parts">
      <DetailGrid>
        {wo.estimatedCost != null && (
          <DetailField label="Estimated cost">{formatCurrency(wo.estimatedCost)}</DetailField>
        )}
        {wo.actualCost != null && (
          <DetailField label="Actual cost">{formatCurrency(wo.actualCost)}</DetailField>
        )}
        {wo.laborCost != null && (
          <DetailField label="Labor cost">{formatCurrency(wo.laborCost)}</DetailField>
        )}
        {wo.partsCost != null && (
          <DetailField label="Parts cost">{formatCurrency(wo.partsCost)}</DetailField>
        )}
        {wo.totalCost != null && (
          <DetailField label="Total">
            <span className="font-semibold">{formatCurrency(wo.totalCost)}</span>
          </DetailField>
        )}
        {wo.laborHours != null && <DetailField label="Labor hours">{wo.laborHours}</DetailField>}
        {wo.partsUsed && wo.partsUsed.length > 0 && (
          <DetailField label="Parts used" span={2}>
            <span className="text-xs">
              {wo.partsUsed.map((p) => (typeof p === 'string' ? p : String(p))).join(', ')}
            </span>
          </DetailField>
        )}
      </DetailGrid>
    </DetailCard>
  );
}

export function WorkOrderCustomerCard({ wo }: { wo: WorkOrderDetail }) {
  if (!wo.customerName && !wo.customerPhone && !wo.customerEmail && !wo.customerSignature) {
    return null;
  }

  return (
    <DetailCard title="Customer">
      <DetailGrid className="gap-2">
        {wo.customerName && <DetailField label="Name">{wo.customerName}</DetailField>}
        {wo.customerPhone && <DetailField label="Phone">{wo.customerPhone}</DetailField>}
        {wo.customerEmail && <DetailField label="Email">{wo.customerEmail}</DetailField>}
      </DetailGrid>
      {wo.customerSignature && (
        <div className="mt-3">
          <p className="mb-1 text-xs text-muted-foreground">Customer signature</p>
          <SignatureImage value={wo.customerSignature} alt="Customer signature" />
        </div>
      )}
    </DetailCard>
  );
}

export function WorkOrderPauseResumeCard({ wo }: { wo: WorkOrderDetail }) {
  if (!wo.isPaused && !wo.pausedAt && !wo.pauseReason && !wo.resumedAt && !wo.pauseHistory) {
    return null;
  }

  return (
    <DetailCard title="Pause / resume">
      <DetailGrid className="gap-2">
        <DetailField label="Paused">{wo.isPaused ? 'Yes' : 'No'}</DetailField>
        {wo.pausedAt && (
          <DetailField label="Paused at">{formatMaybeIso(wo.pausedAt)}</DetailField>
        )}
        {wo.pauseReason && (
          <DetailField label="Reason" span={2}>
            <span className="whitespace-pre-wrap">{wo.pauseReason}</span>
          </DetailField>
        )}
        {wo.resumedAt && (
          <DetailField label="Resumed at">{formatMaybeIso(wo.resumedAt)}</DetailField>
        )}
        {wo.pauseHistory != null && String(wo.pauseHistory) !== '' && (
          <DetailField label="Pause history" span={2}>
            <pre className="max-h-32 overflow-x-auto rounded bg-muted/50 p-2 text-xs">
              {JSON.stringify(wo.pauseHistory, null, 0)}
            </pre>
          </DetailField>
        )}
      </DetailGrid>
    </DetailCard>
  );
}

export function WorkOrderSyncOfflineCard({ wo }: { wo: WorkOrderDetail }) {
  if (wo.isOffline == null && !wo.lastSyncedAt) return null;

  return (
    <DetailCard title="Sync / offline">
      <DetailGrid className="gap-2">
        {wo.isOffline != null && (
          <DetailField label="Offline">{wo.isOffline ? 'Yes' : 'No'}</DetailField>
        )}
        {wo.lastSyncedAt && (
          <DetailField label="Last synced">{formatMaybeIso(wo.lastSyncedAt)}</DetailField>
        )}
      </DetailGrid>
    </DetailCard>
  );
}

export function WorkOrderReopenHistoryCard({
  rawMeta,
  reopenedByName,
}: {
  rawMeta: Record<string, unknown> | undefined;
  reopenedByName: string | null | undefined;
}) {
  const history = parseReopenHistory(rawMeta);
  if (!history) return null;

  return (
    <DetailCard title="Reopen history" className="mt-4">
      <div className="space-y-3 text-sm">
        <p className="font-medium text-foreground">
          Reopened {history.count} time{history.count !== 1 ? 's' : ''}
        </p>
        {history.reopenedAt && (
          <div>
            <span className="text-muted-foreground">Last reopened: </span>
            {new Date(history.reopenedAt).toLocaleString()}
            {reopenedByName && (
              <span className="text-muted-foreground"> by {reopenedByName}</span>
            )}
          </div>
        )}
        {history.reopenReason && (
          <div>
            <span className="text-muted-foreground">Reason: </span>
            <span className="text-foreground">{history.reopenReason}</span>
          </div>
        )}
        {history.previousStatus && (
          <div>
            <span className="text-muted-foreground">Previous status: </span>
            <StatusBadge status={history.previousStatus} />
          </div>
        )}
        {history.previousCompletionDate && (
          <div>
            <span className="text-muted-foreground">Previous completion: </span>
            {new Date(history.previousCompletionDate).toLocaleString()}
          </div>
        )}
      </div>
    </DetailCard>
  );
}

export function WorkOrderActivityCard({
  activityHistory,
}: {
  activityHistory: WorkOrderActivityEntry[] | string | null | undefined;
}) {
  const activity = parseActivityHistory(activityHistory);
  if (activity.length === 0) return null;

  return (
    <DetailCard title="Activity history" className="mt-4">
      <ul className="space-y-2 text-sm">
        {activity.map((entry, i) => (
          <li
            key={i}
            className="flex flex-wrap items-baseline gap-2 border-b border-border pb-2 last:border-0 last:pb-0"
          >
            <time className="shrink-0 text-muted-foreground">
              {new Date(entry.at).toLocaleString()}
            </time>
            <span className="font-medium capitalize">{entry.type}</span>
            {entry.note && <span className="text-muted-foreground">— {entry.note}</span>}
          </li>
        ))}
      </ul>
    </DetailCard>
  );
}

export function WorkOrderTextSectionCard({
  title,
  content,
  className,
}: {
  title: string;
  content: string;
  className?: string;
}) {
  return (
    <DetailCard title={title} className={className}>
      <p className="whitespace-pre-wrap text-sm text-foreground">{content}</p>
    </DetailCard>
  );
}

export function WorkOrderSignaturesCard({ wo }: { wo: WorkOrderDetail }) {
  if (!wo.requestorSignature && !wo.technicianSignature) return null;

  return (
    <DetailCard title="Signatures" className="mt-4">
      <div className="grid gap-4 sm:grid-cols-2">
        {wo.requestorSignature && (
          <div>
            <p className="mb-1 text-xs text-muted-foreground">Requestor</p>
            <SignatureImage value={wo.requestorSignature} alt="Requestor signature" />
          </div>
        )}
        {wo.technicianSignature && (
          <div>
            <p className="mb-1 text-xs text-muted-foreground">Technician</p>
            <SignatureImage value={wo.technicianSignature} alt="Technician signature" />
          </div>
        )}
      </div>
    </DetailCard>
  );
}
