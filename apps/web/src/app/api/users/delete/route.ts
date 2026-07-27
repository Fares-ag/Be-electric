import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/api/require-admin';

/**
 * Deletes profile first (scrubs assignees via RPC when present), then Auth.
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

  if (auth.userId === id.trim()) {
    return NextResponse.json({ error: 'You cannot delete your own account' }, { status: 400 });
  }

  const supabaseService = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    serviceRoleKey,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );

  const { data: profile } = await supabaseService
    .from('users')
    .select('email')
    .eq('id', id.trim())
    .maybeSingle();
  const email = (profile?.email as string | undefined)?.trim().toLowerCase();

  const { error: profileError } = await auth.supabaseAuth.rpc('delete_user_by_id', {
    p_id: id.trim(),
  });
  if (profileError) {
    return NextResponse.json(
      { error: `Profile delete failed: ${profileError.message}` },
      { status: 500 }
    );
  }

  if (email) {
    await supabaseService.from('admin_users').delete().eq('email', email);
  }

  const { error: authError } = await supabaseService.auth.admin.deleteUser(id.trim());
  if (authError) {
    return NextResponse.json(
      {
        error: `Profile deleted but Auth delete failed: ${authError.message}. Retry or remove Auth user manually.`,
      },
      { status: 500 }
    );
  }

  return NextResponse.json({ ok: true, message: 'User removed from Auth and app.' });
}
