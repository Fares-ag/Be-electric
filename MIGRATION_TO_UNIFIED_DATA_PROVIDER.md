# Migration to UnifiedDataProvider - Complete Guide

## ✅ **COMPLETED MIGRATIONS**

### Screens:

1. ✅ **User Management Screen** - Uses `Consumer<UnifiedDataProvider>` for real-time users
2. ✅ **Inventory List Screen** - Uses `Consumer<UnifiedDataProvider>` for real-time inventory
3. ✅ **Create PM Task Screen** - Uses `Consumer<UnifiedDataProvider>` for technicians list
4. ✅ **Create Maintenance Request Screen** - Uses `UnifiedDataProvider.createWorkOrder()`

---

## 🔄 **REMAINING MIGRATIONS**

### **Screens Still Using WebDatabaseService:**

#### 1. **Requestor Status Screen**

**File:** `lib/screens/requestor/requestor_status_screen.dart`
**Current:** Loads work orders with `WebDatabaseService.instance.getAllWorkOrders()`
**Action Needed:** Convert to `Consumer<UnifiedDataProvider>` to get real-time work orders

**Example Fix:**

```dart
// Instead of:
Future<void> _loadMyRequests() async {
  final allWorkOrders = await WebDatabaseService.instance.getAllWorkOrders();
  setState(() {
    _myRequests = allWorkOrders.where((wo) => wo.requestorId == user.id).toList();
  });
}

// Use:
Consumer<UnifiedDataProvider>(
  builder: (context, unifiedProvider, child) {
    final myRequests = unifiedProvider.workOrders
        .where((wo) => wo.requestorId == user.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView(...);
  },
)
```

#### 2. **Requestor Main Screen**

**File:** `lib/screens/requestor/requestor_main_screen.dart`
**Action Needed:** Similar to Requestor Status Screen

#### 3. **Work Email Validation Screen**

**File:** `lib/screens/requestor/work_email_validation_screen.dart`
**Action Needed:** Replace user lookups with `UnifiedDataProvider.users`

#### 4. **Technician Viewer Screen**

**File:** `lib/screens/admin/technician_viewer_screen.dart`
**Action Needed:** Use `Consumer<UnifiedDataProvider>` for technicians

#### 5. **Low Stock Alerts Screen**

**File:** `lib/screens/inventory/low_stock_alerts_screen.dart`
**Action Needed:** Use `Consumer<UnifiedDataProvider>` for inventory

#### 6. **Parts Request Screen**

**File:** `lib/screens/inventory/parts_request_screen.dart`
**Action Needed:** Use `Consumer<UnifiedDataProvider>` for inventory items

---

### **Providers Still Using WebDatabaseService:**

#### 1. **Work Order Provider**

**File:** `lib/providers/work_order_provider.dart`
**Current:** May have WebDB calls
**Action Needed:** Verify it delegates to UnifiedDataProvider

#### 2. **PM Task Provider**

**File:** `lib/providers/pm_task_provider.dart`
**Current:** May have WebDB calls
**Action Needed:** Verify it delegates to UnifiedDataProvider

#### 3. **Auth Provider**

**File:** `lib/providers/auth_provider.dart`
**Current:** May use WebDB for user lookups
**Action Needed:** Use UnifiedDataProvider.users instead

---

## 🎯 **MIGRATION PATTERN**

For all remaining screens, follow this pattern:

### **Pattern 1: Loading Data Once (Convert to Real-Time)**

```dart
// OLD WAY ❌
class _MyScreenState extends State<MyScreen> {
  List<WorkOrder> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await WebDatabaseService.instance.getAllWorkOrders();
    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _data.length,
      itemBuilder: (context, index) => _buildItem(_data[index]),
    );
  }
}

// NEW WAY ✅
class _MyScreenState extends State<MyScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<UnifiedDataProvider>(
      builder: (context, unifiedProvider, child) {
        final data = unifiedProvider.workOrders;  // Real-time!

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) => _buildItem(data[index]),
        );
      },
    );
  }
}
```

### **Pattern 2: Creating Data**

```dart
// OLD WAY ❌
await WebDatabaseService.instance.createWorkOrder(workOrder);

// NEW WAY ✅
final unifiedProvider = Provider.of<UnifiedDataProvider>(context, listen: false);
await unifiedProvider.createWorkOrder(
  problemDescription: description,
  requestorId: userId,
  assetId: assetId,
  asset: asset,  // Pass full asset object
  priority: priority,
);
```

### **Pattern 3: Filtering Data**

