'use client';

import { Button } from '@/components/ui/Button';
import { Modal, ModalActions } from '@/components/ui/Modal';
import { MAX_REOPEN_COUNT } from '@/lib/work-order-detail';

type StatusModalProps = {
  open: boolean;
  target: string | null;
  reason: string;
  reasonError: string | null;
  pending: boolean;
  onReasonChange: (value: string) => void;
  onClose: () => void;
  onConfirm: () => void;
};

export function WorkOrderStatusModal({
  open,
  target,
  reason,
  reasonError,
  pending,
  onReasonChange,
  onClose,
  onConfirm,
}: StatusModalProps) {
  const label = target ? target.replace(/([A-Z])/g, ' $1').trim() : '';

  return (
    <Modal open={open} onClose={onClose} title={target ? `Reason for ${label}` : ''}>
      {target && (
        <>
          <div className="space-y-4">
            <p className="text-sm text-muted-foreground">
              Please provide a reason for changing the status to &quot;{label}&quot;.
            </p>
            <div>
              <label className="mb-1.5 block text-sm font-medium text-foreground">
                Reason <span className="text-destructive">*</span>
              </label>
              <textarea
                value={reason}
                onChange={(e) => onReasonChange(e.target.value)}
                placeholder="At least 10 characters"
                rows={3}
                className="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary/20"
              />
            </div>
            {reasonError && <p className="text-sm text-destructive">{reasonError}</p>}
          </div>
          <ModalActions>
            <Button variant="outline" onClick={onClose}>
              Cancel
            </Button>
            <Button onClick={onConfirm} disabled={pending || reason.trim().length < 10}>
              {pending ? 'Updating…' : 'Update status'}
            </Button>
          </ModalActions>
        </>
      )}
    </Modal>
  );
}

type ReopenModalProps = {
  open: boolean;
  reopenCount: number;
  reason: string;
  description: string;
  error: string | null;
  pending: boolean;
  onReasonChange: (value: string) => void;
  onDescriptionChange: (value: string) => void;
  onClose: () => void;
  onConfirm: () => void;
};

export function WorkOrderReopenModal({
  open,
  reopenCount,
  reason,
  description,
  error,
  pending,
  onReasonChange,
  onDescriptionChange,
  onClose,
  onConfirm,
}: ReopenModalProps) {
  const left = MAX_REOPEN_COUNT - reopenCount;

  return (
    <Modal open={open} onClose={onClose} title="Reopen work order">
      <div className="space-y-4">
        <p className="text-sm text-muted-foreground">
          This will set the work order back to &quot;Reopened&quot; and clear assignments. You have {left}{' '}
          reopen{left === 1 ? '' : 's'} left.
        </p>
        <div>
          <label className="mb-1.5 block text-sm font-medium text-foreground">
            Reason for reopening <span className="text-destructive">*</span>
          </label>
          <textarea
            value={reason}
            onChange={(e) => onReasonChange(e.target.value)}
            placeholder="At least 10 characters"
            rows={3}
            className="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary/20"
          />
        </div>
        <div>
          <label className="mb-1.5 block text-sm font-medium text-foreground">
            Updated problem description (optional)
          </label>
          <textarea
            value={description}
            onChange={(e) => onDescriptionChange(e.target.value)}
            placeholder="Leave blank to keep current description"
            rows={2}
            className="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary/20"
          />
        </div>
        {error && <p className="text-sm text-destructive">{error}</p>}
      </div>
      <ModalActions>
        <Button variant="outline" onClick={onClose}>
          Cancel
        </Button>
        <Button onClick={onConfirm} disabled={reason.trim().length < 10 || pending}>
          {pending ? 'Reopening…' : 'Reopen'}
        </Button>
      </ModalActions>
    </Modal>
  );
}
