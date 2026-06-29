import { describe, expect, it } from 'vitest';
import { isLowStockItem } from '@/lib/inventory';

describe('inventory', () => {
  it('flags items at or below minimum stock', () => {
    expect(
      isLowStockItem({
        id: '1',
        name: 'Fuse',
        category: null,
        currentStock: 2,
        minStock: 5,
        unit: null,
        sku: null,
        location: null,
        description: null,
      })
    ).toBe(true);
    expect(
      isLowStockItem({
        id: '2',
        name: 'Cable',
        category: null,
        currentStock: 10,
        minStock: 5,
        unit: null,
        sku: null,
        location: null,
        description: null,
      })
    ).toBe(false);
  });
});