```dart
// OLD WAY ❌
final allData = await WebDatabaseService.instance.getAllWorkOrders();
final filtered = allData.where((wo) => wo.status == WorkOrderStatus.open).toList();

// NEW WAY ✅
Consumer<UnifiedDataProvider>(
  builder: (context, unifiedProvider, child) {
    final filtered = unifiedProvider.workOrders
        .where((wo) => wo.status == WorkOrderStatus.open)
        .toList();

    return MyWidget(data: filtered);
  },
)
```

---

## 📝 **CHECKLIST FOR EACH MIGRATION**

For each screen you migrate:

- [ ] Import `UnifiedDataProvider`
- [ ] Remove `WebDatabaseService` import
- [ ] Replace `FutureBuilder` or `_loadData()` with `Consumer<UnifiedDataProvider>`
- [ ] Remove local state variables (`_data`, `_isLoading`)
- [ ] Use provider getters (`workOrders`, `users`, `assets`, `inventoryItems`, `pmTasks`)
- [ ] Test that the screen updates in real-time

---

## 🚀 **BENEFITS OF MIGRATION**

After full migration, you'll have:

✅ **Real-time updates** - All screens auto-update when Firestore changes
✅ **No manual refresh** - Remove all refresh buttons and `_loadData()` methods  
✅ **Consistent UX** - All screens behave the same way
✅ **Less code** - Remove duplicate loading logic
✅ **Better performance** - Single source of truth, no redundant queries

---

## ⚠️ **KEEP WebDatabaseService FOR:**

- Database initialization (`_insertSampleData()`)
- Migration/cleanup scripts
- Seeder utilities
- Low-level operations that need direct DB access

---

## 📊 **MIGRATION STATUS**

- **Completed:** 4/14 files (28%)
- **In Progress:** Remaining screens
- **Next Priority:** Requestor screens (most user-facing)

---

**Last Updated:** 2025-10-27



## ✅ **COMPLETED MIGRATIONS**

### Screens:

1. ✅ **User Management Screen** - Uses `Consumer<UnifiedDataProvider>` for real-time users
2. ✅ **Inventory List Screen** - Uses `Consumer<UnifiedDataProvider>` for real-time inventory
3. ✅ **Create PM Task Screen** - Uses `Consumer<UnifiedDataProvider>` for technicians list
4. ✅ **Create Maintenance Request Screen** - Uses `UnifiedDataProvider.createWorkOrder()`

---

## 🔄 **REMAINING MIGRATIONS**

### **Screens Still Using WebDatabaseService:**

#### 1. **Requestor Status Screen**

**File:** `lib/screens/requestor/requestor_status_screen.dart`
**Current:** Loads work orders with `WebDatabaseService.instance.getAllWorkOrders()`
**Action Needed:** Convert to `Consumer<UnifiedDataProvider>` to get real-time work orders

**Example Fix:**

```dart
// Instead of:
Future<void> _loadMyRequests() async {
  final allWorkOrders = await WebDatabaseService.instance.getAllWorkOrders();
  setState(() {
    _myRequests = allWorkOrders.where((wo) => wo.requestorId == user.id).toList();
  });
}

// Use:
Consumer<UnifiedDataProvider>(
  builder: (context, unifiedProvider, child) {
    final myRequests = unifiedProvider.workOrders
        .where((wo) => wo.requestorId == user.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView(...);
  },
)
```

#### 2. **Requestor Main Screen**

**File:** `lib/screens/requestor/requestor_main_screen.dart`
**Action Needed:** Similar to Requestor Status Screen

#### 3. **Work Email Validation Screen**

**File:** `lib/screens/requestor/work_email_validation_screen.dart`
**Action Needed:** Replace user lookups with `UnifiedDataProvider.users`

#### 4. **Technician Viewer Screen**

**File:** `lib/screens/admin/technician_viewer_screen.dart`
**Action Needed:** Use `Consumer<UnifiedDataProvider>` for technicians

#### 5. **Low Stock Alerts Screen**

**File:** `lib/screens/inventory/low_stock_alerts_screen.dart`
**Action Needed:** Use `Consumer<UnifiedDataProvider>` for inventory

#### 6. **Parts Request Screen**

**File:** `lib/screens/inventory/parts_request_screen.dart`
**Action Needed:** Use `Consumer<UnifiedDataProvider>` for inventory items

---

### **Providers Still Using WebDatabaseService:**

#### 1. **Work Order Provider**

**File:** `lib/providers/work_order_provider.dart`
**Current:** May have WebDB calls
**Action Needed:** Verify it delegates to UnifiedDataProvider

#### 2. **PM Task Provider**

**File:** `lib/providers/pm_task_provider.dart`
**Current:** May have WebDB calls
**Action Needed:** Verify it delegates to UnifiedDataProvider

#### 3. **Auth Provider**

**File:** `lib/providers/auth_provider.dart`
**Current:** May use WebDB for user lookups
**Action Needed:** Use UnifiedDataProvider.users instead

