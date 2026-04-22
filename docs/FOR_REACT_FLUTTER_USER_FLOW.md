# For the Next.js (beelectric-react) project: Entire user flow in the Flutter app

**Context:** This document describes how users (Requestor and Technician) move through the Flutter app so the React admin can stay aligned on auth, roles, and data usage. Copy or paste into the React Cursor as needed.

---

## 1. App scope and roles in Flutter

- **Flutter app serves:** **Requestor** and **Technician** only.
- **Admin** and **Manager** are not served by the Flutter app; they are directed to the web (React) app (see `docs/FLUTTER_APP_MODIFICATIONS.md` — `WebAppRedirectScreen`).
- **Roles** come from `public.users.role` and are resolved after Supabase Auth login via `getUserByEmail` / `getUserById` (RPCs). The app uses `User.isRequestor`, `User.isTechnician`, `User.isAdminOrManager`, etc.

---

## 2. Authentication flow

1. **Login screen**  
   User enters email + password.

2. **Supabase Auth**  
   `SupabaseAuthService.signInWithEmailAndPassword(email, password)` → `auth.signInWithPassword`. On success, we have `auth.uid()` and `auth.users` row.

3. **Resolve app user (role, name, companyId)**  
   - Call `SupabaseDatabaseService.getUserByEmail(email)` which uses RPC **`get_user_by_email(p_email)`** (SECURITY DEFINER) to read from `public.users`.  
   - If a row exists: use it → `currentUser` has `id`, `role`, `name`, `companyId`, etc.  
   - If no row and `AppConfig.autoCreateUsersOnLogin` is true (or it’s the first user): create user via RPC **`insert_user(p_row)`**, then load again.  
   - If no row and auto-create is false: login fails with a message that the user must be created by an admin first.  
   - **Demo mode** (debug only): demo users (e.g. `requestor@qauto.com`, `technician@qauto.com`) can log in with a fixed password; they are either loaded from `public.users` or created as in-memory demo users.

4. **Session persistence**  
   On successful login, Flutter stores `current_user_id` in `SharedPreferences` and keeps `currentUser` in `AuthProvider`.  
   On app start, `checkAuthStatus()` runs: if Supabase is signed in, it loads the app user from DB again (to get latest role); otherwise it tries to restore from `current_user_id` via `getUserById`.

5. **Logout**  
   `SupabaseAuthService.signOut()` plus clear `current_user_id` and `AuthProvider.currentUser`.

**Important for React:**  
- Flutter depends on **`public.users`** for role and identity. Admin-created users in the React app (with correct `id` = auth UUID and `role`) will log in correctly in Flutter.  
- User lookup uses RPCs: `get_user_by_email`, `get_user_by_id`, `get_users_list` (and `insert_user` / `update_user` / `delete_user_by_id` for writes). Flutter does not read `public.users` via direct table SELECT.

---

## 3. Requestor flow

### 3.1 After login

- Role is `requestor` → app shows **Requestor** experience (e.g. `RequestorMainScreen`).
- Requestor can: create maintenance requests, view “My Requests,” view analytics for own requests, manage notification settings.

### 3.2 Create maintenance request (work order)

1. User chooses asset type (e.g. Siemens / Kostad charger) or scans QR.  
2. Fills form: problem description (required), priority, category, optional photos and notes.  
3. **Submit** → Flutter builds a `WorkOrder` with:
   - `requestorId` = current user id (`currentUser.id`, which matches `auth.uid()` when user was created from Auth),
   - `requestorName` = current user name,
   - `companyId` = current user’s company (if set),
   - `assetId` if an asset was selected,
   - `status` = open (or equivalent),
   - other fields (priority, category, photoPath/metadata, etc.).

4. **Create in backend:**  
   Flutter does **not** insert into `work_orders` directly. It calls the RPC **`upsert_work_order(p_row)`** with the work order as JSONB.  
   - That function is **SECURITY DEFINER** and performs INSERT (or ON CONFLICT UPDATE) into `public.work_orders`.  
   - So the row is created in the same table the React admin uses; visibility in the admin is purely an RLS / app-filtering issue (see `FOR_REACT_WHY_REQUESTOR_WOS_MISSING.md`).

### 3.3 View “My Requests”

- Flutter either:
  - Calls **`getAllWorkOrders()`**, which runs `from('work_orders').select().order('createdAt', ascending: false)`, or  
  - Subscribes to **`listenToWorkOrders()`**, which streams `work_orders` with the same ordering.  
- **RLS** on `work_orders` restricts rows so the requestor only sees rows where `requestorId` = `auth.uid()`. So “My Requests” is exactly the set of work orders they created (or are otherwise allowed by RLS).  
- No client-side filter by `requestorId` is required; the backend enforces it.

