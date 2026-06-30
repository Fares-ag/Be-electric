import { supabase } from '@/lib/supabase';
import { fetchAllPages } from '@/lib/supabase-pagination';
import {
  deriveOccurrenceStatus,
  frequencyDays,
  isUpcomingOccurrence,
  type PmFrequency,
  type PmOccurrenceStatus,
} from '@/lib/pm-schedule';

export const PM_SCHEDULES_LIST_QUERY_KEY = ['pm-schedules'] as const;
export const UPCOMING_PM_OCCURRENCES_QUERY_KEY = ['pm-upcoming-occurrences'] as const;
export const pmScheduleDetailQueryKey = (id: string) => ['pm-schedule', id] as const;
export const pmScheduleOccurrencesQueryKey = (scheduleId: string) =>
  ['pm-schedule-occurrences', scheduleId] as const;
export const pmOccurrenceDetailQueryKey = (id: string) => ['pm-occurrence', id] as const;

export type PmAssetSummary = {
  name?: string | null;
  location?: string | null;
  manufacturer?: string | null;
  model?: string | null;
  serialNumber?: string | null;
  companyId?: string | null;
  company?: { name?: string | null } | null;
};

export type PmScheduleListRow = {
  id: string;
  taskName: string;
  frequency: string;
  scheduleStartDate: string;
  scheduleEndDate: string;
  companyId: string | null;
  assignedTechnicianIds: string[] | null;
  createdAt: string;
  company?: { name?: string | null } | null;
  occurrenceCount?: number;
  overdueCount?: number;
  upcomingCount?: number;
  nextDueDate?: string | null;
};

export type PmScheduleDetail = PmScheduleListRow & {
  description: string | null;
  frequencyValue: number;
  createdById: string | null;
  updatedAt: string | null;
  metadata: Record<string, unknown> | null;
};

export type PmOccurrenceRow = {
  id: string;
  scheduleId: string;
  assetId: string;
  dueDate: string;
  status: string;
  completedAt: string | null;
  completedById: string | null;
  completionNotes: string | null;
  completionPhotoPath: string | null;
  cancelledAt: string | null;
  cancelledById: string | null;
  cancelReason: string | null;
  assignedTechnicianIds: string[] | null;
  metadata: Record<string, unknown> | null;
  asset?: PmAssetSummary | null;
  schedule?: {
    taskName?: string;
    frequency?: string;
    description?: string | null;
    metadata?: Record<string, unknown> | null;
  } | null;
  derivedStatus?: PmOccurrenceStatus;
};

export type UpcomingPmOccurrenceRow = PmOccurrenceRow & {
  schedule?: {
    taskName?: string;
    company?: { name?: string | null } | null;
  } | null;
};

const SCHEDULE_LIST_SELECT =
  'id, taskName, frequency, scheduleStartDate, scheduleEndDate, companyId, assignedTechnicianIds, createdAt, company:companies(name)';

const SCHEDULE_DETAIL_SELECT =
  'id, taskName, description, frequency, frequencyValue, scheduleStartDate, scheduleEndDate, companyId, assignedTechnicianIds, createdById, createdAt, updatedAt, metadata, company:companies(name)';

const ASSET_SUMMARY_SELECT =
  'name, location, manufacturer, model, serialNumber, companyId, company:companies(name)';

const OCCURRENCE_BASE_SELECT =
  'id, scheduleId, assetId, dueDate, status, completedAt, completedById, completionNotes, completionPhotoPath, cancelledAt, cancelledById, cancelReason, assignedTechnicianIds, metadata';

const OCCURRENCE_SELECT = `${OCCURRENCE_BASE_SELECT}, asset:assets(${ASSET_SUMMARY_SELECT})`;

const OCCURRENCE_DETAIL_SELECT =
  `${OCCURRENCE_SELECT}, schedule:pm_schedules(taskName, frequency, description, metadata)`;

const UPCOMING_OCCURRENCE_SELECT =
  `${OCCURRENCE_SELECT}, schedule:pm_schedules(taskName, company:companies(name))`;

function mapOccurrence(row: PmOccurrenceRow): PmOccurrenceRow {
  return {
    ...row,
    derivedStatus: deriveOccurrenceStatus(row.status, row.dueDate),
  };
}

