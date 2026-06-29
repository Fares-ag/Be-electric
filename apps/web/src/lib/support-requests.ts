export const SUPPORT_REQUEST_STATUSES = [
  'submitted',
  'in_progress',
  'resolved',
  'closed',
] as const;

/** Flutter requestor types — Know How and Commissioning only. */
export const SUPPORT_REQUEST_TYPES = ['knowHow', 'commissioning'] as const;

export type SupportRequestStatus = (typeof SUPPORT_REQUEST_STATUSES)[number];
export type SupportRequestType = (typeof SUPPORT_REQUEST_TYPES)[number];

export type SupportAttachment = {
  url: string;
  fileName?: string;
  contentType?: string;
  size?: number;
};

export type SupportRequestListRow = {
  id: string;
  type: string;
  status: string;
  summary: string | null;
  createdBy: string | null;
  companyId: string | null;
  createdAt: string;
  company?: { name?: string | null } | null;
  requester?: { name?: string | null; email?: string | null } | null;
};

export type SupportRequestDetail = SupportRequestListRow & {
  topic: string | null;
  question: string | null;
  details: string | null;
  chargerModel: string | null;
  chargerSerialNumber: string | null;
  address: string | null;
  country: string | null;
  scheduledDate: string | null;
  staffReply: string | null;
  attachments: SupportAttachment[];
};

export function formatSupportLabel(value: string): string {
  return value
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (c) => c.toUpperCase());
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

export function matchesSupportSearch(row: SupportRequestListRow, query: string): boolean {
  const q = query.trim().toLowerCase();
  if (!q) return true;
  return [
    row.summary,
    row.requester?.name,
    row.requester?.email,
    row.type,
    row.status,
    row.company?.name,
  ]
    .filter(Boolean)
    .some((part) => String(part).toLowerCase().includes(q));
}

export function matchesSupportDateRange(
  createdAt: string,
  from?: string,
  to?: string
): boolean {
  const ts = Date.parse(createdAt);
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
    if (!matchesSupportDateRange(row.createdAt, filters.dateFrom, filters.dateTo)) return false;
    if (!matchesSupportSearch(row, filters.search ?? '')) return false;
    return true;
  });
}

export function isKnowHowRequest(type: string): boolean {
  return type === 'knowHow';
}

export function isCommissioningRequest(type: string): boolean {
  return type === 'commissioning';
}

/** Admin status workflow aligned with Flutter requestor visibility. */
export const SUPPORT_STATUS_TRANSITIONS: Record<SupportRequestStatus, readonly SupportRequestStatus[]> = {
  submitted: ['submitted', 'in_progress', 'resolved', 'closed'],
  in_progress: ['in_progress', 'resolved', 'closed'],
  resolved: ['resolved', 'closed', 'in_progress'],
  closed: ['closed', 'in_progress'],
};

export function allowedSupportStatuses(current: string | null | undefined): SupportRequestStatus[] {
  if (!current) return [...SUPPORT_REQUEST_STATUSES];
  const allowed = SUPPORT_STATUS_TRANSITIONS[current as SupportRequestStatus];
  return allowed ? [...allowed] : [...SUPPORT_REQUEST_STATUSES];
}

export function isAllowedSupportStatusTransition(from: string, to: string): boolean {
  if (from === to) return true;
  const allowed = SUPPORT_STATUS_TRANSITIONS[from as SupportRequestStatus];
  return allowed ? allowed.includes(to as SupportRequestStatus) : false;
}
