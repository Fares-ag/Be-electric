export type ChargerManufacturer = 'Kostad' | 'Siemens';

/** Kostad chargers are named with a KOS prefix; all others are Siemens. */
export function manufacturerFromChargerName(name: string | null | undefined): ChargerManufacturer | null {
  const trimmed = name?.trim();
  if (!trimmed) return null;
  return trimmed.toUpperCase().startsWith('KOS') ? 'Kostad' : 'Siemens';
}
