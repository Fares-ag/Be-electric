# QA fix status — 2026-07-20

Baselines: Flutter `b7c1f71` (WIP working tree), Web `f7c196d`.

| ID | Status | Notes |
|----|--------|-------|
| BE-QA-001 | **Fixed (code)** | Deactivate bans Auth, global signOut, drops `admin_users`; `requireAdmin` checks `isActive`; migration makes `get_my_role` NULL when inactive |
| BE-QA-002 | **Fixed (code)** | API + RPC: only `is_true_admin()` may assign `role=admin`; admin_users sync on create/update |
| BE-QA-003 | **Fixed (migration draft)** | Requestor company-scoped assets/companies; staff global read |
| BE-QA-004 | **Fixed** | UPDATE payload + no swallow + EnhancedNotification + fulfill-only decrement |
| BE-QA-005 | **Partial** | Trees mirrored both ways + `MIGRATION_APPLY_ORDER.md`; orphan→occurrences still TODO |
| BE-QA-006 | **Documented** | WIP DI kept local; no GetIt dump to HEAD; handbook still WIP-leaning |
| BE-QA-007 | **Fixed** | Auth create rollback on profile failure |
| BE-QA-008 | **Fixed** | Delete profile then Auth |
| BE-QA-009 | **Fixed** | `createFallbackUser` gated to `NODE_ENV===development` |
| BE-QA-010 | **Fixed (WIP)** | Requestor dashboard/analytics/status use `loadRequestorWorkOrders` |
| BE-QA-011 | **Already fixed (WIP)** | `workOrdersForRoleListView` assignment-only |
| BE-QA-013 | **Partial** | Proxy already trims keys (f7c196d); ops must align Vercel↔Edge secrets |
| BE-QA-014 | **Fixed (migration draft)** | files INSERT path prefixes |
| BE-QA-OFF-001 | **Deferred** | SyncQueue dead — see `TECHNICIAN_OFFLINE_MODE.md` |
| BE-QA-OFF-002 | **Fixed** | via BE-QA-004 |
| BE-QA-OFF-003 | **Fixed** | getAllPartsRequests rethrows |

## Prod SQL you must approve

```bash
# From Be-electric-1 (preferred SSOT) after review:
# supabase db push   # or Dashboard SQL for 20260720160000_security_role_tenant_storage.sql

# Or Flutter:
./scripts/db.sh run scripts/sql/migrate_security_role_tenant_storage.sql
```

Then run verify queries in `docs/MIGRATION_APPLY_ORDER.md`.

## Residual risk

- Full offline sync still not implemented (online-first).
- Storage path policy may break uploads that use unexpected prefixes — confirm all Flutter/web upload folders.
- `get_my_role` still collapses manager→`'admin'` string for admin_users managers (pre-existing).
- Orphan scrub still misses `pm_task_occurrences` assignees.
- Human: push secrets, device smoke, apply migrations.
