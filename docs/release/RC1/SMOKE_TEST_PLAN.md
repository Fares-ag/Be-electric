# RC1 — Smoke Test Plan (post-production deploy)

Execute within **30 minutes** of production cutover. Stop and rollback if any P0 item fails.

## Critical (P0)

| # | Test | Steps | Pass |
|---|------|-------|------|
| 1 | Admin login | `/login` → dashboard | ☐ |
| 2 | WO list loads | `/work-orders` no error | ☐ |
| 3 | Assign technician | WO detail → assign → save | ☐ |
| 4 | Push notification | Assign → check amber/green push message | ☐ |
| 5 | Requestor create (Flutter) | Create WO with 2 photos | ☐ |
| 6 | **Requestor sign-off (Flutter)** | Complete WO → sign → `requestorSignature` in DB | ☐ |
| 7 | **Requestor reopen (Flutter)** | Reopen completed WO → `status=reopened` | ☐ |
| 8 | Technician complete (Flutter) | Start → complete assigned WO | ☐ |
| 9 | Photo URL | Open WO with photo — image loads | ☐ |
| 10 | Escalation blocked | Requestor JWT cannot set assignees (SQL or API test) | ☐ |

## High (P1)

| # | Test | Pass |
|---|------|------|
| 11 | Parts request approve | ☐ |
| 12 | Support request inbox | ☐ |
| 13 | PM schedule list | ☐ |
| 14 | Notifications mark read | ☐ |
| 15 | Requestor web `/request` | ☐ |
| 16 | Legal pages `/privacy` `/terms` | ☐ |

## Infrastructure

| # | Test | Pass |
|---|------|------|
| 17 | Supabase health dashboard green | ☐ |
| 18 | Vercel deployment success | ☐ |
| 19 | No spike in 5xx on Vercel | ☐ |
| 20 | Edge function logs clean | ☐ |

## SQL spot-check (service role or SQL editor)

```sql
SELECT pg_get_functiondef('public.enforce_requestor_work_order_update()'::regprocedure)
  LIKE '%v_is_sign_off%' AS rc1_applied;
```

Expected: `true`
