import { isAdminRole, type AppRole } from '@/lib/roles';

export type NotificationLinkInput = {
  relatedId: string | null;
  relatedType: string | null;
};

/** Role-aware deep link for in-app notifications. Avoids sending requestors to admin-only routes. */
export function notificationRelatedHref(
  n: NotificationLinkInput,
  role: AppRole | undefined
): string | null {
  if (!n.relatedId || !n.relatedType) return null;
  if (n.relatedType === 'work_order') return `/work-orders/${n.relatedId}`;
  if (n.relatedType === 'parts_request') {
    return isAdminRole(role) ? '/parts-requests' : null;
  }
  if (n.relatedType === 'support_request') {
    return isAdminRole(role) ? `/support-requests/${n.relatedId}` : null;
  }
  return null;
}
