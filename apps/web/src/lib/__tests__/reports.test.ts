import { describe, expect, it } from 'vitest';
import { PM_OCCURRENCE_EXPORT_HEADERS, SUPPORT_REQUEST_EXPORT_HEADERS } from '@/lib/reports';

describe('reports', () => {
  it('defines PM occurrence export columns', () => {
    expect(PM_OCCURRENCE_EXPORT_HEADERS).toContain('derivedStatus');
    expect(PM_OCCURRENCE_EXPORT_HEADERS).toContain('chargerName');
  });

  it('defines support request export columns', () => {
    expect(SUPPORT_REQUEST_EXPORT_HEADERS).toContain('requesterEmail');
    expect(SUPPORT_REQUEST_EXPORT_HEADERS).toContain('createdAt');
  });
});
