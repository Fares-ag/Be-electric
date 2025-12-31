# 🔍 Assignment Diagnostic Tool

## Purpose

The Assignment Diagnostic Tool helps troubleshoot issues with technician assignment functionality by providing comprehensive insights into:

- User and technician data
- Work order and PM task assignments
- Orphaned assignments (assigned to non-existent technicians)
- Technician workload distribution

---

## How to Access

1. **Log in as Admin or Manager**
2. **Navigate to Admin Dashboard**
3. **Click the 3-dot menu** in the top-right corner
4. **Select "Assignment Diagnostic"**

---

## What It Checks

### ✅ **User Statistics**

- **Total Users**: Count of all users in the system
- **Total Technicians**: Count of users with role "technician"
- **Role Distribution**: Breakdown of users by role

### ✅ **Work Order Statistics**

- **Total Work Orders**: All work orders in the system
- **Assigned**: Work orders with a technician assigned
- **Unassigned**: Work orders without a technician
- **Orphaned**: Work orders assigned to non-existent technicians

### ✅ **PM Task Statistics**

- **Total PM Tasks**: All PM tasks in the system
- **Assigned**: PM tasks with a technician assigned
- **Unassigned**: PM tasks without a technician
- **Orphaned**: PM tasks assigned to non-existent technicians

### ✅ **Technician List**

- **Name and Email**: Full technician details
- **Work Order Count**: How many work orders each technician has
- **PM Task Count**: How many PM tasks each technician has
- **Total Workload**: Combined task count

---

## Common Issues and Solutions

### ⚠️ **Issue 1: "No Technicians Found"**

**Symptoms:**

- 0 technicians shown in diagnostic
- Assignment dialog shows empty dropdown
- Technician performance shows 0 work orders

**Possible Causes:**

#### **1. No Technicians Created**

**Solution:**

1. Go to **User Management**
2. Create a new user
3. Set role to **"technician"** (lowercase)

#### **2. Role Field Has Wrong Casing**

**Problem:** Technicians created with role "Technician" or "TECHNICIAN" instead of "technician"

**Solution:**

1. Go to **Firestore Console** (Firebase web console)
2. Navigate to `cmms → users`
3. Check the `role` field for each technician
4. Change to lowercase: **"technician"**

#### **3. Data Hasn't Loaded**

**Solution:**

1. Wait 5-10 seconds for real-time sync
2. Click the **Refresh** button in the diagnostic screen
3. Check console logs for stream errors

---

### ⚠️ **Issue 2: "Orphaned Assignments"**

**Symptoms:**

- Diagnostic shows "X orphaned assignments"
- Work orders/PM tasks assigned to deleted technicians

**Cause:**

- Technician users were deleted but their assignments remain

**Solution:**

#### **Option A: Reassign Manually**

1. Go to **Work Order List**
2. Find orphaned work orders
3. Click "Assign Technician"
4. Select a current technician

#### **Option B: Unassign and Reassign**

1. Use the **TechnicianAssignmentDialog**
2. Click **"Unassign"** first
3. Then reassign to a valid technician

#### **Option C: Fix in Firestore**

1. Go to **Firestore Console**
2. Navigate to `cmms → workOrders` or `cmms → pmTasks`
3. Find documents with invalid `assignedTechnicianId`
4. Either delete the field or set to a valid technician ID

---

### ⚠️ **Issue 3: "Can't Assign Technicians"**

**Symptoms:**

- Assignment dialog doesn't save
- Error message when trying to assign
- Assignment reverts after refresh

**Possible Causes:**

#### **1. Permission Issues**

**Solution:**

- Only Admins and Managers can assign technicians
- Check your role in User Management

#### **2. Firestore Not Updating**

**Solution:**

1. Check **Data Sync Diagnostic** for parsing errors
2. Verify Firestore connection is active
3. Check console for error messages

#### **3. Invalid Technician ID**

**Solution:**

1. Run **Assignment Diagnostic**
2. Verify the technician ID exists in the list
3. Try assigning a different technician

---

## Debug Console Output

When the diagnostic runs, you'll see console output like:

```
🔍 === ASSIGNMENT DIAGNOSTIC REPORT ===
📊 Total Users: 25
👨‍🔧 Total Technicians: 5
📋 Role Distribution: {admin: 2, manager: 3, technician: 5, requestor: 15}
🔧 Total Work Orders: 150
  - Assigned: 120
  - Unassigned: 30
  - Orphaned: 0
🗓️ Total PM Tasks: 75
  - Assigned: 60
  - Unassigned: 15
  - Orphaned: 0
=====================================
```

### Healthy Output:

- ✅ Technicians > 0
- ✅ Orphaned = 0
- ✅ No warnings

