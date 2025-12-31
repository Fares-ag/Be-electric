# ⚡ Performance Profiling Guide - Q-AUTO CMMS

## Overview

Comprehensive performance profiling tools to identify bottlenecks, measure operation speeds, and optimize your Q-AUTO CMMS app.

---

## ✅ **What's Implemented**

### **Performance Monitor (`lib/utils/performance_monitor.dart`)**

Complete performance tracking system:

- ✅ Measure sync/async operations
- ✅ Track operation statistics (min/max/avg)
- ✅ Detect slow operations automatically
- ✅ Export metrics for analysis
- ✅ Widget build performance tracking
- ✅ Frame rate monitoring

### **Performance Diagnostic Screen**

Admin dashboard feature:

- ✅ Real-time performance metrics
- ✅ Operation statistics
- ✅ Slow operation detection
- ✅ Detailed operation breakdown
- ✅ Filter and search
- ✅ Clear metrics

---

## 🎯 **Usage Examples**

### **1. Basic Operation Measurement**

```dart
import 'package:qauto_cmms/utils/performance_monitor.dart';

// Measure a synchronous operation
final result = PerformanceMonitor.measure('loadWorkOrders', () {
  return loadWorkOrders();
});

// Measure an asynchronous operation
await PerformanceMonitor.measureAsync('fetchFromFirestore', () async {
  return await firestore.collection('work_orders').get();
});
```

### **2. Measure with Metadata**

```dart
await PerformanceMonitor.measureAsync(
  'loadWorkOrders',
  () async {
    return await loadWorkOrders();
  },
  metadata: {
    'count': workOrders.length,
    'filter': 'status:open',
  },
);
```

### **3. Manual Timing**

```dart
final stopwatch = PerformanceMonitor.start();

// Do work
await complexOperation();

PerformanceMonitor.end(stopwatch, 'complexOperation', metadata: {
  'items': 100,
});
```

### **4. Widget Build Tracking**

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _tracker = WidgetPerformanceTracker('MyWidget');

  @override
  Widget build(BuildContext context) {
    _tracker.startBuild();

    // Build your widget
    final widget = Column(children: [...]);

    _tracker.endBuild();
    return widget;
  }
}
```

---

## 📊 **Performance Diagnostic Screen**

### **Access:**

1. Login as Admin
2. Tap menu (⋮) in top right
3. Select "Performance Diagnostic"

### **Features:**

#### **Summary Card**

- Total operations tracked
- Unique operations
- Slow operations count
- Current threshold (default: 500ms)

#### **Operations List**

- All tracked operations
- Sorted by average duration (slowest first)
- Visual indicators (✅ fast, ⚠️ slow)
- Tap to see details

#### **Operation Details**

- Total executions
- Total time
- Average time
- Min/Max time
- Recent execution times (last 10)

#### **Filters**

- Show only slow operations
- Search operations

#### **Actions**

- Refresh metrics
- Clear all metrics

---

## 🔧 **Configuration**

### **Enable/Disable Profiling**

```dart
// Enable profiling (default: debug mode only)
PerformanceMonitor.enabled = true;

// Disable profiling
PerformanceMonitor.enabled = false;
```

### **Set Slow Operation Threshold**

```dart
// Default: 500ms
PerformanceMonitor.slowOperationThreshold = const Duration(milliseconds: 500);

// More strict: 300ms
PerformanceMonitor.slowOperationThreshold = const Duration(milliseconds: 300);

// More lenient: 1000ms (1 second)
PerformanceMonitor.slowOperationThreshold = const Duration(seconds: 1);
```

---

## 📋 **Getting Performance Reports**

### **Console Report**

```dart
// Print report to console
PerformanceMonitor.printReport();

// Get report as string
final report = PerformanceMonitor.getReport();
print(report);
```

**Example Output:**

```
=== PERFORMANCE REPORT ===
Total operations tracked: 147
Unique operations: 23
Slow operations (>500ms): 3

=== OPERATION STATISTICS ===
loadWorkOrders: avg=823ms, min=654ms, max=1245ms, count=12
loadPMTasks: avg=345ms, min=287ms, max=512ms, count=8
syncToFirestore: avg=156ms, min=98ms, max=234ms, count=45
```

### **Export Metrics**

```dart
// Export as JSON-compatible map
final metrics = PerformanceMonitor.exportMetrics();

