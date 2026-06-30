import Link from 'next/link';
import { cn } from '@/lib/utils';

export function FilterChipLink({
  href,
  active,
  children,
  count,
  className,
}: {
  href: string;
  active: boolean;
  children: React.ReactNode;
  count?: number;
  className?: string;
}) {
  return (
    <Link
      href={href}
      className={cn(
        'inline-flex items-center gap-2 rounded-full border border-border bg-background px-3 py-1.5 text-sm transition-colors',
        'hover:border-primary/40 hover:bg-muted/50',
        active && 'border-primary bg-primary/5 ring-1 ring-primary/30',
        className
      )}
    >
      {children}
      {count != null ? (
        <span className="tabular-nums text-xs font-semibold text-muted-foreground">{count}</span>
      ) : null}
    </Link>
  );
}
