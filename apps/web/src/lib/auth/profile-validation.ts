import type { User } from '@beelectric/supabase';

export function profileRowToUser(row: Record<string, unknown> | null): User | null {
  if (!row || !row.id) return null;
  return {
    id: String(row.id),
    email: String(row.email ?? ''),
    name: String(row.name ?? row.email ?? 'User'),
    role: (row.role as User['role']) ?? 'requestor',
    department: row.department ? String(row.department) : null,
    companyId: row.companyId ?? row.company_id ? String(row.companyId ?? row.company_id) : null,
    isActive: row.isActive !== false && row.is_active !== false,
    createdAt: String(row.createdAt ?? row.created_at ?? new Date().toISOString()),
    updatedAt: row.updatedAt ?? row.updated_at ? String(row.updatedAt ?? row.updated_at) : undefined,
  };
}

export function validateProfileForAuth(
  row: Record<string, unknown> | null,
  authUserId: string
): { ok: true } | { ok: false; message: string } {
  if (!row?.id) {
    return { ok: false, message: 'No profile found. Contact your administrator.' };
  }
  if (String(row.id) !== authUserId) {
    return { ok: false, message: 'Profile mismatch. Contact your administrator.' };
  }
  if (row.isActive === false || row.is_active === false) {
    return {
      ok: false,
      message: 'Your account has been deactivated. Contact your administrator.',
    };
  }
  return { ok: true };
}