// Save to file or send to analytics
await saveMetrics(metrics);
```

**Export Structure:**

```json
{
  "timestamp": "2025-01-28T10:30:00.000Z",
  "total_metrics": 147,
  "operations": ["loadWorkOrders", "loadPMTasks", ...],
  "slow_operations_count": 3,
  "statistics": {
    "loadWorkOrders": {
      "count": 12,
      "avg_ms": 823,
      "min_ms": 654,
      "max_ms": 1245
    }
  },
  "recent_metrics": [...]
}
```

---

## 🎯 **Common Use Cases**

### **1. Identify Slow Database Queries**

```dart
// In your data service
Future<List<WorkOrder>> getWorkOrders() async {
  return await PerformanceMonitor.measureAsync('getWorkOrders', () async {
    return await firestore.collection('work_orders').get();
  });
}
```

**Then:**

1. Use the app normally
2. Open Performance Diagnostic
3. Look for `getWorkOrders`
4. Check if avg time is high
5. Optimize query if needed

### **2. Track Screen Load Times**

```dart
class WorkOrderListScreen extends StatefulWidget {
  @override
  State<WorkOrderListScreen> createState() => _WorkOrderListScreenState();
}

class _WorkOrderListScreenState extends State<WorkOrderListScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await PerformanceMonitor.measureAsync('WorkOrderListScreen.load', () async {
      await loadWorkOrders();
      await loadFilters();
    });
  }
}
```

### **3. Monitor Network Operations**

```dart
Future<void> syncData() async {
  await PerformanceMonitor.measureAsync('syncToFirestore', () async {
    // Upload work orders
    await PerformanceMonitor.measureAsync('sync.workOrders', () async {
      await uploadWorkOrders();
    });

    // Upload PM tasks
    await PerformanceMonitor.measureAsync('sync.pmTasks', () async {
      await uploadPMTasks();
    });
  });
}
```

### **4. Track Widget Rebuilds**

```dart
class ExpensiveWidget extends StatefulWidget {
  @override
  State<ExpensiveWidget> createState() => _ExpensiveWidgetState();
}

class _ExpensiveWidgetState extends State<ExpensiveWidget> {
  final _tracker = WidgetPerformanceTracker('ExpensiveWidget');

  @override
  Widget build(BuildContext context) {
    _tracker.startBuild();
    final widget = _buildComplexUI();
    _tracker.endBuild();

    // Check rebuild count
    print('Build count: ${_tracker.buildCount}');

    return widget;
  }
}
```

---

## 🚀 **Optimization Workflow**

### **Step 1: Enable Profiling**

```dart
// In main.dart or app config
if (kDebugMode) {
  PerformanceMonitor.enabled = true;
}
```

### **Step 2: Use App Normally**

- Navigate through all screens
- Perform common operations
- Create/edit work orders
- Load PM tasks
- Search and filter

### **Step 3: Review Performance Diagnostic**

1. Open Performance Diagnostic screen
2. Sort operations by duration
3. Identify slow operations (>500ms)
4. Examine operation details

### **Step 4: Optimize Slow Operations**

**Example:** If `loadWorkOrders` is slow:

```dart
// BEFORE (slow)
Future<List<WorkOrder>> loadWorkOrders() async {
  final snapshot = await firestore.collection('work_orders').get();
  return snapshot.docs.map((doc) => WorkOrder.fromMap(doc.data())).toList();
}

// AFTER (optimized with pagination)
Future<List<WorkOrder>> loadWorkOrders({int limit = 20}) async {
  final snapshot = await firestore
    .collection('work_orders')
    .limit(limit)
    .get();
  return snapshot.docs.map((doc) => WorkOrder.fromMap(doc.data())).toList();
}
```

### **Step 5: Measure Improvement**

1. Clear metrics
2. Test optimized operation
3. Compare before/after times
4. Repeat for other slow operations

---

## 📊 **Interpreting Results**

### **Good Performance:**

- ✅ Average operation time < 300ms
- ✅ No operations > 1 second
- ✅ Consistent times (low variance)

### **Acceptable Performance:**

- ⚠️ Average operation time 300-500ms
- ⚠️ Occasional operations > 500ms
- ⚠️ Some variance in times

### **Poor Performance:**

- ❌ Average operation time > 500ms
- ❌ Many operations > 1 second
- ❌ High variance in times

### **Optimization Targets:**

| Operation Type  | Target Time    | Warning Time |
| --------------- | -------------- | ------------ |
| Database Query  | < 200ms        | > 500ms      |
| Network Request | < 300ms        | > 1000ms     |
| Widget Build    | < 16ms (60fps) | > 32ms       |
| Data Processing | < 100ms        | > 500ms      |
| Screen Load     | < 500ms        | > 2000ms     |

---

## 🔍 **Advanced Usage**

### **Get Statistics for Specific Operation**

```dart
final stats = PerformanceMonitor.getStatsForOperation('loadWorkOrders');
if (stats != null) {
  print('Average: ${stats.avgDuration.inMilliseconds}ms');
  print('Count: ${stats.count}');
}
```

### **Get All Slow Operations**

```dart
final slowOps = PerformanceMonitor.getSlowOperations();
for (final metric in slowOps) {
  print('${metric.operation}: ${metric.duration.inMilliseconds}ms');
}
```

### **Clear Specific Operation Metrics**

```dart
// Clear just one operation
PerformanceMonitor.clearOperation('loadWorkOrders');