### Unhealthy Output:

- ❌ Technicians = 0
- ❌ Orphaned > 0
- ⚠️ Warnings present

---

## Real-Time Diagnostic Logging

When you try to assign a technician, watch the console for:

### **Technician Loading:**

```
🔍 Getting technicians...
📊 Total users in system: 25
👥 User roles in system:
  - admin: 2
  - manager: 3
  - technician: 5
  - requestor: 15
✅ Found 5 technicians
```

### **Work Order Filtering:**

```
🔍 Getting work orders for technician: tech_abc123
📊 Total work orders in system: 150
✅ Found 12 work orders for technician tech_abc123
```

### **PM Task Filtering:**

```
🔍 Getting PM tasks for technician: tech_abc123
📊 Total PM tasks in system: 75
✅ Found 8 PM tasks for technician tech_abc123
```

---

## Best Practices

### ✅ **Create Technicians Properly:**

1. Always use lowercase "technician" for role field
2. Provide valid email addresses
3. Don't delete technician accounts (deactivate instead)

### ✅ **Regular Diagnostics:**

1. Run diagnostic weekly to catch orphaned assignments
2. Check after deleting users
3. Monitor technician workload distribution

### ✅ **Data Consistency:**

1. Use **Assignment Diagnostic** + **Data Sync Diagnostic** together
2. Fix parsing errors first (Data Sync)
3. Then fix assignment issues (Assignment Diagnostic)

---

## Contact

If issues persist after following this guide:

1. Export diagnostic report
2. Check Firestore console for data integrity
3. Review console logs for errors
4. Consider running **Duplicate Cleanup** tool

---

**Last Updated:** October 27, 2025



## Purpose

The Assignment Diagnostic Tool helps troubleshoot issues with technician assignment functionality by providing comprehensive insights into:

- User and technician data
- Work order and PM task assignments
- Orphaned assignments (assigned to non-existent technicians)
- Technician workload distribution

---

## How to Access

1. **Log in as Admin or Manager**
2. **Navigate to Admin Dashboard**
3. **Click the 3-dot menu** in the top-right corner
4. **Select "Assignment Diagnostic"**

---

## What It Checks

### ✅ **User Statistics**

- **Total Users**: Count of all users in the system
- **Total Technicians**: Count of users with role "technician"
- **Role Distribution**: Breakdown of users by role

### ✅ **Work Order Statistics**

- **Total Work Orders**: All work orders in the system
- **Assigned**: Work orders with a technician assigned
- **Unassigned**: Work orders without a technician
- **Orphaned**: Work orders assigned to non-existent technicians

### ✅ **PM Task Statistics**

- **Total PM Tasks**: All PM tasks in the system
- **Assigned**: PM tasks with a technician assigned
- **Unassigned**: PM tasks without a technician
- **Orphaned**: PM tasks assigned to non-existent technicians

### ✅ **Technician List**

- **Name and Email**: Full technician details
- **Work Order Count**: How many work orders each technician has
- **PM Task Count**: How many PM tasks each technician has
- **Total Workload**: Combined task count

---

## Common Issues and Solutions

### ⚠️ **Issue 1: "No Technicians Found"**

**Symptoms:**

- 0 technicians shown in diagnostic
- Assignment dialog shows empty dropdown
- Technician performance shows 0 work orders

**Possible Causes:**

#### **1. No Technicians Created**

**Solution:**

1. Go to **User Management**
2. Create a new user
3. Set role to **"technician"** (lowercase)

#### **2. Role Field Has Wrong Casing**

**Problem:** Technicians created with role "Technician" or "TECHNICIAN" instead of "technician"

**Solution:**

1. Go to **Firestore Console** (Firebase web console)
2. Navigate to `cmms → users`
3. Check the `role` field for each technician
4. Change to lowercase: **"technician"**

#### **3. Data Hasn't Loaded**

**Solution:**

1. Wait 5-10 seconds for real-time sync
2. Click the **Refresh** button in the diagnostic screen
3. Check console logs for stream errors

---

### ⚠️ **Issue 2: "Orphaned Assignments"**

**Symptoms:**

- Diagnostic shows "X orphaned assignments"
- Work orders/PM tasks assigned to deleted technicians

**Cause:**

- Technician users were deleted but their assignments remain

**Solution:**

#### **Option A: Reassign Manually**

1. Go to **Work Order List**
2. Find orphaned work orders
3. Click "Assign Technician"
4. Select a current technician

#### **Option B: Unassign and Reassign**

1. Use the **TechnicianAssignmentDialog**
2. Click **"Unassign"** first
3. Then reassign to a valid technician

#### **Option C: Fix in Firestore**

