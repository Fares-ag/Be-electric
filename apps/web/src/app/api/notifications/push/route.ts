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

  // Edge Functions are invoked with the service role key. In production (Vercel) you must
  // add SUPABASE_SERVICE_ROLE_KEY in Project Settings → Environment Variables.
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!serviceRoleKey) {
    console.warn('[push] SUPABASE_SERVICE_ROLE_KEY is not set (e.g. in Vercel env). Push will not work.');
    return NextResponse.json(
      {
        error: 'SUPABASE_SERVICE_ROLE_KEY is not set. Add it in Vercel → Project → Settings → Environment Variables.',
        code: 'MISSING_SERVICE_ROLE_KEY',
      },
      { status: 500 }
    );
  }
  const functionsUrl = `${url.replace(/\/$/, '')}/functions/v1/send-push-notification`;
  const payload = {
    type: body.type ?? 'notification',
    external_user_ids,
    title,
    message,
    data: body.data ?? {},
  };
  // Log so you can verify in server logs (Vercel → Deployment → Logs) that the route and Edge Function are called
  console.log('[push] Calling Edge Function send-push-notification', {
    type: payload.type,
    recipientCount: external_user_ids.length,
    title: payload.title?.slice(0, 50),
  });
  const res = await fetch(functionsUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${serviceRoleKey}`,
    },
    body: JSON.stringify(payload),
  });
  const text = await res.text();
  if (!res.ok) {
    console.warn('[push] Edge Function returned error', res.status, text);
    const isServerError = res.status >= 500 || res.status === 404;
    const hint =
      res.status === 404
        ? 'Deploy the Edge Function: Supabase Dashboard → Edge Functions → deploy "send-push-notification", and ensure NEXT_PUBLIC_SUPABASE_URL points to that project.'
        : undefined;
    return NextResponse.json(
      {
        error: `Push service returned ${res.status}: ${text}`,
        code: 'EDGE_FUNCTION_ERROR',
        hint,
      },
      { status: isServerError ? 502 : 400 }
    );
  }
  console.log('[push] Edge Function succeeded');
  return NextResponse.json(
    { ok: true },
    {
      headers: {
        // So you can confirm in browser Network tab that the route ran and invoked the Edge Function
        'X-Push-Invoked': 'true',
      },
    }
  );
}
