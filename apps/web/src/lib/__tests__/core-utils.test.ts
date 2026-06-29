import { describe, expect, it } from 'vitest';
import { computeAnalyticsMetrics, computePmOccurrenceStatusData } from '@/lib/analytics-metrics';
import { deriveOccurrenceStatus } from '@/lib/pm-schedule';
import { manufacturerFromChargerName } from '@/lib/charger-manufacturer';
import { rowsToCsv } from '@/lib/export-csv';
import {
  DEFAULT_NOTIFICATION_PREFERENCES,
  normalizeNotificationPreferences,
} from '@/lib/notification-preferences';
import {
  canRequestorReopen,
  collectRequestPhotos,
  collectCompletionPhotos,
  formatMaybeIso,
  getReopenCount,
  isAllowedAdminStatusTransition,
  isActiveWorkOrderStatus,
  isRequestorOpenStatus,
  metaPhotoPaths,
  parsePhotoPaths,
  parseReopenHistory,
} from '@/lib/work-order-detail';
import {
  canAccessRoute,
  defaultHomeForRole,
  isAdminRoute,
  isWorkOrderDetailRoute,
  redirectForUnauthorizedRoute,
  unauthorizedRouteMessage,
} from '@/lib/roles';

describe('charger-manufacturer', () => {
  it('assigns Kostad when charger name starts with KOS', () => {
    expect(manufacturerFromChargerName('KOS-123')).toBe('Kostad');
    expect(manufacturerFromChargerName('kos_charger_01')).toBe('Kostad');
  });

  it('assigns Siemens for all other charger names', () => {
    expect(manufacturerFromChargerName('SIE-001')).toBe('Siemens');
    expect(manufacturerFromChargerName('Charger A')).toBe('Siemens');
  });

  it('returns null for empty names', () => {
    expect(manufacturerFromChargerName('')).toBeNull();
    expect(manufacturerFromChargerName(null)).toBeNull();
  });
});

describe('export-csv', () => {
  it('escapes commas and quotes in cells', () => {
    const csv = rowsToCsv(['name', 'note'], [{ name: 'Acme', note: 'Say "hello", world' }]);
    expect(csv).toContain('"Say ""hello"", world"');
  });

  it('handles null values as empty cells', () => {
    const csv = rowsToCsv(['a'], [{ a: null }]);
    expect(csv).toBe('a\r\n');
  });
});

describe('roles', () => {
  it('allows admin on dashboard', () => {
    expect(canAccessRoute('/dashboard', 'admin')).toBe(true);
  });

  it('blocks requestor from admin users list', () => {
    expect(canAccessRoute('/users', 'requestor')).toBe(false);
  });

  it('allows requestor on work order detail only', () => {
    expect(canAccessRoute('/work-orders', 'requestor')).toBe(false);
    expect(canAccessRoute('/work-orders/abc-123', 'requestor')).toBe(true);
  });

  it('allows all web roles on shared notification settings', () => {
    expect(canAccessRoute('/notification-settings', 'admin')).toBe(true);
    expect(canAccessRoute('/notification-settings', 'requestor')).toBe(true);
  });

  it('redirects unauthorized requestor to my-requests', () => {
    expect(redirectForUnauthorizedRoute('/users', 'requestor')).toBe('/my-requests');
  });

  it('returns default homes by role', () => {
    expect(defaultHomeForRole('admin')).toBe('/dashboard');
    expect(defaultHomeForRole('requestor')).toBe('/my-requests');
  });

  it('identifies admin routes', () => {
    expect(isAdminRoute('/work-orders')).toBe(true);
    expect(isAdminRoute('/support-requests')).toBe(true);
    expect(isAdminRoute('/my-requests')).toBe(false);
  });

  it('explains unauthorized redirects for requestors', () => {
    expect(unauthorizedRouteMessage('/users', 'requestor')).toContain('administrators');
    expect(unauthorizedRouteMessage('/work-orders', 'requestor')).toContain('work order list');
  });
});

