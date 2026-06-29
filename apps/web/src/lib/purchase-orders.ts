export const PURCHASE_ORDER_STATUSES = ['draft', 'submitted', 'ordered', 'received'] as const;

export type PurchaseOrderStatus = (typeof PURCHASE_ORDER_STATUSES)[number];

export type PurchaseOrderRow = {
  id: string;
  orderNumber: string | null;
  status: string;
  orderedItems: unknown;
  requestedBy: string;
  createdAt: string;
  orderedAt?: string | null;
  receivedAt?: string | null;
  updatedAt?: string | null;
};

/** Procurement workflow: draft → submitted → ordered → received. */
export const PURCHASE_ORDER_STATUS_TRANSITIONS: Record<
  PurchaseOrderStatus,
  readonly PurchaseOrderStatus[]
> = {
  draft: ['draft', 'submitted'],
  submitted: ['submitted', 'ordered', 'draft'],
  ordered: ['ordered', 'received'],
  received: ['received'],
};

export function allowedPurchaseOrderStatuses(current: string | null | undefined): PurchaseOrderStatus[] {
  if (!current) return [...PURCHASE_ORDER_STATUSES];
  const allowed = PURCHASE_ORDER_STATUS_TRANSITIONS[current as PurchaseOrderStatus];
  return allowed ? [...allowed] : [...PURCHASE_ORDER_STATUSES];
}

export function isAllowedPurchaseOrderStatusTransition(from: string, to: string): boolean {
  if (from === to) return true;
  const allowed = PURCHASE_ORDER_STATUS_TRANSITIONS[from as PurchaseOrderStatus];
  return allowed ? allowed.includes(to as PurchaseOrderStatus) : false;
}

export function formatPurchaseOrderLabel(value: string): string {
  return value.replace(/([A-Z])/g, ' $1').trim();
}
