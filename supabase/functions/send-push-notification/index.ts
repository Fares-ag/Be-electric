// Supabase Edge Function: send push notification via OneSignal
// Invoked when work order is assigned, PM task due, etc.
// Requires: ONE_SIGNAL_APP_ID, ONE_SIGNAL_REST_API_KEY (secrets)

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const ONE_SIGNAL_URL = "https://api.onesignal.com/notifications";

interface PushPayload {
  type: string;
  external_user_ids: string[];
  title: string;
  message: string;
  data?: Record<string, string | number | boolean>;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: cors() });
  }

  try {
    const appId = Deno.env.get("ONE_SIGNAL_APP_ID");
    const apiKey = Deno.env.get("ONE_SIGNAL_REST_API_KEY");
    if (!appId || !apiKey) {
      return json(
        { error: "OneSignal credentials not configured" },
        { status: 500, headers: cors() }
      );
    }

    const body = (await req.json()) as PushPayload;
    const { type, external_user_ids, title, message, data = {} } = body;

    if (!external_user_ids?.length || !title || !message) {
      return json(
        { error: "external_user_ids, title, and message are required" },
        { status: 400, headers: cors() }
      );
    }

    const payload = {
      app_id: appId,
      include_aliases: { external_id: external_user_ids },
      target_channel: "push" as const,
      headings: { en: title },
      contents: { en: message },
      data: { type, ...data },
    };

    const res = await fetch(ONE_SIGNAL_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Key ${apiKey}`,
      },
      body: JSON.stringify(payload),
    });

    const result = await res.json();
    if (!res.ok) {
      return json(
        { error: result.errors?.[0] || "OneSignal API error", details: result },
        { status: res.status, headers: cors() }
      );
    }

    return json({ success: true, id: result.id }, { headers: cors() });
  } catch (e) {
    return json(
      { error: String(e) },
      { status: 500, headers: cors() }
    );
  }
});

function json(body: object, init?: ResponseInit) {
  return new Response(JSON.stringify(body), {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...init?.headers,
    },
  });
}

function cors() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
  };
}
