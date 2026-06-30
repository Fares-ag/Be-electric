import { describe, expect, it } from 'vitest';
import { formatWorkOrderPriority, workOrderPriorityVariant } from '@/lib/work-order-list';

describe('work-order-list', () => {
  it('maps priority to badge variants', () => {
    expect(workOrderPriorityVariant('high')).toBe('destructive');
    expect(workOrderPriorityVariant('low')).toBe('secondary');
    expect(workOrderPriorityVariant('medium')).toBe('warning');
  });

  it('formats priority labels', () => {
    expect(formatWorkOrderPriority('high')).toBe('high');
  });
});