---

## 🎯 **MIGRATION PATTERN**

For all remaining screens, follow this pattern:

### **Pattern 1: Loading Data Once (Convert to Real-Time)**

```dart
// OLD WAY ❌
class _MyScreenState extends State<MyScreen> {
  List<WorkOrder> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await WebDatabaseService.instance.getAllWorkOrders();
    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _data.length,
      itemBuilder: (context, index) => _buildItem(_data[index]),
    );
  }
}

// NEW WAY ✅
class _MyScreenState extends State<MyScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<UnifiedDataProvider>(
      builder: (context, unifiedProvider, child) {
        final data = unifiedProvider.workOrders;  // Real-time!

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) => _buildItem(data[index]),
        );
      },
    );
  }
}
```

### **Pattern 2: Creating Data**

```dart
// OLD WAY ❌
await WebDatabaseService.instance.createWorkOrder(workOrder);

// NEW WAY ✅
final unifiedProvider = Provider.of<UnifiedDataProvider>(context, listen: false);
await unifiedProvider.createWorkOrder(
  problemDescription: description,
  requestorId: userId,
  assetId: assetId,
  asset: asset,  // Pass full asset object
  priority: priority,
);
```

### **Pattern 3: Filtering Data**

```dart
// OLD WAY ❌
final allData = await WebDatabaseService.instance.getAllWorkOrders();
final filtered = allData.where((wo) => wo.status == WorkOrderStatus.open).toList();

// NEW WAY ✅
Consumer<UnifiedDataProvider>(
  builder: (context, unifiedProvider, child) {
    final filtered = unifiedProvider.workOrders
        .where((wo) => wo.status == WorkOrderStatus.open)
        .toList();

    return MyWidget(data: filtered);
  },
)
```

---

## 📝 **CHECKLIST FOR EACH MIGRATION**

For each screen you migrate:

- [ ] Import `UnifiedDataProvider`
- [ ] Remove `WebDatabaseService` import
- [ ] Replace `FutureBuilder` or `_loadData()` with `Consumer<UnifiedDataProvider>`
- [ ] Remove local state variables (`_data`, `_isLoading`)
- [ ] Use provider getters (`workOrders`, `users`, `assets`, `inventoryItems`, `pmTasks`)
- [ ] Test that the screen updates in real-time

---

## 🚀 **BENEFITS OF MIGRATION**

After full migration, you'll have:

✅ **Real-time updates** - All screens auto-update when Firestore changes
✅ **No manual refresh** - Remove all refresh buttons and `_loadData()` methods  
✅ **Consistent UX** - All screens behave the same way
✅ **Less code** - Remove duplicate loading logic
✅ **Better performance** - Single source of truth, no redundant queries

---

## ⚠️ **KEEP WebDatabaseService FOR:**

- Database initialization (`_insertSampleData()`)
- Migration/cleanup scripts
- Seeder utilities
- Low-level operations that need direct DB access

---

## 📊 **MIGRATION STATUS**

- **Completed:** 4/14 files (28%)
- **In Progress:** Remaining screens
- **Next Priority:** Requestor screens (most user-facing)

---

**Last Updated:** 2025-10-27



## ✅ **COMPLETED MIGRATIONS**

### Screens:

1. ✅ **User Management Screen** - Uses `Consumer<UnifiedDataProvider>` for real-time users
2. ✅ **Inventory List Screen** - Uses `Consumer<UnifiedDataProvider>` for real-time inventory
3. ✅ **Create PM Task Screen** - Uses `Consumer<UnifiedDataProvider>` for technicians list
4. ✅ **Create Maintenance Request Screen** - Uses `UnifiedDataProvider.createWorkOrder()`

---

## 🔄 **REMAINING MIGRATIONS**

### **Screens Still Using WebDatabaseService:**

#### 1. **Requestor Status Screen**

**File:** `lib/screens/requestor/requestor_status_screen.dart`
**Current:** Loads work orders with `WebDatabaseService.instance.getAllWorkOrders()`
**Action Needed:** Convert to `Consumer<UnifiedDataProvider>` to get real-time work orders

**Example Fix:**

```dart
// Instead of:
Future<void> _loadMyRequests() async {
  final allWorkOrders = await WebDatabaseService.instance.getAllWorkOrders();
  setState(() {
    _myRequests = allWorkOrders.where((wo) => wo.requestorId == user.id).toList();
  });
}

// Use:
Consumer<UnifiedDataProvider>(
  builder: (context, unifiedProvider, child) {
    final myRequests = unifiedProvider.workOrders
        .where((wo) => wo.requestorId == user.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView(...);
  },
)
```

#### 2. **Requestor Main Screen**

