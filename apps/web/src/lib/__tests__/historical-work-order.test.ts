import { describe, expect, it } from 'vitest';
import {
  buildHistoricalWorkOrderInsert,
  generateHistoricalTicketNumber,
  validateHistoricalWorkOrderInput,
  workOrderCompanyName,
} from '@/lib/historical-work-order';

const NOW = new Date('2026-06-15T12:00:00.000Z');

const baseInput = {
  problemDescription: 'Historical pump failure',
  status: 'closed' as const,
  priority: 'medium',
  requestorId: 'req-1',
  requestorName: 'Test Requestor',
  companyId: 'company-1',
  assetId: 'asset-1',
  createdAtLocal: '2025-03-01T09:00',
  completedAtLocal: '2025-03-02T14:00',
  closedAtLocal: '2025-03-03T10:00',
  recordedById: 'admin-1',
};

describe('historical-work-order', () => {
  it('validates a closed historical record', () => {
    expect(validateHistoricalWorkOrderInput(baseInput, NOW)).toBeNull();
  });

  it('defaults closedAt from completed when closed status omits closedAt', () => {
    const payload = buildHistoricalWorkOrderInsert(
      {
        ...baseInput,
        closedAtLocal: '',
      },
      NOW
    );
    expect(payload.closedAt).toBe(payload.completedAt);
  });

  it('rejects future created date', () => {
    expect(
      validateHistoricalWorkOrderInput(
        { ...baseInput, createdAtLocal: '2026-12-01T09:00' },
        NOW
      )
    ).toMatch(/past/i);
  });

  it('rejects completed before created', () => {
    expect(
      validateHistoricalWorkOrderInput(
        {
          ...baseInput,
          createdAtLocal: '2025-03-05T09:00',
          completedAtLocal: '2025-03-01T14:00',
        },
        NOW
      )
    ).toMatch(/before created/i);
  });

  it('builds assignee fields when technicians selected', () => {
    const payload = buildHistoricalWorkOrderInsert(
      {
        ...baseInput,
        assignedTechnicianIds: ['tech-1', 'tech-2'],
      },
      NOW
    );
    expect(payload.assignedTechnicianIds).toEqual(['tech-1', 'tech-2']);
    expect(payload.primaryTechnicianId).toBe('tech-1');
    expect(payload.assignedAt).toBe(payload.completedAt);
    expect(payload.metadata.source).toBe('historical_admin');
  });

  it('generates ticket numbers with WO-HIST prefix', () => {
    expect(generateHistoricalTicketNumber(NOW)).toMatch(/^WO-HIST-20260615-/);
  });

  it('formats company name from embed', () => {
    expect(workOrderCompanyName({ company: { name: 'Oasis Mall' } })).toBe('Oasis Mall');
    expect(workOrderCompanyName({ company: null })).toBe('—');
  });
});
