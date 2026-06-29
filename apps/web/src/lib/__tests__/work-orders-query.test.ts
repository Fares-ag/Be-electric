import { describe, expect, it } from 'vitest';
import { ACTIVE_WORK_ORDER_STATUSES } from '@/lib/work-order-detail';

describe('work-orders query filters', () => {
  it('includes reopened in active status filter set', () => {
    expect(ACTIVE_WORK_ORDER_STATUSES).toContain('reopened');
    expect(ACTIVE_WORK_ORDER_STATUSES).toEqual(['assigned', 'inProgress', 'reopened']);
  });
});
