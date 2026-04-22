# React App Quick Start — Admin & Requestor

Quick reference for building the React web app in a separate Cursor project.

## Setup

```bash
npx create-next-app qauto-cmms-web --typescript
cd qauto-cmms-web
npm install @supabase/supabase-js
```

## Supabase Config

```typescript
// lib/supabase.ts
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
```

## Design Tokens (CSS / Tailwind)

```css
:root {
  --color-primary: #000000;
  --color-accent: #002911;      /* Be Electric green */
  --color-error: #D32F2F;
  --color-info: #1976D2;
  --color-warning: #F57C00;
  --color-bg: #F5F5F5;
  --color-surface: #FFFFFF;
  --color-border: #E0E0E0;
  --color-text-secondary: #757575;
  --font-sans: 'Suisse Int\'l', system-ui, sans-serif;
  --radius-card: 16px;
  --radius-button: 8px;
}
```

## Auth Flow

```typescript
// Login
const { data, error } = await supabase.auth.signInWithPassword({ email, password })

// Get user from users table
const { data: user } = await supabase
  .from('users')
  .select('*')
  .eq('id', data.user.id)
  .single()

// Role: user.role → 'admin' | 'manager' | 'requestor'
```

## Key Pages to Build

1. **Login** — Email/password form
2. **Admin Dashboard** — Side nav: Dashboard, Work Orders, PM Tasks, Inventory, Analytics, Users, Companies, Settings
3. **Work Order List** — Table with filters, assign technician
4. **Create Request** (Requestor) — Asset selection → Form (description, priority, category, photos)
5. **My Requests** (Requestor) — List of own work orders
6. **Asset List** — CRUD assets
7. **User Management** — CRUD users, set role
8. **Inventory** — CRUD items, low stock alerts
9. **Parts Request Queue** — Approve/reject
10. **Analytics** — Charts (WO by status, completion rate, etc.)

## Work Order Status Flow

```
open → assigned → inProgress → completed → closed
         ↑                          ↓
         └────── reopened ←──────────┘
```

## Enums (TypeScript)

```typescript
type WorkOrderStatus = 'open' | 'assigned' | 'inProgress' | 'completed' | 'closed' | 'cancelled' | 'reopened'
type WorkOrderPriority = 'low' | 'medium' | 'high' | 'urgent' | 'critical'
type UserRole = 'requestor' | 'technician' | 'manager' | 'admin'
```

## Storage Upload

```typescript
const { data, error } = await supabase.storage
  .from('work-order-photos')
  .upload(`${workOrderId}/${Date.now()}_${file.name}`, file)

const { data: { publicUrl } } = supabase.storage
  .from('work-order-photos')
  .getPublicUrl(data.path)
```

## Full Documentation

See [CMMS_FULL_DOCUMENTATION.md](./CMMS_FULL_DOCUMENTATION.md) for complete schema, flows, and API details.
