import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';

type UserEntry = { id: string; name: string; role?: string; email?: string };

/**
 * Fetches users via the SECURITY DEFINER `get_users_list` RPC (bypasses
 * table-level GRANTs and RLS) and returns a lookup map keyed by user id.
 */
export function useUsersMap(enabled = true) {
  const query = useQuery({
    queryKey: ['users-list'],
    queryFn: async (): Promise<UserEntry[]> => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any -- RPC exists in DB, may not be in generated types
      const { data, error } = await (supabase as any).rpc('get_users_list');
      if (error) throw error;
      return ((data ?? []) as Record<string, unknown>[]).map((u) => ({
        id: String(u.id),
        name: String(u.name ?? ''),
        role: u.role ? String(u.role) : undefined,
        email: u.email ? String(u.email) : undefined,
      }));
    },
    staleTime: 60_000,
    enabled,
  });

  const map = new Map<string, UserEntry>();
  if (query.data) {
    for (const u of query.data) map.set(u.id, u);
  }

  return { users: query.data ?? [], usersMap: map, ...query };
}
