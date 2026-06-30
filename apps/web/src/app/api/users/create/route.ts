import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/api/require-admin';
import { validateUserForm } from '@/lib/users';

/**
 * Creates a user in Supabase Auth AND in public.users via insert_user RPC.
 * Auth user is created with service role; profile row uses admin JWT (handbook parity).
 */
export async function POST(request: Request) {
  const auth = await requireAdmin(request);
  if (!auth.ok) return auth.response;

  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!serviceRoleKey) {
    return NextResponse.json(
      { error: 'SUPABASE_SERVICE_ROLE_KEY is not set. Add it to Vercel env vars to create users.' },
      { status: 500 }
    );
  }

  const body = await request.json().catch(() => ({}));
  const { email, name, role = 'requestor', companyId = null, department = null, password } = body as {
    email?: string;
    name?: string;
    role?: string;
    companyId?: string | null;
    department?: string | null;
    password?: string;
  };

  if (!email?.trim()) {
    return NextResponse.json({ error: 'Email is required' }, { status: 400 });
  }

  const validationError = validateUserForm(
    {
      name: name ?? email,
      email,
      role: role ?? 'requestor',
      companyId,
    },
    'create'
  );
  if (validationError) {
    return NextResponse.json({ error: validationError }, { status: 400 });
  }

  if (password?.trim() && password.trim().length < 6) {
    return NextResponse.json(
      { error: 'Password must be at least 6 characters' },
      { status: 400 }
    );
  }

  const supabaseService = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    serviceRoleKey,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );

  const finalPassword = password?.trim()
    ? password.trim()
    : generateTempPassword();

  const { data: authUser, error: authError } = await supabaseService.auth.admin.createUser({
    email: email.trim().toLowerCase(),
    password: finalPassword,
    email_confirm: true,
    user_metadata: { name: (name ?? email).trim(), role: role ?? 'requestor' },
  });

  if (authError) {
    return NextResponse.json(
      { error: authError.message },
      { status: 400 }
    );
  }

  if (!authUser.user) {
    return NextResponse.json({ error: 'Failed to create auth user' }, { status: 500 });
  }

  const id = authUser.user.id;

  const { error: profileError } = await auth.supabaseAuth.rpc('insert_user', {
    p_id: id,
    p_email: email.trim().toLowerCase(),
    p_name: (name ?? email).trim(),
    p_role: role ?? 'requestor',
    p_is_active: true,
    p_company_id: companyId?.trim() || null,
    p_department: department?.trim() || null,
  });

  if (profileError) {
    return NextResponse.json(
      { error: `User created in Auth but profile failed: ${profileError.message}` },
      { status: 500 }
    );
  }

  return NextResponse.json({
    id,
    email: authUser.user.email,
    tempPassword: password?.trim() ? undefined : finalPassword,
    message: password?.trim()
      ? 'User created. They can sign in with the password you set.'
      : 'User created. Share the temporary password with them so they can sign in and change it.',
  });
}

function generateTempPassword(length = 14): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  let s = '';
  for (let i = 0; i < length; i++) {
    s += chars[Math.floor(Math.random() * chars.length)];
  }
  return s + '!1';
}
