import { describe, expect, it } from 'vitest';
import {
  computeDueDates,
  deriveOccurrenceStatus,
  buildOccurrenceMonthBuckets,
  isUpcomingOccurrence,
  matchesOccurrenceStatusFilter,
  previewOccurrences,
  scheduleEndDateFromDurationYears,
  summarizeOccurrenceStats,
  validateCancelReason,
  validateCompletionNotes,
  validateRescheduleDueDate,
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
    expect(deriveOccurrenceStatus('pending', '2026-12-01', '2026-06-27')).toBe('upcoming');
  });

  it('detects upcoming occurrences for admin filters', () => {
    expect(isUpcomingOccurrence('pending', '2026-06-27', '2026-06-27')).toBe(true);
    expect(isUpcomingOccurrence('pending', '2026-06-26', '2026-06-27')).toBe(false);
    expect(isUpcomingOccurrence('completed', '2026-12-01', '2026-06-27')).toBe(false);
    expect(matchesOccurrenceStatusFilter('upcoming', 'pending', '2026-12-01', '2026-06-27')).toBe(
      true
    );
    expect(matchesOccurrenceStatusFilter('overdue', 'pending', '2020-01-01', '2026-06-27')).toBe(
      true
    );
  });

  it('validates completion, cancel, and reschedule inputs', () => {
    expect(validateCompletionNotes('ok')).toBeNull();
    expect(validateCancelReason('')).toMatch(/required/i);
    expect(validateRescheduleDueDate('2026-06-26', '2026-06-27')).toMatch(/past/i);
    expect(validateRescheduleDueDate('2026-06-27', '2026-06-27')).toBeNull();
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

  it('summarizes occurrence stats by derived status', () => {
    const stats = summarizeOccurrenceStats(
      [
        { status: 'pending', dueDate: '2026-12-01' },
        { status: 'pending', dueDate: '2020-01-01' },
        { status: 'completed', dueDate: '2024-01-01' },
        { status: 'cancelled', dueDate: '2024-06-01' },
      ],
      '2026-06-27'
    );
    expect(stats.total).toBe(4);
    expect(stats.upcoming).toBe(1);
    expect(stats.overdue).toBe(1);
    expect(stats.completed).toBe(1);
    expect(stats.cancelled).toBe(1);
  });

  it('builds monthly buckets for workload strip', () => {
    const buckets = buildOccurrenceMonthBuckets([
      { status: 'pending', dueDate: '2026-06-15' },
      { status: 'pending', dueDate: '2026-06-29' },
      { status: 'pending', dueDate: '2026-07-10' },
    ]);
    expect(buckets).toHaveLength(2);
    expect(buckets[0].count).toBe(2);
    expect(buckets[1].count).toBe(1);
  });
});