// Clear all
PerformanceMonitor.clear();
```

---

## 🧪 **Testing Performance**

```dart
test('Work order loading performance', () async {
  // Clear previous metrics
  PerformanceMonitor.clear();

  // Load work orders
  await loadWorkOrders();

  // Check performance
  final stats = PerformanceMonitor.getStatsForOperation('loadWorkOrders');
  expect(stats, isNotNull);
  expect(stats!.avgDuration.inMilliseconds, lessThan(500));
});
```

---

## ✅ **Best Practices**

1. **Measure Everything:**

   - All database queries
   - Network requests
   - Heavy computations
   - Screen loads

2. **Use Descriptive Names:**

   - ✅ `loadWorkOrders.withFilters`
   - ❌ `load1`

3. **Add Metadata:**

   - Include relevant context
   - Item counts
   - Filter parameters

4. **Profile in Debug:**

   - Enable only in debug mode
   - Disable in production (overhead)

5. **Regular Monitoring:**

   - Check diagnostics weekly
   - Track trends over time
   - Address regressions quickly

6. **Optimize Iteratively:**
   - Fix slowest operations first
   - Measure impact
   - Don't over-optimize

---

## 📚 **Integration with Other Tools**

### **With Logger Service**

```dart
await PerformanceMonitor.measureAsync('criticalOperation', () async {
  LoggerService.info('Starting critical operation');
  final result = await criticalOperation();
  LoggerService.info('Critical operation completed');
  return result;
});
```

### **With Analytics**

```dart
final stats = PerformanceMonitor.getAllStats();
for (final entry in stats.entries) {
  AnalyticsIntegrationService.logEvent('performance_metric', {
    'operation': entry.key,
    'avg_duration_ms': entry.value.avgDuration.inMilliseconds,
  });
}
```

---

## ✅ **Status**

- ✅ Performance monitoring implemented
- ✅ Diagnostic screen ready
- ✅ Slow operation detection
- ✅ Statistics calculation
- ✅ Export functionality
- ✅ Widget tracking
- ✅ Frame rate monitoring
- ✅ Production-ready

---

**Date:** 2025-01-28  
**Status:** ✅ **COMPLETE**  
**Impact:** **HIGH** (Identify and fix bottlenecks)  
**Risk:** **ZERO** (Monitoring only, no code changes)

---

**⚡ Your app can now be profiled and optimized!**



## Overview

Comprehensive performance profiling tools to identify bottlenecks, measure operation speeds, and optimize your Q-AUTO CMMS app.

---

## ✅ **What's Implemented**

### **Performance Monitor (`lib/utils/performance_monitor.dart`)**

Complete performance tracking system:

- ✅ Measure sync/async operations
- ✅ Track operation statistics (min/max/avg)
- ✅ Detect slow operations automatically
- ✅ Export metrics for analysis
- ✅ Widget build performance tracking
- ✅ Frame rate monitoring

### **Performance Diagnostic Screen**

Admin dashboard feature:

- ✅ Real-time performance metrics
- ✅ Operation statistics
- ✅ Slow operation detection
- ✅ Detailed operation breakdown
- ✅ Filter and search
- ✅ Clear metrics

---

## 🎯 **Usage Examples**

### **1. Basic Operation Measurement**

```dart
import 'package:qauto_cmms/utils/performance_monitor.dart';

// Measure a synchronous operation
final result = PerformanceMonitor.measure('loadWorkOrders', () {
  return loadWorkOrders();
});

// Measure an asynchronous operation
await PerformanceMonitor.measureAsync('fetchFromFirestore', () async {
  return await firestore.collection('work_orders').get();
});
```

### **2. Measure with Metadata**

```dart
await PerformanceMonitor.measureAsync(
  'loadWorkOrders',
  () async {
    return await loadWorkOrders();
  },
  metadata: {
    'count': workOrders.length,
    'filter': 'status:open',
  },
);
```

### **3. Manual Timing**

```dart
final stopwatch = PerformanceMonitor.start();