---

## 4. Technician flow

### 4.1 After login

- Role is `technician` → app shows **Technician** experience (e.g. `TechnicianMainScreen`).
- Technician sees: assigned work orders, assigned PM tasks, parts requests, QR scanner, and technician-scoped analytics.

### 4.2 Assigned work orders and PM tasks

- **Work orders:**  
  Flutter uses **`getWorkOrdersByTechnician(technicianId)`** with `technicianId` = current user id.  
  Query: `from('work_orders').select().contains('assignedTechnicianIds', [technicianId]).order('createdAt', ascending: false)`.  
  RLS also applies, so the technician only sees work orders they are allowed to see (assigned to them).  
- **PM tasks:**  
  Similar idea: query/stream `pm_tasks` filtered by `assignedTechnicianIds` containing the current user.  
- **Realtime:**  
  Flutter can use `listenToWorkOrders()` and `listenToPMTasks()`; RLS again limits the stream to rows the technician is allowed to see.

### 4.3 Work on a work order

- Technician opens an assigned work order.  
- **Start work** → Flutter updates the row (e.g. `status` → in progress, `startedAt`) via **`updateWorkOrder(workOrderId, workOrder)`**, which does `from('work_orders').update(data).eq('id', workOrderId)`.  
- RLS: technician can only update work orders where they are in `assignedTechnicianIds` (see migration `work_orders_update_policy`).  
- **Complete work** → Technician fills corrective actions, recommendations, completion photos, technician signature, etc. Flutter updates the same work order (status completed, completion fields).  
- Requestor can then sign off (requestor signature); that update is also done via the same update path (RLS allows requestor to update own work orders).

### 4.4 Parts requests

- From an assigned work order, technician can create a **parts request**.  
- Flutter inserts into `parts_requests` (with `workOrderId`, `requestedBy` = current user, etc.).  
- RLS allows technicians to insert with `requestedBy` = self and to read their own or those tied to work orders assigned to them.  
- Admin/Manager in the **React** app approve or reject parts requests and manage inventory.

### 4.5 QR / assets

- Technician can scan a QR code to open an asset and see related work orders or create a request.  
- Asset and work order data are read via Supabase with the same RLS that applies to technicians (e.g. company/assignment visibility as defined in your policies).

---

## 5. Data and API summary (for alignment with React)

| Concern | Flutter behavior |
|--------|-------------------|
| **Auth** | Supabase Auth (email/password). Session = auth.uid() + app user from `public.users`. |
| **User resolution** | RPCs: `get_user_by_email`, `get_user_by_id`, `get_users_list`. Optional auto-create via `insert_user` (first user or if enabled). |
| **Work order create (requestor)** | RPC **`upsert_work_order(p_row)`** only. No direct INSERT into `work_orders`. |
| **Work order read** | Direct `from('work_orders').select()` or stream; RLS filters by requestorId / assignedTechnicianIds / admin-manager. |
| **Work order update** | Direct `from('work_orders').update(data).eq('id', id)`. RLS: technician (assigned only), requestor (own), admin/manager (all). |
| **Technician “my work orders”** | `getWorkOrdersByTechnician(technicianId)` = filter by `assignedTechnicianIds`; RLS still applied. |
| **Requestor “my requests”** | No explicit requestorId filter in Flutter; RLS returns only rows where requestorId = auth.uid(). |
| **Parts requests** | Direct table insert/select; RLS by requestedBy, work order assignment, and admin/manager. |
| **Companies** | User has `companyId` from `public.users`. Work orders created by requestor carry that `companyId` when set in the app. |

---

## 6. Role-based navigation (intended)

- **requestor** → Requestor main (create request, my requests, analytics, notifications).  
- **technician** → Technician main (assigned work orders, PM tasks, parts, QR, analytics).  
- **admin / manager** → Redirect to web app (React) with a message; they do not use the Flutter app for admin tasks.

---

## 7. What React should assume

- **Same Supabase project:** Auth users and `public.users` are shared. A user created or updated in the React admin (with correct `id` and `role`) will behave correctly in Flutter.  
- **Work orders** created in Flutter (requestor) are in `public.work_orders`; if they don’t show in the admin, the cause is RLS or admin UI filtering (see `FOR_REACT_WHY_REQUESTOR_WOS_MISSING.md`).  
- **RLS and RPCs** in `supabase/` (migrations, `get_my_role`, `get_user_by_email`, `upsert_work_order`, etc.) are the single source of truth; Flutter does not implement its own permission logic beyond using these APIs and respecting the same role names and table shapes.

This is the entire user flow on the Flutter side as it relates to the shared backend and the React admin.
