export type OrphanEntityType = 'work_order' | 'pm_schedule' | 'pm_occurrence' | 'pm_task';

export type OrphanAssignmentRow = {
  entityType: OrphanEntityType;
  entityId: string;
  entityLabel: string;
  href: string;
  orphanUserIds: string[];
  allAssigneeIds: string[];
  primaryTechnicianId?: string | null;
};

export function collectOrphanIds(
  assigneeIds: string[] | null | undefined,
  knownUserIds: Set<string>
): string[] {
  if (!assigneeIds?.length) return [];
  return [...new Set(assigneeIds.filter((id) => id && !knownUserIds.has(id)))];
}

export function mergeOrphanIds(
  assigneeIds: string[] | null | undefined,
  primaryTechnicianId: string | null | undefined,
  knownUserIds: Set<string>
): string[] {
  const fromList = collectOrphanIds(assigneeIds, knownUserIds);
  const fromPrimary =
    primaryTechnicianId && !knownUserIds.has(primaryTechnicianId) ? [primaryTechnicianId] : [];
  return [...new Set([...fromList, ...fromPrimary])];
}

/** Remove orphan IDs; optionally append a replacement technician (deduped). */
export function scrubAssigneeList(
  current: string[],
  orphanIds: string[],
  replacementId?: string | null
): string[] {
  const orphans = new Set(orphanIds);
  const next = current.filter((id) => !orphans.has(id));
  const replacement = replacementId?.trim();
  if (replacement && !next.includes(replacement)) {
    next.push(replacement);
  }
  return next;
}

export function entityTypeLabel(type: OrphanEntityType): string {
  switch (type) {
    case 'work_order':
      return 'Work order';
    case 'pm_schedule':
      return 'PM schedule';
    case 'pm_occurrence':
      return 'PM occurrence';
    case 'pm_task':
      return 'PM task (legacy)';
    default:
      return type;
  }
}