export async function fetchPmSchedulesList(): Promise<PmScheduleListRow[]> {
  const { data, error } = await supabase
    .from('pm_schedules')
    .select(SCHEDULE_LIST_SELECT)
    .order('createdAt', { ascending: false });
  if (error) throw error;

  const schedules = (data ?? []) as PmScheduleListRow[];
  if (schedules.length === 0) return [];

  const todayIso = new Date().toISOString().slice(0, 10);
  const occSummary = await fetchAllPages<{ scheduleId: string; dueDate: string; status: string }>(
    async (from, to) => {
      const result = await supabase
        .from('pm_task_occurrences')
        .select('scheduleId, dueDate, status')
        .in(
          'scheduleId',
          schedules.map((s) => s.id)
        )
        .range(from, to);
      return { data: result.data ?? [], error: result.error ? new Error(result.error.message) : null };
    }
  );

  const counts = new Map<string, number>();
  const overdueCounts = new Map<string, number>();
  const upcomingCounts = new Map<string, number>();
  const nextDue = new Map<string, string>();
  for (const row of occSummary) {
    const sid = row.scheduleId as string;
    counts.set(sid, (counts.get(sid) ?? 0) + 1);
    const due = row.dueDate as string;
    const status = row.status as string;
    if (deriveOccurrenceStatus(status, due, todayIso) === 'overdue') {
      overdueCounts.set(sid, (overdueCounts.get(sid) ?? 0) + 1);
    }
    if (isUpcomingOccurrence(status, due, todayIso)) {
      upcomingCounts.set(sid, (upcomingCounts.get(sid) ?? 0) + 1);
    }
    if (status === 'completed' || status === 'cancelled') continue;
    const current = nextDue.get(sid);
    if (!current || due < current) nextDue.set(sid, due);
  }

  return schedules.map((s) => ({
    ...s,
    occurrenceCount: counts.get(s.id) ?? 0,
    overdueCount: overdueCounts.get(s.id) ?? 0,
    upcomingCount: upcomingCounts.get(s.id) ?? 0,
    nextDueDate: nextDue.get(s.id) ?? null,
  }));
}

export async function fetchPmScheduleDetail(id: string): Promise<PmScheduleDetail | null> {
  const { data, error } = await supabase
    .from('pm_schedules')
    .select(SCHEDULE_DETAIL_SELECT)
    .eq('id', id)
    .single();
  if (error) throw error;
  if (!data) return null;
  const row = data as Record<string, unknown>;
  return {
    ...(data as PmScheduleListRow),
    description: (row.description as string | null) ?? null,
    frequencyValue: Number(row.frequencyValue ?? 0),
    createdById: (row.createdById as string | null) ?? null,
    updatedAt: (row.updatedAt as string | null) ?? null,
    metadata: (row.metadata as Record<string, unknown> | null) ?? null,
  };
}

export async function fetchPmScheduleOccurrences(scheduleId: string): Promise<PmOccurrenceRow[]> {
  const rows = await fetchAllPages<PmOccurrenceRow>(async (from, to) => {
    const result = await supabase
      .from('pm_task_occurrences')
      .select(OCCURRENCE_SELECT)
      .eq('scheduleId', scheduleId)
      .order('dueDate', { ascending: true })
      .order('id', { ascending: true })
      .range(from, to);
    return {
      data: (result.data ?? []) as PmOccurrenceRow[],
      error: result.error ? new Error(result.error.message) : null,
    };
  });
  return rows.map(mapOccurrence);
}

export async function fetchPmOccurrenceDetail(id: string): Promise<PmOccurrenceRow | null> {
  const { data, error } = await supabase
    .from('pm_task_occurrences')
    .select(OCCURRENCE_DETAIL_SELECT)
    .eq('id', id)
    .single();
  if (error) throw error;
  if (!data) return null;
  return mapOccurrence(data as PmOccurrenceRow);
}

export async function fetchUpcomingPmOccurrences(
  options?: { limit?: number; todayIso?: string }
): Promise<UpcomingPmOccurrenceRow[]> {
  const todayIso = options?.todayIso ?? new Date().toISOString().slice(0, 10);
  const maxRows = options?.limit ?? 2000;
  const rows = await fetchAllPages<UpcomingPmOccurrenceRow>(async (from, to) => {
    if (from >= maxRows) return { data: [], error: null };
    const cappedTo = Math.min(to, maxRows - 1);
    const result = await supabase
      .from('pm_task_occurrences')
      .select(UPCOMING_OCCURRENCE_SELECT)
      .gte('dueDate', todayIso)
      .neq('status', 'completed')
      .neq('status', 'cancelled')
      .order('dueDate', { ascending: true })
      .order('id', { ascending: true })
      .range(from, cappedTo);
    return {
      data: (result.data ?? []) as UpcomingPmOccurrenceRow[],
      error: result.error ? new Error(result.error.message) : null,
    };
  });
  return rows.slice(0, maxRows).map(mapOccurrence);
}

