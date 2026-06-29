import { describe, expect, it } from 'vitest';
import {
  companyDeleteBlockReason,
  countRowsByCompanyId,
  validateCompanyForm,
} from '@/lib/companies';

describe('companies', () => {
  it('requires a company name', () => {
    expect(validateCompanyForm({ name: '  ' })).toContain('name');
    expect(validateCompanyForm({ name: 'Acme' })).toBeNull();
  });

  it('validates contact email format', () => {
    expect(validateCompanyForm({ name: 'Acme', contactEmail: 'not-an-email' })).toContain('email');
    expect(validateCompanyForm({ name: 'Acme', contactEmail: 'ops@acme.com' })).toBeNull();
  });

  it('blocks delete when users or chargers are linked', () => {
    expect(companyDeleteBlockReason({ users: 2, assets: 0 })).toContain('user');
    expect(companyDeleteBlockReason({ users: 0, assets: 3 })).toContain('charger');
    expect(companyDeleteBlockReason({ users: 0, assets: 0 })).toBeNull();
  });

  it('counts rows grouped by company id', () => {
    expect(
      countRowsByCompanyId([
        { companyId: 'c1' },
        { companyId: 'c1' },
        { companyId: 'c2' },
        { companyId: null },
      ])
    ).toEqual({ c1: 2, c2: 1 });
  });
});