describe('work-order-detail', () => {
  it('detects work order detail paths', () => {
    expect(isWorkOrderDetailRoute('/work-orders/wo-1')).toBe(true);
    expect(isWorkOrderDetailRoute('/work-orders')).toBe(false);
  });

  it('reads reopen count from metadata aliases', () => {
    expect(getReopenCount({ reopenCount: 2 })).toBe(2);
    expect(getReopenCount({ reopen_count: 1 })).toBe(1);
  });

  it('parses reopen history from metadata aliases', () => {
    expect(parseReopenHistory(undefined)).toBeNull();
    expect(parseReopenHistory({ reopenCount: 0 })).toBeNull();
    expect(parseReopenHistory({ reopen_count: 2, reopened_at: '2024-06-01T12:00:00.000Z' })).toEqual({
      count: 2,
      reopenedAt: '2024-06-01T12:00:00.000Z',
      reopenedBy: null,
      reopenReason: null,
      previousStatus: null,
      previousCompletionDate: null,
    });
  });

  it('parses JSON photo path arrays', () => {
    expect(parsePhotoPaths('["a.jpg","b.jpg"]')).toHaveLength(2);
  });

  it('builds public URLs for storage paths in metadata', () => {
    process.env.NEXT_PUBLIC_SUPABASE_URL = 'https://example.supabase.co';
    const urls = metaPhotoPaths(
      { photoPaths: ['wo-1/request/photo.jpg'] },
      ['photoPaths']
    );
    expect(urls[0]).toContain('work-order-photos/wo-1/request/photo.jpg');
  });

  it('collects Flutter request photos from metadata.photoPaths and photoPath', () => {
    const photos = collectRequestPhotos('https://cdn.example/a.jpg', {
      photoPaths: ['https://cdn.example/a.jpg', 'https://cdn.example/b.jpg'],
    });
    expect(photos).toEqual(['https://cdn.example/a.jpg', 'https://cdn.example/b.jpg']);
  });

  it('collects Flutter completion photos from metadata.completionPhotoPaths', () => {
    const photos = collectCompletionPhotos('https://cdn.example/c1.jpg', {
      completionPhotoPaths: ['https://cdn.example/c1.jpg', 'https://cdn.example/c2.jpg'],
    });
    expect(photos).toEqual(['https://cdn.example/c1.jpg', 'https://cdn.example/c2.jpg']);
  });

  it('falls back to photoPath column when metadata.photoPaths is empty', () => {
    const photos = collectRequestPhotos('https://cdn.example/only.jpg', {});
    expect(photos).toEqual(['https://cdn.example/only.jpg']);
  });

  it('collects metadata photo paths', () => {
    expect(metaPhotoPaths({ photo_urls: ['http://x/1.png'] }, ['photo_urls'])).toEqual([
      'http://x/1.png',
    ]);
  });

  it('evaluates requestor reopen eligibility', () => {
    expect(
      canRequestorReopen(
        {
          id: '1',
          ticketNumber: 'WO-1',
          problemDescription: 'x',
          requestorId: 'u1',
          status: 'completed',
          priority: 'medium',
          createdAt: new Date().toISOString(),
          metadata: { reopenCount: 0 },
        },
        'u1',
        true
      )
    ).toBe(true);
  });

  it('allows reopen for closed and cancelled work orders', () => {
    const base = {
      id: '1',
      ticketNumber: 'WO-1',
      problemDescription: 'x',
      requestorId: 'u1',
      priority: 'medium' as const,
      createdAt: new Date().toISOString(),
      metadata: { reopenCount: 0 },
    };
    expect(canRequestorReopen({ ...base, status: 'closed' }, 'u1', true)).toBe(true);
    expect(canRequestorReopen({ ...base, status: 'cancelled' }, 'u1', true)).toBe(true);
    expect(canRequestorReopen({ ...base, status: 'open' }, 'u1', true)).toBe(false);
  });

  it('blocks invalid admin status transitions', () => {
    expect(isAllowedAdminStatusTransition('open', 'completed')).toBe(false);
    expect(isAllowedAdminStatusTransition('inProgress', 'completed')).toBe(true);
    expect(isAllowedAdminStatusTransition('completed', 'closed')).toBe(true);
  });

  it('treats reopened as active pipeline work', () => {
    expect(isActiveWorkOrderStatus('reopened')).toBe(true);
    expect(isActiveWorkOrderStatus('open')).toBe(false);
    expect(isRequestorOpenStatus('reopened')).toBe(true);
    expect(isRequestorOpenStatus('closed')).toBe(false);
  });

  it('formats ISO timestamps for display', () => {
    expect(formatMaybeIso(null)).toBe('—');
    expect(formatMaybeIso('2024-01-15T10:00:00.000Z')).not.toBe('—');
  });
});

