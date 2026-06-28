import { NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/api/require-admin';

/**
 * Forwards push notification payload to the Supabase Edge Function
 * send-push-notification (OneSignal). Caller must be admin or manager.
 */
export async function POST(request: Request) {
  const auth = await requireAdmin(request);
  if (!auth.ok) return auth.response;

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

  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !serviceRoleKey) {
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

  return NextResponse.json(
    { ok: true },
    {
      headers: {
        'X-Push-Invoked': 'true',
      },
    }
  );
}
