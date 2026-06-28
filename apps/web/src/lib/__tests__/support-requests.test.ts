import { describe, expect, it } from 'vitest';
import {
  filterSupportRequests,
  formatSupportLabel,
  matchesSupportDateRange,
  matchesSupportSearch,
  parseSubmittedFields,
  parseSupportAttachments,
  type SupportRequestListRow,
} from '@/lib/support-requests';

const sampleRows: SupportRequestListRow[] = [
  {
    id: '1',
    ticketNumber: 'SR-001',
    type: 'technical',
    status: 'open',
    subject: 'Login issue',
    requesterId: 'u1',
    requesterName: 'Alex Requestor',
    requesterEmail: 'alex@example.com',
    companyId: 'c1',
    submittedAt: '2024-06-15T10:00:00.000Z',
    updatedAt: '2024-06-15T10:00:00.000Z',
    company: { name: 'Acme Energy' },
  },
  {
    id: '2',
    ticketNumber: 'SR-002',
    type: 'billing',
    status: 'resolved',
    subject: 'Invoice question',
    requesterId: 'u2',
    requesterName: 'Sam User',
    requesterEmail: 'sam@example.com',
    companyId: 'c2',
    submittedAt: '2024-06-20T10:00:00.000Z',
    updatedAt: '2024-06-21T10:00:00.000Z',
    company: { name: 'Beta Power' },
  },
];

describe('support-requests', () => {
  it('formats labels for display', () => {
    expect(formatSupportLabel('waiting_on_customer')).toBe('Waiting On Customer');
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

  it('parses submitted field objects', () => {
    expect(parseSubmittedFields({ appVersion: '1.2.3' })).toEqual({ appVersion: '1.2.3' });
    expect(parseSubmittedFields(null)).toEqual({});
  });

  it('matches search text across ticket and requester fields', () => {
    expect(matchesSupportSearch(sampleRows[0], 'alex')).toBe(true);
    expect(matchesSupportSearch(sampleRows[0], 'invoice')).toBe(false);
  });

  it('matches submitted date ranges', () => {
    expect(matchesSupportDateRange('2024-06-15T10:00:00.000Z', '2024-06-01', '2024-06-18')).toBe(true);
    expect(matchesSupportDateRange('2024-06-15T10:00:00.000Z', '2024-06-16', undefined)).toBe(false);
  });

  it('filters by status, company, type, and date', () => {
    const filtered = filterSupportRequests(sampleRows, {
      status: 'open',
      companyId: 'c1',
      type: 'technical',
      dateFrom: '2024-06-01',
      dateTo: '2024-06-30',
      search: 'login',
    });
    expect(filtered).toHaveLength(1);
    expect(filtered[0]?.ticketNumber).toBe('SR-001');
  });
});
