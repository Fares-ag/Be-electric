'use client';

import { useEffect } from 'react';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/Button';

interface ModalProps {
  open: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
  className?: string;
}

export function Modal({ open, onClose, title, children, className }: ModalProps) {
  useEffect(() => {
    if (open) document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = '';
    };
  }, [open]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        aria-hidden
        onClick={onClose}
      />
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="modal-title"
        className={cn(
          'relative z-10 w-full max-w-md rounded-xl border border-border bg-card p-6 shadow-lg',
          className
        )}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between mb-4">
          <h2 id="modal-title" className="font-display text-lg font-semibold text-foreground">
            {title}
          </h2>
          <Button variant="ghost" size="sm" onClick={onClose} type="button" className="text-muted-foreground hover:text-foreground">
            ✕
          </Button>
        </div>
        {children}
      </div>
    </div>
  );
}

interface ModalActionsProps {
  children: React.ReactNode;
  className?: string;
}

export function ModalActions({ children, className }: ModalActionsProps) {
  return (
    <div className={cn('mt-6 flex justify-end gap-2', className)}>
      {children}
    </div>
  );
}
