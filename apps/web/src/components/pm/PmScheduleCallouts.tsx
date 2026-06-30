import Link from 'next/link';
import { AlertTriangle, CalendarClock, Plus } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { cn } from '@/lib/utils';

type PmScheduleCalloutsProps = {
  overdueCount: number;
  upcomingCount: number;
  onCreateClick: () => void;
  className?: string;
};

export function PmScheduleCallouts({
  overdueCount,
  upcomingCount,
  onCreateClick,
  className,
}: PmScheduleCalloutsProps) {
  return (
    <div className={cn('grid gap-4 sm:grid-cols-3', className)}>
      <Link href="/pm-schedules?status=overdue" className="group block">
        <Card className="h-full border-red-200/80 transition-all hover:border-red-400 hover:shadow-sm dark:border-red-900/50">
          <CardContent className="flex items-start gap-3 p-4">
            <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-red-600 text-white">
              <AlertTriangle className="h-5 w-5" aria-hidden />
            </span>
            <div>
              <p className="text-sm font-medium text-muted-foreground">Overdue</p>
              <p className="font-display text-2xl font-bold text-foreground">{overdueCount}</p>
              <p className="mt-1 text-xs text-muted-foreground group-hover:text-foreground">
                Past due · view schedules
              </p>
            </div>
          </CardContent>
        </Card>
      </Link>

      <Link href="/pm-schedules?view=upcoming" className="group block">
        <Card className="h-full border-blue-200/80 transition-all hover:border-blue-400 hover:shadow-sm dark:border-blue-900/50">
          <CardContent className="flex items-start gap-3 p-4">
            <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-blue-600 text-white">
              <CalendarClock className="h-5 w-5" aria-hidden />
            </span>
            <div>
              <p className="text-sm font-medium text-muted-foreground">Upcoming tasks</p>
              <p className="font-display text-2xl font-bold text-foreground">{upcomingCount}</p>
              <p className="mt-1 text-xs text-muted-foreground group-hover:text-foreground">
                Due today or later · all schedules
              </p>
            </div>
          </CardContent>
        </Card>
      </Link>

      <Card className="h-full border-dashed">
        <CardContent className="flex h-full flex-col justify-between gap-3 p-4">
          <div className="flex items-start gap-3">
            <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-primary text-primary-foreground">
              <Plus className="h-5 w-5" aria-hidden />
            </span>
            <div>
              <p className="text-sm font-medium text-foreground">New schedule</p>
              <p className="mt-1 text-xs text-muted-foreground">
                Materialize due dates across selected chargers
              </p>
            </div>
          </div>
          <Button onClick={onCreateClick} className="w-full sm:w-auto">
            Create PM schedule
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
