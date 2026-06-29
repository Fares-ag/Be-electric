import type { AppRole } from '@/lib/roles';

export const APP_ROLES = ['requestor', 'technician', 'manager', 'admin'] as const;

export function isValidAppRole(role: string): role is AppRole {
  return (APP_ROLES as readonly string[]).includes(role);
}

export type UserFormInput = {
  name?: string;
  email?: string;
  role: string;
  companyId?: string | null;
};

export function validateUserForm(input: UserFormInput, mode: 'create' | 'update'): string | null {
  if (!input.name?.trim()) return 'Name is required';
  if (mode === 'create' && !input.email?.trim()) return 'Email is required';
  if (!isValidAppRole(input.role)) return 'Invalid role';
  if (input.role === 'requestor' && !input.companyId?.trim()) {
    return 'Requestors must be assigned to a company';
  }
  return null;
}
