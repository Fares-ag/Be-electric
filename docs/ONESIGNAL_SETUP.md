# OneSignal Push Notifications Setup

This doc describes how to enable and configure OneSignal push notifications for the Be Electric CMMS Flutter app.

---

## 1. OneSignal Dashboard Setup

1. **Create account** at [onesignal.com](https://onesignal.com) (free tier available).
2. **Create or select app** → Settings → Keys & IDs. Note:
   - **OneSignal App ID** (e.g. `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)
   - **REST API Key** (Settings → Keys & IDs → REST API Key)
3. **Configure platforms:**
   - **Android:** Add Firebase project; upload `google-services.json` or server key. See [OneSignal Android setup](https://documentation.onesignal.com/docs/android-sdk-setup).
   - **iOS:** Add APNs credentials (p8 token or p12). See [OneSignal iOS setup](https://documentation.onesignal.com/docs/ios-sdk-setup).

---

## 2. Flutter App Configuration

### 2.1 OneSignal App ID

Pass the App ID at build time. **Required for push to work** (if not set, push is disabled with no errors).

**Run (debug):**
```bash
flutter run --dart-define=ONE_SIGNAL_APP_ID=your-onesignal-app-id
```

**Production APK (technicians must have this for notifications):**
```bash
flutter build apk --release --dart-define=ONE_SIGNAL_APP_ID=your-onesignal-app-id
```

Use your real OneSignal App ID from the dashboard (Settings → Keys & IDs). In CI/build scripts, always set `ONE_SIGNAL_APP_ID` for release builds.

### 2.1a Production release scripts (this repo)

Push is **compile-time** enabled: the App ID must be present in **release** and **store** builds, or the SDK does not initialize.

**Option A — environment variable (CI friendly)**

PowerShell (Windows), from the **repository root**:

```powershell
$env:ONE_SIGNAL_APP_ID = "your-onesignal-app-id"
# optional: $env:SUPABASE_URL / $env:SUPABASE_ANON_KEY for production values
.\scripts\build_production.ps1 -Target technician -AndroidFormat appbundle
```

Bash (macOS / Linux / Git Bash):

```bash
export ONE_SIGNAL_APP_ID=your-onesignal-app-id
./scripts/build_production.sh technician appbundle
```

Targets: `requestor` | `technician` | `both` (default).  
Android: second argument / `-AndroidFormat` = `apk` (default) | `appbundle` | `ipa` for iOS.

**Option B — defines file (no env vars in shell)**

1. Copy `scripts/defines.production.json.example` to `scripts/defines.production.json` (this file is **gitignored**).
2. Fill in `ONE_SIGNAL_APP_ID` and, if needed, `SUPABASE_URL` / `SUPABASE_ANON_KEY`.
3. Run the same `build_production` scripts; they auto-detect `defines.production.json` and pass `--dart-define-from-file=...`.

**Server-side (required for assignment pushes):** deploy the Supabase function and set `ONE_SIGNAL_APP_ID` + `ONE_SIGNAL_REST_API_KEY` in Supabase secrets (section 3 below). Without that, the app can receive pushes from OneSignal tests, but your backend will not send assignment notifications.

### 2.2 Behavior

- On **login**, the app calls `OneSignal.login(userId)` so the device is linked to the Supabase `public.users` id.
- On **logout**, the app calls `OneSignal.logout()`.
- Pushes are targeted by **external_user_id** = `public.users.id`.

---

## 3. Supabase Edge Function (Server-Side Sends)

The Edge Function `send-push-notification` sends pushes via the OneSignal REST API.

### 3.1 Deploy the function

```bash
cd supabase
supabase functions deploy send-push-notification --no-verify-jwt
```

### 3.2 Set secrets

```bash
supabase secrets set ONE_SIGNAL_APP_ID=your-onesignal-app-id
supabase secrets set ONE_SIGNAL_REST_API_KEY=your-onesignal-rest-api-key
```

### 3.3 Invoke from your backend

**POST** to  
`https://<project-ref>.supabase.co/functions/v1/send-push-notification`

**Headers:** `Content-Type: application/json`  
(Optional: `Authorization: Bearer <anon_key>` if you enable JWT verification)

**Body:**

```json
{
  "type": "work_order_assigned",
  "external_user_ids": ["user-uuid-1", "user-uuid-2"],
  "title": "New Work Order Assigned",
  "message": "You have been assigned work order #WO-123.",
  "data": {
    "work_order_id": "wo-uuid",
    "ticket_number": "WO-123"
  }
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `type` | No | e.g. `work_order_assigned`, `pm_task_due` |
| `external_user_ids` | Yes | Supabase `public.users.id` values (technicians to notify) |
| `title` | Yes | Notification title |
| `message` | Yes | Notification body |
| `data` | No | Extra payload (work_order_id, pm_task_id, etc.) |

---

## 4. When to Send Pushes

### Work order assigned

When `work_orders.assignedTechnicianIds` is set or updated (from React admin or any client), call the Edge Function with the technician IDs:

```javascript
// Example: after updating work order in React admin
const techIds = updatedWorkOrder.assignedTechnicianIds; // from form
if (techIds?.length) {
  await fetch(`${SUPABASE_URL}/functions/v1/send-push-notification`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      type: 'work_order_assigned',
      external_user_ids: techIds,
      title: 'New Work Order Assigned',
      message: `Work order ${ticketNumber} has been assigned to you.`,
      data: { work_order_id: id, ticket_number: ticketNumber },
    }),
  });
}
```

### PM task upcoming / overdue

Use a **cron job** (e.g. Supabase cron, external scheduler) to:

1. Query `pm_tasks` where `nextDueDate` is today or overdue and status is pending.
2. For each task, get `assignedTechnicianIds`.
3. Call the Edge Function for each technician with appropriate title/message.

---

## 5. Database Webhook (Alternative)

Instead of calling the Edge Function from your app, you can use **Supabase Database Webhooks**:

1. Supabase Dashboard → Database → Webhooks → Create.
2. Table: `work_orders`, Events: `INSERT`, `UPDATE`.
3. URL: `https://<project-ref>.supabase.co/functions/v1/send-push-notification`
4. HTTP Headers: `Content-Type: application/json`.
5. In the webhook payload you receive `record` and `old_record`. You need a thin adapter that:
   - Compares `record.assignedTechnicianIds` with `old_record?.assignedTechnicianIds`.
   - If changed and non-empty, calls the Edge Function (or a wrapper) with `external_user_ids = record.assignedTechnicianIds`.

