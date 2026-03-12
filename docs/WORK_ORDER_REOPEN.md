# Work order reopening (Flutter ↔ React alignment)

When a **requestor** reopens a completed/closed (or cancelled) work order in the Flutter app, this document describes the flow and data. The React admin uses it to display reopen history and to stay aligned if we add a web reopen action.

---

## 1. Who can reopen

- **Only the requestor** who created the work order (`requestorId` = current user). The provider validates `workOrder.requestorId == currentUserId` and throws otherwise.
- In Flutter, the **Reopen** button is shown only when the work order is **completed or closed** and the current user is the requestor. The backend also allows reopening when status is **cancelled**, but the detail screen may not show the button for cancelled.

---

## 2. When reopen is allowed

- **Status:** Work order must be **completed**, **closed**, or **cancelled**. Reopening from open/assigned/inProgress is not allowed.
- **Reopen count:** Optional limit (default **3**). If `reopenCount >= maxReopenCount`, the provider throws. Flutter uses `maxReopenCount: 3` in `reopenWorkOrder()`.

---

## 3. Flow in Flutter

1. User opens **WorkOrderDetailScreen** for their own work order that is completed or closed.
2. User taps **Reopen Work Order**.
3. **ReopenWorkOrderDialog** collects:
   - **Reason for Reopening** (required, min 10 characters).
   - Optional: **Edit Problem Description** (checkbox); if checked, **Updated Problem Description** (optional, min 10 chars if provided).
4. **UnifiedDataProvider.reopenWorkOrder()** is called with workOrderId, currentUserId, reason, editedDescription, maxReopenCount.
5. Provider fetches the latest work order, validates status and requestor, then builds an updated work order and calls **updateWorkOrder** (direct UPDATE on `work_orders`).

---

## 4. What changes when reopening

| Field | New value |
|-------|-----------|
| **status** | `reopened` (not `open`) |
| **assignedTechnicianIds** | `[]` |
| **primaryTechnicianId** | `null` |
| **assignedAt**, **startedAt**, **completedAt**, **closedAt** | `null` |
| **problemDescription** | `editedDescription` if provided, else unchanged |
| **reopenedAt** | now |
| **reopenedBy** | currentUserId (requestor) |
| **reopenReason** | user-entered reason |
| **reopenCount** | previous + 1 |
| **previousCompletionDate** | `completedAt ?? closedAt` before clear |
| **previousStatus** | completed | closed | cancelled |
| **updatedAt** | now |
| **isPaused** / **pausedAt** / **pauseReason** / **resumedAt** | false / null |

Completion data (correctiveActions, recommendations, signatures, completion photos) is **not** cleared; only timestamps and assignment fields are reset.

---

## 5. Where reopen data is stored in the DB

- Flutter sends the work order update via **direct UPDATE** on `public.work_orders`. In **SupabaseDatabaseService.updateWorkOrder()**, reopen fields are **merged into the row’s `metadata`** JSONB. So in the database, reopen data lives under **`work_orders.metadata`**:
  - `metadata.reopenedAt` (ISO8601 string)
  - `metadata.reopenedBy` (user id)
  - `metadata.reopenReason` (text)
  - `metadata.reopenCount` (number)
  - `metadata.previousCompletionDate` (ISO8601 string)
  - `metadata.previousStatus` (string: completed | closed | cancelled)

When **reading** work orders, Flutter merges these from `metadata` back into the in-memory model.

**React admin:** For reopen history and “Reopened N times” UI, read from **`metadata`** (e.g. `metadata.reopenedAt`, `metadata.reopenReason`, `metadata.reopenCount`, `metadata.previousStatus`, `metadata.previousCompletionDate`). The **status** column is set to **`reopened`** so you can filter/list reopened work orders by status.

---

## 6. Summary for React

- **Who:** Only the **requestor** (creator) can reopen; enforced by `requestorId == currentUserId`.
- **When:** Status must be **completed**, **closed**, or **cancelled**; and `reopenCount < maxReopenCount` (Flutter uses 3).
- **UI:** Reopen dialog collects **reason** (required) and optional **edited problem description**.
- **Effect:** Status → `reopened`, assignments and work timestamps cleared, completion data preserved; reopen fields stored in **metadata**.
- **API:** Direct **UPDATE** on `work_orders`; no RPC. RLS applies.

When implementing reopen display or a web reopen action: only requestor can reopen; status must be completed/closed/cancelled; reopen data is in `work_orders.metadata`; status column is set to `reopened`.
