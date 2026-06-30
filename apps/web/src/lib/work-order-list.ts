import type { BadgeVariant } from '@/components/ui/Badge';

export function workOrderPriorityVariant(priority: string | null | undefined): BadgeVariant {
  switch (String(priority ?? 'medium').toLowerCase()) {
    case 'high':
    case 'urgent':
      return 'destructive';
    case 'low':
      return 'secondary';
    default:
      return 'warning';
  }
}

export function formatWorkOrderPriority(priority: string | null | undefined): string {
  const value = String(priority ?? 'medium');
  return value.replace(/([A-Z])/g, ' $1').trim();
}
