'use client';

import { cn } from '@/lib/utils';
import Link from 'next/link';
import { ChevronRight, Inbox, type LucideIcon } from 'lucide-react';
import { Button } from '@/components/ui/Button';

export type BreadcrumbItem = {
  label: string;
  href?: string;
};

export function PageHeader({
  title,
  description,
  breadcrumbs,
  actions,
  className,
}: {
  title: string;
  description?: string;
  breadcrumbs?: BreadcrumbItem[];
  actions?: React.ReactNode;
  className?: string;
}) {
  return (
    <div className={cn('flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between', className)}>
      <div className="min-w-0">
        {breadcrumbs && breadcrumbs.length > 0 ? (
          <nav aria-label="Breadcrumb" className="mb-2">
            <ol className="flex flex-wrap items-center gap-1 text-sm text-muted-foreground">
              {breadcrumbs.map((item, index) => (
                <li key={`${item.label}-${index}`} className="flex min-w-0 items-center gap-1">
                  {index > 0 ? (
                    <ChevronRight className="h-3.5 w-3.5 shrink-0 opacity-60" aria-hidden />
                  ) : null}
                  {item.href ? (
                    <Link
                      href={item.href}
                      className="truncate hover:text-foreground underline-offset-2 hover:underline"
                    >
                      {item.label}
                    </Link>
                  ) : (
                    <span className="truncate font-medium text-foreground">{item.label}</span>
                  )}
                </li>
              ))}
            </ol>
          </nav>
        ) : null}
        <h1 className="font-display text-2xl font-semibold tracking-tight text-foreground">{title}</h1>
        {description ? (
          <p className="mt-1 text-sm text-muted-foreground">{description}</p>
        ) : null}
      </div>
      {actions ? <div className="flex shrink-0 flex-wrap items-center gap-2">{actions}</div> : null}
    </div>
  );
}

export function LoadingSpinner({
  label = 'Loading…',
  className,
}: {
  label?: string;
  className?: string;
}) {
  return (
    <div
      className={cn('flex flex-col items-center justify-center gap-3 py-12', className)}
      role="status"
      aria-live="polite"
    >
      <div className="h-6 w-6 animate-spin rounded-full border-2 border-primary border-t-transparent" />
      <span className="sr-only">{label}</span>
    </div>
  );
}

export function EmptyState({
  title,
  description,
  action,
  icon: Icon = Inbox,
  iconClassName,
  className,
}: {
  title: string;
  description?: string;
  action?: React.ReactNode;
  icon?: LucideIcon;
  iconClassName?: string;
  className?: string;
}) {
  return (
    <div className={cn('flex flex-col items-center justify-center px-6 py-14 text-center', className)}>
      <div
        className={cn(
          'mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-muted text-muted-foreground',
          iconClassName
        )}
      >
        <Icon className="h-7 w-7" aria-hidden />
      </div>
      <p className="font-medium text-foreground">{title}</p>
      {description ? <p className="mt-1 max-w-sm text-sm text-muted-foreground">{description}</p> : null}
      {action ? <div className="mt-4">{action}</div> : null}
    </div>
  );
}

export function QueryErrorState({
  title = 'Failed to load data',
  message,
  hint,
  onRetry,
}: {
  title?: string;
  message?: string;
  hint?: string;
  onRetry?: () => void;
}) {
  return (
    <div className="px-6 py-12 text-center" role="alert">
      <p className="font-medium text-destructive">{title}</p>
      {message ? <p className="mt-1 text-sm text-muted-foreground">{message}</p> : null}
      {hint ? <p className="mt-2 text-xs text-muted-foreground">{hint}</p> : null}
      {onRetry ? (
        <Button type="button" variant="outline" size="sm" className="mt-4" onClick={onRetry}>
          Try again
        </Button>
      ) : null}
    </div>
  );
}

export function DataTableShell({
  isLoading,
  error,
  isEmpty,
  emptyTitle,
  emptyDescription,
  emptyAction,
  emptyIcon,
  emptyIconClassName,
  onRetry,
  errorHint,
  children,
}: {
  isLoading: boolean;
  error: unknown;
  isEmpty: boolean;
  emptyTitle: string;
  emptyDescription?: string;
  emptyAction?: React.ReactNode;
  emptyIcon?: LucideIcon;
  emptyIconClassName?: string;
  onRetry?: () => void;
  errorHint?: string;
  children: React.ReactNode;
}) {
  if (error) {
    return (
      <QueryErrorState
        message={error instanceof Error ? error.message : String(error)}
        hint={errorHint}
        onRetry={onRetry}
      />
    );
  }
  if (isLoading) return <LoadingSpinner />;
  if (isEmpty) {
    return (
      <EmptyState
        title={emptyTitle}
        description={emptyDescription}
        action={emptyAction}
        icon={emptyIcon}
        iconClassName={emptyIconClassName}
      />
    );
  }
  return <>{children}</>;
}
