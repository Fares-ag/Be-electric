# RC1 — Known Issues (deferred post-RC1)

Intentionally **not** fixed in RC1. Track for next release.

## P1 — High

| Issue | Impact |
|-------|--------|
| No Next.js middleware | Client-only route guards; brief unauthorized flash |
| Uncapped list queries | support, inventory, companies, assets, dashboard WO summary, PM schedule head query |
| E2E mostly credential-gated | CI does not prove critical flows without secrets |
| No Content-Security-Policy | Baseline headers only (`next.config.js`) |
| Dual PM model (`pm_tasks` + `pm_schedules`) | Legacy realtime/prefetch paths remain |
| `schema-pull.mjs` flaky on Windows | Manual types regen workaround |
| Parts requests SELECT for technicians | May not see all WO-linked requests |

## P2 — Medium

| Issue | Impact |
|-------|--------|
| Inline Supabase queries in pages | Inconsistent error handling |
| Duplicate notification realtime subscriptions | Extra invalidations |
| No enterprise audit log | Compliance gap |
| No integration test suite | Regression risk |
| Auth fallback user synthesis | Should never run in prod |

## P3 — Future

| Issue | Impact |
|-------|--------|
| Web requestor sign-off | Flutter-only today |
| Full CSP | Security hardening |
| Server-side pagination UI | Scale at 10k+ rows |
| Centralized query layer | Maintainability |
| Deprecate `pm_tasks` | Model simplification |

## RC1 blockers (must be zero before GA)

- ~~P0-1 Requestor sign-off regression~~ → fix in `20260703120000` (apply + mobile verify)
- P0-2 Git/deploy alignment → commit + tag + deploy
- P0-3 Cross-platform QA → manual checklist on staging

**Batch C:** Do not start until RC1 GA criteria met.
