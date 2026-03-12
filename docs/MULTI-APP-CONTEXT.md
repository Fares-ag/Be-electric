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
- **RPCs for Flutter** are defined in this repo: `get_user_by_email(p_email)`, `upsert_work_order(p_row jsonb)` (see `supabase/migrations/20260311140000_flutter_sync_rpcs.sql`). Run that migration (or the ensure script) so Flutter can resolve users and create work orders.

### Env (all apps)

- `SUPABASE_URL` — same for all (e.g. from React `apps/web/.env.example`).
- `SUPABASE_ANON_KEY` — same anon key for all.
- No need for service role in mobile apps; use anon + RLS.

### Admin portal: seeing requestor-created work orders

- Work orders created by the Flutter requestor (via RPC `upsert_work_order`) are stored in `public.work_orders`. If they don’t show in the admin portal, the usual cause is **RLS**: the admin user is not treated as admin/manager.
- **`get_my_role()`** (used by “Admins can read all work orders”) now checks **`public.admin_users` first**: if the logged-in user’s email is in `admin_users` with `is_admin` or `is_manager`, it returns `'admin'`. Otherwise it uses `public.users.role`. That way admins who were synced from auth with role `'requestor'` still get admin visibility.
- **To fix:** Ensure the admin’s email exists in `public.admin_users` with `is_admin = true` or `is_manager = true`. Run `supabase/fix-once-and-for-all.sql` (or the same `get_my_role()` definition) in the Supabase SQL Editor so the function is deployed. Diagnostic: `supabase/diagnose-admin-work-orders.sql` (replace `YOUR_ADMIN_EMAIL` and run).

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
