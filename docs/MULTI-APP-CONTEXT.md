# Beelectric CMMS — Multi-app shared context

This document is the **single source of truth** for how the React admin app and the two Flutter apps (technician + requestor) fit together. Keep it in sync in **both** Cursor projects so the AI in each project has the same picture.

---

## Apps in the ecosystem

| App | Repo / Cursor project | Stack | Purpose |
|-----|------------------------|--------|---------|
| **Admin (web)** | `beelectric-react` (this repo) | Next.js, React, Turborepo | Back-office: companies, users, work orders, assignments, reports |
| **Technician** | Flutter project (separate Cursor workspace) | Flutter / Dart | Field technicians: view/complete assigned work orders |
| **Requestor** | Flutter project (separate Cursor workspace) | Flutter / Dart | Requestors: create/view requests, track status |

---

## Shared backend: Supabase

- **One Supabase project** for all three apps.
- **Auth**: Supabase Auth (email/password, etc.). Same `auth.users`; app-specific roles via `public.users.role` and `public.admin_users`.
- **Database**: PostgreSQL under `public`; schema and migrations live in the **React repo** (`supabase/`).
- **RLS**: Row Level Security policies are defined in the React repo; any change here affects Flutter apps too.
- **Realtime**: Optional; same Supabase Realtime for all clients.

### Key tables / concepts (high level)

- `public.users` — extended profile, `role` (e.g. technician, requestor, admin).
- `public.admin_users` — admin/manager flags for back-office.
- Work orders, companies, and related entities are in the same DB; Flutter apps read/write according to RLS.

### Flutter user flow (for React alignment)

- **`docs/FLUTTER_USER_FLOW.md`** — Full requestor/technician flow: auth, RPCs (`get_user_by_email`, `upsert_work_order`, etc.), how work orders and parts requests are created/read, and what React should assume. Use it when changing users, roles, work orders, or RLS so the admin stays aligned with the Flutter app.
- **`docs/WORK_ORDER_REOPEN.md`** — How work order reopening works in Flutter: only requestor can reopen; status must be completed/closed/cancelled; reopen data (reopenedAt, reopenReason, reopenCount, previousCompletionDate, previousStatus) lives in **`work_orders.metadata`**; status column is set to `reopened`. Use it for reopen history in the admin and for any web reopen feature.
- **RPCs for Flutter** are defined in this repo: `get_user_by_email(p_email)`, `upsert_work_order(p_row jsonb)` (see `supabase/migrations/20260311140000_flutter_sync_rpcs.sql`). Run that migration (or the ensure script) so Flutter can resolve users and create work orders.

### Env (all apps)

- `SUPABASE_URL` — same for all (e.g. from React `apps/web/.env.example`).
- `SUPABASE_ANON_KEY` — same anon key for all.
- No need for service role in mobile apps; use anon + RLS.

### Admin portal: seeing requestor-created work orders

- Work orders created by the Flutter requestor (via RPC `upsert_work_order`) are stored in `public.work_orders`. If they don’t show in the admin portal, the usual cause is **RLS**: the admin user is not treated as admin/manager.
- **`get_my_role()`** (used by “Admins can read all work orders”) now checks **`public.admin_users` first**: if the logged-in user’s email is in `admin_users` with `is_admin` or `is_manager`, it returns `'admin'`. Otherwise it uses `public.users.role`. That way admins who were synced from auth with role `'requestor'` still get admin visibility.
- **To fix:** Ensure the admin’s email exists in `public.admin_users` with `is_admin = true` or `is_manager = true`. Run `supabase/fix-once-and-for-all.sql` (or the same `get_my_role()` definition) in the Supabase SQL Editor so the function is deployed. Diagnostic: `supabase/diagnose-admin-work-orders.sql` (replace `YOUR_ADMIN_EMAIL` and run).

### Security hardening (June 2026)

- **`public.users` / `public.admin_users`**: RLS re-enabled; direct `anon` table grants revoked.
- **User RPCs** (`get_user_by_id`, `get_user_by_email`, `get_users_list`, `insert_user`, `update_user`, `delete_user_by_id`, `get_admin_by_email`): authenticated only; self-read or admin-scoped. Flutter must call these **after** `signInWithPassword` (JWT present).
- **`upsert_work_order`**: requires auth; non-admin callers must set `requestorId = auth.uid()`; `anon` EXECUTE revoked (migration `20260629140000`).
- **Inventory / purchase orders**: admin/manager only. **Parts requests**: admin manage + users read/insert own rows.
- **Work order INSERT RLS**: `requestorId` must match `auth.uid()` unless admin/manager.

---

