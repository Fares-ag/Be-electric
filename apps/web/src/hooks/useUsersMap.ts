import { useQuery } from '@tanstack/react-query';
import {
  USERS_LIST_QUERY_KEY,
  fetchUsersList,
  toUsersMapEntry,
  type UsersMapEntry,
} from '@/lib/queries/users';

/**
 * Fetches users via the SECURITY DEFINER `get_users_list` RPC (bypasses
 * table-level GRANTs and RLS) and returns a lookup map keyed by user id.
 */
export function useUsersMap(enabled = true) {
  const query = useQuery({
    queryKey: USERS_LIST_QUERY_KEY,
    queryFn: async (): Promise<UsersMapEntry[]> => {
      const users = await fetchUsersList();
      return users.map(toUsersMapEntry);
    },
    staleTime: 60_000,
    enabled,
  });

  const map = new Map<string, UsersMapEntry>();
  if (query.data) {
    for (const u of query.data) map.set(u.id, u);
  }

  return { users: query.data ?? [], usersMap: map, ...query };
}
