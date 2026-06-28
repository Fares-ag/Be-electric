import { useCallback, useState } from 'react';

/** Prevents duplicate form submissions while an async handler runs. */
export function useFormSubmitLock() {
  const [submitting, setSubmitting] = useState(false);

  const runSubmit = useCallback(async (fn: () => Promise<void> | void) => {
    if (submitting) return;
    setSubmitting(true);
    try {
      await fn();
    } finally {
      setSubmitting(false);
    }
  }, [submitting]);

  return { submitting, runSubmit, setSubmitting };
}
