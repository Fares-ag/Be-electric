import { supabase } from '@/lib/supabase';
import { profileRowToUser, validateProfileForAuth } from '@/lib/auth/profile-validation';

export { profileRowToUser, validateProfileForAuth };

export async function fetchUserProfileByEmail(
  email: string
): Promise<Record<string, unknown> | null> {
  const { data, error } = await supabase.rpc('get_user_by_email', { p_email: email.trim() });
  if (error) throw error;
  return (data?.[0] as Record<string, unknown>) ?? null;
}

export async function fetchUserProfileById(id: string): Promise<Record<string, unknown> | null> {
  const { data, error } = await supabase.rpc('get_user_by_id', { p_id: id });
  if (error) throw error;
  return (data?.[0] as Record<string, unknown>) ?? null;
}
