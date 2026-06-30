import { supabase } from '@/lib/supabase';
import { fetchAllPages } from '@/lib/supabase-pagination';
import { fetchUsersList } from '@/lib/queries/users';
import { updatePmScheduleAssignees } from '@/lib/queries/pm-schedules';
import { updateWorkOrderAssignees } from '@/lib/work-order-assignees';
import {
  mergeOrphanIds,
  scrubAssigneeList,
  type OrphanAssignmentRow,
  type OrphanEntityType,
} from '@/lib/orphan-assignments';

export const ORPHAN_ASSIGNMENTS_QUERY_KEY = ['orphan-assignments'] as const;

export async function fetchOrphanAssignments(): Promise<OrphanAssignmentRow[]> {
  const users = await fetchUsersList();
  const knownUserIds = new Set(users.map((u) => u.id));
  const rows: OrphanAssignmentRow[] = [];

  const workOrders = await fetchAllPages<{
    id: string;
    ticketNumber: string | null;
    assignedTechnicianIds: string[] | null;
    primaryTechnicianId: string | null;
  }>(async (from, to) => {
    const { data, error } = await supabase
      .from('work_orders')
      .select('id, ticketNumber, assignedTechnicianIds, primaryTechnicianId')
      .or('assignedTechnicianIds.not.is.null,primaryTechnicianId.not.is.null')
      .range(from, to);
    return { data, error: error ? new Error(error.message) : null };
  });

  for (const wo of workOrders) {
    const orphanUserIds = mergeOrphanIds(
      wo.assignedTechnicianIds,
      wo.primaryTechnicianId,
      knownUserIds
    );
    if (!orphanUserIds.length) continue;
    rows.push({
      entityType: 'work_order',
      entityId: wo.id,
      entityLabel: wo.ticketNumber ?? wo.id.slice(0, 8),
      href: `/work-orders/${wo.id}`,
      orphanUserIds,
      allAssigneeIds: wo.assignedTechnicianIds ?? [],
      primaryTechnicianId: wo.primaryTechnicianId,
    });
  }

  const pmSchedules = await fetchAllPages<{
    id: string;
    taskName: string;
    assignedTechnicianIds: string[] | null;
  }>(async (from, to) => {
    const { data, error } = await supabase
      .from('pm_schedules')
      .select('id, taskName, assignedTechnicianIds')
      .not('assignedTechnicianIds', 'is', null)
      .range(from, to);
    return { data, error: error ? new Error(error.message) : null };
  });

  for (const schedule of pmSchedules) {
    const orphanUserIds = mergeOrphanIds(schedule.assignedTechnicianIds, null, knownUserIds);
    if (!orphanUserIds.length) continue;
    rows.push({
      entityType: 'pm_schedule',
      entityId: schedule.id,
      entityLabel: schedule.taskName,
      href: `/pm-schedules/${schedule.id}`,
      orphanUserIds,
      allAssigneeIds: schedule.assignedTechnicianIds ?? [],
    });
  }

  const pmOccurrences = await fetchAllPages<{
    id: string;
    scheduleId: string;
    dueDate: string;
    assignedTechnicianIds: string[] | null;
    schedule: { taskName?: string | null } | null;
  }>(async (from, to) => {
    const { data, error } = await supabase
      .from('pm_task_occurrences')
      .select('id, scheduleId, dueDate, assignedTechnicianIds, schedule:pm_schedules(taskName)')
      .not('assignedTechnicianIds', 'is', null)
      .range(from, to);
    return { data, error: error ? new Error(error.message) : null };
  });

  for (const occ of pmOccurrences) {
    const orphanUserIds = mergeOrphanIds(occ.assignedTechnicianIds, null, knownUserIds);
    if (!orphanUserIds.length) continue;
    const taskName = occ.schedule?.taskName ?? 'PM occurrence';
    rows.push({
      entityType: 'pm_occurrence',
      entityId: occ.id,
      entityLabel: `${taskName} · ${occ.dueDate}`,
      href: `/pm-schedules/${occ.scheduleId}/occurrences/${occ.id}`,
      orphanUserIds,
      allAssigneeIds: occ.assignedTechnicianIds ?? [],
    });
  }

  const pmTasks = await fetchAllPages<{
    id: string;
    taskName: string;
    assignedTechnicianIds: string[] | null;
  }>(async (from, to) => {
    const { data, error } = await supabase
      .from('pm_tasks')
      .select('id, taskName, assignedTechnicianIds')
      .not('assignedTechnicianIds', 'is', null)
      .range(from, to);
    return { data, error: error ? new Error(error.message) : null };
  });

  for (const task of pmTasks) {
    const orphanUserIds = mergeOrphanIds(task.assignedTechnicianIds, null, knownUserIds);
    if (!orphanUserIds.length) continue;
    rows.push({
      entityType: 'pm_task',
      entityId: task.id,
      entityLabel: task.taskName,
      href: `/pm-tasks/${task.id}`,
      orphanUserIds,
      allAssigneeIds: task.assignedTechnicianIds ?? [],
    });
  }

  return rows.sort((a, b) => a.entityLabel.localeCompare(b.entityLabel));
}

export async function resolveOrphanAssignment(
  row: OrphanAssignmentRow,
  replacementId?: string | null
): Promise<void> {
  const nextAssignees = scrubAssigneeList(row.allAssigneeIds, row.orphanUserIds, replacementId);
  const now = new Date().toISOString();

  switch (row.entityType) {
    case 'work_order': {
      const primaryOrphan =
        row.primaryTechnicianId && row.orphanUserIds.includes(row.primaryTechnicianId);
      await updateWorkOrderAssignees(
        row.entityId,
        nextAssignees,
        primaryOrphan ? { primaryTechnicianId: replacementId?.trim() || null } : undefined
      );
      return;
    }
    case 'pm_schedule':
      await updatePmScheduleAssignees(row.entityId, nextAssignees);
      return;
    case 'pm_occurrence': {
      const { error } = await supabase
        .from('pm_task_occurrences')
        .update({ assignedTechnicianIds: nextAssignees, updatedAt: now })
        .eq('id', row.entityId);
      if (error) throw error;
      return;
    }
    case 'pm_task': {
      const { error } = await supabase
        .from('pm_tasks')
        .update({ assignedTechnicianIds: nextAssignees, updatedAt: now })
        .eq('id', row.entityId);
      if (error) throw error;
      return;
    }
    default: {
      const _exhaustive: never = row.entityType;
      throw new Error(`Unsupported entity type: ${String(_exhaustive)}`);
    }
  }
}

export function orphanSummaryByType(rows: OrphanAssignmentRow[]): Record<OrphanEntityType, number> {
  const counts: Record<OrphanEntityType, number> = {
    work_order: 0,
    pm_schedule: 0,
    pm_occurrence: 0,
    pm_task: 0,
  };
  for (const row of rows) {
    counts[row.entityType]++;
  }
  return counts;
}
