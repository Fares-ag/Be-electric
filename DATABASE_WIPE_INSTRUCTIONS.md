# 🗑️ **Complete Database Wipe - Instructions**

## ✅ **New Database Wipe Feature Ready!**

I've created a **REAL database wipe utility** that actually deletes ALL data from Firestore (not just local storage).

---

## 🚀 **How to Wipe Your Database:**

### **Step 1: Hot Restart**

```bash
r  (press 'r' in your Flutter terminal)
```

### **Step 2: Access the Wipe Tool**

1. Open your app
2. Log in as **Admin**
3. Go to **Admin Dashboard**
4. Click the **3-dot menu** (⋮) in the top-right
5. Scroll to the bottom
6. Click **"Clear Database"** (red text)

### **Step 3: Confirm Deletion**

You'll see a **DANGER ZONE** dialog showing:

- ⚠️ Warning that this is permanent
- 🔧 List of all data that will be deleted
- 🗑️ Work Orders, PM Tasks, Users, Assets, Inventory, etc.

Click **"DELETE EVERYTHING"** (red button)

### **Step 4: Wait for Completion**

- Loading dialog will show "Deleting all data..."
- The utility will delete ALL documents from Firestore
- You'll see a success dialog with deletion count

### **Step 5: Restart Your App**

After the wipe completes:

```bash
R  (capital R for full restart)
```

---

## 📊 **What Gets Deleted:**

### **Firestore Collections:**

- ✅ `cmms/workOrders` - All work orders
- ✅ `cmms/pmTasks` - All PM tasks
- ✅ `cmms/assets` - All assets
- ✅ `cmms/users` - All users
- ✅ `cmms/inventoryItems` - All inventory
- ✅ `cmms/workflows` - All workflows
- ✅ `cmms/notifications` - All notifications
- ✅ `cmms/partsRequests` - All parts requests
- ✅ `cmms/purchaseOrders` - All purchase orders
- ✅ `cmms/auditLogs` - All audit logs
- ✅ `cmms/analytics` - All analytics data

### **Local Storage:**

- ✅ All SharedPreferences data cleared

---

## ✅ **What Happens After Wipe:**

1. **Database is completely empty**
2. **You'll see 0 users, 0 work orders, 0 everything**
3. **Fresh start - like a brand new installation**
4. **You can create new users, work orders, etc.**

---

## 🔧 **Troubleshooting:**

### **If the wipe doesn't work:**

1. Check your **console/terminal** for error messages
2. Make sure you have **internet connection** (Firestore access)
3. Make sure you're logged in as **Admin**
4. Try **hot restarting** first (`r`)

### **If you see "Permission Denied":**

- Check your Firestore security rules
- Make sure delete operations are allowed

---

## 📝 **Console Output:**

When the wipe runs successfully, you'll see:

```
🗑️ Starting Firestore database wipe...
🗑️ Deleting collection: cmms/workOrders
✅ Deleted 1 documents from cmms/workOrders
🗑️ Deleting collection: cmms/pmTasks
✅ Deleted 1 documents from cmms/pmTasks
🗑️ Deleting collection: cmms/users
✅ Deleted 292 documents from cmms/users
...
✅ Firestore wipe complete!
🗑️ Clearing local storage...
✅ Local storage cleared
🎉 COMPLETE DATABASE WIPE FINISHED!
📊 Total documents deleted: 295
```

---

## ⚠️ **IMPORTANT WARNINGS:**

1. **THIS IS PERMANENT** - There's no undo!
2. **ALL DATA WILL BE LOST** - Make backups if needed
3. **RESTART REQUIRED** - After wipe, do a full restart (`R`)
4. **NO RECOVERY** - Once deleted, data cannot be recovered

---

## 🎯 **Quick Steps:**

```
1. Hot restart (r)
2. Admin Dashboard → 3-dot menu → Clear Database
3. Click "DELETE EVERYTHING"
4. Wait for completion
5. Full restart (R)
6. Fresh database! ✨
```

---

