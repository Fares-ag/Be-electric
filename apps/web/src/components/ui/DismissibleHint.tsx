'use client';

import { useEffect, useState } from 'react';
import { Info, X } from 'lucide-react';
import { cn } from '@/lib/utils';
import { dismissUiHint, isUiHintDismissed, type UiHintKey } from '@/lib/ui-hints';

export function DismissibleHint({
  hintKey,
  title,
  children,
  className,
}: {
  hintKey: UiHintKey;
  title?: string;
  children: React.ReactNode;
  className?: string;
}) {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    setVisible(!isUiHintDismissed(hintKey));
  }, [hintKey]);

  if (!visible) return null;

  function handleDismiss() {
    dismissUiHint(hintKey);
    setVisible(false);
  }

  return (
    <div
      role="note"
      className={cn(
        'relative flex gap-3 rounded-lg border border-primary/20 bg-primary/5 px-4 py-3',
        className
      )}
    >
      <Info className="mt-0.5 h-5 w-5 shrink-0 text-primary" aria-hidden />
      <div className="min-w-0 flex-1 text-sm">
        {title ? <p className="font-medium text-foreground">{title}</p> : null}
        <div className={cn('text-muted-foreground', title && 'mt-1')}>{children}</div>
      </div>
      <button
        type="button"
        onClick={handleDismiss}
        className="flex h-8 w-8 shrink-0 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
        aria-label="Dismiss hint"
      >
        <X className="h-4 w-4" />
      </button>
    </div>
  );
}
