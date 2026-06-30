export const PM_FREQUENCIES = [
  { value: 'daily', label: 'Daily', days: 1 },
  { value: 'weekly', label: 'Weekly', days: 7 },
  { value: 'monthly', label: 'Monthly', days: 30 },
  { value: 'quarterly', label: 'Quarterly', days: 90 },
  { value: 'semiAnnually', label: 'Semi-annually', days: 180 },
  { value: 'annually', label: 'Annually', days: 365 },
  { value: 'asNeeded', label: 'As needed', days: 0 },
] as const;

export type PmFrequency = (typeof PM_FREQUENCIES)[number]['value'];

export const PM_OCCURRENCE_STATUSES = ['pending', 'upcoming', 'completed', 'overdue', 'cancelled'] as const;
export type PmOccurrenceStatus = (typeof PM_OCCURRENCE_STATUSES)[number];

/** Filter-only status: pending work with due date on or after today. */
export type PmOccurrenceDisplayStatus = PmOccurrenceStatus;

export type ScheduleWindowInput = {
  frequency: PmFrequency;
  startDate: string;
  endDate: string;
};

export type OccurrencePreviewRow = {
  assetId: string;
  dueDate: string;
  status: PmOccurrenceStatus;
};

export function frequencyDays(frequency: PmFrequency): number {
  return PM_FREQUENCIES.find((f) => f.value === frequency)?.days ?? 0;
}

function parseIsoDate(value: string): Date {
  const [y, m, d] = value.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d));
}

function formatIsoDate(date: Date): string {
  return date.toISOString().slice(0, 10);
}

function addCalendarInterval(date: Date, frequency: PmFrequency): Date {
  const next = new Date(date.getTime());
  switch (frequency) {
    case 'daily':
      next.setUTCDate(next.getUTCDate() + 1);
      return next;
    case 'weekly':
      next.setUTCDate(next.getUTCDate() + 7);
      return next;
    case 'monthly':
      next.setUTCMonth(next.getUTCMonth() + 1);
      return next;
    case 'quarterly':
      next.setUTCMonth(next.getUTCMonth() + 3);
      return next;
    case 'semiAnnually':
      next.setUTCMonth(next.getUTCMonth() + 6);
      return next;
    case 'annually':
      next.setUTCFullYear(next.getUTCFullYear() + 1);
      return next;
    case 'asNeeded':
    default:
      return next;
  }
}

/** Calendar-aware due dates from start through end (inclusive). */
export function computeDueDates(input: ScheduleWindowInput): string[] {
  const start = parseIsoDate(input.startDate);
  const end = parseIsoDate(input.endDate);
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime()) || end < start) {
    return [];
  }

  if (input.frequency === 'asNeeded') {
    return [input.startDate];
  }

  const dates: string[] = [];
  let cursor = new Date(start.getTime());
  while (cursor <= end) {
    dates.push(formatIsoDate(cursor));
    const next = addCalendarInterval(cursor, input.frequency);
    if (next.getTime() <= cursor.getTime()) break;
    cursor = next;
  }
  return dates;
}

export function scheduleEndDateFromDurationYears(startDate: string, years: number): string {
  const start = parseIsoDate(startDate);
  const end = new Date(start.getTime());
  end.setUTCFullYear(end.getUTCFullYear() + years);
  end.setUTCDate(end.getUTCDate() - 1);
  return formatIsoDate(end);
}

export function previewOccurrences(
  assetIds: string[],
  window: ScheduleWindowInput
): OccurrencePreviewRow[] {
  const dueDates = computeDueDates(window);
  const rows: OccurrencePreviewRow[] = [];
  for (const assetId of assetIds) {
    for (const dueDate of dueDates) {
      rows.push({ assetId, dueDate, status: 'pending' });
    }
  }
  return rows;
}

/** Derive display status client-side: pending past due → overdue (no DB write required for v1). */
export function deriveOccurrenceStatus(
  storedStatus: string,
  dueDate: string,
  todayIso = new Date().toISOString().slice(0, 10)
): PmOccurrenceStatus {
  if (storedStatus === 'completed' || storedStatus === 'cancelled') {
    return storedStatus as PmOccurrenceStatus;
  }
  if (dueDate < todayIso) return 'overdue';
  if (storedStatus === 'overdue') return 'overdue';
  return 'upcoming';
}

