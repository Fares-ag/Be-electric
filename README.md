# Be Electric — QAuto CMMS

Monorepo for the QAuto CMMS React web app (Admin + Requestor).

## Structure

```
beelectric-react/
├── apps/
│   └── web/          # Next.js 14 app (Admin + Requestor)
├── packages/
│   ├── supabase/     # Supabase client, types
│   └── ui/           # Design system (Be Electric brand)
├── package.json
└── turbo.json
```

## Setup

1. Install dependencies:

```bash
npm install
```

2. Copy env and add your Supabase credentials:

```bash
cp apps/web/.env.example apps/web/.env.local
```

Default values (from docs):

```
NEXT_PUBLIC_SUPABASE_URL=https://sdhqjyjeczrbnvukrmny.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=sb_publishable_jymzllhRW_CVJH6pY3qleA_7GRd1ETA
```

3. Run dev (from repo root):

```bash
npm run dev
```

Or from the web app: `cd apps/web && npx next dev`

**Supabase:** The app connects to your **hosted** Supabase project via the env vars above. No local database is required. To run SQL or migrations on the hosted DB, use the [Supabase Dashboard](https://supabase.com/dashboard) SQL Editor or `supabase db push` (after `supabase link`). The `supabase/` folder’s local config is only for optional local dev (`supabase start`).

## Build

```bash
npm run build
```

## E2E tests (Playwright)

From `apps/web`: `npm run e2e`. Starts the dev server if needed and runs smoke tests (login, parts-requests, request page). For UI: `npm run e2e:ui`.

## Routes

### Admin / Manager
- `/dashboard` — Summary cards
- `/work-orders` — Work order list with filters
- `/work-orders/:id` — Work order detail
- `/pm-tasks` — PM task list
- `/assets` — Asset list
- `/users` — User management
- `/companies` — Company management
- `/inventory` — Inventory items, low stock
- `/parts-requests` — Approve/reject technician requests
- `/purchase-orders` — Purchase orders
- `/analytics` — Analytics dashboard
- `/reports` — Export reports
- `/settings` — App settings
- `/notifications` — Notifications

### Requestor
- `/request` — Create maintenance request
- `/my-requests` — Own work orders
- `/requestor-analytics` — Own stats
- `/notification-settings` — Notification prefs
- `/notifications` — Notification list

## Demo credentials

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@qauto.com | demo123 |
| Requestor | requestor@qauto.com | demo123 |

## Local full stack (Docker + Supabase CLI)

Run Supabase and the web app with one command. Requires **Docker** and **Supabase CLI** (e.g. `npm install -g supabase` or use `npx supabase`).

### One command (recommended)

```bash
npm run stack:up
```

This will:

1. Start Supabase locally (if not already running) via `supabase start` (Docker).
2. Write `apps/web/.env.local` and `.env.docker` with the local API URL and anon key.
3. Build and run the web app in Docker (`docker compose up --build`).

- **App:** http://localhost:3000  
- **Supabase Studio:** http://localhost:54323  
- **API (Kong):** http://localhost:54321  

### Manual (two steps)

```bash
# 1. Start Supabase (CLI uses Docker under the hood)
npm run supabase:start

# 2. Copy local env and start the app in Docker
npx supabase status -o env   # copy ANON_KEY and API_URL into .env.docker
docker compose --env-file .env.docker up --build
```

Or run the app on the host (no Docker for app):

```bash
npm run supabase:start
# Create apps/web/.env.local with NEXT_PUBLIC_SUPABASE_URL=http://localhost:54321 and NEXT_PUBLIC_SUPABASE_ANON_KEY from: npx supabase status -o env
npm run dev
```

### CLI usage

With Supabase running, you can use the CLI as usual:

- `npm run supabase:status` — URLs and keys  
- `npx supabase db reset` — reset DB and run migrations  
- `npx supabase migration new <name>` — create a migration  
- Apply RLS: either run migrations (`npx supabase db reset` or `npx supabase migration up`) so `supabase/migrations/*.sql` apply, or paste `supabase/rls-policies.sql` into **Supabase Studio → SQL Editor** (http://localhost:54323) and run it.

### Stop

```bash
npm run stack:down   # stop web container only
npm run supabase:stop   # stop Supabase containers
```

### Pull schema from Supabase

To sync the project with your hosted Supabase database:

1. **Link** (one-time, prompts for DB password):  
   `npx supabase link --project-ref <your-project-ref>`

2. **Types only** – regenerate `supabase/database.types.ts` from the linked project:  
   ```bash
   npx supabase gen types typescript --linked > supabase/database.types.ts
   ```  
   (Use `cmd` on Windows if PowerShell corrupts the file; or run the command and paste the output into `supabase/database.types.ts`.)

3. **Full schema** (SQL migration in `supabase/migrations/`; requires Docker):  
   `npx supabase db pull --linked`

---

## Supabase setup

### Storage (photo uploads)

The migration `20260311210000_storage_bucket_work_order_photos.sql` creates the `work-order-photos` bucket. After running migrations, in Supabase Dashboard → Storage → work-order-photos: set **Public bucket** and allow authenticated users to upload (Storage policies). If you don’t run migrations, create the bucket manually and name it `work-order-photos`.

### Realtime

Realtime is enabled by default on Supabase. Ensure your project has Realtime turned on for `work_orders` and `notifications` in Database → Replication.

### Login without `users` table

If you sign in with Supabase Auth but don't have a matching row in `public.users`, the app uses a fallback user with role `requestor`. Add rows to `users` (with `id` = `auth.users.id`) to assign admin/manager roles.

## Security & keys

- **Do not commit real API keys.** Use `.env.local` (gitignored) and keep `NEXT_PUBLIC_SUPABASE_ANON_KEY` and any secret keys out of the repo. If keys were ever committed, rotate them in the Supabase dashboard and update local env.
- Next.js is kept at a patched version (14.2.35+) for security fixes.

## Design system

- Brand: Be Electric (accent green `#002911`)
- Tokens in `packages/ui/src/design-tokens.ts`
- Components: Button, Card, Input, StatusBadge, PriorityBadge
