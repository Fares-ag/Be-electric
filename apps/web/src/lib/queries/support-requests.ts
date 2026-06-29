import { supabase } from '@/lib/supabase';
import {
  parseSupportAttachments,
  isAllowedSupportStatusTransition,
  formatSupportLabel,
  type SupportRequestDetail,
  type SupportRequestListRow,
  type SupportRequestStatus,
} from '@/lib/support-requests';

export const SUPPORT_REQUESTS_LIST_QUERY_KEY = ['support-requests'] as const;
export const supportRequestDetailQueryKey = (id: string) => ['support-request', id] as const;

const LIST_SELECT =
  'id, type, status, summary, createdBy, companyId, createdAt, company:companies(name), requester:users!support_requests_createdBy_fkey(name, email)';

const DETAIL_SELECT =
  'id, type, status, summary, topic, question, details, chargerModel, chargerSerialNumber, address, country, scheduledDate, staffReply, attachments, createdBy, companyId, createdAt, company:companies(name), requester:users!support_requests_createdBy_fkey(name, email)';

export async function fetchSupportRequestsList(): Promise<SupportRequestListRow[]> {
  const { data, error } = await supabase
    .from('support_requests')
    .select(LIST_SELECT)
    .order('createdAt', { ascending: false });
  if (error) throw error;
  return (data ?? []) as SupportRequestListRow[];
}

export async function fetchSupportRequestsForExport(): Promise<Record<string, unknown>[]> {
  const rows = await fetchSupportRequestsList();
  return rows.map((row) => ({
    summary: row.summary ?? '',
    type: row.type,
    status: row.status,
    requesterName: row.requester?.name ?? '',
    requesterEmail: row.requester?.email ?? '',
    companyName: row.company?.name ?? '',
    createdAt: row.createdAt,
  }));
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
    topic: (row.topic as string | null) ?? null,
    question: (row.question as string | null) ?? null,
    details: (row.details as string | null) ?? null,
    chargerModel: (row.chargerModel as string | null) ?? null,
    chargerSerialNumber: (row.chargerSerialNumber as string | null) ?? null,
    address: (row.address as string | null) ?? null,
    country: (row.country as string | null) ?? null,
    scheduledDate: (row.scheduledDate as string | null) ?? null,
    staffReply: (row.staffReply as string | null) ?? null,
    attachments: parseSupportAttachments(row.attachments),
  };
}

export async function updateSupportRequestStatus(params: {
  id: string;
  status: SupportRequestStatus;
  currentStatus?: string | null;
}): Promise<void> {
  if (
    params.currentStatus &&
    !isAllowedSupportStatusTransition(params.currentStatus, params.status)
  ) {
    throw new Error(
      `Cannot change status from ${formatSupportLabel(params.currentStatus)} to ${formatSupportLabel(params.status)}.`
    );
  }
  const { error } = await supabase
    .from('support_requests')
    .update({ status: params.status })
    .eq('id', params.id);
  if (error) throw error;
}

export async function updateSupportRequestStaffReply(params: {
  id: string;
  staffReply: string;
}): Promise<void> {
  const { error } = await supabase
    .from('support_requests')
    .update({ staffReply: params.staffReply.trim() || null })
    .eq('id', params.id);
  if (error) throw error;
}
