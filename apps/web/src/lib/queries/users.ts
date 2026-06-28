import { supabase } from '@/lib/supabase';

export const USERS_LIST_QUERY_KEY = ['users-list'] as const;

export type UsersListEntry = {
  id: string;
  name: string;
  email: string;
  role: string;
  isActive: boolean;
  companyId: string | null;
  department: string | null;
};

export type UsersMapEntry = {
  id: string;
  name: string;
  role?: string;
  email?: string;
};

export function normalizeUserRow(r: Record<string, unknown>): UsersListEntry {
  return {
    id: String(r.id ?? ''),
    name: String(r.name ?? ''),
    email: String(r.email ?? ''),
    role: String(r.role ?? 'requestor'),
    isActive: r.isActive !== false && r.is_active !== false,
    companyId:
      r.companyId != null ? String(r.companyId) : r.company_id != null ? String(r.company_id) : null,
    department: r.department != null ? String(r.department) : null,
  };
}

export function toUsersMapEntry(row: UsersListEntry): UsersMapEntry {
  return {
    id: row.id,
    name: row.name,
    role: row.role,
    email: row.email,
  };
}

export async function fetchUsersList(): Promise<UsersListEntry[]> {
  const { data, error } = await supabase.rpc('get_users_list');
  if (error) throw error;
  return ((data ?? []) as Record<string, unknown>[]).map(normalizeUserRow);
}

export async function fetchUsersMapEntries(): Promise<UsersMapEntry[]> {
  const users = await fetchUsersList();
  return users.map(toUsersMapEntry);
}
