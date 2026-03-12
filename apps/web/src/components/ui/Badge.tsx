import { cn } from '@/lib/utils';

interface BadgeProps {
  children: React.ReactNode;
  variant?: 'default' | 'success' | 'warning' | 'destructive' | 'secondary';
  className?: string;
}

export function Badge({ children, variant = 'default', className }: BadgeProps) {
  return (
    <span
      className={cn(
        'inline-flex items-center rounded-md px-2.5 py-0.5 text-xs font-medium',
        variant === 'default' && 'bg-muted text-muted-foreground',
        variant === 'success' && 'bg-accent text-accent-foreground',
        variant === 'warning' && 'bg-amber-100 text-amber-800',
        variant === 'destructive' && 'bg-red-100 text-red-800',
        variant === 'secondary' && 'bg-secondary text-secondary-foreground',
        className
      )}
    >
      {children}
    </span>
  );
}