/** UI label status — maps stored pending + future due dates to upcoming. */
export function getOccurrenceDisplayStatus(
  storedStatus: string,
  dueDate: string,
  todayIso = new Date().toISOString().slice(0, 10)
): PmOccurrenceDisplayStatus {
  return deriveOccurrenceStatus(storedStatus, dueDate, todayIso);
}

export function isUpcomingOccurrence(
  storedStatus: string,
  dueDate: string,
  todayIso = new Date().toISOString().slice(0, 10)
): boolean {
  if (storedStatus === 'completed' || storedStatus === 'cancelled') return false;
  return dueDate >= todayIso;
}

export function matchesOccurrenceStatusFilter(
  filter: string,
  storedStatus: string,
  dueDate: string,
  todayIso = new Date().toISOString().slice(0, 10)
): boolean {
  if (!filter) return true;
  if (filter === 'upcoming') return isUpcomingOccurrence(storedStatus, dueDate, todayIso);
  return getOccurrenceDisplayStatus(storedStatus, dueDate, todayIso) === filter;
}

export function validateCompletionNotes(notes: string): string | null {
  if (notes.length > 4000) return 'Completion notes must be 4000 characters or fewer';
  return null;
}

export function validateCancelReason(reason: string): string | null {
  const trimmed = reason.trim();
  if (!trimmed) return 'Cancel reason is required';
  if (trimmed.length > 500) return 'Cancel reason must be 500 characters or fewer';
  return null;
}

export function validateRescheduleDueDate(
  newDueDate: string,
  todayIso = new Date().toISOString().slice(0, 10)
): string | null {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(newDueDate)) return 'Enter a valid due date';
  if (newDueDate < todayIso) return 'Due date cannot be in the past';
  return null;
}

export function parseScheduleChecklist(metadata: Record<string, unknown> | null | undefined): string[] {
  const raw = metadata?.checklist;
  if (!Array.isArray(raw)) return [];
  return raw.filter((item): item is string => typeof item === 'string' && item.trim().length > 0);
}

export function formatPmFrequency(frequency: string): string {
  return PM_FREQUENCIES.find((f) => f.value === frequency)?.label ?? frequency;
}

export type PmOccurrenceStatsInput = {
  status: string;
  dueDate: string;
};

export type PmOccurrenceStatsSummary = {
  total: number;
  upcoming: number;
  overdue: number;
  completed: number;
  cancelled: number;
};

export function summarizeOccurrenceStats(
  rows: PmOccurrenceStatsInput[],
  todayIso = new Date().toISOString().slice(0, 10)
): PmOccurrenceStatsSummary {
  const summary: PmOccurrenceStatsSummary = {
    total: rows.length,
    upcoming: 0,
    overdue: 0,
    completed: 0,
    cancelled: 0,
  };
  for (const row of rows) {
    const derived = deriveOccurrenceStatus(row.status, row.dueDate, todayIso);
    if (derived === 'upcoming') summary.upcoming += 1;
    else if (derived === 'overdue') summary.overdue += 1;
    else if (derived === 'completed') summary.completed += 1;
    else if (derived === 'cancelled') summary.cancelled += 1;
  }
  return summary;
}

export type PmOccurrenceMonthBucket = {
  monthKey: string;
  label: string;
  count: number;
};

/** Group occurrences by calendar month for a lightweight workload strip chart. */
export function buildOccurrenceMonthBuckets(
  rows: PmOccurrenceStatsInput[],
  maxMonths = 24
): PmOccurrenceMonthBucket[] {
  const counts = new Map<string, number>();
  for (const row of rows) {
    const monthKey = row.dueDate.slice(0, 7);
    if (!/^\d{4}-\d{2}$/.test(monthKey)) continue;
    counts.set(monthKey, (counts.get(monthKey) ?? 0) + 1);
  }
  return [...counts.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .slice(-maxMonths)
    .map(([monthKey, count]) => {
      const [year, month] = monthKey.split('-').map(Number);
      const label = new Date(Date.UTC(year, month - 1, 1)).toLocaleDateString(undefined, {
        month: 'short',
        year: '2-digit',
      });
      return { monthKey, label, count };
    });
}

export const PM_OCCURRENCE_STATUS_LEGEND: {
  status: PmOccurrenceStatus;
  description: string;
}[] = [
  { status: 'upcoming', description: 'Due today or later — still open' },
  { status: 'overdue', description: 'Past due and not completed' },
  { status: 'completed', description: 'Work finished for this due date' },
  { status: 'cancelled', description: 'Skipped or removed from the schedule' },
];
