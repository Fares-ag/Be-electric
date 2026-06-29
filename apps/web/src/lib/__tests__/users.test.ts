import { describe, expect, it } from 'vitest';
import { isValidAppRole, validateUserForm } from '@/lib/users';

describe('users', () => {
  it('accepts known app roles', () => {
    expect(isValidAppRole('requestor')).toBe(true);
    expect(isValidAppRole('admin')).toBe(true);
    expect(isValidAppRole('superuser')).toBe(false);
  });

  it('requires company for requestors', () => {
    expect(
      validateUserForm(
        { name: 'Pat', email: 'pat@example.com', role: 'requestor', companyId: '' },
        'create'
      )
    ).toContain('company');
    expect(
      validateUserForm(
        { name: 'Pat', email: 'pat@example.com', role: 'requestor', companyId: 'co-1' },
        'create'
      )
    ).toBeNull();
  });

  it('allows staff without company', () => {
    expect(
      validateUserForm({ name: 'Tech', role: 'technician', companyId: null }, 'update')
    ).toBeNull();
  });
});
