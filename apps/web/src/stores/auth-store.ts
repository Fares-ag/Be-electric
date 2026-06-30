import { create } from 'zustand';
import { supabase } from '@/lib/supabase';
import type { User } from '@beelectric/supabase';
import { setAuthFlash } from '@/lib/auth-flash';
import {
  fetchUserProfileByEmail,
  fetchUserProfileById,
  profileRowToUser,
  validateProfileForAuth,
} from '@/lib/auth/profile';

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
  ) => Promise<{ error: string | null }>;
  init: () => Promise<void>;
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
  const { data } = await supabase.rpc('get_admin_by_email', { p_email: email });
  const row = data?.[0];
  if (!row) return null;
  if (row.is_admin) return 'admin';
  if (row.is_manager) return 'manager';
  return null;
}

async function resolveProfileUser(
  authId: string,
  fallback?: { email?: string; name?: string }
): Promise<{ user: User | null; error: string | null }> {
  const email = fallback?.email?.trim();

  if (email) {
    try {
      const row = await fetchUserProfileByEmail(email);
      const validation = validateProfileForAuth(row, authId);
      if (!validation.ok) {
        return { user: null, error: validation.message };
      }
      return { user: profileRowToUser(row), error: null };
    } catch (e) {
      if (process.env.NODE_ENV === 'development') {
        console.warn('[auth] get_user_by_email failed:', e);
      }
    }
  }

  try {
    const row = await fetchUserProfileById(authId);
    const validation = validateProfileForAuth(row, authId);
    if (validation.ok) {
      return { user: profileRowToUser(row), error: null };
    }
    if (row && !validation.ok) {
      return { user: null, error: validation.message };
    }
  } catch (e) {
    if (process.env.NODE_ENV === 'development') {
      console.warn('[auth] get_user_by_id failed:', e);
    }
  }

  if (fallback?.email) {
    const adminRole = await getAdminRoleByEmail(fallback.email);
    if (adminRole) {
      return { user: await createFallbackUser(authId, fallback), error: null };
    }
  }

  return { user: null, error: 'No profile found. Contact your administrator.' };
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
      const { error: profileError } = await get().fetchUser(data.user.id, {
        email: data.user.email ?? undefined,
        name: authUser.name,
      });
      if (profileError) {
        await get().signOut();
        return { error: new Error(profileError) };
      }
    }
    return { error: null };
  },

  signOut: async () => {
    await supabase.auth.signOut();
    set({ user: null, authUser: null });
  },

  fetchUser: async (authId, fallback) => {
    const { user, error } = await resolveProfileUser(authId, fallback);
    set({ user });
    return { error };
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
        const { error: profileError } = await get().fetchUser(session.user.id, {
          email: session.user.email ?? undefined,
          name: authUser.name,
        });
        if (profileError) {
          setAuthFlash(profileError);
          await get().signOut();
        }
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
