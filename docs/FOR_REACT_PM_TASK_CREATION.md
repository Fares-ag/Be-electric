# For the Next.js (beelectric-react) project: How a PM task is created in Flutter

**Context:** This describes how preventive maintenance (PM) tasks are created in the Flutter app so the React admin can stay aligned on flow, payload, and schema.

---

## 1. Where PM tasks are created in Flutter

- **Screen:** `CreatePMTaskScreen` (opened from the technician Quick Create menu → “Create PM Task”, or from the admin/manager PM task list FAB).
- **Entry points:** Technician main screen → “+” → “Create PM Task”; or PM Task list (admin/manager) → FAB “Create PM Task”. The screen can receive an optional `initialAsset` when opened from an asset context (e.g. after QR scan).
- **API:** Flutter does **not** use an RPC for creation. It builds a `PMTask` in memory and then calls **direct INSERT via upsert** on `public.pm_tasks`: `SupabaseDatabaseService.createPMTask(pmTask)` → `_client.from('pm_tasks').upsert(data)`. RLS applies; the user must have INSERT permission on `pm_tasks`.

---

## 2. Form fields collected in Flutter

| Field | Required | Source | Notes |
|-------|----------|--------|--------|
| **Description** | ✅ | Text field | Also used as base for **taskName** (truncated to 50 chars if long). |
| **Asset** | No | Optional asset picker, or “General Facility Maintenance” | If “General Facility Maintenance” is checked: no real asset; `assetId` is sent as **empty string** `''`; a synthetic label (e.g. “General Facility - MEP”) and location are used for display only. |
| **Location** | When general | Text field | Only for general facility tasks; stored in metadata/asset display, not as a top-level column. |
| **Facility type** | When general | Dropdown | e.g. Civil, MEP, Appliances, Electrical, Carpentry, Others; used in the synthetic task/asset label. |
| **Frequency** | ✅ | Dropdown | `daily`, `weekly`, `monthly`, `quarterly`, `semiAnnually`, `annually`, `asNeeded`. |
| **Interval (days)** | Derived | From frequency | Default 30; user can edit. Used to compute **nextDueDate** (e.g. now + interval). |
| **Next due date** | ✅ | Date picker | Default: now + 30 days (or from interval). |
| **Checklist** | Optional | List of items | Each item: `text`, `required` (bool). If none and not general maintenance, Flutter uses a default template (e.g. “Inspect equipment condition”, “Check for visible damage”, …). Serialized as **JSON string** (array of `{ text, required }`). |
| **Assigned technicians** | No | Multi-select | Admin/manager can pick users. **Technician:** Flutter does **not** send selected technicians; the provider **auto-assigns** the current user (creator) when `createdById` is a technician. |

**Creator tracking:** The app passes `createdById` (current user id). If no technicians are selected and the creator is a technician, the provider auto-adds the creator to `assignedTechnicianIds`.

---

## 3. Data flow (Flutter → Supabase)

1. User submits the form → `CreatePMTaskScreen._createPMTask()`.
2. **UnifiedDataProvider.createPMTask()** is called with: `taskName`, `assetId`, `asset` (optional), `description`, `checklistJson`, `frequency`, `nextDue`, `assignedTechnicianIds` (null for technician → auto-assign), `createdById`.
3. Provider: if `assignedTechnicianIds` is empty and `createdById` is a technician, it sets `assignedTechnicianIds = [createdById]`.
4. **UnifiedDataService.createPMTask()** builds a **PMTask** with: `id` (deterministic or UUID), `taskName`, `assetId`, `assetName`/`assetLocation` from asset if present, `description`, `checklist` (JSON string), `frequency`, `intervalDays` (from frequency), `nextDueDate`, `assignedTechnicianIds`, `primaryTechnicianId`, `createdAt`/`updatedAt`, `createdById`.
5. **SupabaseDatabaseService.createPMTask(pmTask)** converts the task via **_convertPMTaskToSupabaseMap()** and then **upserts** into `pm_tasks`.

---

## 4. What is written to `public.pm_tasks`

**Table columns (from Flutter’s _convertPMTaskToSupabaseMap):**

| Column | Source | Notes |
|--------|--------|--------|
| **id** | Generated | Deterministic from taskName/assetId/timestamp, or explicit id. |
| **taskName** | Form (description-based) | Required. |
| **assetId** | Form / general | Required in schema; Flutter may send **empty string** for “General Facility” tasks. |
| **description** | Form | Text. |
| **assignedTechnicianIds** | Form or auto-assign | Array of user ids. |
| **frequency** | Form | One of: daily, weekly, monthly, quarterly, semiAnnually, annually, asNeeded. |
| **frequencyValue** | Derived | Integer (interval days): 1, 7, 30, 90, 180, 365, 0 for asNeeded. |
| **nextDueDate** | Form (date picker) | Required. |
| **lastCompletedDate** | — | Null on create. |
| **status** | Default | `pending`. |
| **estimatedDuration** | — | Null on create (from toMap if present). |
| **createdAt** / **updatedAt** | now | Set on create. |
| **idempotencyKey** | Optional | From model if present. |
| **completionPhotoPath** | — | Null on create. |
| **metadata** | JSONB | See below. |

**Metadata (JSONB):** Flutter packs into `metadata` (when present): `assetName`, `assetLocation`, `checklist` (the JSON string), `primaryTechnicianId`, `startedAt`, `completedAt`, `completionNotes`, `technicianSignature`, `technicianEffortMinutes`, `isOffline`, `lastSyncedAt`, `laborCost`, `partsCost`, `totalCost`, `isPaused`, `pausedAt`, `pauseReason`, `resumedAt`, `pauseHistory`, `completionHistory`, **createdById**. So **checklist** and **createdById** are in metadata on create; the rest are for later updates.

---

## 5. Schema note: assetId

The migration defines `pm_tasks.assetId` as **NOT NULL**. Flutter sends **empty string** for “General Facility Maintenance” tasks. If your Postgres or RLS does not accept `''` for a NOT NULL text column, you may need a default (e.g. a sentinel like `'GENERAL'`) or to allow empty string; the React app and any triggers should treat empty or `'GENERAL'` as “no specific asset.”

---

## 6. Who can create PM tasks in Flutter

- **Technician:** Can open Create PM Task from Quick Create. No technician selection; they are **auto-assigned** as the only assigned technician. They can create tasks with or without an asset (including “General Facility”).
- **Admin/Manager:** Can open from the PM task list FAB; can select one or more assigned technicians (or leave unassigned).

---

## 7. Summary for the React Cursor

- **No RPC:** PM task creation is a direct **upsert** into `public.pm_tasks` (authenticated client).
- **Payload:** taskName, assetId (possibly `''`), description, assignedTechnicianIds, frequency, frequencyValue (interval days), nextDueDate, status, createdAt, updatedAt; checklist and createdById (and other optional fields) in **metadata**.
- **Technician creation:** Creator is auto-assigned when they are a technician; no other assignees are sent.
- **General facility:** assetId = `''`; asset display info (name/location/facility type) is reflected in task name and metadata, not in a separate asset row.

Use this so the Next.js admin’s create/edit PM task form and list/detail views stay consistent with what Flutter sends and what the shared schema expects.