**Ready to wipe? Follow the steps above!** 🚀

If it still doesn't work after this, share the console output and I'll help debug!



## ✅ **New Database Wipe Feature Ready!**

I've created a **REAL database wipe utility** that actually deletes ALL data from Firestore (not just local storage).

---

## 🚀 **How to Wipe Your Database:**

### **Step 1: Hot Restart**

```bash
r  (press 'r' in your Flutter terminal)
```

### **Step 2: Access the Wipe Tool**

1. Open your app
2. Log in as **Admin**
3. Go to **Admin Dashboard**
4. Click the **3-dot menu** (⋮) in the top-right
5. Scroll to the bottom
6. Click **"Clear Database"** (red text)

### **Step 3: Confirm Deletion**

You'll see a **DANGER ZONE** dialog showing:

- ⚠️ Warning that this is permanent
- 🔧 List of all data that will be deleted
- 🗑️ Work Orders, PM Tasks, Users, Assets, Inventory, etc.

Click **"DELETE EVERYTHING"** (red button)

### **Step 4: Wait for Completion**

- Loading dialog will show "Deleting all data..."
- The utility will delete ALL documents from Firestore
- You'll see a success dialog with deletion count

### **Step 5: Restart Your App**

After the wipe completes:

```bash
R  (capital R for full restart)
```

---

## 📊 **What Gets Deleted:**

### **Firestore Collections:**

- ✅ `cmms/workOrders` - All work orders
- ✅ `cmms/pmTasks` - All PM tasks
- ✅ `cmms/assets` - All assets
- ✅ `cmms/users` - All users
- ✅ `cmms/inventoryItems` - All inventory
- ✅ `cmms/workflows` - All workflows
- ✅ `cmms/notifications` - All notifications
- ✅ `cmms/partsRequests` - All parts requests
- ✅ `cmms/purchaseOrders` - All purchase orders
- ✅ `cmms/auditLogs` - All audit logs
- ✅ `cmms/analytics` - All analytics data

### **Local Storage:**

- ✅ All SharedPreferences data cleared

---

## ✅ **What Happens After Wipe:**

1. **Database is completely empty**
2. **You'll see 0 users, 0 work orders, 0 everything**
3. **Fresh start - like a brand new installation**
4. **You can create new users, work orders, etc.**

---

## 🔧 **Troubleshooting:**

### **If the wipe doesn't work:**

1. Check your **console/terminal** for error messages
2. Make sure you have **internet connection** (Firestore access)
3. Make sure you're logged in as **Admin**
4. Try **hot restarting** first (`r`)

### **If you see "Permission Denied":**

- Check your Firestore security rules
- Make sure delete operations are allowed

---

## 📝 **Console Output:**

When the wipe runs successfully, you'll see:

```
🗑️ Starting Firestore database wipe...
🗑️ Deleting collection: cmms/workOrders
✅ Deleted 1 documents from cmms/workOrders
🗑️ Deleting collection: cmms/pmTasks
✅ Deleted 1 documents from cmms/pmTasks
🗑️ Deleting collection: cmms/users
✅ Deleted 292 documents from cmms/users
...
✅ Firestore wipe complete!
🗑️ Clearing local storage...
✅ Local storage cleared
🎉 COMPLETE DATABASE WIPE FINISHED!
📊 Total documents deleted: 295
```

---

## ⚠️ **IMPORTANT WARNINGS:**

1. **THIS IS PERMANENT** - There's no undo!
2. **ALL DATA WILL BE LOST** - Make backups if needed
3. **RESTART REQUIRED** - After wipe, do a full restart (`R`)
4. **NO RECOVERY** - Once deleted, data cannot be recovered

---

## 🎯 **Quick Steps:**

```
1. Hot restart (r)
2. Admin Dashboard → 3-dot menu → Clear Database
3. Click "DELETE EVERYTHING"
4. Wait for completion
5. Full restart (R)
6. Fresh database! ✨
```

---

**Ready to wipe? Follow the steps above!** 🚀

