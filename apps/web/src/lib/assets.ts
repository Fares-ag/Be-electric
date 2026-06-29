export const ASSET_STATUSES = ['active', 'inactive', 'maintenance'] as const;

export type AssetStatus = (typeof ASSET_STATUSES)[number];

export function isValidAssetStatus(status: string): status is AssetStatus {
  return (ASSET_STATUSES as readonly string[]).includes(status);
}

export function validateAssetForm(input: { name?: string; status?: string }): string | null {
  if (!input.name?.trim()) return 'Charger name is required';
  const status = input.status?.trim() || 'active';
  if (!isValidAssetStatus(status)) return 'Invalid status';
  return null;
}