// Do work
await complexOperation();

PerformanceMonitor.end(stopwatch, 'complexOperation', metadata: {
  'items': 100,
});
```

### **4. Widget Build Tracking**

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _tracker = WidgetPerformanceTracker('MyWidget');

  @override
  Widget build(BuildContext context) {
    _tracker.startBuild();

    // Build your widget
    final widget = Column(children: [...]);

    _tracker.endBuild();
    return widget;
  }
}
```

---

## 📊 **Performance Diagnostic Screen**

### **Access:**

1. Login as Admin
2. Tap menu (⋮) in top right
3. Select "Performance Diagnostic"

### **Features:**

#### **Summary Card**

- Total operations tracked
- Unique operations
- Slow operations count
- Current threshold (default: 500ms)

#### **Operations List**

- All tracked operations
- Sorted by average duration (slowest first)
- Visual indicators (✅ fast, ⚠️ slow)
- Tap to see details

#### **Operation Details**

- Total executions
- Total time
- Average time
- Min/Max time
- Recent execution times (last 10)

#### **Filters**

- Show only slow operations
- Search operations

#### **Actions**

- Refresh metrics
- Clear all metrics

---

## 🔧 **Configuration**

### **Enable/Disable Profiling**

```dart
// Enable profiling (default: debug mode only)
PerformanceMonitor.enabled = true;

// Disable profiling
PerformanceMonitor.enabled = false;
```

### **Set Slow Operation Threshold**

```dart
// Default: 500ms
PerformanceMonitor.slowOperationThreshold = const Duration(milliseconds: 500);

// More strict: 300ms
PerformanceMonitor.slowOperationThreshold = const Duration(milliseconds: 300);

// More lenient: 1000ms (1 second)
PerformanceMonitor.slowOperationThreshold = const Duration(seconds: 1);
```

---

## 📋 **Getting Performance Reports**

### **Console Report**

```dart
// Print report to console
PerformanceMonitor.printReport();

// Get report as string
final report = PerformanceMonitor.getReport();
print(report);
```

**Example Output:**

```
=== PERFORMANCE REPORT ===
Total operations tracked: 147
Unique operations: 23
Slow operations (>500ms): 3

=== OPERATION STATISTICS ===
loadWorkOrders: avg=823ms, min=654ms, max=1245ms, count=12
loadPMTasks: avg=345ms, min=287ms, max=512ms, count=8
syncToFirestore: avg=156ms, min=98ms, max=234ms, count=45
```

### **Export Metrics**

```dart
// Export as JSON-compatible map
final metrics = PerformanceMonitor.exportMetrics();

// Save to file or send to analytics
await saveMetrics(metrics);
```

**Export Structure:**

```json
{
  "timestamp": "2025-01-28T10:30:00.000Z",
  "total_metrics": 147,
  "operations": ["loadWorkOrders", "loadPMTasks", ...],
  "slow_operations_count": 3,
  "statistics": {
    "loadWorkOrders": {
      "count": 12,
      "avg_ms": 823,
      "min_ms": 654,
      "max_ms": 1245
    }
  },
  "recent_metrics": [...]
}
```

---

## 🎯 **Common Use Cases**

### **1. Identify Slow Database Queries**

```dart
// In your data service
Future<List<WorkOrder>> getWorkOrders() async {
  return await PerformanceMonitor.measureAsync('getWorkOrders', () async {
    return await firestore.collection('work_orders').get();
  });
}
```

**Then:**

1. Use the app normally
2. Open Performance Diagnostic
3. Look for `getWorkOrders`
4. Check if avg time is high
5. Optimize query if needed

### **2. Track Screen Load Times**

```dart
class WorkOrderListScreen extends StatefulWidget {
  @override
  State<WorkOrderListScreen> createState() => _WorkOrderListScreenState();
}

class _WorkOrderListScreenState extends State<WorkOrderListScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await PerformanceMonitor.measureAsync('WorkOrderListScreen.load', () async {
      await loadWorkOrders();
      await loadFilters();
    });
  }
}
```

### **3. Monitor Network Operations**

```dart
Future<void> syncData() async {
  await PerformanceMonitor.measureAsync('syncToFirestore', () async {
    // Upload work orders
    await PerformanceMonitor.measureAsync('sync.workOrders', () async {
      await uploadWorkOrders();
    });

    // Upload PM tasks
    await PerformanceMonitor.measureAsync('sync.pmTasks', () async {
      await uploadPMTasks();
    });
  });
}
```

