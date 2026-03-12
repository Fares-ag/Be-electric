/**
 * Central map: every status value used in the app gets its own badge variant (color).
 * Used for work orders, PM tasks, parts requests, purchase orders, assets.
 */
export const STATUS_VARIANT: Record<string, string> = {
  // Work order
  open: 'open',
  assigned: 'assigned',
  inProgress: 'inProgress',
  completed: 'completed',
  closed: 'closed',
  cancelled: 'cancelled',
  reopened: 'reopened',
  // PM task
  pending: 'pending',
  overdue: 'overdue',
  // Parts request
  approved: 'approved',
  rejected: 'rejected',
  fulfilled: 'fulfilled',
  // Purchase order / generic
  draft: 'draft',
  submitted: 'submitted',
  ordered: 'ordered',
  received: 'received',
  // Asset / generic
  active: 'active',
  inactive: 'inactive',
  maintenance: 'maintenance',
};

export type StatusBadgeVariant = keyof typeof STATUS_VARIANT | 'default';

/** Returns the badge variant for a status string (e.g. from DB). Unknown statuses use 'default'. */
export function getStatusVariant(status: string | null | undefined): string {
  if (status == null || status === '') return 'default';
  const normalized = String(status).trim();
  return STATUS_VARIANT[normalized] ?? 'default';
}
