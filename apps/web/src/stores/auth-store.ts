import { create } from 'zustand';
import { supabase } from '@/lib/supabase';
import type { User } from '@beelectric/supabase';

interface AuthState {
  user: User | null;
  authUser: { id: string; email?: string; name?: string } | null;
  loading: boolean;
  setUser: (user: User | null) => void;
  signIn: (email: string, password: string) => Promise<{ error: Error | null }>;
  signOut: () => Promise<void>;
  fetchUser: (
    authId: string,
    fallback?: { email?: string; name?: string }
  ) => Promise<void>;
  init: () => Promise<void>;
}

function toUser(row: Record<string, unknown> | null): User | null {
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

async function createFallbackUser(
  authId: string,
  fallback: { email?: string; name?: string }
): Promise<User> {
  const email = fallback.email ?? '';
  const name = fallback.name ?? email.split('@')[0] ?? 'User';
  let role: User['role'] = 'requestor';
  const adminRole = await getAdminRoleByEmail(email);
  if (adminRole) role = adminRole;
  return {
    id: authId,
    email,
    name,
    role,
    department: null,
    companyId: null,
    isActive: true,
    createdAt: new Date().toISOString(),
  };
}

async function getAdminRoleByEmail(email: string): Promise<'admin' | 'manager' | null> {
  const { data } = await (supabase as any).rpc('get_admin_by_email', { p_email: email });
  const row = (data as { is_admin?: boolean; is_manager?: boolean }[] | null)?.[0];
  if (!row) return null;
  if (row.is_admin) return 'admin';
  if (row.is_manager) return 'manager';
  return null;
}

/** Fetches user row only (no admin role override). */
async function getUserByAuthIdOnly(authId: string): Promise<User | null> {
  const { data, error } = await (supabase as any).rpc('get_user_by_id', { p_id: authId });
  if (error) {
    console.warn('[auth] users table fetch failed:', error.message);
    return null;
  }
  const rows = data as Record<string, unknown>[] | null;
  const row = rows && rows.length > 0 ? rows[0] : null;
  return toUser(row);
}

async function getUserByAuthId(authId: string, _knownEmail?: string): Promise<User | null> {
  // Use role from public.users when present. admin_users is only used in createFallbackUser
  // when there is no row in users (e.g. first login or admin-only account).
  const dbUser = await getUserByAuthIdOnly(authId);
  return dbUser ?? null;
}

export const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  authUser: null,
  loading: true,

  setUser: (user) => set({ user }),

  signIn: async (email, password) => {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    if (error) return { error };

    if (data.user) {
      const authUser = {
        id: data.user.id,
        email: data.user.email ?? undefined,
        name: data.user.user_metadata?.name ?? data.user.email?.split('@')[0],
      };
      set({ authUser });
      await get().fetchUser(data.user.id, {
        email: data.user.email ?? undefined,
        name: authUser.name,
      });
    }
    return { error: null };
  },

  signOut: async () => {
    await supabase.auth.signOut();
    set({ user: null, authUser: null });
  },

  fetchUser: async (authId, fallback) => {
    const knownEmail = fallback?.email;
    const dbUser = await getUserByAuthId(authId, knownEmail);
    const user = dbUser ?? (fallback ? await createFallbackUser(authId, fallback) : null);
    set({ user });
  },

  init: async () => {
    try {
      const {
        data: { session },
      } = await supabase.auth.getSession();

      if (session?.user) {
        const authUser = {
          id: session.user.id,
          email: session.user.email ?? undefined,
          name:
            session.user.user_metadata?.name ?? session.user.email?.split('@')[0],
        };
        set({ authUser });
        await get().fetchUser(session.user.id, {
          email: session.user.email ?? undefined,
          name: authUser.name,
        });
      } else {
        set({ user: null, authUser: null });
      }
    } catch (e) {
      console.warn('[auth] init failed:', e);
      set({ user: null, authUser: null });
    } finally {
      set({ loading: false });
    }
  },
}));
