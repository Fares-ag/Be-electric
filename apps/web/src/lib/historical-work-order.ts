export const HISTORICAL_WORK_ORDER_STATUSES = ['completed', 'closed'] as const;
export type HistoricalWorkOrderStatus = (typeof HISTORICAL_WORK_ORDER_STATUSES)[number];

export const HISTORICAL_WORK_ORDER_PRIORITIES = [
  'low',
  'medium',
  'high',
  'urgent',
  'critical',
] as const;

export type HistoricalWorkOrderFormInput = {
  problemDescription: string;
  status: HistoricalWorkOrderStatus;
  priority: string;
  requestorId: string;
  requestorName: string;
  companyId: string;
  assetId: string;
  createdAtLocal: string;
  completedAtLocal: string;
  closedAtLocal: string;
  ticketNumber?: string;
  location?: string;
  category?: string;
  notes?: string;
  correctiveActions?: string;
  recommendations?: string;
  assignedTechnicianIds?: string[];
  recordedById: string;
};

export type HistoricalWorkOrderInsertPayload = {
  id: string;
  ticketNumber: string;
  problemDescription: string;
  status: HistoricalWorkOrderStatus;
  priority: string;
  requestorId: string;
  requestorName: string;
  companyId: string;
  assetId: string;
  location: string | null;
  category: string | null;
  notes: string | null;
  correctiveActions: string | null;
  recommendations: string | null;
  assignedTechnicianIds: string[] | null;
  primaryTechnicianId: string | null;
  assignedAt: string | null;
  createdAt: string;
  completedAt: string;
  closedAt: string | null;
  updatedAt: string;
  metadata: Record<string, unknown>;
};

function parseLocalDateTime(value: string): Date | null {
  const trimmed = value.trim();
  if (!trimmed) return null;
  const parsed = new Date(trimmed);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

export function generateHistoricalTicketNumber(now = new Date()): string {
  const ymd = now.toISOString().slice(0, 10).replace(/-/g, '');
  const suffix = Math.random().toString(36).slice(2, 6).toUpperCase();
  return `WO-HIST-${ymd}-${suffix}`;
}

export function validateHistoricalWorkOrderInput(
  input: HistoricalWorkOrderFormInput,
  now = new Date()
): string | null {
  if (!input.problemDescription.trim()) return 'Problem description is required';
  if (!input.requestorId.trim()) return 'Requestor is required';
  if (!input.requestorName.trim()) return 'Requestor name is required';
  if (!input.companyId.trim()) return 'Company is required';
  if (!input.assetId.trim()) return 'Charger is required';
  if (!HISTORICAL_WORK_ORDER_STATUSES.includes(input.status)) {
    return 'Status must be completed or closed';
  }

  const createdAt = parseLocalDateTime(input.createdAtLocal);
  const completedAt = parseLocalDateTime(input.completedAtLocal);
  if (!createdAt) return 'Created date/time is required';
  if (!completedAt) return 'Completed date/time is required';

  const closedAt =
    input.status === 'closed'
      ? parseLocalDateTime(input.closedAtLocal) ?? completedAt
      : null;

  if (input.status === 'closed' && !closedAt) {
    return 'Closed date/time is required for closed work orders';
  }

  if (createdAt.getTime() >= now.getTime()) {
    return 'Created date must be in the past';
  }
  if (completedAt.getTime() >= now.getTime()) {
    return 'Completed date must be in the past';
  }
  if (closedAt && closedAt.getTime() >= now.getTime()) {
    return 'Closed date must be in the past';
  }
  if (completedAt.getTime() < createdAt.getTime()) {
    return 'Completed date cannot be before created date';
  }
  if (closedAt && closedAt.getTime() < completedAt.getTime()) {
    return 'Closed date cannot be before completed date';
  }

  return null;
}

export function buildHistoricalWorkOrderInsert(
  input: HistoricalWorkOrderFormInput,
  now = new Date()
): HistoricalWorkOrderInsertPayload {
  const validationError = validateHistoricalWorkOrderInput(input, now);
  if (validationError) throw new Error(validationError);

  const createdAt = parseLocalDateTime(input.createdAtLocal)!;
  const completedAt = parseLocalDateTime(input.completedAtLocal)!;
  const closedAt =
    input.status === 'closed'
      ? parseLocalDateTime(input.closedAtLocal) ?? completedAt
      : null;

  const assignedTechnicianIds =
    input.assignedTechnicianIds?.filter((id) => id.trim().length > 0) ?? [];
  const hasAssignees = assignedTechnicianIds.length > 0;

  const createdIso = createdAt.toISOString();
  const completedIso = completedAt.toISOString();
  const closedIso = closedAt?.toISOString() ?? null;
  const updatedIso = closedIso ?? completedIso;

  return {
    id: crypto.randomUUID(),
    ticketNumber: input.ticketNumber?.trim() || generateHistoricalTicketNumber(now),
    problemDescription: input.problemDescription.trim(),
    status: input.status,
    priority: input.priority,
    requestorId: input.requestorId.trim(),
    requestorName: input.requestorName.trim(),
    companyId: input.companyId.trim(),
    assetId: input.assetId.trim(),
    location: input.location?.trim() || null,
    category: input.category?.trim() || null,
    notes: input.notes?.trim() || null,
    correctiveActions: input.correctiveActions?.trim() || null,
    recommendations: input.recommendations?.trim() || null,
    assignedTechnicianIds: hasAssignees ? assignedTechnicianIds : null,
    primaryTechnicianId: hasAssignees ? assignedTechnicianIds[0] : null,
    assignedAt: hasAssignees ? completedIso : null,
    createdAt: createdIso,
    completedAt: completedIso,
    closedAt: closedIso,
    updatedAt: updatedIso,
    metadata: {
      source: 'historical_admin',
      recordedAt: now.toISOString(),
      recordedBy: input.recordedById,
    },
  };
}

export function workOrderCompanyName(
  row: { company?: { name?: string | null } | null } | null | undefined
): string {
  const name = row?.company?.name;
  return name?.trim() ? name.trim() : '—';
}
