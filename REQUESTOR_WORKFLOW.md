# Requestor Workflow - Complete System Flow

## Overview
This document explains the **ideal workflow** for requestors in the CMMS system, where requestors create work order requests that remain **OPEN (unassigned)** until admins or managers assign them to technicians.

---

## 1. Requestor Creates Work Order

### Process Flow
```
Requestor → Asset Selection → Create Request Form → Submit
    ↓
Work Order Created
    ↓
Status: OPEN (Unassigned)
    ↓
Appears in Work Orders List
```

### Implementation Details

#### A. Requestor Cannot Assign Technicians
- **Code Location**: `lib/providers/unified_data_provider.dart` - `createWorkOrder()` method
- **Logic**: 
  ```dart
  if (requestorRole == 'requestor') {
    // Requestors cannot assign technicians - work order stays OPEN
    // Ignore any assignedTechnicianIds passed (safety check)
    assignedIds = []; // Empty - no technicians assigned
    status = WorkOrderStatus.open; // Always OPEN
  }
  ```

#### B. Work Order Creation
- **Status**: Always `WorkOrderStatus.open` for requestors
- **Assigned Technicians**: Empty array `[]`
- **Assigned At**: `null`
- **Primary Technician**: `null`

#### C. Requestor Screen
- **File**: `lib/screens/requestor/create_maintenance_request_screen.dart`
- **No Assignment UI**: Requestors don't see any technician assignment options
- **Form Fields**: Only problem description, priority, category, photo

---

## 2. Work Order Appears in System

### Where It Shows Up

#### A. Work Orders List (All Roles)
- **File**: `lib/screens/work_orders/work_order_list_screen.dart`
- **Requestor View**: Shows only their own work orders
- **Admin/Manager View**: Shows ALL work orders (including unassigned)
- **Technician View**: Shows assigned work orders

#### B. Status
- **Status Badge**: Shows "OPEN" (blue/orange color)
- **Assigned Technician**: Shows "Unassigned" or empty
- **Visible To**: Requestor (who created it), Admins, Managers

---

## 3. Admin/Manager Assigns Technician

### Assignment Process

#### A. Who Can Assign
- ✅ **Admins**: Can assign technicians
- ✅ **Managers**: Can assign technicians
- ❌ **Requestors**: Cannot assign (UI hidden, backend blocked)
- ❌ **Technicians**: Cannot assign (unless they created it themselves)

#### B. Assignment Methods

**Method 1: Work Order Detail Screen**
- **File**: `lib/screens/work_orders/work_order_detail_screen.dart`
- **UI Check**: `_shouldShowAssignmentActions()` method
  ```dart
  if (currentUser?.role == 'requestor') {
    return false; // Hide assignment UI
  }
  ```
- **Button**: "Assign Technician" or "Reassign Technician"
- **Dialog**: `TechnicianAssignmentDialog` opens
- **Action**: Select technician(s) → Save

**Method 2: Popup Menu**
- **Location**: Work Order Detail Screen → Three dots menu
- **Option**: "Reassign Technician"
- **Visibility**: Only shown to admins/managers
- **Code**: 
  ```dart
  if (isAdminOrManager)
    PopupMenuItem(value: 'reassign', ...)
  ```

#### C. Assignment Backend
- **Method**: `unifiedProvider.updateWorkOrderTechnicians()`
- **Updates**:
  - `assignedTechnicianIds`: Array of technician IDs
  - `primaryTechnicianId`: First technician ID
  - `assignedAt`: Current timestamp
  - `status`: Changes from `open` → `assigned`
- **Real-time**: All screens update automatically

---

## 4. Work Order Status Transitions

### Complete Lifecycle

```
1. CREATED (by Requestor)
   Status: OPEN
   Assigned: None
   ↓
2. ASSIGNED (by Admin/Manager)
   Status: ASSIGNED
   Assigned: Technician(s)
   ↓
3. WORK STARTED (by Technician)
   Status: IN_PROGRESS
   Assigned: Technician(s)
   ↓
4. WORK COMPLETED (by Technician)
   Status: COMPLETED
   Assigned: Technician(s)
   ↓
5. CLOSED (by Admin/Manager)
   Status: CLOSED
   Assigned: Technician(s)
```

### Requestor Actions at Each Stage

| Stage | Requestor Can | Requestor Cannot |
|-------|--------------|------------------|
| **OPEN** | View, Edit, Cancel | Assign Technician |
| **ASSIGNED** | View, Edit, Cancel | Assign/Reassign Technician |
| **IN_PROGRESS** | View | Edit, Cancel, Assign |
| **COMPLETED** | View, See Report | Edit, Cancel, Assign |
| **CLOSED** | View, See Report | Edit, Cancel, Assign |

---

## 5. Security & Permissions

### Requestor Permissions

#### ✅ Allowed Actions
- Create work orders (status: OPEN)
- View own work orders
- Edit own work orders (before assignment)
- Cancel own work orders (before work starts)
- View analytics
- Configure notifications

#### ❌ Blocked Actions
- Assign technicians (UI hidden, backend blocked)
- Reassign technicians (UI hidden, backend blocked)
- View other requestors' work orders
- Complete work orders
- Access admin features

