import { supabase } from '@/lib/supabase';
import {
  parseSubmittedFields,
  parseSupportAttachments,
  type SupportMessageKind,
  type SupportRequestDetail,
  type SupportRequestListRow,
  type SupportRequestMessage,
  type SupportRequestStatus,
} from '@/lib/support-requests';

export const SUPPORT_REQUESTS_LIST_QUERY_KEY = ['support-requests'] as const;
export const supportRequestDetailQueryKey = (id: string) => ['support-request', id] as const;
export const supportRequestMessagesQueryKey = (id: string) => ['support-request-messages', id] as const;

const LIST_SELECT =
  'id, ticketNumber, type, status, subject, requesterId, requesterName, requesterEmail, companyId, submittedAt, updatedAt, company:companies(name)';

const DETAIL_SELECT =
  'id, ticketNumber, type, status, subject, description, requesterId, requesterName, requesterEmail, requesterPhone, companyId, submittedFields, attachments, submittedAt, createdAt, updatedAt, metadata, company:companies(name)';

const MESSAGE_SELECT =
  'id, supportRequestId, kind, body, authorId, authorName, createdAt';

export async function fetchSupportRequestsList(): Promise<SupportRequestListRow[]> {
  const { data, error } = await supabase
    .from('support_requests')
    .select(LIST_SELECT)
    .order('submittedAt', { ascending: false });
  if (error) throw error;
  return (data ?? []) as SupportRequestListRow[];
}

export async function fetchSupportRequestDetail(id: string): Promise<SupportRequestDetail | null> {
  const { data, error } = await supabase
    .from('support_requests')
    .select(DETAIL_SELECT)
    .eq('id', id)
    .single();
  if (error) throw error;
  if (!data) return null;
  const row = data as Record<string, unknown>;
  return {
    ...(data as SupportRequestListRow),
    description: (row.description as string | null) ?? null,
    requesterPhone: (row.requesterPhone as string | null) ?? null,
    submittedFields: parseSubmittedFields(row.submittedFields),
    attachments: parseSupportAttachments(row.attachments),
    metadata: (row.metadata as Record<string, unknown> | null) ?? null,
    createdAt: String(row.createdAt),
  };
}

export async function fetchSupportRequestMessages(id: string): Promise<SupportRequestMessage[]> {
  const { data, error } = await supabase
    .from('support_request_messages')
    .select(MESSAGE_SELECT)
    .eq('supportRequestId', id)
    .order('createdAt', { ascending: true });
  if (error) throw error;
  return (data ?? []) as SupportRequestMessage[];
}

export async function updateSupportRequestStatus(params: {
  id: string;
  status: SupportRequestStatus;
  authorId: string;
  authorName: string;
}): Promise<void> {
  const now = new Date().toISOString();
  const { error: updateError } = await supabase
    .from('support_requests')
    .update({ status: params.status, updatedAt: now })
    .eq('id', params.id);
  if (updateError) throw updateError;

  const { error: messageError } = await supabase.from('support_request_messages').insert({
    supportRequestId: params.id,
    kind: 'status_change',
    body: `Status changed to ${params.status.replace(/_/g, ' ')}`,
    authorId: params.authorId,
    authorName: params.authorName,
    createdAt: now,
  });
  if (messageError) throw messageError;
}

export async function addSupportRequestMessage(params: {
  supportRequestId: string;
  kind: Extract<SupportMessageKind, 'internal_note' | 'customer_reply'>;
  body: string;
  authorId: string;
  authorName: string;
}): Promise<void> {
  const now = new Date().toISOString();
  const { error: messageError } = await supabase.from('support_request_messages').insert({
    supportRequestId: params.supportRequestId,
    kind: params.kind,
    body: params.body.trim(),
    authorId: params.authorId,
    authorName: params.authorName,
    createdAt: now,
  });
  if (messageError) throw messageError;

  const { error: updateError } = await supabase
    .from('support_requests')
    .update({ updatedAt: now })
    .eq('id', params.supportRequestId);
  if (updateError) throw updateError;
}