If it still doesn't work after this, share the console output and I'll help debug!



## ✅ **New Database Wipe Feature Ready!**

I've created a **REAL database wipe utility** that actually deletes ALL data from Firestore (not just local storage).

---

## 🚀 **How to Wipe Your Database:**

### **Step 1: Hot Restart**

```bash
r  (press 'r' in your Flutter terminal)
```

### **Step 2: Access the Wipe Tool**

1. Open your app
2. Log in as **Admin**
3. Go to **Admin Dashboard**
4. Click the **3-dot menu** (⋮) in the top-right
5. Scroll to the bottom
6. Click **"Clear Database"** (red text)

### **Step 3: Confirm Deletion**

You'll see a **DANGER ZONE** dialog showing:

- ⚠️ Warning that this is permanent
- 🔧 List of all data that will be deleted
- 🗑️ Work Orders, PM Tasks, Users, Assets, Inventory, etc.

Click **"DELETE EVERYTHING"** (red button)

### **Step 4: Wait for Completion**

- Loading dialog will show "Deleting all data..."
- The utility will delete ALL documents from Firestore
- You'll see a success dialog with deletion count

### **Step 5: Restart Your App**

After the wipe completes:

```bash
R  (capital R for full restart)
```

---

## 📊 **What Gets Deleted:**

### **Firestore Collections:**

- ✅ `cmms/workOrders` - All work orders
- ✅ `cmms/pmTasks` - All PM tasks
- ✅ `cmms/assets` - All assets
- ✅ `cmms/users` - All users
- ✅ `cmms/inventoryItems` - All inventory
- ✅ `cmms/workflows` - All workflows
- ✅ `cmms/notifications` - All notifications
- ✅ `cmms/partsRequests` - All parts requests
- ✅ `cmms/purchaseOrders` - All purchase orders
- ✅ `cmms/auditLogs` - All audit logs
- ✅ `cmms/analytics` - All analytics data

### **Local Storage:**

- ✅ All SharedPreferences data cleared

---

## ✅ **What Happens After Wipe:**

1. **Database is completely empty**
2. **You'll see 0 users, 0 work orders, 0 everything**
3. **Fresh start - like a brand new installation**
4. **You can create new users, work orders, etc.**

---

## 🔧 **Troubleshooting:**

### **If the wipe doesn't work:**

1. Check your **console/terminal** for error messages
2. Make sure you have **internet connection** (Firestore access)
3. Make sure you're logged in as **Admin**
4. Try **hot restarting** first (`r`)

### **If you see "Permission Denied":**

- Check your Firestore security rules
- Make sure delete operations are allowed

---

## 📝 **Console Output:**

When the wipe runs successfully, you'll see:

```
🗑️ Starting Firestore database wipe...
🗑️ Deleting collection: cmms/workOrders
✅ Deleted 1 documents from cmms/workOrders
🗑️ Deleting collection: cmms/pmTasks
✅ Deleted 1 documents from cmms/pmTasks
🗑️ Deleting collection: cmms/users
✅ Deleted 292 documents from cmms/users
...
✅ Firestore wipe complete!
🗑️ Clearing local storage...
✅ Local storage cleared
🎉 COMPLETE DATABASE WIPE FINISHED!
📊 Total documents deleted: 295
```

---

## ⚠️ **IMPORTANT WARNINGS:**

1. **THIS IS PERMANENT** - There's no undo!
2. **ALL DATA WILL BE LOST** - Make backups if needed
3. **RESTART REQUIRED** - After wipe, do a full restart (`R`)
4. **NO RECOVERY** - Once deleted, data cannot be recovered

---

## 🎯 **Quick Steps:**

```
1. Hot restart (r)
2. Admin Dashboard → 3-dot menu → Clear Database
3. Click "DELETE EVERYTHING"
4. Wait for completion
5. Full restart (R)
6. Fresh database! ✨
```

---

**Ready to wipe? Follow the steps above!** 🚀

If it still doesn't work after this, share the console output and I'll help debug!


