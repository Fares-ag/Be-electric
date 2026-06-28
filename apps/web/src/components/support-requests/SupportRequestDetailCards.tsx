'use client';

import { DetailCard, DetailField, DetailGrid } from '@/components/ui/DetailCard';
import {
  formatSupportLabel,
  parseSubmittedFields,
  type SupportRequestDetail,
} from '@/lib/support-requests';

function formatFieldValue(value: unknown): string {
  if (value == null || value === '') return '—';
  if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
    return String(value);
  }
  return JSON.stringify(value, null, 2);
}

export function SupportRequestSubmittedFieldsCard({ request }: { request: SupportRequestDetail }) {
  const fields = parseSubmittedFields(request.submittedFields);
  const entries = Object.entries(fields);

  return (
    <DetailCard title="Submitted fields">
      {request.description ? (
        <div className="mb-4 space-y-1 text-sm">
          <p className="text-xs font-medium text-muted-foreground">Description</p>
          <p className="whitespace-pre-wrap">{request.description}</p>
        </div>
      ) : null}
      {entries.length > 0 ? (
        <DetailGrid>
          {entries.map(([key, value]) => (
            <DetailField key={key} label={formatSupportLabel(key)} span={typeof value === 'object' ? 2 : 1}>
              <span className={typeof value === 'object' ? 'whitespace-pre-wrap font-mono text-xs' : ''}>
                {formatFieldValue(value)}
              </span>
            </DetailField>
          ))}
        </DetailGrid>
      ) : !request.description ? (
        <p className="text-sm text-muted-foreground">No additional fields were submitted.</p>
      ) : null}
    </DetailCard>
  );
}

export function SupportRequestRequesterCard({ request }: { request: SupportRequestDetail }) {
  return (
    <DetailCard title="Requester">
      <DetailGrid>
        <DetailField label="Name">{request.requesterName ?? '—'}</DetailField>
        <DetailField label="Email">{request.requesterEmail ?? '—'}</DetailField>
        <DetailField label="Phone">{request.requesterPhone ?? '—'}</DetailField>
        <DetailField label="Company">{request.company?.name ?? '—'}</DetailField>
        <DetailField label="Submitted">
          {new Date(request.submittedAt).toLocaleString()}
        </DetailField>
        <DetailField label="Type">{formatSupportLabel(request.type)}</DetailField>
      </DetailGrid>
    </DetailCard>
  );
}

export function SupportRequestAttachmentsCard({
  attachments,
}: {
  attachments: SupportRequestDetail['attachments'];
}) {
  return (
    <DetailCard title="Attachments">
      {attachments.length === 0 ? (
        <p className="text-sm text-muted-foreground">No attachments uploaded.</p>
      ) : (
        <ul className="space-y-2">
          {attachments.map((file, index) => (
            <li key={`${file.url}-${index}`}>
              <a
                href={file.url}
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm text-primary underline underline-offset-2 hover:text-primary-hover"
              >
                {file.fileName ?? `Attachment ${index + 1}`}
              </a>
              {file.contentType ? (
                <span className="ml-2 text-xs text-muted-foreground">{file.contentType}</span>
              ) : null}
            </li>
          ))}
        </ul>
      )}
    </DetailCard>
  );
}
