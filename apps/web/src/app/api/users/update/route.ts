import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/api/require-admin';
import { assertCanAssignRole } from '@/lib/api/admin-privileges';
import { validateUserForm } from '@/lib/users';

/**
 * Updates a user in both public.users and Supabase Auth (user_metadata).
 * Deactivate also bans Auth, revokes sessions, and removes admin_users.
 */
export async function POST(request: Request) {
  const auth = await requireAdmin(request);
  if (!auth.ok) return auth.response;

  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!serviceRoleKey) {
    return NextResponse.json(
      { error: 'SUPABASE_SERVICE_ROLE_KEY is not set.' },
      { status: 500 }
    );
  }

  const body = await request.json().catch(() => ({}));
  const { id, name, role, isActive, companyId, department } = body as {
    id?: string;
    name?: string;
    role?: string;
    isActive?: boolean;
    companyId?: string | null;
    department?: string | null;
  };

  if (!id?.trim()) {
    return NextResponse.json({ error: 'User id is required' }, { status: 400 });
  }

  const nextRole = role ?? 'requestor';
  const validationError = validateUserForm(
    { name, role: nextRole, companyId },
    'update'
  );
  if (validationError) {
    return NextResponse.json({ error: validationError }, { status: 400 });
  }

  const roleErr = await assertCanAssignRole(auth.supabaseAuth, auth.email, nextRole);
  if (roleErr) {
    return NextResponse.json({ error: roleErr }, { status: 403 });
  }

  if (auth.userId === id.trim() && isActive === false) {
    return NextResponse.json({ error: 'You cannot deactivate your own account' }, { status: 400 });
  }

  const supabaseService = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    serviceRoleKey,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );

  const active = isActive !== false;

  const { error: authError } = await supabaseService.auth.admin.updateUserById(id.trim(), {
    user_metadata: {
      name: (name ?? '').trim(),
      role: nextRole,
    },
    ban_duration: active ? 'none' : '876000h',
  });
  if (authError) {
    return NextResponse.json(
      { error: `Auth update failed: ${authError.message}` },
      { status: 400 }
    );
  }

  if (!active) {
    try {
      await supabaseService.auth.admin.signOut(id.trim(), 'global');
    } catch {
      // Best-effort session revoke; ban still blocks refresh.
    }

    const { data: profile } = await supabaseService
      .from('users')
      .select('email')
      .eq('id', id.trim())
      .maybeSingle();
    const email = (profile?.email as string | undefined)?.trim().toLowerCase();
    if (email) {
      await supabaseService.from('admin_users').delete().eq('email', email);
    }
  }

  const { error: profileError } = await auth.supabaseAuth.rpc('update_user', {
    p_id: id.trim(),
    p_name: (name ?? '').trim(),
    p_role: nextRole,
    p_is_active: active,
    p_company_id: companyId?.trim() || null,
    p_department: department?.trim() || null,
  });
  if (profileError) {
    return NextResponse.json(
      { error: `Profile update failed: ${profileError.message}` },
      { status: 500 }
    );
  }

  // Keep admin_users in sync when promoting/demoting active users.
  if (active) {
    const { data: profile } = await supabaseService
      .from('users')
      .select('email')
      .eq('id', id.trim())
      .maybeSingle();
    const email = (profile?.email as string | undefined)?.trim().toLowerCase();
    if (email) {
      if (nextRole === 'admin' || nextRole === 'manager') {
        await supabaseService.from('admin_users').upsert(
          {
            email,
            is_admin: nextRole === 'admin',
            is_manager: nextRole === 'manager' || nextRole === 'admin',
            updated_at: new Date().toISOString(),
          },
          { onConflict: 'email' }
        );
      } else {
        await supabaseService.from('admin_users').delete().eq('email', email);
      }
    }
  }

  return NextResponse.json({ ok: true, message: 'User updated in Auth and app.' });
}
