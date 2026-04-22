# Technician App — Functional Review

Review of the Flutter technician app: what’s in place, gaps, and suggested functional changes.

---

## 1. What’s in place (working flows)

| Area | Status | Notes |
|------|--------|------|
| **Login & role** | ✅ | Technician lands on `TechnicianMainScreen` via `RoleBasedNavigation`. |
| **Dashboard tab** | ✅ | Welcome card, “Scan Asset QR Code” (primary CTA), stat cards (Assigned Work Orders, PM Tasks), “Request Parts”, “View Work Orders”. Data from `UnifiedDataProvider.getWorkOrdersByTechnician` / `getPMTasksByTechnician`. |
| **Work Orders tab** | ✅ | `WorkOrderListScreen(isTechnicianView: true)` shows work orders where technician is in `assignedTechnicianIds` **or** is `requestorId`. Tap → `WorkOrderDetailScreen`. |
| **Work order detail** | ✅ | Technician can **Start Work** (status → in progress, self-added to assigned if needed), **Pause** (with reason), **Complete** (navigates to `WorkOrderCompletionScreen`). Role checks: `_canPerformWorkActions()` allows technician/admin/manager; requestor cannot. |
| **PM Tasks tab** | ✅ | `PMTaskListScreen(isTechnicianView: true)` shows tasks where technician is in `assignedTechnicianIds`. Tap → `PMTaskDetailScreen`. |
| **PM task detail** | ✅ | **Start Task**, **Complete** (→ `PMTaskCompletionScreen`), completion history. |
| **Request Parts** | ✅ | From dashboard, “Request Parts” → work order picker (assigned only) → `PartsRequestScreen(workOrder)`. |
| **QR scan** | ✅ | “Scan Asset QR Code” → `MobileQRScannerWidget` → result shows asset info + related work orders/PM tasks; “View Tasks” pushes `WorkOrderListScreen` with `assetId`. |
| **Quick Create menu** | ✅ | App bar “+” → Create Work Order, Create PM Task, Scan QR. |
| **Analytics tab** | ✅ | `ConsolidatedAnalyticsDashboard(isTechnicianView: true)`. |
| **Data & realtime** | ✅ | `UnifiedDataProvider` streams work orders, PM tasks, assets, users, etc. Dashboard and lists stay in sync. |

---

## 2. Gaps and inconsistencies

### 2.1 Dashboard vs list scope

- **Dashboard** stat cards use `getWorkOrdersByTechnician(user.id)` and `getPMTasksByTechnician(user.id)` → only rows where the technician is **assigned**.
- **Work Orders list** (technician view) shows work orders **assigned to** the technician **or** **created by** them (`requestorId == currentUserId`).

So the dashboard counts “assigned” only, while the list can show more (e.g. “created by me”). If the intent is “technician sees only assigned,” the list could be aligned to assigned-only in technician view. If “involved in” is intended, consider adding a dashboard line like “Involved work orders” or clarifying in UI that one number is “Assigned” and the list includes “also created by you.”

### 2.2 Double app bar when switching tabs

- **TechnicianMainScreen** has one `AppBar` (title changes by tab: Dashboard, Work Orders, PM Tasks, Analytics).
- **Work Orders** and **PM Tasks** tabs are full `WorkOrderListScreen` / `PMTaskListScreen` widgets, each with its **own** `Scaffold` and `AppBar`.

So when the user is on Work Orders or PM Tasks, **two** app bars appear (parent “Work Orders” / “PM Tasks” and child “Work Orders” / “PM Tasks”). Functionally it works but looks wrong.

**Suggestion:** Add a parameter (e.g. `hideAppBarWhenEmbedded`) to `WorkOrderListScreen` and `PMTaskListScreen`. When `true`, build only the body (list + FAB if any) so the parent’s single app bar is used.

### 2.3 “View Tasks” after QR scan leaves the bottom nav

- After scanning a QR code, “View Tasks” does `Navigator.push(..., WorkOrderListScreen(isTechnicianView: true, assetId: ...))`.
- That pushes a **new** full-screen route. The user leaves the technician bottom nav and must use the system back button.

