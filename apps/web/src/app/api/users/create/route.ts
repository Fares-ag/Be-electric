import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';

/**
 * Creates a user in Supabase Auth AND in public.users so they appear in the app
 * and in Supabase Dashboard → Authentication → Users.
 * Uses the service role key (server-only).
 */
export async function POST(request: Request) {
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!serviceRoleKey) {
    return NextResponse.json(
      { error: 'SUPABASE_SERVICE_ROLE_KEY is not set. Add it to .env.local to create users that can sign in.' },
      { status: 500 }
    );
  }

  const body = await request.json();
  const { email, name, role = 'requestor', companyId = null, department = null } = body as {
    email?: string;
    name?: string;
    role?: string;
    companyId?: string | null;
    department?: string | null;
  };

  if (!email?.trim()) {
    return NextResponse.json({ error: 'Email is required' }, { status: 400 });
  }

  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    serviceRoleKey,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );

  // Generate a one-time password the admin can share with the user
  const tempPassword = generateTempPassword();

  const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
    email: email.trim().toLowerCase(),
    password: tempPassword,
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
    tempPassword,
    message: 'User created in Supabase Auth and in the app. Share the temporary password with them so they can sign in and change it.',
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
