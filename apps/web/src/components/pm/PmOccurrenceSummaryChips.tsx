import { StatusBadge } from '@/components/ui/Badge';
import type { PmOccurrenceStatsSummary } from '@/lib/pm-schedule';
import { cn } from '@/lib/utils';

type PmOccurrenceSummaryChipsProps = {
  stats: PmOccurrenceStatsSummary;
  activeFilter: string;
  onFilterChange: (filter: string) => void;
  className?: string;
};

const CHIPS: {
  key: keyof PmOccurrenceStatsSummary | 'all';
  filter: string;
  label: string;
  status?: string;
}[] = [
  { key: 'all', filter: '', label: 'All' },
  { key: 'upcoming', filter: 'upcoming', label: 'Upcoming', status: 'upcoming' },
  { key: 'overdue', filter: 'overdue', label: 'Overdue', status: 'overdue' },
  { key: 'completed', filter: 'completed', label: 'Completed', status: 'completed' },
  { key: 'cancelled', filter: 'cancelled', label: 'Cancelled', status: 'cancelled' },
];

export function PmOccurrenceSummaryChips({
  stats,
  activeFilter,
  onFilterChange,
  className,
}: PmOccurrenceSummaryChipsProps) {
  return (
    <div className={cn('flex flex-wrap gap-2', className)}>
      {CHIPS.map(({ key, filter, label, status }) => {
        const count = key === 'all' ? stats.total : stats[key];
        const isActive = activeFilter === filter;
        return (
          <button
            key={key}
            type="button"
            onClick={() => onFilterChange(filter)}
            className={cn(
              'inline-flex items-center gap-2 rounded-full border border-border bg-background px-3 py-1.5 text-sm transition-colors',
              'hover:border-primary/40 hover:bg-muted/50',
              isActive && 'border-primary bg-primary/5 ring-1 ring-primary/30'
            )}
          >
            {status ? <StatusBadge status={status}>{label}</StatusBadge> : <span>{label}</span>}
            <span className="tabular-nums font-semibold text-foreground">{count}</span>
          </button>
        );
      })}
    </div>
  );
}
