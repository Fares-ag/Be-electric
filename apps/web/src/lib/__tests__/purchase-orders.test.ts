import { describe, expect, it } from 'vitest';
import {
  allowedPurchaseOrderStatuses,
  isAllowedPurchaseOrderStatusTransition,
} from '@/lib/purchase-orders';

describe('purchase-orders', () => {
  it('allows forward procurement transitions', () => {
    expect(isAllowedPurchaseOrderStatusTransition('draft', 'submitted')).toBe(true);
    expect(isAllowedPurchaseOrderStatusTransition('submitted', 'ordered')).toBe(true);
    expect(isAllowedPurchaseOrderStatusTransition('ordered', 'received')).toBe(true);
  });

  it('blocks skipping workflow steps', () => {
    expect(isAllowedPurchaseOrderStatusTransition('draft', 'received')).toBe(false);
    expect(isAllowedPurchaseOrderStatusTransition('received', 'draft')).toBe(false);
  });

  it('limits status dropdown options by current status', () => {
    expect(allowedPurchaseOrderStatuses('ordered')).toEqual(['ordered', 'received']);
  });
});
