import { describe, expect, it } from 'vitest';
import { manufacturerFromChargerName } from '@/lib/charger-manufacturer';

describe('charger-manufacturer', () => {
  it('maps KOS prefix name to Kostad', () => {
    expect(manufacturerFromChargerName('KOS-123')).toBe('Kostad');
    expect(manufacturerFromChargerName('kos charger')).toBe('Kostad');
  });

  it('maps non-KOS name to Siemens when serial starts with KOS', () => {
    expect(manufacturerFromChargerName('SIE-001', 'KOS-001')).toBe('Siemens');
    expect(manufacturerFromChargerName('Charger A', 'kos123')).toBe('Siemens');
  });

  it('returns null for non-KOS name without KOS serial', () => {
    expect(manufacturerFromChargerName('ABB-001')).toBeNull();
    expect(manufacturerFromChargerName('Charger A', 'SN-001')).toBeNull();
    expect(manufacturerFromChargerName('Charger A', '')).toBeNull();
  });

  it('returns null for empty names', () => {
    expect(manufacturerFromChargerName('')).toBeNull();
    expect(manufacturerFromChargerName(null)).toBeNull();
  });
});