export type CreatePmScheduleInput = {
  taskName: string;
  description?: string;
  frequency: PmFrequency;
  scheduleStartDate: string;
  scheduleEndDate: string;
  companyId?: string | null;
  assignedTechnicianIds: string[];
  createdById?: string | null;
  occurrences: { assetId: string; dueDate: string }[];
};

export async function createScheduleWithOccurrences(
  input: CreatePmScheduleInput
): Promise<{ scheduleId: string; occurrenceCount: number }> {
  const schedulePayload = {
    taskName: input.taskName.trim(),
    description: input.description?.trim() ?? '',
    frequency: input.frequency,
    frequencyValue: frequencyDays(input.frequency),
    scheduleStartDate: input.scheduleStartDate,
    scheduleEndDate: input.scheduleEndDate,
    companyId: input.companyId ?? '',
    assignedTechnicianIds: input.assignedTechnicianIds,
    createdById: input.createdById ?? '',
    metadata: { source: 'admin_web' },
  };

  const occurrencesPayload = input.occurrences.map((o) => ({
    assetId: o.assetId,
    dueDate: o.dueDate,
    status: 'pending',
    assignedTechnicianIds: input.assignedTechnicianIds,
  }));

  const { data, error } = await supabase.rpc('create_pm_schedule_with_occurrences', {
    p_schedule: schedulePayload,
    p_asset_ids: [...new Set(input.occurrences.map((o) => o.assetId))],
    p_occurrences: occurrencesPayload,
  });
  if (error) throw error;

  const result = data as { scheduleId?: string; occurrenceCount?: number } | null;
  if (!result?.scheduleId) throw new Error('Schedule creation failed');
  return {
    scheduleId: result.scheduleId,
    occurrenceCount: Number(result.occurrenceCount ?? 0),
  };
}

export async function completePmOccurrence(params: {
  id: string;
  completedById?: string | null;
  completionNotes?: string | null;
  completionPhotoPath?: string | null;
}): Promise<void> {
  const now = new Date().toISOString();
  const { error } = await supabase
    .from('pm_task_occurrences')
    .update({
      status: 'completed',
      completedAt: now,
      completedById: params.completedById ?? null,
      completionNotes: params.completionNotes?.trim() || null,
      completionPhotoPath: params.completionPhotoPath ?? null,
      updatedAt: now,
    })
    .eq('id', params.id);
  if (error) throw error;
}

export async function cancelPmOccurrence(params: {
  id: string;
  cancelledById?: string | null;
  cancelReason: string;
}): Promise<void> {
  const now = new Date().toISOString();
  const { error } = await supabase
    .from('pm_task_occurrences')
    .update({
      status: 'cancelled',
      cancelledAt: now,
      cancelledById: params.cancelledById ?? null,
      cancelReason: params.cancelReason.trim(),
      updatedAt: now,
    })
    .eq('id', params.id);
  if (error) throw error;
}

export async function reschedulePmOccurrence(params: {
  id: string;
  dueDate: string;
}): Promise<void> {
  const { error } = await supabase
    .from('pm_task_occurrences')
    .update({
      dueDate: params.dueDate,
      updatedAt: new Date().toISOString(),
    })
    .eq('id', params.id);
  if (error) {
    if (error.code === '23505') {
      throw new Error('Another occurrence already exists for this charger on that due date');
    }
    throw error;
  }
}

export async function updatePmOccurrenceAssignees(
  id: string,
  assignedTechnicianIds: string[]
): Promise<void> {
  const { error } = await supabase
    .from('pm_task_occurrences')
    .update({
      assignedTechnicianIds: assignedTechnicianIds,
      updatedAt: new Date().toISOString(),
    })
    .eq('id', id);
  if (error) throw error;
}

/** Update schedule-level assignees and sync open occurrences (pending/overdue/upcoming). */
export async function updatePmScheduleAssignees(
  scheduleId: string,
  assignedTechnicianIds: string[]
): Promise<void> {
  const now = new Date().toISOString();
  const { error: scheduleError } = await supabase
    .from('pm_schedules')
    .update({
      assignedTechnicianIds,
      updatedAt: now,
    })
    .eq('id', scheduleId);
  if (scheduleError) throw scheduleError;

  const { error: occurrenceError } = await supabase
    .from('pm_task_occurrences')
    .update({
      assignedTechnicianIds,
      updatedAt: now,
    })
    .eq('scheduleId', scheduleId)
    .neq('status', 'completed')
    .neq('status', 'cancelled');
  if (occurrenceError) throw occurrenceError;
}

