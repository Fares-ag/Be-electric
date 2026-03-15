import { createClient } from '@supabase/supabase-js';
import { NextResponse } from 'next/server';

/**
 * Forwards push notification payload to the Supabase Edge Function
 * send-push-notification (OneSignal). Caller must be admin or manager.
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

  let body: {
    type?: string;
    external_user_ids?: string[];
    title?: string;
    message?: string;
    data?: Record<string, string>;
  };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 });
  }
  const { external_user_ids, title, message } = body;
  if (!external_user_ids?.length || !title || !message) {
    return NextResponse.json(
      { error: 'external_user_ids (non-empty), title, and message are required' },
      { status: 400 }
    );
  }

  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!serviceRoleKey) {
    return NextResponse.json(
      { error: 'SUPABASE_SERVICE_ROLE_KEY is not set. Add it to your env to call Edge Functions.' },
      { status: 500 }
    );
  }
  const functionsUrl = `${url.replace(/\/$/, '')}/functions/v1/send-push-notification`;
  const res = await fetch(functionsUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${serviceRoleKey}`,
    },
    body: JSON.stringify({
      type: body.type ?? 'notification',
      external_user_ids,
      title,
      message,
      data: body.data ?? {},
    }),
  });
  const text = await res.text();
  if (!res.ok) {
    const isServerError = res.status >= 500 || res.status === 404;
    return NextResponse.json(
      {
        error: `Push service returned ${res.status}: ${text}`,
        hint:
          res.status === 404
            ? 'Edge Function "send-push-notification" not found. Deploy it in Supabase Dashboard → Edge Functions (name must be exactly send-push-notification) and ensure this project matches NEXT_PUBLIC_SUPABASE_URL.'
            : undefined,
      },
      { status: isServerError ? 502 : 400 }
    );
  }
  return NextResponse.json({ ok: true });
}