## Be Electric Support (requestor + admin inbox)

Requestors submit **Know How** and **Commissioning** requests from the Flutter app. Admin staff review them in **Support Inbox** (`/support-requests`).

### Table: `support_requests`

| Column | Notes |
|--------|--------|
| `type` | `knowHow` \| `commissioning` |
| `status` | Requestor creates `submitted`; admin sets `in_progress`, `resolved`, `closed` |
| `summary`, `topic`, `question` | Know How fields |
| `chargerModel`, `chargerSerialNumber`, `address`, `country`, `scheduledDate`, `details` | Commissioning fields |
| `attachments` | jsonb URL array (Storage bucket `files`, path `support_requests/{id}/{fileName}`) |
| `createdBy` | text FK → `users.id` (not `requesterId`) |
| `companyId` | text FK → `companies.id` |
| `staffReply` | text — admin sets; requestor reads in mobile detail |

No RPCs. No threaded `support_request_messages` table (removed; use `staffReply`).

### RLS

| Role | Access |
|------|--------|
| Requestor | INSERT/SELECT own rows (`createdBy = auth.uid()::text`) |
| Admin/manager | Full CRUD via `get_my_role() IN ('admin','manager')` |

### Admin web

- List/detail at `/support-requests` — update **`staffReply`** and **`status`** only.
- Do not use legacy columns (`ticketNumber`, `subject`, `requesterId`).

---

## Preventive maintenance (Option A — schedules + occurrences)

New PM work uses **`pm_schedules`** (template) and **`pm_task_occurrences`** (one row per charger × due date). Legacy **`pm_tasks`** remains for existing mobile data until Flutter migrates.

### Tables

| Table | Purpose |
|-------|---------|
| `pm_schedules` | Admin-created template: task name, frequency, schedule window, company, assigned technicians |
| `pm_task_occurrences` | Materialized due dates per asset; technicians complete these individually |
| `pm_tasks` | **Legacy** — do not create new rows from admin; Flutter may still read until migrated |

### Flutter technician app — migration checklist

1. **Query `pm_task_occurrences`** instead of `pm_tasks` for assigned work lists.
2. **Filter**: `auth.uid()::text = ANY("assignedTechnicianIds")` (RLS enforces this).
3. **Complete** an occurrence: `UPDATE` status to `completed`, set `completedAt`, optional `completionPhotoPath`, `completionNotes`, and `completedById`.
4. **Cancel / reschedule** (admin): set `status = 'cancelled'` with `cancelReason`, `cancelledAt`, `cancelledById`, or change `dueDate` (unique per schedule × asset × date).
5. **Overdue**: derive client-side — `status = 'pending'` and `dueDate < today` → show as overdue (stored status stays `pending` in v1).
6. **Upcoming**: derive client-side — not completed/cancelled and `dueDate >= today` → show as upcoming; admin **Upcoming tasks** view lists these across schedules (`/pm-schedules?view=upcoming`).
7. **Read schedule context**: join `pm_schedules` on `scheduleId` for task name, description, frequency, optional `metadata.checklist` (string array).
8. RPC **`create_pm_schedule_with_occurrences`** is admin-only (web); mobile does not call it.

### RLS summary

- **Admin/manager**: full CRUD on `pm_schedules` and `pm_task_occurrences`.
- **Technician**: SELECT + UPDATE occurrences where assigned; SELECT parent schedule when assigned to any occurrence.

---

## Keeping the two Cursor projects in sync

Cursor does **not** support chat between workspaces. To keep context aligned:

1. **React project (this repo)**  
   - Has `.cursor/rules/multi-app-sync.mdc` (always apply) so the AI knows about the Flutter apps and shared Supabase.  
   - Has this file: `docs/MULTI-APP-CONTEXT.md`.

2. **Flutter project**  
   - Copy this file (`MULTI-APP-CONTEXT.md`) into the Flutter repo (e.g. `docs/` or project root).  
   - Add a Cursor rule there that says: “This is the Beelectric technician/requestor app; the admin app is a React/Next.js repo (beelectric-react). Shared backend: Supabase. See `docs/MULTI-APP-CONTEXT.md` for full context.”

3. **When you change something that affects both**  
   - Schema/RLS/API: update the React repo first, then update this doc (and any Flutter-side docs) if needed.  
   - In the Flutter project, mention “see MULTI-APP-CONTEXT” so the AI can reason about the admin app and shared backend.

---

## Optional: one workspace for both

If you want **one** Cursor workspace that sees both codebases, open a parent folder that contains both repos (e.g. `beelectric/` with `beelectric-react/` and `beelectric-flutter/`). Then both codebases and this doc are in the same context.
