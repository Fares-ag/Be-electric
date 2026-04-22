# For the Next.js (beelectric-react) project: How work order reopening happens in Flutter

**Context:** When a requestor reopens a completed/closed (or cancelled) work order in the Flutter app, the following flow and data apply. Use this in the React admin to display reopen history and stay aligned on behavior.

---

## 1. Who can reopen

- **Only the requestor** who created the work order (`requestorId` = current user) can reopen it. The provider validates `workOrder.requestorId == currentUserId` and throws otherwise.
- In the Flutter UI, the **Reopen** button is shown only when the work order is **completed or closed** and the current user is the requestor. The backend also allows reopening when status is **cancelled**, but the detail screen does not show the button for cancelled in the current build.

---

## 2. When reopen is allowed

- **Status:** Work order must be **completed**, **closed**, or **cancelled**. Reopening from open/assigned/inProgress is not allowed.
- **Reopen count:** Optional limit (default **3**). If `reopenCount >= maxReopenCount`, the provider throws. Flutter uses `maxReopenCount: 3` in `reopenWorkOrder()`.

---

## 3. Flow in Flutter

1. User opens **WorkOrderDetailScreen** for their own work order that is completed or closed.
2. User taps **Reopen Work Order**.
3. **ReopenWorkOrderDialog** is shown:
   - **Reason for Reopening** (required, min 10 characters).
   - Optional: **Edit Problem Description** (checkbox); if checked, an **Updated Problem Description** field (optional, min 10 chars if provided).
   - Dialog returns `{ reopen: true, reason: string, editedDescription?: string }`.
4. **UnifiedDataProvider.reopenWorkOrder()** is called with:
   - `workOrderId`
   - `currentUserId` (must equal `requestorId`)
   - `reason` (required)
   - `editedDescription` (optional; if provided, replaces `problemDescription`)
   - `maxReopenCount` (default 3).
5. Provider fetches the latest work order from Supabase, validates status and requestor, then builds an updated work order and calls **updateWorkOrder** (direct UPDATE on `work_orders`).

---

## 4. What changes when reopening

The provider builds an updated work order with:

| Field | New value |
|-------|-----------|
| **status** | `reopened` (not `open`) |
| **assignedTechnicianIds** | `[]` (cleared – unassigned) |
| **primaryTechnicianId** | `null` |
| **assignedTechnicians** | `null` |
| **assignedAt** | `null` |
| **startedAt** | `null` |
| **completedAt** | `null` |
| **closedAt** | `null` |
| **problemDescription** | `editedDescription` if provided, else unchanged |
| **reopenedAt** | `now` (timestamp of reopen) |
| **reopenedBy** | `currentUserId` (requestor id) |
| **reopenReason** | user-entered reason |
| **reopenCount** | `workOrder.reopenCount + 1` |
| **previousCompletionDate** | `workOrder.completedAt ?? workOrder.closedAt` (preserved before clear) |
| **previousStatus** | previous status (completed/closed/cancelled) |
| **updatedAt** | `now` |
| **isPaused** | `false` |
| **pausedAt** / **pauseReason** / **resumedAt** | `null` |

Completion data (correctiveActions, recommendations, signatures, completion photos, etc.) is **not** cleared; only the timestamps and assignment fields above are reset. So the row keeps completion details for history; the admin can show “last completed at” and “reopen reason” from the reopen fields.

---

## 5. Where reopen data is stored in the DB

- Flutter sends the work order update via **direct UPDATE** on `public.work_orders` (same as other work order updates). The `WorkOrder.toMap()` includes `reopenedAt`, `reopenedBy`, `reopenReason`, `reopenCount`, `previousCompletionDate`, `previousStatus`.
- In **SupabaseDatabaseService.updateWorkOrder()**, these fields are **removed** from the top-level update payload and merged into the row’s **`metadata`** JSONB. So in the database, reopen data typically lives under **`work_orders.metadata`**:
  - `metadata.reopenedAt` (ISO8601 string)
  - `metadata.reopenedBy` (user id)
  - `metadata.reopenReason` (text)
  - `metadata.reopenCount` (number)
  - `metadata.previousCompletionDate` (ISO8601 string)
  - `metadata.previousStatus` (string: completed | closed | cancelled)

When **reading** work orders, Flutter merges these from `metadata` back into the in-memory model so the app sees `reopenedAt`, `reopenReason`, etc. on the WorkOrder.

**React admin:** For reopen history and “reopened N times” UI, read from **`metadata`** (e.g. `metadata->>'reopenedAt'`, `metadata->>'reopenReason'`, `metadata->>'reopenCount'`, `metadata->>'previousStatus'`, `metadata->>'previousCompletionDate'`). The **status** column is set to **`reopened`** so you can filter/list reopened work orders by status.

---

## 6. Summary for the React Cursor

- **Who:** Only the **requestor** (creator) can reopen; enforced by `requestorId == currentUserId`.
- **When:** Status must be **completed**, **closed**, or **cancelled**; and `reopenCount < maxReopenCount` (Flutter uses 3).
- **UI:** Reopen dialog collects **reason** (required) and optional **edited problem description**.
- **Effect:** Status → `reopened`, assignments and work timestamps cleared, completion data preserved; **reopenedAt**, **reopenedBy**, **reopenReason**, **reopenCount**, **previousCompletionDate**, **previousStatus** stored (in Flutter’s flow, in **metadata**).
- **API:** Direct **UPDATE** on `work_orders`; no RPC. RLS applies.

Use this so the Next.js admin can display reopen history, show “Reopened N times” and last reopen reason, and (if you add reopen in the web app) mirror the same rules and payload.

---

**Paste to Next.js Cursor:** When implementing reopen display or a web reopen action, paste this doc (or the Summary section above) into the React project so Cursor knows: only requestor can reopen; status must be completed/closed/cancelled; reopen data lives in `work_orders.metadata` (reopenedAt, reopenedBy, reopenReason, reopenCount, previousCompletionDate, previousStatus); status column is set to `reopened`; no RPC, direct UPDATE with RLS.
