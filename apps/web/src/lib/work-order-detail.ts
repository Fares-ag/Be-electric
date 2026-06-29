export type WorkOrderActivityEntry = {
  at: string;
  type: string;
  note?: string;
};

export type ReopenMetadata = {
  reopenedAt?: string;
  reopenedBy?: string;
  reopenReason?: string;
  reopenCount?: number;
  previousCompletionDate?: string;
  previousStatus?: string;
};

export type WorkOrderMetadata = {
  /** Full request/problem photo URLs (Flutter preferred). */
  photoPaths?: string[];
  /** Full completion photo URLs (Flutter preferred). */
  completionPhotoPaths?: string[];
} & ReopenMetadata;

export type WorkOrderDetail = {
  id: string;
  ticketNumber: string;
  idempotencyKey?: string | null;
  problemDescription: string;
  requestorId: string;
  requestorName?: string | null;
  assetId?: string | null;
  asset?: { name?: string; location?: string; manufacturer?: string | null; id?: string } | null;
  location?: string | null;
  companyId?: string | null;
  company?: { name?: string | null; id?: string } | null;
  primaryTechnicianId?: string | null;
  assignedTechnicianId?: string | null;
  assignedTechnicianIds?: string[] | null;
  assignedAt?: string | null;
  technicianEffortMinutes?: Record<string, number> | unknown | null;
  status: string;
  priority: string;
  category?: string | null;
  createdAt: string;
  updatedAt?: string;
  startedAt?: string | null;
  completedAt?: string | null;
  closedAt?: string | null;
  nextMaintenanceDate?: string | null;
  notes?: string | null;
  correctiveActions?: string | null;
  recommendations?: string | null;
  technicianNotes?: string | null;
  photoPath?: string | null;
  completionPhotoPath?: string | null;
  beforePhotoPath?: string | null;
  afterPhotoPath?: string | null;
  requestorSignature?: string | null;
  technicianSignature?: string | null;
  customerName?: string | null;
  customerPhone?: string | null;
  customerEmail?: string | null;
  customerSignature?: string | null;
  laborCost?: number | null;
  partsCost?: number | null;
  totalCost?: number | null;
  estimatedCost?: number | null;
  actualCost?: number | null;
  laborHours?: number | null;
  partsUsed?: string[] | null;
  isPaused?: boolean | null;
  pausedAt?: string | null;
  pauseReason?: string | null;
  resumedAt?: string | null;
  pauseHistory?: unknown;
  isOffline?: boolean | null;
  lastSyncedAt?: string | null;
  activityHistory?: WorkOrderActivityEntry[] | null;
  metadata?: WorkOrderMetadata | null;
};

export const MAX_REOPEN_COUNT = 3;

export const WORK_ORDER_STATUSES = [
  'open',
  'assigned',
  'inProgress',
  'completed',
  'closed',
  'cancelled',
  'reopened',
] as const;

/** Work actively being handled (admin "Active" list filter). */
export const ACTIVE_WORK_ORDER_STATUSES = ['assigned', 'inProgress', 'reopened'] as const;

/** Requestor-facing open pipeline (not yet completed/closed). */
export const REQUESTOR_OPEN_STATUSES = ['open', 'assigned', 'inProgress', 'reopened'] as const;

export function isActiveWorkOrderStatus(status: string | null | undefined): boolean {
  return status != null && (ACTIVE_WORK_ORDER_STATUSES as readonly string[]).includes(status);
}

export function isRequestorOpenStatus(status: string | null | undefined): boolean {
  return status != null && (REQUESTOR_OPEN_STATUSES as readonly string[]).includes(status);
}

/** Admin/manager status changes allowed from each current status (includes current for display). */
export const ADMIN_STATUS_TRANSITIONS: Record<string, readonly string[]> = {
  open: ['open', 'assigned', 'inProgress', 'cancelled'],
  assigned: ['assigned', 'open', 'inProgress', 'cancelled'],
  inProgress: ['inProgress', 'assigned', 'open', 'completed', 'cancelled'],
  completed: ['completed', 'closed', 'cancelled'],
  closed: ['closed', 'open'],
  cancelled: ['cancelled', 'open'],
  reopened: ['reopened', 'assigned', 'inProgress', 'cancelled'],
};

export function allowedAdminStatuses(current: string | null | undefined): readonly string[] {
  if (!current) return WORK_ORDER_STATUSES;
  return ADMIN_STATUS_TRANSITIONS[current] ?? WORK_ORDER_STATUSES;
}

export function isAllowedAdminStatusTransition(
  from: string | null | undefined,
  to: string
): boolean {
  if (!from || from === to) return true;
  const allowed = ADMIN_STATUS_TRANSITIONS[from];
  return allowed ? allowed.includes(to) : false;
}

export const STATUSES_REQUIRING_REASON = ['completed', 'closed', 'cancelled', 'reopened'] as const;

const SUPABASE_STORAGE_PUBLIC =
  typeof process !== 'undefined'
    ? `${process.env.NEXT_PUBLIC_SUPABASE_URL}/storage/v1/object/public/work-order-photos`
    : '';

export function readMetaString(
  meta: Record<string, unknown> | null | undefined,
  ...keys: string[]
): string | null {
  if (!meta) return null;
  for (const k of keys) {
    const v = meta[k];
    if (v != null && String(v).trim() !== '') return String(v);
  }
  return null;
}

export function formatMaybeIso(value: string | null | undefined): string {
  if (!value) return '—';
  const t = Date.parse(value);
  if (Number.isNaN(t)) return value;
  return new Date(value).toLocaleString();
}

