import { StatusBadge } from '@/components/ui/Badge';
import { PM_OCCURRENCE_STATUS_LEGEND } from '@/lib/pm-schedule';

export function PmOccurrenceStatusLegend({ className }: { className?: string }) {
  return (
    <div className={className}>
      <p className="mb-2 text-xs font-medium uppercase tracking-wide text-muted-foreground">
        Status legend
      </p>
      <ul className="flex flex-wrap gap-x-4 gap-y-2">
        {PM_OCCURRENCE_STATUS_LEGEND.map(({ status, description }) => (
          <li key={status} className="flex items-center gap-2 text-sm">
            <StatusBadge status={status} />
            <span className="text-muted-foreground">{description}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}
