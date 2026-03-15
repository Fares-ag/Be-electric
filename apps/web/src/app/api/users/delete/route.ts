import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';

/**
 * Deletes a user from both Supabase Auth and public.users.
 * Keeps Auth and the app in sync.
 */
export async function POST(request: Request) {
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
      { error: 'SUPABASE_SERVICE_ROLE_KEY is not set.' },
      { status: 500 }
    );
  }

  const body = await request.json().catch(() => ({}));
  const { id } = body as { id?: string };

  if (!id?.trim()) {
    return NextResponse.json({ error: 'User id is required' }, { status: 400 });
  }

  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    serviceRoleKey,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );

  // 1. Delete from Supabase Auth (revokes sessions, prevents login)
  const { error: authError } = await supabase.auth.admin.deleteUser(id.trim());
  if (authError) {
    return NextResponse.json(
      { error: `Auth delete failed: ${authError.message}` },
      { status: 400 }
    );
  }

  // 2. Delete from public.users
  const { error: profileError } = await (supabase as any).rpc('delete_user_by_id', {
    p_id: id.trim(),
  });
  if (profileError) {
    return NextResponse.json(
      { error: `Profile delete failed: ${profileError.message}` },
      { status: 500 }
    );
  }

  return NextResponse.json({ ok: true, message: 'User removed from Auth and app.' });
}
