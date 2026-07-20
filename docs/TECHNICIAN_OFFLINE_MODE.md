# Technician offline: as-implemented vs as-advertised

**Date:** 2026-07-20  
**Baseline:** Flutter `monorepo` @ `b7c1f71` (+ local WIP DI). Web not required for offline.

## As-advertised

- `AppConfig.isOfflineModeEnabled` defaults to `true` (`OFFLINE_MODE` dart-define).
- Models carry `isOffline` / `lastSyncedAt`.
- `SyncQueueService` exists with retry (max 3, every 2 minutes).

## As-implemented

| Area | Reality | Evidence |
|------|---------|----------|
| Offline flag | Config prints only; no write-path gate | `app_config.dart` `isOfflineModeEnabled` |
| Sync queue | **Dead code** — registered in GetIt, never `addWorkOrderOperation` / `addOperation` from app flows | `sync_queue_service.dart`; repo-wide callers = none |
| WO Start/Complete | Direct Supabase UPDATE; fails offline (no queue) | `unified_data_service` / `WorkOrderProvider` |
| Parts create | Direct INSERT; throws if offline (`isOffline: true` only until cloud returns) | `parts_request_service.dart` |
| Parts approve | Was false-success locally (fixed BE-QA-004) | same |
| Local caches | SharedPreferences for parts prefs, enhanced notifications, queue JSON | prefs keys `parts_requests`, `sync_queue`, `enhanced_notifications` |
| Photos | Upload requires network; completion may continue after upload fail (BE-QA-023 deferred) | completion screen |
| Realtime | Channels drop offline; restart on provider re-init / auth — no dedicated reconnect queue | `RealtimeSupabaseService` |
| Conflict rules | **None** — last successful cloud write wins; no merge | — |

## Offline findings

| ID | Sev | Finding | Status |
|----|-----|---------|--------|
| BE-QA-OFF-001 | P1 | `SyncQueueService` never enqueued — offline WO/parts writes are not durable | Documented; full offline queue = larger project (Deferred) |
| BE-QA-OFF-002 | P0 | Parts approve swallowed cloud errors + mutated local stock | **Fixed** (BE-QA-004) |
| BE-QA-OFF-003 | P1 | `getAllPartsRequests` returned `[]` on error (looked empty) | **Fixed** (rethrows; service still prefs-fallback on catch) |
| BE-QA-OFF-004 | P2 | `isOffline` on models not a cloud column for parts; never drives SyncQueue | Deferred |
| BE-QA-OFF-005 | P2 | No offline banner / connectivity UX tied to `OFFLINE_MODE` | Deferred |

## Field expectation (honest)

Technician app is **online-first**. Airplane mode: reads may show last prefs/cache; writes should fail with errors (after BE-QA-004). Do not advertise durable offline field ops until SyncQueue is wired into WO/parts mutations.