1. Go to **Firestore Console**
2. Navigate to `cmms → workOrders` or `cmms → pmTasks`
3. Find documents with invalid `assignedTechnicianId`
4. Either delete the field or set to a valid technician ID

---

### ⚠️ **Issue 3: "Can't Assign Technicians"**

**Symptoms:**

- Assignment dialog doesn't save
- Error message when trying to assign
- Assignment reverts after refresh

**Possible Causes:**

#### **1. Permission Issues**

**Solution:**

- Only Admins and Managers can assign technicians
- Check your role in User Management

#### **2. Firestore Not Updating**

**Solution:**

1. Check **Data Sync Diagnostic** for parsing errors
2. Verify Firestore connection is active
3. Check console for error messages

#### **3. Invalid Technician ID**

**Solution:**

1. Run **Assignment Diagnostic**
2. Verify the technician ID exists in the list
3. Try assigning a different technician

---

## Debug Console Output

When the diagnostic runs, you'll see console output like:

```
🔍 === ASSIGNMENT DIAGNOSTIC REPORT ===
📊 Total Users: 25
👨‍🔧 Total Technicians: 5
📋 Role Distribution: {admin: 2, manager: 3, technician: 5, requestor: 15}
🔧 Total Work Orders: 150
  - Assigned: 120
  - Unassigned: 30
  - Orphaned: 0
🗓️ Total PM Tasks: 75
  - Assigned: 60
  - Unassigned: 15
  - Orphaned: 0
=====================================
```

### Healthy Output:

- ✅ Technicians > 0
- ✅ Orphaned = 0
- ✅ No warnings

### Unhealthy Output:

- ❌ Technicians = 0
- ❌ Orphaned > 0
- ⚠️ Warnings present

---

## Real-Time Diagnostic Logging

When you try to assign a technician, watch the console for:

### **Technician Loading:**

```
🔍 Getting technicians...
📊 Total users in system: 25
👥 User roles in system:
  - admin: 2
  - manager: 3
  - technician: 5
  - requestor: 15
✅ Found 5 technicians
```

### **Work Order Filtering:**

```
🔍 Getting work orders for technician: tech_abc123
📊 Total work orders in system: 150
✅ Found 12 work orders for technician tech_abc123
```

### **PM Task Filtering:**

```
🔍 Getting PM tasks for technician: tech_abc123
📊 Total PM tasks in system: 75
✅ Found 8 PM tasks for technician tech_abc123
```

---

## Best Practices

### ✅ **Create Technicians Properly:**

1. Always use lowercase "technician" for role field
2. Provide valid email addresses
3. Don't delete technician accounts (deactivate instead)

### ✅ **Regular Diagnostics:**

1. Run diagnostic weekly to catch orphaned assignments
2. Check after deleting users
3. Monitor technician workload distribution

### ✅ **Data Consistency:**

1. Use **Assignment Diagnostic** + **Data Sync Diagnostic** together
2. Fix parsing errors first (Data Sync)
3. Then fix assignment issues (Assignment Diagnostic)

---

## Contact

If issues persist after following this guide:

1. Export diagnostic report
2. Check Firestore console for data integrity
3. Review console logs for errors
4. Consider running **Duplicate Cleanup** tool

---

**Last Updated:** October 27, 2025



## Purpose

The Assignment Diagnostic Tool helps troubleshoot issues with technician assignment functionality by providing comprehensive insights into:

- User and technician data
- Work order and PM task assignments
- Orphaned assignments (assigned to non-existent technicians)
- Technician workload distribution

---

## How to Access

1. **Log in as Admin or Manager**
2. **Navigate to Admin Dashboard**
3. **Click the 3-dot menu** in the top-right corner
4. **Select "Assignment Diagnostic"**

---

## What It Checks

### ✅ **User Statistics**

- **Total Users**: Count of all users in the system
- **Total Technicians**: Count of users with role "technician"
- **Role Distribution**: Breakdown of users by role

### ✅ **Work Order Statistics**

- **Total Work Orders**: All work orders in the system
- **Assigned**: Work orders with a technician assigned
- **Unassigned**: Work orders without a technician
- **Orphaned**: Work orders assigned to non-existent technicians

### ✅ **PM Task Statistics**

- **Total PM Tasks**: All PM tasks in the system
- **Assigned**: PM tasks with a technician assigned
- **Unassigned**: PM tasks without a technician
- **Orphaned**: PM tasks assigned to non-existent technicians

### ✅ **Technician List**

- **Name and Email**: Full technician details
- **Work Order Count**: How many work orders each technician has
- **PM Task Count**: How many PM tasks each technician has
- **Total Workload**: Combined task count

---

## Common Issues and Solutions

### ⚠️ **Issue 1: "No Technicians Found"**

**Symptoms:**