### **4. Track Widget Rebuilds**

```dart
class ExpensiveWidget extends StatefulWidget {
  @override
  State<ExpensiveWidget> createState() => _ExpensiveWidgetState();
}

class _ExpensiveWidgetState extends State<ExpensiveWidget> {
  final _tracker = WidgetPerformanceTracker('ExpensiveWidget');

  @override
  Widget build(BuildContext context) {
    _tracker.startBuild();
    final widget = _buildComplexUI();
    _tracker.endBuild();

    // Check rebuild count
    print('Build count: ${_tracker.buildCount}');

    return widget;
  }
}
```

---

## 🚀 **Optimization Workflow**

### **Step 1: Enable Profiling**

```dart
// In main.dart or app config
if (kDebugMode) {
  PerformanceMonitor.enabled = true;
}
```

### **Step 2: Use App Normally**

- Navigate through all screens
- Perform common operations
- Create/edit work orders
- Load PM tasks
- Search and filter

### **Step 3: Review Performance Diagnostic**

1. Open Performance Diagnostic screen
2. Sort operations by duration
3. Identify slow operations (>500ms)
4. Examine operation details

### **Step 4: Optimize Slow Operations**

**Example:** If `loadWorkOrders` is slow:

```dart
// BEFORE (slow)
Future<List<WorkOrder>> loadWorkOrders() async {
  final snapshot = await firestore.collection('work_orders').get();
  return snapshot.docs.map((doc) => WorkOrder.fromMap(doc.data())).toList();
}

// AFTER (optimized with pagination)
Future<List<WorkOrder>> loadWorkOrders({int limit = 20}) async {
  final snapshot = await firestore
    .collection('work_orders')
    .limit(limit)
    .get();
  return snapshot.docs.map((doc) => WorkOrder.fromMap(doc.data())).toList();
}
```

### **Step 5: Measure Improvement**

1. Clear metrics
2. Test optimized operation
3. Compare before/after times
4. Repeat for other slow operations

---

## 📊 **Interpreting Results**

### **Good Performance:**

- ✅ Average operation time < 300ms
- ✅ No operations > 1 second
- ✅ Consistent times (low variance)

### **Acceptable Performance:**

- ⚠️ Average operation time 300-500ms
- ⚠️ Occasional operations > 500ms
- ⚠️ Some variance in times

### **Poor Performance:**

- ❌ Average operation time > 500ms
- ❌ Many operations > 1 second
- ❌ High variance in times

### **Optimization Targets:**

| Operation Type  | Target Time    | Warning Time |
| --------------- | -------------- | ------------ |
| Database Query  | < 200ms        | > 500ms      |
| Network Request | < 300ms        | > 1000ms     |
| Widget Build    | < 16ms (60fps) | > 32ms       |
| Data Processing | < 100ms        | > 500ms      |
| Screen Load     | < 500ms        | > 2000ms     |

---

## 🔍 **Advanced Usage**

### **Get Statistics for Specific Operation**

```dart
final stats = PerformanceMonitor.getStatsForOperation('loadWorkOrders');
if (stats != null) {
  print('Average: ${stats.avgDuration.inMilliseconds}ms');
  print('Count: ${stats.count}');
}
```

### **Get All Slow Operations**

```dart
final slowOps = PerformanceMonitor.getSlowOperations();
for (final metric in slowOps) {
  print('${metric.operation}: ${metric.duration.inMilliseconds}ms');
}
```

### **Clear Specific Operation Metrics**

```dart
// Clear just one operation
PerformanceMonitor.clearOperation('loadWorkOrders');

// Clear all
PerformanceMonitor.clear();
```

---

## 🧪 **Testing Performance**

```dart
test('Work order loading performance', () async {
  // Clear previous metrics
  PerformanceMonitor.clear();

  // Load work orders
  await loadWorkOrders();

  // Check performance
  final stats = PerformanceMonitor.getStatsForOperation('loadWorkOrders');
  expect(stats, isNotNull);
  expect(stats!.avgDuration.inMilliseconds, lessThan(500));
});
```

---

## ✅ **Best Practices**

1. **Measure Everything:**

   - All database queries
   - Network requests
   - Heavy computations
   - Screen loads

2. **Use Descriptive Names:**

   - ✅ `loadWorkOrders.withFilters`
   - ❌ `load1`

3. **Add Metadata:**

   - Include relevant context
   - Item counts
   - Filter parameters

