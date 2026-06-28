'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { ArrowLeft } from 'lucide-react';
import { useAuthStore } from '@/stores/auth-store';
import { Button } from '@/components/ui/Button';
import { StatusBadge } from '@/components/ui/Badge';
import { LoadingSpinner, QueryErrorState } from '@/components/ui/PageStates';
import {
  SupportRequestAttachmentsCard,
  SupportRequestRequesterCard,
  SupportRequestSubmittedFieldsCard,
} from '@/components/support-requests/SupportRequestDetailCards';
import {
  SupportRequestMessagesPanel,
  SupportRequestStatusSelect,
} from '@/components/support-requests/SupportRequestMessagesPanel';
import {
  SUPPORT_REQUESTS_LIST_QUERY_KEY,
  addSupportRequestMessage,
  fetchSupportRequestDetail,
  fetchSupportRequestMessages,
  supportRequestDetailQueryKey,
  supportRequestMessagesQueryKey,
  updateSupportRequestStatus,
} from '@/lib/queries/support-requests';
import { formatSupportLabel, type SupportRequestStatus } from '@/lib/support-requests';

export default function SupportRequestDetailPage() {
  const params = useParams();
  const id = params.id as string;
  const queryClient = useQueryClient();
  const user = useAuthStore((s) => s.user);
  const [statusError, setStatusError] = useState<string | null>(null);

  const { data: request, isLoading, error, refetch } = useQuery({
    queryKey: supportRequestDetailQueryKey(id),
    staleTime: 30 * 1000,
    queryFn: () => fetchSupportRequestDetail(id),
  });

  const { data: messages, isLoading: messagesLoading } = useQuery({
    queryKey: supportRequestMessagesQueryKey(id),
    staleTime: 30 * 1000,
    queryFn: () => fetchSupportRequestMessages(id),
  });

  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: supportRequestDetailQueryKey(id) });
    queryClient.invalidateQueries({ queryKey: supportRequestMessagesQueryKey(id) });
    queryClient.invalidateQueries({ queryKey: SUPPORT_REQUESTS_LIST_QUERY_KEY });
  };

  const statusMutation = useMutation({
    mutationFn: async (status: SupportRequestStatus) => {
      if (!user?.id || !user.name) throw new Error('Not signed in');
      await updateSupportRequestStatus({
        id,
        status,
        authorId: user.id,
        authorName: user.name,
      });
    },
    onSuccess: () => {
      setStatusError(null);
      invalidate();
    },
    onError: (err: Error) => setStatusError(err.message),
  });

  const messageMutation = useMutation({
    mutationFn: async ({
      kind,
      body,
    }: {
      kind: 'internal_note' | 'customer_reply';
      body: string;
    }) => {
      if (!user?.id || !user.name) throw new Error('Not signed in');
      await addSupportRequestMessage({
        supportRequestId: id,
        kind,
        body,
        authorId: user.id,
        authorName: user.name,
      });
    },
    onSuccess: invalidate,
  });

  if (isLoading || messagesLoading) return <LoadingSpinner label="Loading support request" />;

  if (error || !request) {
    return (
      <QueryErrorState
        title="Support request unavailable"
        message={
          error instanceof Error
            ? error.message
            : 'This support request may have been removed or you may not have permission to view it.'
        }
        onRetry={() => refetch()}
      />
    );
  }

  const pending = statusMutation.isPending || messageMutation.isPending;

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div className="space-y-3">
          <Link
            href="/support-requests"
            className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
          >
            <ArrowLeft className="h-4 w-4" aria-hidden />
            Back to Support Inbox
          </Link>
          <div className="flex flex-wrap items-center gap-3">
            <h1 className="text-2xl font-semibold tracking-tight text-foreground">
              {request.ticketNumber}
            </h1>
            <StatusBadge status={request.status} />
          </div>
          <p className="text-lg text-foreground">{request.subject}</p>
          <p className="text-sm text-muted-foreground">
            {formatSupportLabel(request.type)} · Submitted {new Date(request.submittedAt).toLocaleString()}
          </p>
        </div>
        <div className="w-full max-w-xs space-y-2">
          <SupportRequestStatusSelect
            status={request.status}
            pending={pending}
            onChange={(value) => statusMutation.mutate(value as SupportRequestStatus)}
          />
          {statusError ? (
            <p className="text-sm text-destructive" role="alert">
              {statusError}
            </p>
          ) : null}
        </div>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <div className="space-y-4">
          <SupportRequestRequesterCard request={request} />
          <SupportRequestSubmittedFieldsCard request={request} />
          <SupportRequestAttachmentsCard attachments={request.attachments} />
        </div>
        <SupportRequestMessagesPanel
          messages={messages ?? []}
          pending={pending}
          onAddInternalNote={(body) => messageMutation.mutateAsync({ kind: 'internal_note', body })}
          onAddCustomerReply={(body) => messageMutation.mutateAsync({ kind: 'customer_reply', body })}
        />
      </div>
    </div>
  );
}