- 0 technicians shown in diagnostic
- Assignment dialog shows empty dropdown
- Technician performance shows 0 work orders

**Possible Causes:**

#### **1. No Technicians Created**

**Solution:**

1. Go to **User Management**
2. Create a new user
3. Set role to **"technician"** (lowercase)

#### **2. Role Field Has Wrong Casing**

**Problem:** Technicians created with role "Technician" or "TECHNICIAN" instead of "technician"

**Solution:**

1. Go to **Firestore Console** (Firebase web console)
2. Navigate to `cmms → users`
3. Check the `role` field for each technician
4. Change to lowercase: **"technician"**

#### **3. Data Hasn't Loaded**

**Solution:**

1. Wait 5-10 seconds for real-time sync
2. Click the **Refresh** button in the diagnostic screen
3. Check console logs for stream errors

---

### ⚠️ **Issue 2: "Orphaned Assignments"**

**Symptoms:**

- Diagnostic shows "X orphaned assignments"
- Work orders/PM tasks assigned to deleted technicians

**Cause:**

- Technician users were deleted but their assignments remain

**Solution:**

#### **Option A: Reassign Manually**

1. Go to **Work Order List**
2. Find orphaned work orders
3. Click "Assign Technician"
4. Select a current technician

#### **Option B: Unassign and Reassign**

1. Use the **TechnicianAssignmentDialog**
2. Click **"Unassign"** first
3. Then reassign to a valid technician

#### **Option C: Fix in Firestore**

1. Go to **Firestore Console**
2. Navigate to `cmms → workOrders` or `cmms → pmTasks`
3. Find documents with invalid `assignedTechnicianId`
4. Either delete the field or set to a valid technician ID

---

### ⚠️ **Issue 3: "Can't Assign Technicians"**

**Symptoms:**

- Assignment dialog doesn't save
- Error message when trying to assign
- Assignment reverts after refresh

**Possible Causes:**

#### **1. Permission Issues**

**Solution:**

- Only Admins and Managers can assign technicians
- Check your role in User Management

#### **2. Firestore Not Updating**

**Solution:**

1. Check **Data Sync Diagnostic** for parsing errors
2. Verify Firestore connection is active
3. Check console for error messages

#### **3. Invalid Technician ID**

**Solution:**

1. Run **Assignment Diagnostic**
2. Verify the technician ID exists in the list
3. Try assigning a different technician

---

## Debug Console Output

When the diagnostic runs, you'll see console output like:

```
🔍 === ASSIGNMENT DIAGNOSTIC REPORT ===
📊 Total Users: 25
👨‍🔧 Total Technicians: 5
📋 Role Distribution: {admin: 2, manager: 3, technician: 5, requestor: 15}
🔧 Total Work Orders: 150
  - Assigned: 120
  - Unassigned: 30
  - Orphaned: 0
🗓️ Total PM Tasks: 75
  - Assigned: 60
  - Unassigned: 15
  - Orphaned: 0
=====================================
```

### Healthy Output:

- ✅ Technicians > 0
- ✅ Orphaned = 0
- ✅ No warnings

### Unhealthy Output:

- ❌ Technicians = 0
- ❌ Orphaned > 0
- ⚠️ Warnings present

---

## Real-Time Diagnostic Logging

When you try to assign a technician, watch the console for:

### **Technician Loading:**

```
🔍 Getting technicians...
📊 Total users in system: 25
👥 User roles in system:
  - admin: 2
  - manager: 3
  - technician: 5
  - requestor: 15
✅ Found 5 technicians
```

### **Work Order Filtering:**

```
🔍 Getting work orders for technician: tech_abc123
📊 Total work orders in system: 150
✅ Found 12 work orders for technician tech_abc123
```

### **PM Task Filtering:**

```
🔍 Getting PM tasks for technician: tech_abc123
📊 Total PM tasks in system: 75
✅ Found 8 PM tasks for technician tech_abc123
```

---

## Best Practices

### ✅ **Create Technicians Properly:**

1. Always use lowercase "technician" for role field
2. Provide valid email addresses
3. Don't delete technician accounts (deactivate instead)

### ✅ **Regular Diagnostics:**

1. Run diagnostic weekly to catch orphaned assignments
2. Check after deleting users
3. Monitor technician workload distribution

### ✅ **Data Consistency:**

1. Use **Assignment Diagnostic** + **Data Sync Diagnostic** together
2. Fix parsing errors first (Data Sync)
3. Then fix assignment issues (Assignment Diagnostic)

---

## Contact

If issues persist after following this guide:

1. Export diagnostic report
2. Check Firestore console for data integrity
3. Review console logs for errors
4. Consider running **Duplicate Cleanup** tool

---

**Last Updated:** October 27, 2025


