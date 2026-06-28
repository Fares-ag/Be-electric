import { supabase } from '@/lib/supabase';
import {
  deriveOccurrenceStatus,
  frequencyDays,
  type PmFrequency,
  type PmOccurrenceStatus,
} from '@/lib/pm-schedule';

export const PM_SCHEDULES_LIST_QUERY_KEY = ['pm-schedules'] as const;
export const pmScheduleDetailQueryKey = (id: string) => ['pm-schedule', id] as const;
export const pmScheduleOccurrencesQueryKey = (scheduleId: string) =>
  ['pm-schedule-occurrences', scheduleId] as const;
export const pmOccurrenceDetailQueryKey = (id: string) => ['pm-occurrence', id] as const;

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
  completionPhotoPath: string | null;
  assignedTechnicianIds: string[] | null;
  asset?: { name?: string | null } | null;
  schedule?: { taskName?: string; frequency?: string; description?: string | null } | null;
  derivedStatus?: PmOccurrenceStatus;
};

const SCHEDULE_LIST_SELECT =
  'id, taskName, frequency, scheduleStartDate, scheduleEndDate, companyId, assignedTechnicianIds, createdAt, company:companies(name)';

const SCHEDULE_DETAIL_SELECT =
  'id, taskName, description, frequency, frequencyValue, scheduleStartDate, scheduleEndDate, companyId, assignedTechnicianIds, createdById, createdAt, updatedAt, metadata, company:companies(name)';

const OCCURRENCE_SELECT =
  'id, scheduleId, assetId, dueDate, status, completedAt, completionPhotoPath, assignedTechnicianIds, asset:assets(name)';

const OCCURRENCE_DETAIL_SELECT =
  `${OCCURRENCE_SELECT}, schedule:pm_schedules(taskName, frequency, description)`;

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

  const { data: occSummary, error: occError } = await supabase
    .from('pm_task_occurrences')
    .select('scheduleId, dueDate, status')
    .in(
      'scheduleId',
      schedules.map((s) => s.id)
    );
  if (occError) throw occError;

  const counts = new Map<string, number>();
  const nextDue = new Map<string, string>();
  for (const row of occSummary ?? []) {
    const sid = row.scheduleId as string;
    counts.set(sid, (counts.get(sid) ?? 0) + 1);
    const due = row.dueDate as string;
    const status = row.status as string;
    if (status === 'completed' || status === 'cancelled') continue;
    const current = nextDue.get(sid);
    if (!current || due < current) nextDue.set(sid, due);
  }

  return schedules.map((s) => ({
    ...s,
    occurrenceCount: counts.get(s.id) ?? 0,
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
  const { data, error } = await supabase
    .from('pm_task_occurrences')
    .select(OCCURRENCE_SELECT)
    .eq('scheduleId', scheduleId)
    .order('dueDate', { ascending: true });
  if (error) throw error;
  return ((data ?? []) as PmOccurrenceRow[]).map(mapOccurrence);
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
  completionPhotoPath?: string | null;
}): Promise<void> {
  const now = new Date().toISOString();
  const { error } = await supabase
    .from('pm_task_occurrences')
    .update({
      status: 'completed',
      completedAt: now,
      completionPhotoPath: params.completionPhotoPath ?? null,
      updatedAt: now,
    })
    .eq('id', params.id);
  if (error) throw error;
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

/** Count PM schedule occurrences that are past due and not completed/cancelled. */
export async function countOverduePmOccurrences(todayIso = new Date().toISOString().slice(0, 10)): Promise<number> {
  const { data, error } = await supabase
    .from('pm_task_occurrences')
    .select('status, dueDate')
    .neq('status', 'completed')
    .neq('status', 'cancelled');
  if (error) throw error;
  return (data ?? []).filter(
    (row) => deriveOccurrenceStatus(String(row.status), String(row.dueDate), todayIso) === 'overdue'
  ).length;
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
  const { data, error } = await supabase
    .from('pm_task_occurrences')
    .select('status, dueDate');
  if (error) throw error;
  return (data ?? []).map((row) => ({
    status: String(row.status),
    dueDate: String(row.dueDate),
  }));
}
