import { describe, expect, it } from 'vitest';
import { manufacturerFromChargerName } from '@/lib/charger-manufacturer';

describe('charger-manufacturer', () => {
  it('maps KOS prefix to Kostad', () => {
    expect(manufacturerFromChargerName('KOS-123')).toBe('Kostad');
    expect(manufacturerFromChargerName('kos charger')).toBe('Kostad');
  });

  it('defaults non-KOS names to Siemens', () => {
    expect(manufacturerFromChargerName('ABB-001')).toBe('Siemens');
  });

  it('returns null for empty names', () => {
    expect(manufacturerFromChargerName('')).toBeNull();
  });
});