export function effortMinutesDisplay(value: unknown): string {
  if (value == null) return '—';
  if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
    return (
      Object.entries(value as Record<string, number>)
        .map(([k, m]) => `${k.slice(0, 8)}…: ${m} min`)
        .join(', ') || '—'
    );
  }
  return JSON.stringify(value);
}

export function toPhotoUrl(raw: string): string {
  if (raw.startsWith('http')) return raw;
  const clean = raw.startsWith('/') ? raw.slice(1) : raw;
  return SUPABASE_STORAGE_PUBLIC ? `${SUPABASE_STORAGE_PUBLIC}/${clean}` : raw;
}

export function parsePhotoPaths(value: string | null | undefined): string[] {
  if (!value) return [];
  let paths: string[];
  if (value.startsWith('[')) {
    try {
      const parsed = JSON.parse(value);
      paths = Array.isArray(parsed) ? parsed.map(String) : [value];
    } catch {
      paths = [value];
    }
  } else {
    paths = [value];
  }
  return paths.map(toPhotoUrl).filter(Boolean);
}

export function formatCurrency(value: number): string {
  return new Intl.NumberFormat(undefined, { style: 'currency', currency: 'QAR' }).format(value);
}

export function parseActivityHistory(
  value: WorkOrderActivityEntry[] | string | null | undefined
): WorkOrderActivityEntry[] {
  if (!value) return [];
  if (Array.isArray(value)) return value;
  try {
    const parsed = typeof value === 'string' ? JSON.parse(value) : value;
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export function metaPhotoPaths(
  rawMeta: Record<string, unknown> | undefined,
  keys: string[]
): string[] {
  if (!rawMeta) return [];
  for (const key of keys) {
    const value = rawMeta[key];
    if (value == null) continue;
    if (Array.isArray(value)) {
      return value.flatMap((item) => parsePhotoPaths(String(item)));
    }
    if (typeof value === 'string') {
      return parsePhotoPaths(value);
    }
  }
  return [];
}

const FLUTTER_REQUEST_PHOTO_META_KEYS = ['photoPaths', 'photo_paths'] as const;

const FLUTTER_COMPLETION_PHOTO_META_KEYS = ['completionPhotoPaths', 'completion_photo_paths'] as const;

/** Legacy / web-request aliases when metadata.photoPaths is absent. */
const LEGACY_REQUEST_PHOTO_META_KEYS = [
  'requestPhotoPaths',
  'request_photo_paths',
  'photoUrls',
  'photo_urls',
  'photos',
  'problemPhotoPaths',
  'problem_photo_paths',
  'photoUrl',
  'photo_url',
] as const;

/**
 * Request/problem photos — mirrors Flutter read order:
 * metadata.photoPaths (full list) + photoPath column (first image legacy).
 */
export function collectRequestPhotos(
  photoPath: string | null | undefined,
  rawMeta: Record<string, unknown> | undefined
): string[] {
  const fromMeta = metaPhotoPaths(rawMeta, [...FLUTTER_REQUEST_PHOTO_META_KEYS]);
  const fromColumn = parsePhotoPaths(photoPath);
  const merged = [...new Set([...fromMeta, ...fromColumn])];
  if (merged.length > 0) return merged;
  return metaPhotoPaths(rawMeta, [...LEGACY_REQUEST_PHOTO_META_KEYS]);
}

/**
 * Completion photos — mirrors Flutter read order:
 * metadata.completionPhotoPaths (full list) + completionPhotoPath column (first image legacy).
 */
export function collectCompletionPhotos(
  completionPhotoPath: string | null | undefined,
  rawMeta: Record<string, unknown> | undefined
): string[] {
  const fromMeta = metaPhotoPaths(rawMeta, [...FLUTTER_COMPLETION_PHOTO_META_KEYS]);
  const fromColumn = parsePhotoPaths(completionPhotoPath);
  const merged = [...new Set([...fromMeta, ...fromColumn])];
  return merged;
}

export function getReopenCount(rawMeta: Record<string, unknown> | undefined): number {
  return Number(rawMeta?.reopenCount ?? rawMeta?.reopen_count ?? 0);
}

export type ReopenHistoryDetails = {
  count: number;
  reopenedAt: string | null;
  reopenedBy: string | null;
  reopenReason: string | null;
  previousStatus: string | null;
  previousCompletionDate: string | null;
};

export function parseReopenHistory(
  rawMeta: Record<string, unknown> | undefined
): ReopenHistoryDetails | null {
  const count = getReopenCount(rawMeta);
  if (count < 1) return null;
  return {
    count,
    reopenedAt: readMetaString(rawMeta, 'reopenedAt', 'reopened_at'),
    reopenedBy: readMetaString(rawMeta, 'reopenedBy', 'reopened_by'),
    reopenReason: readMetaString(rawMeta, 'reopenReason', 'reopen_reason'),
    previousStatus: readMetaString(rawMeta, 'previousStatus', 'previous_status'),
    previousCompletionDate: readMetaString(
      rawMeta,
      'previousCompletionDate',
      'previous_completion_date'
    ),
  };
}

export function canRequestorReopen(
  wo:
    | {
        requestorId?: string | null;
        status?: string | null;
        metadata?: Record<string, unknown> | WorkOrderMetadata | null;
      }
    | null
    | undefined,
  userId: string | undefined,
  isRequestor: boolean
): boolean {
  if (!isRequestor || !userId || !wo || wo.requestorId !== userId) return false;
  if (!['completed', 'closed', 'cancelled'].includes(wo.status ?? '')) return false;
  const rawMeta = wo.metadata as Record<string, unknown> | undefined;
  return getReopenCount(rawMeta) < MAX_REOPEN_COUNT;
}
