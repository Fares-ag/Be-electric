'use client';

import { useState } from 'react';
import { Download } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { downloadCsv, rowsToCsv } from '@/lib/export-csv';

type ExportCsvButtonProps = {
  filename: string;
  headers: readonly string[];
  getRows: () => Promise<Record<string, unknown>[]> | Record<string, unknown>[];
  label?: string;
  disabled?: boolean;
  variant?: 'primary' | 'outline' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
};

export function ExportCsvButton({
  filename,
  headers,
  getRows,
  label = 'Export CSV',
  disabled,
  variant = 'outline',
  size = 'sm',
}: ExportCsvButtonProps) {
  const [exporting, setExporting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleExport() {
    if (exporting) return;
    setExporting(true);
    setError(null);
    try {
      const rows = await getRows();
      const csv = rowsToCsv([...headers], rows);
      downloadCsv(filename, csv);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Export failed');
    } finally {
      setExporting(false);
    }
  }

  return (
    <div className="flex flex-col items-end gap-1">
      <Button
        type="button"
        variant={variant}
        size={size}
        disabled={disabled || exporting}
        onClick={handleExport}
        className="gap-1.5"
      >
        <Download className="h-4 w-4" aria-hidden />
        {exporting ? 'Exporting…' : label}
      </Button>
      {error ? (
        <p className="text-xs text-destructive" role="alert">
          {error}
        </p>
      ) : null}
    </div>
  );
}
