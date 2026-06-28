'use client';

import { useEffect } from 'react';
import { Button } from '@/components/ui/Button';

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    if (process.env.NODE_ENV === 'development') {
      console.error(error);
    }
  }, [error]);

  return (
    <html lang="en">
      <body className="flex min-h-screen flex-col items-center justify-center gap-4 bg-stone-50 px-4 text-center font-sans">
        <h1 className="text-xl font-semibold text-stone-900">Application error</h1>
        <p className="max-w-md text-sm text-stone-600">
          A critical error occurred. Please refresh the page or try again later.
        </p>
        <button
          type="button"
          onClick={reset}
          className="rounded-lg bg-green-950 px-4 py-2 text-sm font-medium text-white hover:bg-green-900"
        >
          Try again
        </button>
      </body>
    </html>
  );
}
