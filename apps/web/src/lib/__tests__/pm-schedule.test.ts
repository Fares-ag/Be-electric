import { describe, expect, it } from 'vitest';
import {
  computeDueDates,
  deriveOccurrenceStatus,
  previewOccurrences,
  scheduleEndDateFromDurationYears,
} from '@/lib/pm-schedule';

describe('pm-schedule', () => {
  it('computes quarterly dates across two years (8 occurrences)', () => {
    const dates = computeDueDates({
      frequency: 'quarterly',
      startDate: '2024-01-01',
      endDate: '2025-12-31',
    });
    expect(dates).toEqual([
      '2024-01-01',
      '2024-04-01',
      '2024-07-01',
      '2024-10-01',
      '2025-01-01',
      '2025-04-01',
      '2025-07-01',
      '2025-10-01',
    ]);
  });

  it('derives end date from duration in years', () => {
    expect(scheduleEndDateFromDurationYears('2024-01-01', 2)).toBe('2025-12-31');
  });

  it('previews occurrences for multiple assets', () => {
    const rows = previewOccurrences(['a1', 'a2'], {
      frequency: 'quarterly',
      startDate: '2024-01-01',
      endDate: '2024-12-31',
    });
    expect(rows).toHaveLength(8);
    expect(rows.filter((r) => r.assetId === 'a1')).toHaveLength(4);
    expect(rows.every((r) => r.status === 'pending')).toBe(true);
  });

  it('marks pending past-due occurrences as overdue client-side', () => {
    expect(deriveOccurrenceStatus('pending', '2020-01-01', '2026-06-27')).toBe('overdue');
    expect(deriveOccurrenceStatus('completed', '2020-01-01', '2026-06-27')).toBe('completed');
    expect(deriveOccurrenceStatus('pending', '2026-12-01', '2026-06-27')).toBe('pending');
  });

  it('returns single date for as-needed frequency', () => {
    expect(
      computeDueDates({
        frequency: 'asNeeded',
        startDate: '2024-06-01',
        endDate: '2025-06-01',
      })
    ).toEqual(['2024-06-01']);
  });
});
