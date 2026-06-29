import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/api/require-admin';
import { validateUserForm } from '@/lib/users';

/**
 * Updates a user in both public.users and Supabase Auth (user_metadata).
 * Keeps Auth and the app in sync.
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

  const validationError = validateUserForm(
    { name, role: role ?? 'requestor', companyId },
    'update'
  );
  if (validationError) {
    return NextResponse.json({ error: validationError }, { status: 400 });
  }

  if (auth.userId === id.trim() && isActive === false) {
    return NextResponse.json({ error: 'You cannot deactivate your own account' }, { status: 400 });
  }

  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    serviceRoleKey,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );

  const { error: authError } = await supabase.auth.admin.updateUserById(id.trim(), {
    user_metadata: {
      name: (name ?? '').trim(),
      role: role ?? 'requestor',
    },
  });
  if (authError) {
    return NextResponse.json(
      { error: `Auth update failed: ${authError.message}` },
      { status: 400 }
    );
  }

  const { error: profileError } = await supabase.rpc('update_user', {
    p_id: id.trim(),
    p_name: (name ?? '').trim(),
    p_role: role ?? 'requestor',
    p_is_active: isActive !== false,
    p_company_id: companyId?.trim() || null,
    p_department: department?.trim() || null,
  });
  if (profileError) {
    return NextResponse.json(
      { error: `Profile update failed: ${profileError.message}` },
      { status: 500 }
    );
  }

  return NextResponse.json({ ok: true, message: 'User updated in Auth and app.' });
}