4. **Profile in Debug:**

   - Enable only in debug mode
   - Disable in production (overhead)

5. **Regular Monitoring:**

   - Check diagnostics weekly
   - Track trends over time
   - Address regressions quickly

6. **Optimize Iteratively:**
   - Fix slowest operations first
   - Measure impact
   - Don't over-optimize

---

## 📚 **Integration with Other Tools**

### **With Logger Service**

```dart
await PerformanceMonitor.measureAsync('criticalOperation', () async {
  LoggerService.info('Starting critical operation');
  final result = await criticalOperation();
  LoggerService.info('Critical operation completed');
  return result;
});
```

### **With Analytics**

```dart
final stats = PerformanceMonitor.getAllStats();
for (final entry in stats.entries) {
  AnalyticsIntegrationService.logEvent('performance_metric', {
    'operation': entry.key,
    'avg_duration_ms': entry.value.avgDuration.inMilliseconds,
  });
}
```

---

## ✅ **Status**

- ✅ Performance monitoring implemented
- ✅ Diagnostic screen ready
- ✅ Slow operation detection
- ✅ Statistics calculation
- ✅ Export functionality
- ✅ Widget tracking
- ✅ Frame rate monitoring
- ✅ Production-ready

---

**Date:** 2025-01-28  
**Status:** ✅ **COMPLETE**  
**Impact:** **HIGH** (Identify and fix bottlenecks)  
**Risk:** **ZERO** (Monitoring only, no code changes)

---

**⚡ Your app can now be profiled and optimized!**



## Overview

Comprehensive performance profiling tools to identify bottlenecks, measure operation speeds, and optimize your Q-AUTO CMMS app.

---

## ✅ **What's Implemented**

### **Performance Monitor (`lib/utils/performance_monitor.dart`)**

Complete performance tracking system:

- ✅ Measure sync/async operations
- ✅ Track operation statistics (min/max/avg)
- ✅ Detect slow operations automatically
- ✅ Export metrics for analysis
- ✅ Widget build performance tracking
- ✅ Frame rate monitoring

### **Performance Diagnostic Screen**

Admin dashboard feature:

- ✅ Real-time performance metrics
- ✅ Operation statistics
- ✅ Slow operation detection
- ✅ Detailed operation breakdown
- ✅ Filter and search
- ✅ Clear metrics

---

## 🎯 **Usage Examples**

### **1. Basic Operation Measurement**

```dart
import 'package:qauto_cmms/utils/performance_monitor.dart';

// Measure a synchronous operation
final result = PerformanceMonitor.measure('loadWorkOrders', () {
  return loadWorkOrders();
});

// Measure an asynchronous operation
await PerformanceMonitor.measureAsync('fetchFromFirestore', () async {
  return await firestore.collection('work_orders').get();
});
```

### **2. Measure with Metadata**

```dart
await PerformanceMonitor.measureAsync(
  'loadWorkOrders',
  () async {
    return await loadWorkOrders();
  },
  metadata: {
    'count': workOrders.length,
    'filter': 'status:open',
  },
);
```

### **3. Manual Timing**

```dart
final stopwatch = PerformanceMonitor.start();

// Do work
await complexOperation();

PerformanceMonitor.end(stopwatch, 'complexOperation', metadata: {
  'items': 100,
});
```

### **4. Widget Build Tracking**

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _tracker = WidgetPerformanceTracker('MyWidget');

  @override
  Widget build(BuildContext context) {
    _tracker.startBuild();

    // Build your widget
    final widget = Column(children: [...]);

    _tracker.endBuild();
    return widget;
  }
}
```

---

## 📊 **Performance Diagnostic Screen**

### **Access:**

1. Login as Admin
2. Tap menu (⋮) in top right
3. Select "Performance Diagnostic"

### **Features:**

#### **Summary Card**

- Total operations tracked
- Unique operations
- Slow operations count
- Current threshold (default: 500ms)

#### **Operations List**

- All tracked operations
- Sorted by average duration (slowest first)
- Visual indicators (✅ fast, ⚠️ slow)
- Tap to see details

#### **Operation Details**

- Total executions
- Total time
- Average time
- Min/Max time
- Recent execution times (last 10)

#### **Filters**

- Show only slow operations
- Search operations

#### **Actions**

- Refresh metrics
- Clear all metrics

---

## 🔧 **Configuration**

### **Enable/Disable Profiling**

```dart
// Enable profiling (default: debug mode only)
PerformanceMonitor.enabled = true;

