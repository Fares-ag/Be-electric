# Preventive Maintenance (PPM) — Flutter integration guide

**Audience:** Flutter **Technician** and **Requestor** apps  
**Backend source of truth:** `beelectric-react` repo → `supabase/migrations/`  
**Admin web:** React app → `/pm-schedules`  
**Last updated:** June 2026 (Option A — schedules + occurrences)

Copy this file into both Flutter Cursor projects (`docs/PM_FLUTTER_INTEGRATION.md`) and reference it from your multi-app Cursor rule alongside `docs/MULTI-APP-CONTEXT.md`.
0
---

## 1. Executive summary

| App | PM role |
|-----|---------|
| **Technician (Flutter)** | **Must implement** — query assigned `pm_task_occurrences`, show detail, complete with notes/photo. Keep legacy `pm_tasks` until migration is done. |
| **Requestor (Flutter)** | **No PM features** — requestors do not get PM assignments and cannot complete PM. No UI or queries required. |
| **Admin (React web)** | Creates schedules, manages occurrences (cancel/reschedule/assign). Technicians execute in the field. |

**Why migrate:** Admin now creates PM via **`pm_schedules`** + **`pm_task_occurrences`**. Legacy **`pm_tasks`** is read-only on web and receives no new rows. Flutter still reading only `pm_tasks` will **miss all new preventive maintenance work**.

---

## 2. Data model (Option A)

### 2.1 `pm_schedules` (template — admin-created)

One row per PM program (task name, frequency, date window, company, default assignees).

| Column | Type | Notes |
|--------|------|--------|
| `id` | uuid | PK |
| `taskName` | text | Display title |
| `description` | text | Optional instructions |
| `frequency` | text | `daily`, `weekly`, `monthly`, `quarterly`, `semiAnnually`, `annually`, `asNeeded` |
| `frequencyValue` | integer | Day interval hint (admin sets on create) |
| `scheduleStartDate` | date | ISO `YYYY-MM-DD` |
| `scheduleEndDate` | date | ISO `YYYY-MM-DD` |
| `companyId` | text | FK → `companies.id` |
| `assignedTechnicianIds` | text[] | Default assignees (user UUID strings) |
| `createdById` | text | FK → `users.id` |
| `metadata` | jsonb | Optional `checklist`: string[] |
| `createdAt`, `updatedAt` | timestamptz | Audit |

**Technician access:** SELECT only, when assigned to at least one occurrence on that schedule (RLS).

**Mobile does not create schedules.** RPC `create_pm_schedule_with_occurrences` is admin/manager only (web).

### 2.2 `pm_task_occurrences` (executable unit — one per charger × due date)

| Column | Type | Notes |
|--------|------|--------|
| `id` | uuid | PK — use in deep links / push payload |
| `scheduleId` | uuid | FK → `pm_schedules.id` |
| `assetId` | text | FK → `assets.id` (charger) |
| `dueDate` | date | ISO `YYYY-MM-DD` |
| `status` | text | Stored: `pending`, `completed`, `overdue`, `cancelled` |
| `assignedTechnicianIds` | text[] | Who should do this occurrence |
| `completedAt` | timestamptz | Set on complete |
| `completedById` | text | FK → `users.id` |
| `completionNotes` | text | Optional, max 4000 chars (web validates) |
| `completionPhotoPath` | text | Storage path in `files` bucket |
| `cancelledAt`, `cancelledById`, `cancelReason` | | Admin cancel only |
| `metadata` | jsonb | Reserved |
| `createdAt`, `updatedAt` | timestamptz | Audit |

**Unique constraint:** `(scheduleId, assetId, dueDate)` — rescheduling to an existing slot fails with duplicate key.

### 2.3 `pm_tasks` (legacy — deprecate)

Single-row model: one task per asset with `nextDueDate`. Flutter may still read/complete **existing** rows until fully migrated. **Do not build new features on this table.**

| Legacy | New model |
|--------|-----------|
| `pm_tasks.id` | `pm_task_occurrences.id` |
| `pm_tasks.taskName` | `pm_schedules.taskName` (join) |
| `pm_tasks.nextDueDate` | `pm_task_occurrences.dueDate` |
| `pm_tasks.status` | `pm_task_occurrences.status` + derived overdue/upcoming |
| `pm_tasks.completionPhotoPath` | `pm_task_occurrences.completionPhotoPath` |

---

## 3. Display status (derive client-side — v1)

Stored `status` is often `pending` even when past due. **Do not rely on stored `overdue` alone.**

