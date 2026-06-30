# RC1 — Deployment Plan

## Order of operations

### Phase 1 — Staging validation

1. **Commit** all RC1 code + migrations to release branch.
2. **Apply migrations** (staging Supabase):
   ```bash
   npx supabase db push --linked --yes
   ```
3. **Verify** migration list ends with `20260703120000`.
4. **Regenerate types** (see `RELEASE_CONSISTENCY.md`).
5. **Deploy edge function**:
   ```bash
   npx supabase functions deploy send-push-notification --yes
   ```
6. **Deploy React Admin** to Vercel preview (staging env vars).
7. **Run** `QA_CHECKLIST.md` on staging with Flutter staging builds.

### Phase 2 — Production

1. **Maintenance window** (optional): notify customers if schema change window needed (RC1 migrations already applied on linked prod from prior work — confirm target project).
2. **Apply pending migrations** to production Supabase (if any not yet applied):
   ```bash
   npx supabase db push --linked --yes
   ```
3. **Deploy edge function** to production project.
4. **Deploy Vercel production** from RC1 git tag.
5. **Run** `SMOKE_TEST_PLAN.md` immediately.
6. **Monitor** Supabase logs + Vercel errors for 30 minutes.

## Environment variables

| Variable | Where | Required |
|----------|-------|----------|
| `NEXT_PUBLIC_SUPABASE_URL` | Vercel | Yes |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Vercel | Yes |
| `SUPABASE_SERVICE_ROLE_KEY` | Vercel (server only) | Yes (push) |
| `ONE_SIGNAL_APP_ID` | Supabase Edge secrets | Yes |
| `ONE_SIGNAL_REST_API_KEY` | Supabase Edge secrets | Yes |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase Edge secrets | Yes |
| `E2E_ADMIN_EMAIL/PASSWORD` | CI optional | Staging E2E |

## Verification steps (post-deploy)

1. Admin login → dashboard loads
2. Assign WO → push invoked (check `X-Push-Invoked` or OneSignal dashboard)
3. Flutter Requestor sign-off on completed WO
4. Flutter Requestor reopen
5. Upload photo → `files` bucket URL resolves