// Disable profiling
PerformanceMonitor.enabled = false;
```

### **Set Slow Operation Threshold**

```dart
// Default: 500ms
PerformanceMonitor.slowOperationThreshold = const Duration(milliseconds: 500);

// More strict: 300ms
PerformanceMonitor.slowOperationThreshold = const Duration(milliseconds: 300);

// More lenient: 1000ms (1 second)
PerformanceMonitor.slowOperationThreshold = const Duration(seconds: 1);
```

---

## 📋 **Getting Performance Reports**

### **Console Report**

```dart
// Print report to console
PerformanceMonitor.printReport();

// Get report as string
final report = PerformanceMonitor.getReport();
print(report);
```

**Example Output:**

```
=== PERFORMANCE REPORT ===
Total operations tracked: 147
Unique operations: 23
Slow operations (>500ms): 3

=== OPERATION STATISTICS ===
loadWorkOrders: avg=823ms, min=654ms, max=1245ms, count=12
loadPMTasks: avg=345ms, min=287ms, max=512ms, count=8
syncToFirestore: avg=156ms, min=98ms, max=234ms, count=45
```

### **Export Metrics**

```dart
// Export as JSON-compatible map
final metrics = PerformanceMonitor.exportMetrics();

// Save to file or send to analytics
await saveMetrics(metrics);
```

**Export Structure:**

```json
{
  "timestamp": "2025-01-28T10:30:00.000Z",
  "total_metrics": 147,
  "operations": ["loadWorkOrders", "loadPMTasks", ...],
  "slow_operations_count": 3,
  "statistics": {
    "loadWorkOrders": {
      "count": 12,
      "avg_ms": 823,
      "min_ms": 654,
      "max_ms": 1245
    }
  },
  "recent_metrics": [...]
}
```

---

## 🎯 **Common Use Cases**

### **1. Identify Slow Database Queries**

```dart
// In your data service
Future<List<WorkOrder>> getWorkOrders() async {
  return await PerformanceMonitor.measureAsync('getWorkOrders', () async {
    return await firestore.collection('work_orders').get();
  });
}
```

**Then:**

1. Use the app normally
2. Open Performance Diagnostic
3. Look for `getWorkOrders`
4. Check if avg time is high
5. Optimize query if needed

### **2. Track Screen Load Times**

```dart
class WorkOrderListScreen extends StatefulWidget {
  @override
  State<WorkOrderListScreen> createState() => _WorkOrderListScreenState();
}

class _WorkOrderListScreenState extends State<WorkOrderListScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await PerformanceMonitor.measureAsync('WorkOrderListScreen.load', () async {
      await loadWorkOrders();
      await loadFilters();
    });
  }
}
```

### **3. Monitor Network Operations**

```dart
Future<void> syncData() async {
  await PerformanceMonitor.measureAsync('syncToFirestore', () async {
    // Upload work orders
    await PerformanceMonitor.measureAsync('sync.workOrders', () async {
      await uploadWorkOrders();
    });

    // Upload PM tasks
    await PerformanceMonitor.measureAsync('sync.pmTasks', () async {
      await uploadPMTasks();
    });
  });
}
```

### **4. Track Widget Rebuilds**

```dart
class ExpensiveWidget extends StatefulWidget {
  @override
  State<ExpensiveWidget> createState() => _ExpensiveWidgetState();
}

class _ExpensiveWidgetState extends State<ExpensiveWidget> {
  final _tracker = WidgetPerformanceTracker('ExpensiveWidget');

  @override
  Widget build(BuildContext context) {
    _tracker.startBuild();
    final widget = _buildComplexUI();
    _tracker.endBuild();

    // Check rebuild count
    print('Build count: ${_tracker.buildCount}');

    return widget;
  }
}
```

---

## 🚀 **Optimization Workflow**

### **Step 1: Enable Profiling**

```dart
// In main.dart or app config
if (kDebugMode) {
  PerformanceMonitor.enabled = true;
}
```

### **Step 2: Use App Normally**

- Navigate through all screens
- Perform common operations
- Create/edit work orders
- Load PM tasks
- Search and filter

### **Step 3: Review Performance Diagnostic**

1. Open Performance Diagnostic screen
2. Sort operations by duration
3. Identify slow operations (>500ms)
4. Examine operation details

### **Step 4: Optimize Slow Operations**

**Example:** If `loadWorkOrders` is slow:

```dart
// BEFORE (slow)
Future<List<WorkOrder>> loadWorkOrders() async {
  final snapshot = await firestore.collection('work_orders').get();
  return snapshot.docs.map((doc) => WorkOrder.fromMap(doc.data())).toList();
}

