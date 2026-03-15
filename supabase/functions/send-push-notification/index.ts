// OneSignal push notification – target by external_user_id (Supabase public.users.id).
// Set secrets: ONE_SIGNAL_APP_ID, ONE_SIGNAL_REST_API_KEY

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

const ONE_SIGNAL_URL = 'https://api.onesignal.com/notifications';

interface IncomingBody {
  type?: string;
  external_user_ids: string[];
  title: string;
  message: string;
  data?: Record<string, string>;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: { 'Access-Control-Allow-Origin': '*' } });
  }
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const appId = Deno.env.get('ONE_SIGNAL_APP_ID');
  const apiKey = Deno.env.get('ONE_SIGNAL_REST_API_KEY');
  if (!appId || !apiKey) {
    return new Response(
      JSON.stringify({ error: 'ONE_SIGNAL_APP_ID or ONE_SIGNAL_REST_API_KEY not set' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }

  let body: IncomingBody;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const { external_user_ids, title, message, data } = body;
  if (!external_user_ids?.length || !title || !message) {
    return new Response(
      JSON.stringify({ error: 'external_user_ids, title, and message are required' }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    );
  }

  const res = await fetch(ONE_SIGNAL_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Key ${apiKey}`,
    },
    body: JSON.stringify({
      app_id: appId,
      target_channel: 'push',
      include_aliases: { external_id: external_user_ids },
      headings: { en: title },
      contents: { en: message },
      data: data ?? {},
    }),
  });

  const text = await res.text();
  if (!res.ok) {
    return new Response(
      JSON.stringify({ error: `OneSignal error: ${res.status}`, detail: text }),
      { status: res.status >= 500 ? 502 : 400, headers: { 'Content-Type': 'application/json' } }
    );
  }
  return new Response(text || '{}', {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
});
