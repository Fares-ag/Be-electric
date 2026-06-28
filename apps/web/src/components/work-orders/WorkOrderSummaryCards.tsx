import { DetailCard, DetailField, DetailGrid } from '@/components/ui/DetailCard';
import { manufacturerFromChargerName } from '@/lib/charger-manufacturer';
import { effortMinutesDisplay, formatMaybeIso, readMetaString, type WorkOrderDetail } from '@/lib/work-order-detail';

type AssetMeta = {
  id?: string;
  name?: string;
  location?: string | null;
  manufacturer?: string | null;
} | null | undefined;

type CompanyMeta = { id?: string; name?: string } | null | undefined;

export function WorkOrderIdentityCard({ wo }: { wo: WorkOrderDetail }) {
  return (
    <DetailCard title="Identity & request">
      <DetailGrid>
        <DetailField label="Ticket">
          <span className="font-medium">{wo.ticketNumber}</span>
        </DetailField>
        <DetailField label="Requestor">{wo.requestorName ?? '—'}</DetailField>
        <DetailField label="Problem" span={2}>
          <span className="whitespace-pre-wrap text-foreground">{wo.problemDescription}</span>
        </DetailField>
      </DetailGrid>
    </DetailCard>
  );
}

export function WorkOrderLocationCard({
  wo,
  metaAsset,
  metaCompany,
}: {
  wo: WorkOrderDetail;
  metaAsset: AssetMeta;
  metaCompany: CompanyMeta;
}) {
  const assetName = wo.asset?.name ?? metaAsset?.name ?? '—';
  const assetId = wo.assetId ?? metaAsset?.id;
  const manufacturer =
    manufacturerFromChargerName(assetName !== '—' ? assetName : null) ??
    wo.asset?.manufacturer ??
    metaAsset?.manufacturer;
  const location =
    wo.location && wo.location.trim() !== ''
      ? wo.location
      : (wo.asset?.location ?? metaAsset?.location ?? '—');

  return (
    <DetailCard title="Where / tenant">
      <DetailGrid>
        <DetailField label="Charger (asset)" span={2}>
          {assetName}
          {assetId && (
            <span className="ml-1 text-xs text-muted-foreground">({String(assetId).slice(0, 8)}…)</span>
          )}
        </DetailField>
        {manufacturer != null && <DetailField label="Manufacturer">{manufacturer}</DetailField>}
        <DetailField label="Location" span={2}>
          {location}
        </DetailField>
        <DetailField label="Company">
          {wo.company?.name ?? metaCompany?.name ?? '—'}
        </DetailField>
        <DetailField label="Company ID">
          <span className="break-all font-mono text-xs">{wo.companyId ?? metaCompany?.id ?? '—'}</span>
        </DetailField>
      </DetailGrid>
    </DetailCard>
  );
}

export function WorkOrderAssignmentCard({
  wo,
  primaryTechnicianName,
  visible,
}: {
  wo: WorkOrderDetail;
  primaryTechnicianName: string | null | undefined;
  visible: boolean;
}) {
  if (!visible) return null;

  return (
    <DetailCard title="Assignment & effort">
      <DetailGrid>
        <DetailField label="Primary technician">
          {primaryTechnicianName ?? (wo.primaryTechnicianId ? wo.primaryTechnicianId : '—')}
        </DetailField>
        {wo.assignedTechnicianId && (
          <DetailField label="Legacy assignedTechnicianId">
            <span className="font-mono text-xs">{wo.assignedTechnicianId}</span>
          </DetailField>
        )}
        <DetailField label="Technician effort (minutes)" span={2}>
          <span className="text-xs">{effortMinutesDisplay(wo.technicianEffortMinutes)}</span>
        </DetailField>
        <DetailField label="Assigned at">{formatMaybeIso(wo.assignedAt)}</DetailField>
      </DetailGrid>
    </DetailCard>
  );
}

export function WorkOrderTimelineCard({
  wo,
  rawMeta,
}: {
  wo: WorkOrderDetail;
  rawMeta: Record<string, unknown> | undefined;
}) {
  return (
    <DetailCard title="Timeline">
      <DetailGrid>
        <DetailField label="Created">{new Date(wo.createdAt).toLocaleString()}</DetailField>
        <DetailField label="Updated">
          {wo.updatedAt ? new Date(wo.updatedAt).toLocaleString() : '—'}
        </DetailField>
        <DetailField label="Assigned">{formatMaybeIso(wo.assignedAt)}</DetailField>
        <DetailField label="Started">{formatMaybeIso(wo.startedAt)}</DetailField>
        <DetailField label="Completed">{formatMaybeIso(wo.completedAt)}</DetailField>
        <DetailField label="Closed">{formatMaybeIso(wo.closedAt)}</DetailField>
        <DetailField label="Next maintenance">
          {wo.nextMaintenanceDate
            ? new Date(wo.nextMaintenanceDate).toLocaleDateString(undefined, { dateStyle: 'medium' })
            : '—'}
        </DetailField>
        {readMetaString(rawMeta, 'firstResponseTime', 'first_response_time') && (
          <DetailField label="First response (metadata)">
            {readMetaString(rawMeta, 'firstResponseTime', 'first_response_time')}
          </DetailField>
        )}
        {readMetaString(rawMeta, 'actualStartTime', 'actual_start_time') && (
          <DetailField label="Actual start (metadata)">
            {readMetaString(rawMeta, 'actualStartTime', 'actual_start_time')}
          </DetailField>
        )}
        {readMetaString(rawMeta, 'actualEndTime', 'actual_end_time') && (
          <DetailField label="Actual end (metadata)">
            {readMetaString(rawMeta, 'actualEndTime', 'actual_end_time')}
          </DetailField>
        )}
        {readMetaString(rawMeta, 'estimatedDuration', 'estimated_duration') && (
          <DetailField label="Est. duration (metadata)">
            {readMetaString(rawMeta, 'estimatedDuration', 'estimated_duration')}
          </DetailField>
        )}
        {readMetaString(rawMeta, 'actualDuration', 'actual_duration') && (
          <DetailField label="Actual duration (metadata)">
            {readMetaString(rawMeta, 'actualDuration', 'actual_duration')}
          </DetailField>
        )}
      </DetailGrid>
    </DetailCard>
  );
}
