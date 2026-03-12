import { cn } from '@/lib/utils';
import { getStatusVariant } from '@/lib/status-variants';

/** All badge variants: semantic + per-status colors for work orders, PM tasks, parts, etc. */
export type BadgeVariant =
  | 'default'
  | 'secondary'
  | 'success'
  | 'warning'
  | 'destructive'
  // Status-specific (each status has its own color)
  | 'open'
  | 'assigned'
  | 'inProgress'
  | 'completed'
  | 'closed'
  | 'cancelled'
  | 'reopened'
  | 'pending'
  | 'overdue'
  | 'approved'
  | 'rejected'
  | 'fulfilled'
  | 'draft'
  | 'submitted'
  | 'ordered'
  | 'received'
  | 'active'
  | 'inactive'
  | 'maintenance';

interface BadgeProps {
  children: React.ReactNode;
  variant?: BadgeVariant | string;
  className?: string;
}

const variantClasses: Record<BadgeVariant, string> = {
  default: 'bg-muted text-muted-foreground',
  secondary: 'bg-secondary text-secondary-foreground',
  success: 'bg-accent text-accent-foreground',
  warning: 'bg-amber-600 text-white',
  destructive: 'bg-red-600 text-white',
  // Work order – deep colors, white text
  open: 'bg-blue-600 text-white',
  assigned: 'bg-indigo-600 text-white',
  inProgress: 'bg-orange-600 text-white',
  completed: 'bg-green-600 text-white',
  closed: 'bg-slate-600 text-white',
  cancelled: 'bg-red-600 text-white',
  reopened: 'bg-orange-600 text-white',
  // PM / Parts / PO
  pending: 'bg-yellow-600 text-white',
  overdue: 'bg-red-600 text-white',
  approved: 'bg-green-600 text-white',
  rejected: 'bg-red-600 text-white',
  fulfilled: 'bg-teal-600 text-white',
  draft: 'bg-zinc-600 text-white',
  submitted: 'bg-blue-600 text-white',
  ordered: 'bg-violet-600 text-white',
  received: 'bg-green-600 text-white',
  // Asset / generic
  active: 'bg-green-600 text-white',
  inactive: 'bg-slate-600 text-white',
  maintenance: 'bg-amber-600 text-white',
};

export function Badge({ children, variant = 'default', className }: BadgeProps) {
  const v = (variant in variantClasses ? variant : 'default') as BadgeVariant;
  return (
    <span
      className={cn(
        'inline-flex items-center rounded-md px-2.5 py-0.5 text-xs font-medium',
        variantClasses[v],
        className
      )}
    >
      {children}
    </span>
  );
}

/** Renders a status string with its dedicated color. Use for work orders, PM tasks, parts, etc. */
export function StatusBadge({
  status,
  children,
  className,
}: {
  status: string | null | undefined;
  children?: React.ReactNode;
  className?: string;
}) {
  const label = children ?? (status == null ? '-' : String(status).replace(/([A-Z])/g, ' $1').trim());
  return (
    <Badge variant={getStatusVariant(status)} className={className}>
      {label}
    </Badge>
  );
}
