'use client';

import { useEffect, useState } from 'react';
import { DetailCard } from '@/components/ui/DetailCard';
import { Button } from '@/components/ui/Button';
import { SUPPORT_REQUEST_STATUSES, formatSupportLabel } from '@/lib/support-requests';

type Props = {
  staffReply: string | null;
  pending: boolean;
  onSaveStaffReply: (body: string) => Promise<void>;
};

export function SupportRequestStaffReplyPanel({
  staffReply,
  pending,
  onSaveStaffReply,
}: Props) {
  const [reply, setReply] = useState(staffReply ?? '');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setReply(staffReply ?? '');
  }, [staffReply]);

  async function submit() {
    setError(null);
    if (reply.trim().length < 2) {
      setError('Please enter at least 2 characters.');
      return;
    }
    try {
      await onSaveStaffReply(reply.trim());
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to save staff reply');
    }
  }

  return (
    <DetailCard title="Staff reply">
      <p className="mb-3 text-sm text-muted-foreground">
        Saved to <code className="text-xs">staffReply</code> — visible to the requestor in the mobile app.
      </p>
      {staffReply ? (
        <div className="mb-4 rounded-lg border border-border bg-muted/30 px-3 py-2 text-sm whitespace-pre-wrap">
          {staffReply}
        </div>
      ) : (
        <p className="mb-4 text-sm text-muted-foreground">No staff reply yet.</p>
      )}
      <textarea
        value={reply}
        onChange={(e) => setReply(e.target.value)}
        rows={6}
        placeholder="Reply to the requestor…"
        className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
      />
      {error ? (
        <p className="mt-2 text-sm text-destructive" role="alert">
          {error}
        </p>
      ) : null}
      <div className="mt-3">
        <Button type="button" disabled={pending} onClick={() => void submit()}>
          Save staff reply
        </Button>
      </div>
    </DetailCard>
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
        {SUPPORT_REQUEST_STATUSES.map((value) => (
          <option key={value} value={value}>
            {formatSupportLabel(value)}
          </option>
        ))}
      </select>
    </label>
  );
}
