export type InventoryItemRow = {
  id: string;
  name: string;
  category: string | null;
  currentStock: number;
  minStock: number | null;
  unit: string | null;
  sku: string | null;
  location: string | null;
  description: string | null;
};

export function inventoryStock(item: InventoryItemRow): number {
  return Number(item.currentStock ?? 0);
}

export function inventoryMinStock(item: InventoryItemRow): number | null {
  if (item.minStock == null) return null;
  return Number(item.minStock);
}

export function isLowStockItem(item: InventoryItemRow): boolean {
  const min = inventoryMinStock(item);
  if (min == null) return false;
  return inventoryStock(item) <= min;
}
