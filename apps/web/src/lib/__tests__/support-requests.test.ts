import { describe, expect, it } from 'vitest';
import {
  allowedSupportStatuses,
  filterSupportRequests,
  formatSupportLabel,
  isAllowedSupportStatusTransition,
  matchesSupportDateRange,
  matchesSupportSearch,
  parseSupportAttachments,
  type SupportRequestListRow,
} from '@/lib/support-requests';

const sampleRows: SupportRequestListRow[] = [
  {
    id: '1',
    type: 'knowHow',
    status: 'submitted',
    summary: 'How to reset charger',
    createdBy: 'u1',
    companyId: 'c1',
    createdAt: '2024-06-15T10:00:00.000Z',
    company: { name: 'Acme Energy' },
    requester: { name: 'Alex Requestor', email: 'alex@example.com' },
  },
  {
    id: '2',
    type: 'commissioning',
    status: 'resolved',
    summary: 'Site commissioning request',
    createdBy: 'u2',
    companyId: 'c2',
    createdAt: '2024-06-20T10:00:00.000Z',
    company: { name: 'Beta Power' },
    requester: { name: 'Sam User', email: 'sam@example.com' },
  },
];

describe('support-requests', () => {
  it('formats labels for display', () => {
    expect(formatSupportLabel('knowHow')).toBe('Know How');
    expect(formatSupportLabel('in_progress')).toBe('In Progress');
  });

  it('parses attachment payloads', () => {
    expect(
      parseSupportAttachments([
        { url: 'https://cdn.example/a.jpg', fileName: 'photo.jpg' },
        'https://cdn.example/b.jpg',
      ])
    ).toEqual([
      { url: 'https://cdn.example/a.jpg', fileName: 'photo.jpg' },
      { url: 'https://cdn.example/b.jpg' },
    ]);
  });

  it('matches search text across summary and requester fields', () => {
    expect(matchesSupportSearch(sampleRows[0], 'alex')).toBe(true);
    expect(matchesSupportSearch(sampleRows[0], 'commissioning')).toBe(false);
  });

  it('matches created date ranges', () => {
    expect(matchesSupportDateRange('2024-06-15T10:00:00.000Z', '2024-06-01', '2024-06-18')).toBe(true);
    expect(matchesSupportDateRange('2024-06-15T10:00:00.000Z', '2024-06-16', undefined)).toBe(false);
  });

  it('filters by status, company, type, and date', () => {
    const filtered = filterSupportRequests(sampleRows, {
      status: 'submitted',
      companyId: 'c1',
      type: 'knowHow',
      dateFrom: '2024-06-01',
      dateTo: '2024-06-30',
      search: 'reset',
    });
    expect(filtered).toHaveLength(1);
    expect(filtered[0]?.summary).toBe('How to reset charger');
  });

  it('limits support status options by current status', () => {
    expect(allowedSupportStatuses('submitted')).toEqual([
      'submitted',
      'in_progress',
      'resolved',
      'closed',
    ]);
    expect(allowedSupportStatuses('closed')).toEqual(['closed', 'in_progress']);
  });

  it('blocks invalid support status transitions', () => {
    expect(isAllowedSupportStatusTransition('submitted', 'in_progress')).toBe(true);
    expect(isAllowedSupportStatusTransition('closed', 'resolved')).toBe(false);
  });
});
