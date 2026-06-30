# RC1 — Release Checklist

Complete every item before production cutover.

## Code & database

- [ ] P0-1 migration `20260703120000` applied to staging Supabase
- [ ] P0-1 migration applied to production Supabase
- [ ] All migrations `20260630120000`–`20260703120000` committed to git
- [ ] All React Admin RC changes committed (no unstaged release code)
- [ ] `supabase/database.types.ts` regenerated from linked project and committed
- [ ] Edge function `send-push-notification` deployed from same commit
- [ ] Git tag `v1.0.0-rc1` (or agreed RC tag) created

## Environment

- [ ] Vercel: `NEXT_PUBLIC_SUPABASE_URL`
- [ ] Vercel: `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- [ ] Vercel: `SUPABASE_SERVICE_ROLE_KEY` (push proxy)
- [ ] Supabase Edge secrets: `ONE_SIGNAL_APP_ID`, `ONE_SIGNAL_REST_API_KEY`, `SUPABASE_SERVICE_ROLE_KEY`
- [ ] Flutter Requestor + Technician: same Supabase URL/anon key as web
- [ ] OneSignal linked to production app IDs

## Verification

- [ ] `npm run test` — 88+ unit tests pass
- [ ] `npm run build` — production build succeeds
- [ ] Manual QA checklist (`QA_CHECKLIST.md`) — P0 rows pass on staging
- [ ] Smoke test plan (`SMOKE_TEST_PLAN.md`) ready for post-deploy
- [ ] Rollback plan reviewed (`ROLLBACK_PLAN.md`)

## Documentation

- [ ] Release notes sent to stakeholders
- [ ] Known issues (`KNOWN_ISSUES.md`) acknowledged
- [ ] Flutter app build numbers pinned in release notes

## Sign-off

- [ ] Engineering
- [ ] QA
- [ ] Security
- [ ] Operations