/** Count PM schedule occurrences that are past due and not completed/cancelled. */
export async function countOverduePmOccurrences(todayIso = new Date().toISOString().slice(0, 10)): Promise<number> {
  const rows = await fetchAllPages<{ status: string; dueDate: string }>(async (from, to) => {
    const { data, error } = await supabase
      .from('pm_task_occurrences')
      .select('status, dueDate')
      .neq('status', 'completed')
      .neq('status', 'cancelled')
      .range(from, to);
    return { data, error: error ? new Error(error.message) : null };
  });
  return rows.filter(
    (row) => deriveOccurrenceStatus(String(row.status), String(row.dueDate), todayIso) === 'overdue'
  ).length;
}

/** Count PM occurrences due today or later that are still open. */
export async function countUpcomingPmOccurrences(todayIso = new Date().toISOString().slice(0, 10)): Promise<number> {
  const { count, error } = await supabase
    .from('pm_task_occurrences')
    .select('id', { count: 'exact', head: true })
    .gte('dueDate', todayIso)
    .neq('status', 'completed')
    .neq('status', 'cancelled');
  if (error) throw error;
  return count ?? 0;
}

export type RecentPmOccurrenceCompletion = {
  id: string;
  scheduleId: string;
  completedAt: string;
  taskName: string;
};

export async function fetchRecentCompletedPmOccurrences(
  limit = 15
): Promise<RecentPmOccurrenceCompletion[]> {
  const { data, error } = await supabase
    .from('pm_task_occurrences')
    .select('id, scheduleId, completedAt, schedule:pm_schedules(taskName)')
    .eq('status', 'completed')
    .not('completedAt', 'is', null)
    .order('completedAt', { ascending: false })
    .limit(limit);
  if (error) throw error;

  return (data ?? []).map((row) => ({
    id: String(row.id),
    scheduleId: String(row.scheduleId),
    completedAt: String(row.completedAt),
    taskName: String((row.schedule as { taskName?: string } | null)?.taskName ?? 'PM schedule'),
  }));
}

export type PmOccurrenceAnalyticsRow = {
  status: string;
  dueDate: string;
};

export async function fetchPmOccurrencesForAnalytics(): Promise<PmOccurrenceAnalyticsRow[]> {
  const rows = await fetchAllPages<{ status: string; dueDate: string }>(async (from, to) => {
    const { data, error } = await supabase
      .from('pm_task_occurrences')
      .select('status, dueDate')
      .range(from, to);
    return { data, error: error ? new Error(error.message) : null };
  });
  return rows.map((row) => ({
    status: String(row.status),
    dueDate: String(row.dueDate),
  }));
}

const PM_OCCURRENCE_EXPORT_SELECT =
  'dueDate, status, completedAt, completionNotes, asset:assets(name), schedule:pm_schedules(taskName, frequency, company:companies(name))';

export async function fetchPmOccurrencesForExport(
  todayIso = new Date().toISOString().slice(0, 10)
): Promise<Record<string, unknown>[]> {
  const data = await fetchAllPages<Record<string, unknown>>(async (from, to) => {
    const { data: page, error } = await supabase
      .from('pm_task_occurrences')
      .select(PM_OCCURRENCE_EXPORT_SELECT)
      .order('dueDate', { ascending: false })
      .range(from, to);
    return { data: page as Record<string, unknown>[] | null, error: error ? new Error(error.message) : null };
  });
  return data.map((row) => {
    const r = row as Record<string, unknown>;
    const schedule = r.schedule as {
      taskName?: string;
      company?: { name?: string | null };
    } | null;
    const asset = r.asset as { name?: string | null } | null;
    const storedStatus = String(r.status ?? '');
    const dueDate = String(r.dueDate ?? '');
    return {
      taskName: schedule?.taskName ?? '',
      dueDate,
      derivedStatus: deriveOccurrenceStatus(storedStatus, dueDate, todayIso),
      storedStatus,
      chargerName: asset?.name ?? '',
      companyName: schedule?.company?.name ?? '',
      completedAt: r.completedAt ?? '',
      completionNotes: r.completionNotes ?? '',
    };
  });
}
