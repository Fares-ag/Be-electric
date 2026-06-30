# RC1 — Rollback Plan

## If deployment fails — decision tree

1. **App broken, DB OK** → Redeploy previous Vercel build + previous edge function bundle.
2. **DB migration caused issue** → Apply targeted SQL rollback below, then redeploy previous app.
3. **Sign-off still broken** → Do not rollback to `20260702120000`; forward-fix only.

---

## Migration rollbacks (reverse order)

### `20260703120000` (RC1 sign-off fix)

Re-apply function from `20260702120000_requestor_work_order_update_guard.sql` (not recommended — reintroduces sign-off bug).

### `20260702120000` (requestor UPDATE trigger)

```sql
DROP TRIGGER IF EXISTS enforce_requestor_work_order_update ON public.work_orders;
DROP FUNCTION IF EXISTS public.enforce_requestor_work_order_update();
NOTIFY pgrst, 'reload schema';
```

### `20260701130000` (notifications INSERT)

```sql
DROP POLICY IF EXISTS "Authenticated can insert notifications" ON notifications;
CREATE POLICY "Authenticated can insert notifications"
  ON notifications FOR INSERT TO authenticated WITH CHECK (true);
NOTIFY pgrst, 'reload schema';
```

### `20260701120000` (upsert field guard)

Re-apply `upsert_work_order` body from `20260629140000_harden_work_order_rpcs.sql`.

### `20260630130000` (files bucket)

```sql
DROP POLICY IF EXISTS "Authenticated can upload files" ON storage.objects;
DROP POLICY IF EXISTS "Public read files" ON storage.objects;
```

---

## Application rollback

- **Vercel:** Promote previous production deployment.
- **Edge function:** Redeploy prior git SHA: `git show <prev>:supabase/functions/send-push-notification/index.ts`
- **Flutter:** No rollback if DB RPC signatures unchanged; if trigger dropped, mobile escalation guard removed.

---

## Record rollback

Document in incident log: timestamp, migration version reverted, app version restored, QA re-run results.
