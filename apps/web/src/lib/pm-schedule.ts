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

export const PM_OCCURRENCE_STATUSES = ['pending', 'completed', 'overdue', 'cancelled'] as const;
export type PmOccurrenceStatus = (typeof PM_OCCURRENCE_STATUSES)[number];

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
  return storedStatus === 'overdue' ? 'overdue' : 'pending';
}

export function formatPmFrequency(frequency: string): string {
  return PM_FREQUENCIES.find((f) => f.value === frequency)?.label ?? frequency;
}