**File:** `lib/screens/requestor/requestor_main_screen.dart`
**Action Needed:** Similar to Requestor Status Screen

#### 3. **Work Email Validation Screen**

**File:** `lib/screens/requestor/work_email_validation_screen.dart`
**Action Needed:** Replace user lookups with `UnifiedDataProvider.users`

#### 4. **Technician Viewer Screen**

**File:** `lib/screens/admin/technician_viewer_screen.dart`
**Action Needed:** Use `Consumer<UnifiedDataProvider>` for technicians

#### 5. **Low Stock Alerts Screen**

**File:** `lib/screens/inventory/low_stock_alerts_screen.dart`
**Action Needed:** Use `Consumer<UnifiedDataProvider>` for inventory

#### 6. **Parts Request Screen**

**File:** `lib/screens/inventory/parts_request_screen.dart`
**Action Needed:** Use `Consumer<UnifiedDataProvider>` for inventory items

---

### **Providers Still Using WebDatabaseService:**

#### 1. **Work Order Provider**

**File:** `lib/providers/work_order_provider.dart`
**Current:** May have WebDB calls
**Action Needed:** Verify it delegates to UnifiedDataProvider

#### 2. **PM Task Provider**

**File:** `lib/providers/pm_task_provider.dart`
**Current:** May have WebDB calls
**Action Needed:** Verify it delegates to UnifiedDataProvider

#### 3. **Auth Provider**

**File:** `lib/providers/auth_provider.dart`
**Current:** May use WebDB for user lookups
**Action Needed:** Use UnifiedDataProvider.users instead

---

## 🎯 **MIGRATION PATTERN**

For all remaining screens, follow this pattern:

### **Pattern 1: Loading Data Once (Convert to Real-Time)**

```dart
// OLD WAY ❌
class _MyScreenState extends State<MyScreen> {
  List<WorkOrder> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await WebDatabaseService.instance.getAllWorkOrders();
    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _data.length,
      itemBuilder: (context, index) => _buildItem(_data[index]),
    );
  }
}

// NEW WAY ✅
class _MyScreenState extends State<MyScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<UnifiedDataProvider>(
      builder: (context, unifiedProvider, child) {
        final data = unifiedProvider.workOrders;  // Real-time!

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) => _buildItem(data[index]),
        );
      },
    );
  }
}
```

### **Pattern 2: Creating Data**

```dart
// OLD WAY ❌
await WebDatabaseService.instance.createWorkOrder(workOrder);

// NEW WAY ✅
final unifiedProvider = Provider.of<UnifiedDataProvider>(context, listen: false);
await unifiedProvider.createWorkOrder(
  problemDescription: description,
  requestorId: userId,
  assetId: assetId,
  asset: asset,  // Pass full asset object
  priority: priority,
);
```

### **Pattern 3: Filtering Data**

```dart
// OLD WAY ❌
final allData = await WebDatabaseService.instance.getAllWorkOrders();
final filtered = allData.where((wo) => wo.status == WorkOrderStatus.open).toList();

// NEW WAY ✅
Consumer<UnifiedDataProvider>(
  builder: (context, unifiedProvider, child) {
    final filtered = unifiedProvider.workOrders
        .where((wo) => wo.status == WorkOrderStatus.open)
        .toList();

    return MyWidget(data: filtered);
  },
)
```

---

## 📝 **CHECKLIST FOR EACH MIGRATION**

For each screen you migrate:

- [ ] Import `UnifiedDataProvider`
- [ ] Remove `WebDatabaseService` import
- [ ] Replace `FutureBuilder` or `_loadData()` with `Consumer<UnifiedDataProvider>`
- [ ] Remove local state variables (`_data`, `_isLoading`)
- [ ] Use provider getters (`workOrders`, `users`, `assets`, `inventoryItems`, `pmTasks`)
- [ ] Test that the screen updates in real-time

---

## 🚀 **BENEFITS OF MIGRATION**

After full migration, you'll have:

✅ **Real-time updates** - All screens auto-update when Firestore changes
✅ **No manual refresh** - Remove all refresh buttons and `_loadData()` methods  
✅ **Consistent UX** - All screens behave the same way
✅ **Less code** - Remove duplicate loading logic
✅ **Better performance** - Single source of truth, no redundant queries

---

## ⚠️ **KEEP WebDatabaseService FOR:**

- Database initialization (`_insertSampleData()`)
- Migration/cleanup scripts
- Seeder utilities
- Low-level operations that need direct DB access

---

## 📊 **MIGRATION STATUS**

- **Completed:** 4/14 files (28%)
- **In Progress:** Remaining screens
- **Next Priority:** Requestor screens (most user-facing)

---

**Last Updated:** 2025-10-27


