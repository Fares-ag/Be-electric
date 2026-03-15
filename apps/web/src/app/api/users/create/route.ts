import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';

/**
 * Creates a user in Supabase Auth AND in public.users so they appear in the app
 * and in Supabase Dashboard → Authentication → Users.
 * Requires: caller must be an admin/manager (verified via Bearer token).
 * Uses the service role key (server-only) for user creation.
 */
export async function POST(request: Request) {
  // 1. Verify caller is authenticated and is admin/manager
  const authHeader = request.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  const token = authHeader.slice(7);
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !anonKey) {
    return NextResponse.json({ error: 'Server misconfigured' }, { status: 500 });
  }
  const supabaseAuth = createClient(url, anonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const { data: { user }, error: userError } = await supabaseAuth.auth.getUser();
  if (userError || !user?.email) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { data: adminData } = await (supabaseAuth as any).rpc('get_admin_by_email', {
    p_email: user.email,
  });
  const adminRow = (adminData as { is_admin?: boolean; is_manager?: boolean }[] | null)?.[0];
  if (!adminRow?.is_admin && !adminRow?.is_manager) {
    return NextResponse.json({ error: 'Forbidden: admin or manager role required' }, { status: 403 });
  }

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

  if (password?.trim() && password.trim().length < 6) {
    return NextResponse.json(
      { error: 'Password must be at least 6 characters' },
      { status: 400 }
    );
  }

  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    serviceRoleKey,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );

  const finalPassword = password?.trim()
    ? password.trim()
    : generateTempPassword();

  const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
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

  // Ensure public.users has the full profile (trigger may have inserted; upsert to set role, company, department)
  const { error: profileError } = await supabase.from('users').upsert(
    {
      id,
      email: email.trim().toLowerCase(),
      name: (name ?? email).trim(),
      role: role ?? 'requestor',
      isActive: true,
      companyId: companyId?.trim() || null,
      department: department?.trim() || null,
      updatedAt: new Date().toISOString(),
    },
    { onConflict: 'id' }
  );

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
  return s + '!1'; // ensure at least one special and one number for typical password rules
}
