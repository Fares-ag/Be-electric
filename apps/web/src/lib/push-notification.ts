import { supabase } from '@/lib/supabase';

export type PushNotificationPayload = {
  type?: string;
  external_user_ids: string[];
  title: string;
  message: string;
  data?: Record<string, string>;
};

export async function sendPushNotification(payload: PushNotificationPayload): Promise<void> {
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const token = session?.access_token;
  if (!token) return;

  const res = await fetch('/api/notifications/push', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    const body = (await res.json().catch(() => ({}))) as { error?: string };
    throw new Error(body.error ?? `Push notification failed (${res.status})`);
  }
}
