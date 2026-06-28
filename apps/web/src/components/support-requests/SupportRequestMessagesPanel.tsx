'use client';

import { useState } from 'react';
import { DetailCard } from '@/components/ui/DetailCard';
import { Button } from '@/components/ui/Button';
import { formatSupportLabel, type SupportRequestMessage } from '@/lib/support-requests';

type Props = {
  messages: SupportRequestMessage[];
  pending: boolean;
  onAddInternalNote: (body: string) => Promise<void>;
  onAddCustomerReply: (body: string) => Promise<void>;
};

function messageLabel(kind: SupportRequestMessage['kind']): string {
  if (kind === 'internal_note') return 'Internal note';
  if (kind === 'customer_reply') return 'Customer reply';
  return 'Status change';
}

export function SupportRequestMessagesPanel({
  messages,
  pending,
  onAddInternalNote,
  onAddCustomerReply,
}: Props) {
  const [internalNote, setInternalNote] = useState('');
  const [customerReply, setCustomerReply] = useState('');
  const [error, setError] = useState<string | null>(null);

  async function submit(kind: 'internal_note' | 'customer_reply', body: string, reset: () => void) {
    setError(null);
    if (body.trim().length < 2) {
      setError('Please enter at least 2 characters.');
      return;
    }
    try {
      if (kind === 'internal_note') await onAddInternalNote(body.trim());
      else await onAddCustomerReply(body.trim());
      reset();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to save message');
    }
  }

  return (
    <div className="space-y-4">
      <DetailCard title="Conversation & staff notes">
        {messages.length === 0 ? (
          <p className="mb-4 text-sm text-muted-foreground">No staff notes or replies yet.</p>
        ) : (
          <ul className="mb-4 space-y-3">
            {messages.map((message) => (
              <li
                key={message.id}
                className="rounded-lg border border-border bg-muted/30 px-3 py-2 text-sm"
              >
                <div className="mb-1 flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
                  <span className="font-medium text-foreground">{messageLabel(message.kind)}</span>
                  <span>{new Date(message.createdAt).toLocaleString()}</span>
                  {message.authorName ? <span>by {message.authorName}</span> : null}
                </div>
                <p className="whitespace-pre-wrap">{message.body}</p>
              </li>
            ))}
          </ul>
        )}
      </DetailCard>

      {error ? (
        <p className="text-sm text-destructive" role="alert">
          {error}
        </p>
      ) : null}

      <DetailCard title="Add internal note">
        <textarea
          value={internalNote}
          onChange={(e) => setInternalNote(e.target.value)}
          rows={4}
          placeholder="Visible to staff only"
          className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
        />
        <div className="mt-3">
          <Button
            type="button"
            disabled={pending}
            onClick={() => void submit('internal_note', internalNote, () => setInternalNote(''))}
          >
            Save internal note
          </Button>
        </div>
      </DetailCard>

      <DetailCard title="Add customer reply">
        <textarea
          value={customerReply}
          onChange={(e) => setCustomerReply(e.target.value)}
          rows={4}
          placeholder="Reply recorded for the requester (no email sent yet)"
          className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
        />
        <div className="mt-3">
          <Button
            type="button"
            variant="outline"
            disabled={pending}
            onClick={() => void submit('customer_reply', customerReply, () => setCustomerReply(''))}
          >
            Save customer reply
          </Button>
        </div>
      </DetailCard>
    </div>
  );
}

export function SupportRequestStatusSelect({
  status,
  pending,
  onChange,
}: {
  status: string;
  pending: boolean;
  onChange: (status: string) => void;
}) {
  return (
    <label className="flex flex-col gap-1 text-sm">
      <span className="font-medium text-foreground">Status</span>
      <select
        value={status}
        disabled={pending}
        onChange={(e) => onChange(e.target.value)}
        className="rounded-lg border border-border bg-background px-3 py-2 text-sm"
      >
        {['open', 'in_progress', 'waiting_on_customer', 'resolved', 'closed'].map((value) => (
          <option key={value} value={value}>
            {formatSupportLabel(value)}
          </option>
        ))}
      </select>
    </label>
  );
}
