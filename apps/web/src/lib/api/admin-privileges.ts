import type { SupabaseClient } from '@supabase/supabase-js';

export type AdminFlags = { is_admin: boolean; is_manager: boolean };

/** True when caller may assign/update `role=admin` (admin_users.is_admin only). */
export async function callerIsAdmin(
  supabaseAuth: SupabaseClient,
  email: string
): Promise<boolean> {
  const { data, error } = await supabaseAuth.rpc('get_admin_by_email', {
    p_email: email,
  });
  if (error) return false;
  const row = (data as AdminFlags[] | null)?.[0];
  return !!row?.is_admin;
}

export async function assertCanAssignRole(
  supabaseAuth: SupabaseClient,
  callerEmail: string,
  role: string
): Promise<string | null> {
  if (role !== 'admin') return null;
  const ok = await callerIsAdmin(supabaseAuth, callerEmail);
  if (!ok) {
    return 'Only admins can assign the admin role';
  }
  return null;
}
