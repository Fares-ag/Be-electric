# Push Notifications (OneSignal) – React Admin

The React admin app sends push notifications to technicians via the Supabase Edge Function `send-push-notification` (OneSignal). Technicians receive notifications on their Flutter app when work is assigned.

## When notifications are sent

| Action | Type | Recipients |
|--------|------|------------|
| Assign technicians to a work order | `work_order_assigned` | Assigned technician IDs |
| Assign technicians to a PM task (detail page) | `pm_task_assigned` | Assigned technician IDs |
| Create PM task with assignees | `pm_task_assigned` | Assigned technician IDs |

## Flow

1. Admin/manager assigns technicians in the React app (work order or PM task).
2. After the DB update succeeds, the app calls **POST `/api/notifications/push`** with the payload.
3. The API route checks that the caller is admin/manager, then forwards the request to **Supabase Edge Function** `send-push-notification`.
4. The Edge Function uses OneSignal to send pushes to devices whose `external_user_id` matches the technician’s `public.users.id`.

Notifications are best-effort: if the push service fails, the assign action still succeeds.

## API route

- **URL:** `POST /api/notifications/push`
- **Auth:** `Authorization: Bearer <session access token>` (admin or manager only)
- **Body:** Same as [OneSignal Push Notifications Setup](./ONE_SIGNAL_SETUP.md) §3.3:
  - `external_user_ids` (required)
  - `title` (required)
  - `message` (required)
  - `type`, `data` (optional)

## Prerequisites

- Supabase Edge Function `send-push-notification` deployed and secrets set (`ONE_SIGNAL_APP_ID`, `ONE_SIGNAL_REST_API_KEY`).
- Flutter technician app configured with OneSignal and `OneSignal.login(userId)` on login so devices are linked to `public.users.id`.

## Production (Vercel)

For push to work in production you must:

1. **Add `SUPABASE_SERVICE_ROLE_KEY`** in Vercel: Project → Settings → Environment Variables. Use the same Supabase project as `NEXT_PUBLIC_SUPABASE_URL`. Get the key from Supabase Dashboard → Project Settings → API → `service_role` (secret).
2. **Redeploy** after adding the variable so the server can call the Edge Function.
3. Ensure the **Edge Function is deployed to that same Supabase project** (e.g. `supabase functions deploy send-push-notification`).

If the key is missing, assigning a work order or PM task will still save, but the app will show an amber message under “Assigned technicians” explaining that push was not sent and to add the key in Vercel.

See the main setup doc (e.g. **OneSignal Push Notifications Setup**) for dashboard, Flutter, and Edge Function setup.
