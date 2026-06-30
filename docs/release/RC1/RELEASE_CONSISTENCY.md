# RC1 — Release Consistency Report

**Linked Supabase:** synced through `20260702120000` at audit start; **`20260703120000` pending apply**.

---

## Migration inventory

| Check | Result |
|-------|--------|
| Local SQL files | 45 (including RC1 fix) |
| Remote applied | 44 → 45 after RC1 push |
| Duplicate versions | None |
| Orphan remote-only | None |
| Conflicting order | None |

## Git vs database vs deploy

| Artifact | `origin/main` | Local | Supabase |
|----------|---------------|-------|----------|
| Migrations `20260630120000`–`20260703120000` | **Missing** | Present | Applied (except RC1 pending) |
| React RC code (auth, storage, pagination) | **Missing** | Modified/untracked | N/A |
| Edge function auth hardening | **Missing** | Modified | Deployed |
| `database.types.ts` | Stale vs local | Regenerated locally | Match after regen |

## P0-2 verdict: **OPEN**

Commit all migrations + RC code as one release tag before Vercel production deploy.

## Types consistency

Run after final migration:

```powershell
$out = npx supabase gen types typescript --linked 2>$null
$text = ($out -join "`n") -replace '^Initialising login role\.\.\.\r?\n',''
Set-Content supabase/database.types.ts $text -Encoding utf8
```

Commit the result.
