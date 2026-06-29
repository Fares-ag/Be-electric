import { describe, expect, it } from 'vitest';
import { isValidAssetStatus, validateAssetForm } from '@/lib/assets';

describe('assets', () => {
  it('accepts known asset statuses', () => {
    expect(isValidAssetStatus('active')).toBe(true);
    expect(isValidAssetStatus('retired')).toBe(false);
  });

  it('requires charger name and valid status', () => {
    expect(validateAssetForm({ name: '', status: 'active' })).toContain('name');
    expect(validateAssetForm({ name: 'KOS-001', status: 'bogus' })).toContain('status');
    expect(validateAssetForm({ name: 'KOS-001', status: 'maintenance' })).toBeNull();
  });
});