Use the same rules as admin web (`apps/web/src/lib/pm-schedule.ts`):

```
function deriveDisplayStatus(storedStatus, dueDate, todayIso):
  if storedStatus in ('completed', 'cancelled') → return storedStatus
  if dueDate < todayIso → return 'overdue'
  return 'upcoming'   // pending + due today or future
```

Filter buckets:

- **Open:** not `completed` and not `cancelled`
- **Overdue:** open and `dueDate < today`
- **Upcoming:** open and `dueDate >= today`

Sort open work by `dueDate` ascending (overdue first in UI if desired).

---

## 4. RLS (what Flutter can rely on)

All calls use **authenticated JWT** (same as work orders). No RPCs for PM reads/writes except admin-only create RPC.

| Role | `pm_schedules` | `pm_task_occurrences` |
|------|----------------|------------------------|
| **admin / manager** | Full CRUD | Full CRUD |
| **technician** | SELECT if assigned to any occurrence on schedule | SELECT + UPDATE where `auth.uid()::text = ANY(assignedTechnicianIds)` |
| **requestor** | No access | No access |

**Technician complete:** UPDATE allowed by RLS; app should only set completion fields (`status`, `completedAt`, `completedById`, `completionNotes`, `completionPhotoPath`, `updatedAt`). Cancel/reschedule is **admin web only** in v1.

---

## 5. Technician app — required implementation

### 5.1 List assigned PM occurrences

Replace (or merge with) legacy `pm_tasks` list.

**Suggested select** (PostgREST embed):

```sql
-- Equivalent Supabase Dart select string:
id, scheduleId, assetId, dueDate, status, assignedTechnicianIds,
completedAt, completionPhotoPath, completionNotes,
schedule:pm_schedules(taskName, description, frequency, metadata),
asset:assets(name, location, manufacturer, model, serialNumber)
```

**Query:**

```dart
final uid = currentUser.id;
await supabase
  .from('pm_task_occurrences')
  .select(_occurrenceListSelect)
  .contains('assignedTechnicianIds', [uid])
  .order('dueDate', ascending: true);
```

RLS already restricts rows; `.contains` mirrors web intent and avoids leaking unassigned rows if policies change.

**Unified inbox (recommended during migration):**

1. Fetch legacy `pm_tasks` (existing code).
2. Fetch `pm_task_occurrences` (new code).
3. Map both to a shared `PmWorkItem` UI model with a `source: legacy | occurrence` discriminator.
4. Sort by due date.

### 5.2 Detail screen

Show:

- Schedule: `taskName`, `description`, `frequency`
- Charger: asset name, location, manufacturer, model, serial
- Due date + derived status badge (overdue / upcoming / completed / cancelled)
- Optional checklist: `schedule.metadata.checklist` → `List<String>` (display only in v1; no per-item completion tracking yet)
- Assignees (optional display)

### 5.3 Complete occurrence

1. Optional: upload photo to Storage bucket **`files`** at path:

   ```
   pm_occurrences/{occurrenceId}/completion/{timestamp}_{random}.{ext}
   ```

   (Matches admin web: `apps/web/src/lib/storage-config.ts`.)

2. UPDATE row:

```dart
await supabase.from('pm_task_occurrences').update({
  'status': 'completed',
  'completedAt': DateTime.now().toUtc().toIso8601String(),
  'completedById': currentUser.id,
  'completionNotes': notes.trim().isEmpty ? null : notes.trim(),
  'completionPhotoPath': photoPath, // or null
  'updatedAt': DateTime.now().toUtc().toIso8601String(),
}).eq('id', occurrenceId);
```

3. Do **not** set `cancelledAt`, `cancelReason`, or change `dueDate` from mobile (admin only).

**Legacy complete** (`pm_tasks`): keep existing path until legacy list is empty.

### 5.4 Realtime (optional)

Subscribe to `pm_task_occurrences` INSERT/UPDATE (same pattern as `listenToPMTasks()`). RLS limits events to assigned rows.

Admin web invalidates on channel `pm_task_occurrences` changes.

### 5.5 Push notifications (contract)

**Today:** Legacy PM assign on web sends push type `pm_task_assigned` with `data.pm_task_id`.

**Planned for new model** (implement handler when admin web ships push):

| Field | Value |
|-------|--------|
| `type` | `pm_occurrence_assigned` (proposed) |
| `data.pm_occurrence_id` | occurrence uuid |
| `data.schedule_id` | schedule uuid |
| `data.task_name` | schedule task name |
| `data.due_date` | ISO date |