**Suggestion:** Either:
- Keep current behavior and make it clear in copy (“Open work orders for this asset” with back to return), or
- Replace the push with switching to the Work Orders tab and applying an asset filter (would require the main screen to support “open tab N with filter” and the list screen to accept an initial `assetId` from the parent).

### 2.4 Seed General Assets in technician menu

- Technician app bar has a **PopupMenuButton** with “Setup General Assets” → `SeedGeneralAssetsScreen`.
- Seeding/creating assets is an **admin/manager** concern in the permission matrix (“Manage assets” ✅ Admin/Manager, ❌ Technician).

**Suggestion:** Hide “Setup General Assets” for role `technician` (e.g. only show for admin/manager, or remove from the technician build if this app is technician-only).

### 2.5 Quick Create: “Create PM Task” for technician

- **Permission matrix:** “Create maintenance request” is allowed for Technician; creating **PM tasks** (preventive schedules) is not explicitly listed and is typically an admin/manager function.
- The Quick Create menu currently offers **Create PM Task** to everyone, including technicians.

**Suggestion:** Either remove “Create PM Task” from the technician Quick Create menu and keep it for admin/manager only, or explicitly allow it in the permission matrix and in RLS if technicians should create PM tasks.

### 2.6 PartsRequestScreen imports

- `PartsRequestScreen` uses `package:qauto_cmms/theme/app_theme.dart` and `package:qauto_cmms/...` for models/providers/services.
- Rest of the app (e.g. work order list, technician main) uses relative imports and `../../utils/app_theme.dart`.

**Suggestion:** Make imports consistent (e.g. use relative imports and `utils/app_theme.dart` in `PartsRequestScreen`) so one theme and one app_theme source are used and refactors are easier.

---

## 3. Permission and product alignment

| Topic | Doc / RLS | App behavior | Recommendation |
|-------|-----------|---------------|----------------|
| Technician completes work orders | ✅ Assigned only | Detail screen allows Start/Pause/Complete; RLS limits updates to assigned | OK. |
| Technician starts/completes PM tasks | ✅ | PMTaskDetailScreen allows Start/Complete | OK. |
| Request parts | ✅ | Parts request from assigned work order only | OK. |
| Create work order (maintenance request) | ✅ Matrix allows | Quick Create “Create Work Order” | OK. |
| Create PM task | Not in matrix | Quick Create “Create PM Task” | Restrict to admin/manager or document and allow. |
| Manage / seed assets | ❌ Technician | “Setup General Assets” in menu | Hide or remove for technician. |

---

## 4. Suggested functional changes (short list)

1. **Single app bar in technician flow**  
   Add `hideAppBarWhenEmbedded` (or similar) to `WorkOrderListScreen` and `PMTaskListScreen`; when embedded in `TechnicianMainScreen`, render only body so the parent’s app bar is the only one.

2. **Hide “Setup General Assets” for technicians**  
   In `TechnicianMainScreen` app bar menu, show “Setup General Assets” only when `currentUser` is admin or manager (or remove it if this app is technician-only).

3. **Quick Create: restrict “Create PM Task”**  
   Show “Create PM Task” in Quick Create only for admin/manager (or remove from technician flow until product says otherwise).

4. **Align Work Orders list with dashboard (optional)**  
   If technicians should see only **assigned** work orders, remove the `requestorId == currentUserId` branch in the technician view of `WorkOrderListScreen`. If “created by me” is intentional, add a short label or tooltip so it’s clear.

5. **PartsRequestScreen imports**  
   Switch to relative imports and `../../utils/app_theme.dart` (and same pattern for other lib files) for consistency and to avoid duplicate theme references.

6. **QR “View Tasks” navigation (optional)**  
   Decide whether “View Tasks” after QR scan should stay as a full-screen push or switch to Work Orders tab with asset filter and keep the user inside the bottom nav.

---

## 5. Summary

- Core technician flows are implemented: dashboard, work orders (list → detail → start/pause/complete), PM tasks (list → detail → start/complete), parts request, QR scan, analytics, and realtime data.
- Main functional improvements: one app bar when embedded, hide “Setup General Assets” and optionally “Create PM Task” for technicians, and align list vs dashboard scope and imports as above.

If you specify which of these you want (e.g. “implement 1 and 2 only”), the next step is to apply those changes in the codebase.
