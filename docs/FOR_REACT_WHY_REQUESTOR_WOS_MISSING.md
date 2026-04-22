# For the Next.js (beelectric-react) project: Why work orders created by the Flutter requestor don’t show in the admin portal

**Context (from the Flutter side):** This doc is meant to be copy-pasted or summarized in the React Cursor so the admin app can fix why requestor-created work orders don’t appear there.

---

## 1. How the Flutter requestor creates a work order

- The **requestor app** creates work orders via the **RPC** `upsert_work_order(p_row jsonb)` (in `supabase/migrations/20260311060600_work_orders_upsert_rpc.sql` and `scripts/apply_work_order_upsert_rpc.sql`).
- That function is **SECURITY DEFINER** and inserts/updates directly into `public.work_orders`. So the row **does** get written to the database; it’s not a “insert failed” issue.
- Flutter calls: `supabase.rpc('upsert_work_order', params: {'p_row': data})` with a payload built from the requestor’s `WorkOrder` (including `requestorId`, `companyId`, etc.).

So: **requestor-created work orders are real rows in `public.work_orders`.** If they don’t show in the admin portal, the cause is either **RLS** (admin can’t see the row) or **app-side filtering** in the Next.js app (e.g. only “my company” work orders).

---

## 2. Why the admin might not see those rows (RLS)

Admin visibility for **all** work orders is gated by SELECT policies that depend on the **admin user existing in `public.users`** with the right role.

- **Policy “Admins can read all work orders”**  
  Uses `get_my_role() = ANY (ARRAY['admin','manager'])`.  
  `get_my_role()` is defined as:  
  `SELECT role::text FROM public.users WHERE id::text = auth.uid()::text LIMIT 1`  
  So:
  - The logged-in user must have a row in `public.users`.
  - That row’s `id` must equal `auth.uid()` (same user).
  - That row’s `role` must be `'admin'` or `'manager'`.  
  If any of these fail (e.g. no row, or role is something else), `get_my_role()` returns NULL and this policy does **not** allow the admin to see the row.

- **Policy “work_orders_select_policy”**  
  Allows select if the user is admin/manager **by matching `public.users` to `auth.users` by email** and checking `u.role IN ('admin','manager')`. So again: the admin must exist in `public.users` with the same email as in `auth.users` and role admin/manager.

**Conclusion:** If the admin portal user is not correctly represented in `public.users` (same `id` as `auth.uid()`, or same email + role admin/manager), then **RLS will hide some or all work orders** from that user, including the ones created by the Flutter requestor.

---

## 3. Why the admin might not see them (app-side filtering)

Even if RLS allows the admin to see all rows, the **Next.js app** might:

- Only fetch work orders for “my company” (e.g. `companyId = currentUser.companyId`).
- Use a view or API that filters by company.

If the requestor created the work order with a **different** `companyId` than the admin’s, and the admin UI only shows “work orders in my company,” then those requestor-created work orders won’t appear.

---

## 4. What to check in the React repo

1. **Admin user in `public.users`**  
   - For the account used in the admin portal: ensure there is a row in `public.users` with:
     - `id = auth.uid()` (so `get_my_role()` works), **or** at least the same email as in `auth.users` and `role IN ('admin','manager')` for the email-based policy.
   - If admins are created only in `auth.users` and never synced to `public.users`, then `get_my_role()` will return NULL and “Admins can read all work orders” will never pass.

2. **How work orders are loaded in the admin portal**  
   - If the UI filters by `companyId` (e.g. “only my company”), ensure that **admin/manager** users either:
     - See all companies’ work orders, or  
     - Have a way to see work orders for the same company as the requestor (and that the Flutter app sets `companyId` correctly when the requestor creates the work order).

3. **RLS and `get_my_role()`**  
   - Confirm that `get_my_role()` is used with the same `public.users` shape you expect (e.g. `users.id` = UUID string matching `auth.uid()`) and that admin/manager roles are set correctly so that “Admins can read all work orders” applies to the admin portal user.

---

## 5. Short summary for the React Cursor

- Flutter requestor creates work orders via **RPC `upsert_work_order`**; rows **are** in `public.work_orders`.
- If they don’t show in the admin portal, the cause is either:
  - **RLS:** Admin user missing or wrong in `public.users` (so `get_my_role()` isn’t admin/manager and “Admins can read all work orders” doesn’t apply), or
  - **App:** Admin UI only shows work orders for “my company” and the requestor’s work order has a different `companyId`.

Fix by ensuring admin users exist in `public.users` with correct role (and id/email) and that the admin app does not over-filter work orders for admin/manager users.
