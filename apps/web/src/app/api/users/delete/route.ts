import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/api/require-admin';

/**
 * Deletes a user from both Supabase Auth and public.users.
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
  const { id } = body as { id?: string };

  if (!id?.trim()) {
    return NextResponse.json({ error: 'User id is required' }, { status: 400 });
  }

  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    serviceRoleKey,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );

  const { error: authError } = await supabase.auth.admin.deleteUser(id.trim());
  if (authError) {
    return NextResponse.json(
      { error: `Auth delete failed: ${authError.message}` },
      { status: 400 }
    );
  }

  const { error: profileError } = await supabase.rpc('delete_user_by_id', {
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
