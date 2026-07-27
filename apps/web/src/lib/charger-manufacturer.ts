export type ChargerManufacturer = 'Kostad' | 'Siemens';

/**
 * Charger manufacturer rule (shared with Flutter + Supabase trigger):
 * - Name starts with KOS (case-insensitive) → Kostad
 * - Otherwise → Siemens only if serial number starts with KOS
 */
export function manufacturerFromChargerName(
  name: string | null | undefined,
  serialNumber?: string | null | undefined
): ChargerManufacturer | null {
  const trimmedName = name?.trim();
  if (!trimmedName) return null;

  if (trimmedName.toUpperCase().startsWith('KOS')) {
    return 'Kostad';
  }

  const trimmedSerial = serialNumber?.trim();
  if (trimmedSerial && trimmedSerial.toUpperCase().startsWith('KOS')) {
    return 'Siemens';
  }

  return null;
}
