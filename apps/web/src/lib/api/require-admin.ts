import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';

type AdminCheckRow = { is_admin: boolean; is_manager: boolean };

export type RequireAdminResult =
  | { ok: true; email: string; supabaseAuth: SupabaseClient }
  | { ok: false; response: NextResponse };

export async function requireAdmin(request: Request): Promise<RequireAdminResult> {
  const authHeader = request.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return { ok: false, response: NextResponse.json({ error: 'Unauthorized' }, { status: 401 }) };
  }

  const token = authHeader.slice(7);
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !anonKey) {
    return { ok: false, response: NextResponse.json({ error: 'Server misconfigured' }, { status: 500 }) };
  }

  const supabaseAuth = createClient(url, anonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });

  const {
    data: { user },
    error: userError,
  } = await supabaseAuth.auth.getUser();
  if (userError || !user?.email) {
    return { ok: false, response: NextResponse.json({ error: 'Unauthorized' }, { status: 401 }) };
  }

  const { data: adminData, error: adminError } = await supabaseAuth.rpc('get_admin_by_email', {
    p_email: user.email,
  });
  if (adminError) {
    return {
      ok: false,
      response: NextResponse.json({ error: 'Unable to verify admin access' }, { status: 403 }),
    };
  }

  const adminRow = (adminData as AdminCheckRow[] | null)?.[0];
  if (!adminRow?.is_admin && !adminRow?.is_manager) {
    return {
      ok: false,
      response: NextResponse.json({ error: 'Forbidden: admin or manager role required' }, { status: 403 }),
    };
  }

  return { ok: true, email: user.email, supabaseAuth };
}
