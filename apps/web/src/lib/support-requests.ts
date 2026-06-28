export const SUPPORT_REQUEST_STATUSES = [
  'open',
  'in_progress',
  'waiting_on_customer',
  'resolved',
  'closed',
] as const;

export const SUPPORT_REQUEST_TYPES = [
  'general',
  'billing',
  'technical',
  'account',
  'app_issue',
  'other',
] as const;

export type SupportRequestStatus = (typeof SUPPORT_REQUEST_STATUSES)[number];
export type SupportRequestType = (typeof SUPPORT_REQUEST_TYPES)[number];
export type SupportMessageKind = 'internal_note' | 'customer_reply' | 'status_change';

export type SupportAttachment = {
  url: string;
  fileName?: string;
  contentType?: string;
  size?: number;
};

export type SupportRequestListRow = {
  id: string;
  ticketNumber: string;
  type: string;
  status: string;
  subject: string;
  requesterId: string | null;
  requesterName: string | null;
  requesterEmail: string | null;
  companyId: string | null;
  submittedAt: string;
  updatedAt: string | null;
  company?: { name?: string | null } | null;
};

export type SupportRequestDetail = SupportRequestListRow & {
  description: string | null;
  requesterPhone: string | null;
  submittedFields: Record<string, unknown>;
  attachments: SupportAttachment[];
  metadata: Record<string, unknown> | null;
  createdAt: string;
};

export type SupportRequestMessage = {
  id: string;
  supportRequestId: string;
  kind: SupportMessageKind;
  body: string;
  authorId: string | null;
  authorName: string | null;
  createdAt: string;
};

export function formatSupportLabel(value: string): string {
  return value.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
}

export function parseSupportAttachments(value: unknown): SupportAttachment[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => {
      if (typeof item === 'string') return { url: item };
      if (item && typeof item === 'object' && 'url' in item) {
        const row = item as Record<string, unknown>;
        return {
          url: String(row.url),
          fileName: row.fileName != null ? String(row.fileName) : undefined,
          contentType: row.contentType != null ? String(row.contentType) : undefined,
          size: typeof row.size === 'number' ? row.size : undefined,
        };
      }
      return null;
    })
    .filter((item): item is SupportAttachment => Boolean(item?.url));
}

export function parseSubmittedFields(value: unknown): Record<string, unknown> {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return {};
}

export function matchesSupportSearch(row: SupportRequestListRow, query: string): boolean {
  const q = query.trim().toLowerCase();
  if (!q) return true;
  return [
    row.ticketNumber,
    row.subject,
    row.requesterName,
    row.requesterEmail,
    row.type,
    row.status,
    row.company?.name,
  ]
    .filter(Boolean)
    .some((part) => String(part).toLowerCase().includes(q));
}

export function matchesSupportDateRange(
  submittedAt: string,
  from?: string,
  to?: string
): boolean {
  const ts = Date.parse(submittedAt);
  if (Number.isNaN(ts)) return true;
  if (from) {
    const fromTs = Date.parse(`${from}T00:00:00.000Z`);
    if (!Number.isNaN(fromTs) && ts < fromTs) return false;
  }
  if (to) {
    const toTs = Date.parse(`${to}T23:59:59.999Z`);
    if (!Number.isNaN(toTs) && ts > toTs) return false;
  }
  return true;
}

export function filterSupportRequests(
  rows: SupportRequestListRow[],
  filters: {
    search?: string;
    status?: string;
    companyId?: string;
    type?: string;
    dateFrom?: string;
    dateTo?: string;
  }
): SupportRequestListRow[] {
  return rows.filter((row) => {
    if (filters.status && row.status !== filters.status) return false;
    if (filters.companyId && row.companyId !== filters.companyId) return false;
    if (filters.type && row.type !== filters.type) return false;
    if (!matchesSupportDateRange(row.submittedAt, filters.dateFrom, filters.dateTo)) return false;
    if (!matchesSupportSearch(row, filters.search ?? '')) return false;
    return true;
  });
}