Deep link: open occurrence detail for `pm_occurrence_id`.

Until push exists, technicians see new work via list refresh / realtime only.

---

## 6. Requestor app — explicit non-scope

**Requestors have no PM role.**

- Do **not** query `pm_schedules` or `pm_task_occurrences`.
- Do **not** add PM screens to the requestor navigation.
- No RLS path for requestor on PM tables.

If the Flutter repo is a **single binary** with role-based routing:

- `role == requestor` → hide all PM modules (same as today for PM tasks if already hidden).
- `role == technician` → show PM module per section 5.

Document this in the requestor Cursor rule so AI does not add PM features there.

---

## 7. Storage

| Bucket | Path pattern | Used for |
|--------|--------------|----------|
| `files` | `pm_occurrences/{occurrenceId}/completion/...` | New model completion photos |
| `files` | `pm_tasks/{taskId}/completion/...` | Legacy completion photos |

Migration `20260630130000_storage_bucket_files.sql`: authenticated INSERT + public READ on `files` bucket.

Store **`completionPhotoPath`** as the object path (not full URL) unless your app already prefixes with Supabase storage URL helper.

---

## 8. Admin web behavior (for parity)

Technicians should match admin completion semantics:

| Action | Who | Table |
|--------|-----|--------|
| Create schedule + occurrences | Admin web | RPC + tables |
| Assign / reassign technicians | Admin web | `pm_schedules` + open occurrences |
| Complete with notes + photo | Admin web or **Technician Flutter** | `pm_task_occurrences` |
| Cancel / reschedule | Admin web only | `pm_task_occurrences` |

Admin routes:

- `/pm-schedules` — list, create wizard, upcoming view
- `/pm-schedules/{id}` — occurrence grid
- `/pm-schedules/{id}/occurrences/{occurrenceId}` — complete / cancel / reschedule

Reference implementation: `apps/web/src/lib/queries/pm-schedules.ts`, `apps/web/src/lib/pm-schedule.ts`.

---

## 9. Migration checklist (technician app)

- [ ] Add `PmOccurrence` model + Supabase service methods (list, detail, complete, photo upload)
- [ ] Implement `deriveOccurrenceStatus()` (section 3)
- [ ] Merge legacy `pm_tasks` + new occurrences in technician PM inbox (or switch fully when legacy empty)
- [ ] Occurrence detail UI with checklist display from `metadata.checklist`
- [ ] Completion flow with `files` bucket upload
- [ ] Realtime subscription on `pm_task_occurrences` (optional)
- [ ] Push handler for `pm_occurrence_assigned` when available
- [ ] QA: admin creates schedule → technician sees occurrence → complete → admin sees completed on web
- [ ] QA: legacy `pm_tasks` still completable until deprecated

**Requestor app checklist:**

- [ ] Confirm no PM queries or UI (section 6)
- [ ] If shared codebase, gate PM routes on `role == technician`

---

## 10. QA scenarios (staging)

1. **Happy path:** Admin creates quarterly schedule for 2 chargers, assigns Tech A → Tech A sees 2+ occurrences → completes one with photo → Admin occurrence detail shows completed.
2. **Overdue:** Occurrence with past `dueDate`, `status=pending` → Flutter shows **Overdue** badge.
3. **RLS:** Tech B cannot read/update Tech A’s occurrence (expect empty or permission error).
4. **Legacy coexistence:** Old `pm_tasks` row still appears and completable alongside new occurrences.
5. **Requestor:** Requestor login → no PM menu, no PM API calls.

---

## 11. Related docs (React repo)

| Doc | Purpose |
|-----|---------|
| `docs/MULTI-APP-CONTEXT.md` | Ecosystem + PM summary |
| `docs/FLUTTER_USER_FLOW.md` | Auth, work orders, **legacy** PM mention (update after migration) |
| `supabase/migrations/20260628160000_pm_schedules_and_occurrences.sql` | Schema + RLS + create RPC |
| `supabase/migrations/20260630120000_pm_occurrence_completion_fields.sql` | Completion/cancel columns |

---

## 12. Out of scope for Flutter v1 (admin / future)

- Creating or editing schedules
- Cancelling or rescheduling occurrences
- Checklist item-level completion tracking
- Auto-extending schedule windows (occurrences are pre-generated for the schedule window)
- Push on assign (admin web gap — see section 5.5)

These may ship in later releases; schema already supports admin-side cancel/reschedule.