// AFTER (optimized with pagination)
Future<List<WorkOrder>> loadWorkOrders({int limit = 20}) async {
  final snapshot = await firestore
    .collection('work_orders')
    .limit(limit)
    .get();
  return snapshot.docs.map((doc) => WorkOrder.fromMap(doc.data())).toList();
}
```

### **Step 5: Measure Improvement**

1. Clear metrics
2. Test optimized operation
3. Compare before/after times
4. Repeat for other slow operations

---

## 📊 **Interpreting Results**

### **Good Performance:**

- ✅ Average operation time < 300ms
- ✅ No operations > 1 second
- ✅ Consistent times (low variance)

### **Acceptable Performance:**

- ⚠️ Average operation time 300-500ms
- ⚠️ Occasional operations > 500ms
- ⚠️ Some variance in times

### **Poor Performance:**

- ❌ Average operation time > 500ms
- ❌ Many operations > 1 second
- ❌ High variance in times

### **Optimization Targets:**

| Operation Type  | Target Time    | Warning Time |
| --------------- | -------------- | ------------ |
| Database Query  | < 200ms        | > 500ms      |
| Network Request | < 300ms        | > 1000ms     |
| Widget Build    | < 16ms (60fps) | > 32ms       |
| Data Processing | < 100ms        | > 500ms      |
| Screen Load     | < 500ms        | > 2000ms     |

---

## 🔍 **Advanced Usage**

### **Get Statistics for Specific Operation**

```dart
final stats = PerformanceMonitor.getStatsForOperation('loadWorkOrders');
if (stats != null) {
  print('Average: ${stats.avgDuration.inMilliseconds}ms');
  print('Count: ${stats.count}');
}
```

### **Get All Slow Operations**

```dart
final slowOps = PerformanceMonitor.getSlowOperations();
for (final metric in slowOps) {
  print('${metric.operation}: ${metric.duration.inMilliseconds}ms');
}
```

### **Clear Specific Operation Metrics**

```dart
// Clear just one operation
PerformanceMonitor.clearOperation('loadWorkOrders');

// Clear all
PerformanceMonitor.clear();
```

---

## 🧪 **Testing Performance**

```dart
test('Work order loading performance', () async {
  // Clear previous metrics
  PerformanceMonitor.clear();

  // Load work orders
  await loadWorkOrders();

  // Check performance
  final stats = PerformanceMonitor.getStatsForOperation('loadWorkOrders');
  expect(stats, isNotNull);
  expect(stats!.avgDuration.inMilliseconds, lessThan(500));
});
```

---

## ✅ **Best Practices**

1. **Measure Everything:**

   - All database queries
   - Network requests
   - Heavy computations
   - Screen loads

2. **Use Descriptive Names:**

   - ✅ `loadWorkOrders.withFilters`
   - ❌ `load1`

3. **Add Metadata:**

   - Include relevant context
   - Item counts
   - Filter parameters

4. **Profile in Debug:**

   - Enable only in debug mode
   - Disable in production (overhead)

5. **Regular Monitoring:**

   - Check diagnostics weekly
   - Track trends over time
   - Address regressions quickly

6. **Optimize Iteratively:**
   - Fix slowest operations first
   - Measure impact
   - Don't over-optimize

---

## 📚 **Integration with Other Tools**

### **With Logger Service**

```dart
await PerformanceMonitor.measureAsync('criticalOperation', () async {
  LoggerService.info('Starting critical operation');
  final result = await criticalOperation();
  LoggerService.info('Critical operation completed');
  return result;
});
```

### **With Analytics**

```dart
final stats = PerformanceMonitor.getAllStats();
for (final entry in stats.entries) {
  AnalyticsIntegrationService.logEvent('performance_metric', {
    'operation': entry.key,
    'avg_duration_ms': entry.value.avgDuration.inMilliseconds,
  });
}
```

---

## ✅ **Status**

- ✅ Performance monitoring implemented
- ✅ Diagnostic screen ready
- ✅ Slow operation detection
- ✅ Statistics calculation
- ✅ Export functionality
- ✅ Widget tracking
- ✅ Frame rate monitoring
- ✅ Production-ready

---

**Date:** 2025-01-28  
**Status:** ✅ **COMPLETE**  
**Impact:** **HIGH** (Identify and fix bottlenecks)  
**Risk:** **ZERO** (Monitoring only, no code changes)

---

**⚡ Your app can now be profiled and optimized!**


