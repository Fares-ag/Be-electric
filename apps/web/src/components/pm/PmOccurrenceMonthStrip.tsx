import type { PmOccurrenceMonthBucket } from '@/lib/pm-schedule';
import { cn } from '@/lib/utils';

export function PmOccurrenceMonthStrip({
  buckets,
  className,
}: {
  buckets: PmOccurrenceMonthBucket[];
  className?: string;
}) {
  if (buckets.length === 0) {
    return (
      <p className={cn('text-sm text-muted-foreground', className)}>
        No due dates to chart for this schedule.
      </p>
    );
  }

  const maxCount = Math.max(...buckets.map((b) => b.count), 1);

  return (
    <div className={className}>
      <p className="mb-3 text-xs font-medium uppercase tracking-wide text-muted-foreground">
        Workload by month
      </p>
      <div
        className="flex items-end gap-1 overflow-x-auto pb-1"
        role="img"
        aria-label="Occurrences per month bar chart"
      >
        {buckets.map((bucket) => {
          const heightPct = Math.max(8, Math.round((bucket.count / maxCount) * 100));
          return (
            <div
              key={bucket.monthKey}
              className="flex min-w-[2rem] flex-1 flex-col items-center gap-1"
              title={`${bucket.label}: ${bucket.count} occurrence${bucket.count === 1 ? '' : 's'}`}
            >
              <span className="text-[10px] tabular-nums text-muted-foreground">{bucket.count}</span>
              <div
                className="w-full rounded-t bg-primary/70 transition-all"
                style={{ height: `${heightPct}px`, minHeight: '8px', maxHeight: '64px' }}
              />
              <span className="text-[9px] text-muted-foreground whitespace-nowrap">
                {bucket.label}
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
