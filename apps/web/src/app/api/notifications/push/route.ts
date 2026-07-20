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

  const url = process.env.NEXT_PUBLIC_SUPABASE_URL?.trim();
  // Trim: Vercel/Dashboard values often pick up trailing newlines or quotes.
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY?.trim().replace(/^["']|["']$/g, '');
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
      apikey: serviceRoleKey,
    },
    body: JSON.stringify(payload),
  });
  const text = await res.text();
  if (!res.ok) {
    const isServerError = res.status >= 500 || res.status === 404;
    const hint =
      res.status === 404
        ? 'Deploy the Edge Function: Supabase Dashboard → Edge Functions → deploy "send-push-notification", and ensure NEXT_PUBLIC_SUPABASE_URL points to that project.'
        : res.status === 401
          ? 'Vercel SUPABASE_SERVICE_ROLE_KEY must be the service_role secret from the same Supabase project as NEXT_PUBLIC_SUPABASE_URL (Dashboard → Project Settings → API). Also set that key as an Edge Function secret, then redeploy.'
          : undefined;
    return NextResponse.json(
      {
        error: `Push service returned ${res.status}: ${text}`,
        code: res.status === 401 ? 'SERVICE_ROLE_MISMATCH' : 'EDGE_FUNCTION_ERROR',
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