The default Supabase webhook sends the raw DB payload. You may need a small Edge Function that receives the webhook, parses `record`, and forwards a properly shaped body to `send-push-notification`.

---

## 6. Troubleshooting: No notifications on Android

If technicians get no push after a work order is assigned, check the following.

| Check | What to do |
|-------|-------------|
| **1. APK built with App ID** | The release APK must be built with `--dart-define=ONE_SIGNAL_APP_ID=your-app-id`. If you built with only `flutter build apk --release`, push is disabled. Rebuild with the flag and reinstall. |
| **2. Edge Function deployed** | Run `supabase functions deploy send-push-notification --no-verify-jwt` and set secrets `ONE_SIGNAL_APP_ID` and `ONE_SIGNAL_REST_API_KEY`. |
| **3. Who triggers the push** | **If you assign from the Flutter app** (e.g. assign technician from the app), the app now calls the Edge Function automatically. **If you assign from the React/admin web dashboard**, that dashboard must call the Edge Function when it saves the assignment (see [§4 When to Send Pushes](#4-when-to-send-pushes)). Otherwise no push is sent. |
| **4. On the technician phone** | Technician must be **logged in** (so `OneSignal.login(userId)` ran and the device is linked to their user id). They must have **allowed notifications** when the app prompted. |
| **5. OneSignal dashboard** | In OneSignal → your app → Platforms: **Android** must be configured (Firebase / FCM) with the same `google-services.json` (or server key) as in your app. |

Quick test: in OneSignal Dashboard → Messages → New Push → send a test to "Test Users" or to a segment; if that works but in-app assign doesn’t, the issue is step 3 (who calls the function).

---

## 7. Summary

| Step | Action |
|------|--------|
| 1 | Create OneSignal app, configure Android/iOS |
| 2 | Set `ONE_SIGNAL_APP_ID` when building Flutter app (required for production APK) |
| 3 | Deploy `send-push-notification` Edge Function |
| 4 | Set `ONE_SIGNAL_APP_ID` and `ONE_SIGNAL_REST_API_KEY` as Supabase secrets |
| 5 | Assignments from the **Flutter app** trigger push automatically; from the **web dashboard** you must call the Edge Function when saving (see §4) or use a DB webhook |
| 6 | (Optional) Add cron for PM task due/overdue notifications |
