'use client';

import { DetailCard, DetailField, DetailGrid } from '@/components/ui/DetailCard';
import {
  formatSupportLabel,
  isCommissioningRequest,
  isKnowHowRequest,
  type SupportRequestDetail,
} from '@/lib/support-requests';

export function SupportRequestSubmittedFieldsCard({ request }: { request: SupportRequestDetail }) {
  return (
    <DetailCard title="Request details">
      <DetailGrid>
        <DetailField label="Type">{formatSupportLabel(request.type)}</DetailField>
        <DetailField label="Summary">{request.summary ?? '—'}</DetailField>

        {isKnowHowRequest(request.type) ? (
          <>
            <DetailField label="Topic">{request.topic ?? '—'}</DetailField>
            <DetailField label="Question" span={2}>
              <span className="whitespace-pre-wrap">{request.question ?? '—'}</span>
            </DetailField>
          </>
        ) : null}

        {isCommissioningRequest(request.type) ? (
          <>
            <DetailField label="Charger model">{request.chargerModel ?? '—'}</DetailField>
            <DetailField label="Serial number">{request.chargerSerialNumber ?? '—'}</DetailField>
            <DetailField label="Address" span={2}>
              {request.address ?? '—'}
            </DetailField>
            <DetailField label="Country">{request.country ?? '—'}</DetailField>
            <DetailField label="Scheduled date">
              {request.scheduledDate
                ? new Date(request.scheduledDate).toLocaleString()
                : '—'}
            </DetailField>
            <DetailField label="Details" span={2}>
              <span className="whitespace-pre-wrap">{request.details ?? '—'}</span>
            </DetailField>
          </>
        ) : null}
      </DetailGrid>
    </DetailCard>
  );
}

export function SupportRequestRequesterCard({ request }: { request: SupportRequestDetail }) {
  return (
    <DetailCard title="Requester">
      <DetailGrid>
        <DetailField label="Name">{request.requester?.name ?? '—'}</DetailField>
        <DetailField label="Email">{request.requester?.email ?? '—'}</DetailField>
        <DetailField label="Company">{request.company?.name ?? '—'}</DetailField>
        <DetailField label="Submitted">
          {new Date(request.createdAt).toLocaleString()}
        </DetailField>
      </DetailGrid>
    </DetailCard>
  );
}

export { SupportRequestAttachmentsCard } from '@/components/support-requests/SupportRequestAttachmentsCard';