describe('analytics-metrics', () => {
  it('computes completion rate and counts', () => {
    const metrics = computeAnalyticsMetrics(
      [
        {
          id: '1',
          status: 'open',
          priority: 'high',
          createdAt: '2024-01-01T00:00:00.000Z',
          completedAt: null,
          closedAt: null,
        },
        {
          id: '2',
          status: 'completed',
          priority: 'medium',
          createdAt: '2024-01-01T00:00:00.000Z',
          completedAt: '2024-01-03T00:00:00.000Z',
          closedAt: null,
        },
        {
          id: '3',
          status: 'reopened',
          priority: 'medium',
          createdAt: '2024-01-01T00:00:00.000Z',
          completedAt: null,
          closedAt: null,
        },
      ],
      [{ id: 'pm1', status: 'pending', nextDueDate: '2020-01-01' }],
      '2024-06-01'
    );

    expect(metrics.totalWorkOrders).toBe(3);
    expect(metrics.openCount).toBe(1);
    expect(metrics.inProgressCount).toBe(1);
    expect(metrics.completedCount).toBe(1);
    expect(metrics.completionRate).toBe(33);
    expect(metrics.overduePmCount).toBe(1);
    expect(metrics.mttrDays).toBeGreaterThan(0);
  });

  it('excludes cancelled work orders from completion rate', () => {
    const metrics = computeAnalyticsMetrics(
      [
        {
          id: '1',
          status: 'completed',
          priority: 'medium',
          createdAt: '2024-01-01T00:00:00.000Z',
          completedAt: '2024-01-03T00:00:00.000Z',
          closedAt: null,
        },
        {
          id: '2',
          status: 'cancelled',
          priority: 'medium',
          createdAt: '2024-01-01T00:00:00.000Z',
          completedAt: null,
          closedAt: null,
        },
      ],
      [],
      '2024-06-01'
    );
    expect(metrics.completionRate).toBe(100);
  });

  it('derives PM occurrence status buckets for charts', () => {
    const data = computePmOccurrenceStatusData(
      [
        { status: 'pending', dueDate: '2024-06-10' },
        { status: 'pending', dueDate: '2024-05-01' },
        { status: 'completed', dueDate: '2024-04-01' },
      ],
      deriveOccurrenceStatus,
      '2024-06-01'
    );
    const byName = Object.fromEntries(data.map((d) => [d.name, d.value]));
    expect(byName.pending).toBe(1);
    expect(byName.overdue).toBe(1);
    expect(byName.completed).toBe(1);
  });
});

describe('notification-preferences', () => {
  it('merges partial stored preferences with defaults', () => {
    expect(normalizeNotificationPreferences({ emailOnStatusChange: true })).toEqual({
      emailOnAssigned: DEFAULT_NOTIFICATION_PREFERENCES.emailOnAssigned,
      emailOnCompleted: DEFAULT_NOTIFICATION_PREFERENCES.emailOnCompleted,
      emailOnStatusChange: true,
    });
  });

  it('returns defaults for invalid input', () => {
    expect(normalizeNotificationPreferences(null)).toEqual(DEFAULT_NOTIFICATION_PREFERENCES);
  });
});