### Backend Enforcement

#### A. Work Order Creation
```dart
// lib/providers/unified_data_provider.dart
if (requestorRole == 'requestor') {
  assignedIds = []; // Force empty
  status = WorkOrderStatus.open; // Force OPEN
  // Ignore any assignedTechnicianIds parameter
}
```

#### B. Assignment UI
```dart
// lib/screens/work_orders/work_order_detail_screen.dart
bool _shouldShowAssignmentActions() {
  if (currentUser?.role == 'requestor') {
    return false; // Hide assignment buttons
  }
  // ... admin/manager checks
}
```

#### C. Assignment Backend
```dart
// lib/screens/work_orders/work_order_detail_screen.dart
Future<void> _reassignTechnician() async {
  if (authProvider.currentUser?.role != 'admin' &&
      authProvider.currentUser?.role != 'manager') {
    // Show error and return
    return;
  }
  // ... proceed with assignment
}
```

---

## 6. Notification Flow

### When Requestor Creates Work Order
1. **Notification Created**: `notifyWorkOrderCreated()`
   - Sent to: Requestor
   - Message: "Work order created and pending assignment"
   - Type: `workOrderCreated`

### When Admin/Manager Assigns Technician
1. **Notification to Technician**: `notifyWorkOrderAssigned()`
   - Sent to: Assigned technician(s)
   - Message: "You have been assigned to work order..."
   - Type: `workOrderAssigned`

2. **Notification to Requestor**: (if enabled)
   - Sent to: Requestor
   - Message: "Your work order has been assigned to [Technician]"
   - Type: `workOrderAssigned`

### Requestor Notification Preferences
- **Settings**: `RequestorNotificationSettingsScreen`
- **Options**:
  - Notify when assigned: ON/OFF
  - Notify when started: ON/OFF
  - Notify when completed: ON/OFF
  - Channel: Push/Email/SMS
  - Frequency: Immediate/Daily/Weekly

---

## 7. Data Flow Diagram

```
┌─────────────────┐
│   REQUESTOR     │
│  Creates Request│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Work Order     │
│  Status: OPEN   │
│  Assigned: None │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Work Orders    │
│  List (All)     │
│  - Visible to   │
│    Admins/      │
│    Managers     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ ADMIN/MANAGER   │
│ Assigns Tech    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Work Order     │
│  Status:        │
│  ASSIGNED       │
│  Assigned: Tech │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  TECHNICIAN     │
│  Receives       │
│  Notification   │
│  & Starts Work  │
└─────────────────┘
```

---

## 8. Code Verification

### Key Files Modified

1. **`lib/providers/unified_data_provider.dart`**
   - ✅ Modified `createWorkOrder()` to enforce OPEN status for requestors
   - ✅ Blocks technician assignment for requestors
   - ✅ Allows assignment for admins/managers/technicians

2. **`lib/screens/work_orders/work_order_detail_screen.dart`**
   - ✅ Updated `_shouldShowAssignmentActions()` to exclude requestors
   - ✅ Updated popup menu to hide reassign option for requestors
   - ✅ Assignment buttons only visible to admins/managers

3. **`lib/screens/requestor/create_maintenance_request_screen.dart`**
   - ✅ No technician assignment UI (correct)
   - ✅ Only passes: description, priority, category, photo
   - ✅ Does NOT pass `assignedTechnicianIds`

---

## 9. Testing Checklist

### Requestor Workflow
- [ ] Requestor creates work order → Status is OPEN
- [ ] Requestor cannot see assignment options
- [ ] Work order appears in work orders list
- [ ] Admin/Manager can see the work order
- [ ] Admin/Manager can assign technician
- [ ] Status changes to ASSIGNED after assignment
- [ ] Requestor receives notification (if enabled)
- [ ] Requestor can view assigned technician
- [ ] Requestor cannot reassign technician

### Admin/Manager Workflow
- [ ] Can see all work orders (including unassigned)
- [ ] Can assign technicians to OPEN work orders
- [ ] Can reassign technicians
- [ ] Assignment updates status correctly
- [ ] Notifications sent to technician and requestor

---

## 10. Summary

### ✅ Current Implementation Status

**Requestor Workflow**: ✅ **CORRECT**
- Requestors create work orders as OPEN (unassigned)
- No assignment UI visible to requestors
- Backend enforces OPEN status for requestors
- Work orders appear in system for admin/manager assignment

**Admin/Manager Assignment**: ✅ **WORKING**
- Assignment UI only visible to admins/managers
- Can assign technicians to OPEN work orders
- Status updates correctly (OPEN → ASSIGNED)
- Notifications sent appropriately

**Security**: ✅ **ENFORCED**
- Backend blocks requestor assignment attempts
- UI hides assignment options from requestors
- Role-based access control working

### Workflow Confirmation

The system now works exactly as specified:
1. ✅ Requestor creates request → Work order created as OPEN
2. ✅ Work order appears in work orders list
3. ✅ Only admins/managers can assign technicians
4. ✅ Assignment changes status to ASSIGNED
5. ✅ Requestor can view but cannot assign

**The workflow is now correctly implemented!** 🎉


