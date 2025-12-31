# 📋 Logger Migration Guide

## Overview

We've implemented a centralized `LoggerService` to replace scattered `print` and `debugPrint` statements. This guide shows how to gradually migrate existing code.

---

## ✅ **Benefits**

- 🎯 **Structured logging** with log levels (debug, info, warning, error)
- 🔍 **Better debugging** with tags, timestamps, and stack traces
- 🚀 **Production-ready** with configurable log levels
- 📊 **Crash reporting** integration ready (Firebase Crashlytics)
- ⚡ **Performance tracking** built-in

---

## 📖 **Usage Examples**

### **Basic Logging**

```dart
// BEFORE
print('User logged in');
debugPrint('Data loaded: $data');

// AFTER
LoggerService.info('User logged in', tag: 'Auth');
LoggerService.debug('Data loaded: $data', tag: 'DataService');
```

### **Error Logging**

```dart
// BEFORE
try {
  await loadData();
} catch (e) {
  print('Error loading data: $e');
}

// AFTER
try {
  await loadData();
} catch (e, stackTrace) {
  LoggerService.error(
    'Error loading data',
    error: e,
    stackTrace: stackTrace,
    tag: 'DataService',
  );
}
```

### **Warning Logging**

```dart
// BEFORE
print('⚠️ Cache size exceeds 100MB');

// AFTER
LoggerService.warning('Cache size exceeds 100MB', tag: 'CacheService');
```

### **Performance Tracking**

```dart
// BEFORE
final stopwatch = Stopwatch()..start();
await heavyOperation();
stopwatch.stop();
print('Operation took: ${stopwatch.elapsedMilliseconds}ms');

// AFTER
await LoggerService.measureAsync('Heavy operation', () async {
  await heavyOperation();
});
```

### **User Actions (for Analytics)**

```dart
// Track user interactions
LoggerService.logUserAction('work_order_created', parameters: {
  'priority': 'high',
  'asset_id': assetId,
});
```

### **HTTP Requests/Responses**

```dart
LoggerService.logRequest(
  method: 'GET',
  url: 'https://api.example.com/data',
  headers: headers,
);

LoggerService.logResponse(
  statusCode: 200,
  url: 'https://api.example.com/data',
  duration: elapsed,
);
```

---

## 🔧 **Configuration**

### **Development Mode**

```dart
// In main.dart or app initialization
LoggerService.configure(
  minimumLogLevel: LogLevel.debug, // Show all logs
  enableTimestamps: true,
  enableStackTraces: true,
);
```

### **Production Mode**

```dart
LoggerService.configure(
  minimumLogLevel: LogLevel.warning, // Only warnings and errors
  enableTimestamps: false,
  enableStackTraces: false,
);
```

### **With Crash Reporting**

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

LoggerService.configure(
  crashReporter: (error, stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  },
);
```

---

## 🔄 **Migration Strategy**

### **Phase 1: New Code** ✅

- Use `LoggerService` for all new code
- NO MORE `print` or `debugPrint` in new files

### **Phase 2: Critical Services** (Gradual)

Migrate existing services one at a time:

1. Start with most frequently used services
2. Replace `print` with `LoggerService.info/error`
3. Test after each migration
4. Commit changes

**Priority Services to Migrate:**

- `unified_data_service.dart`
- `firebase_firestore_service.dart`
- `unified_data_provider.dart`
- `auth_provider.dart`
- `work_order_provider.dart`

### **Phase 3: UI Layer** (Gradual)

- Migrate screens and widgets
- Focus on error handling in UI

---

## 📝 **Migration Checklist for a Service**

```dart
// 1. Import LoggerService
import 'package:qauto_cmms/services/logger_service.dart';

// 2. Replace print statements
// BEFORE:
print('🔥 Firestore: Creating work order');

// AFTER:
LoggerService.info('Creating work order', tag: 'Firestore');

// 3. Replace error handling
// BEFORE:
print('❌ Error: $e');

// AFTER:
LoggerService.error('Operation failed', error: e, stackTrace: stackTrace, tag: 'Firestore');

// 4. Replace debug prints
// BEFORE:
debugPrint('Data: $data');

// AFTER:
LoggerService.debug('Data: $data', tag: 'ServiceName');
```

---

## 🎯 **Log Level Guidelines**

| Level       | When to Use                               | Example                                           |
| ----------- | ----------------------------------------- | ------------------------------------------------- |
| **Debug**   | Detailed debugging info, temporary traces | `LoggerService.debug('User data: $user')`         |
| **Info**    | General informational messages            | `LoggerService.info('Sync completed')`            |
| **Warning** | Potentially harmful situations            | `LoggerService.warning('API rate limit at 80%')`  |
| **Error**   | Error events, exceptions                  | `LoggerService.error('Failed to load', error: e)` |

---

## ⚠️ **DO NOT**

❌ Remove existing logging until tested
❌ Mix `print` and `LoggerService` in the same file (migrate completely)
❌ Log sensitive user data (passwords, tokens, etc.)
❌ Log in tight loops (performance impact)

---

## ✅ **DO**

✅ Add meaningful tags to identify log sources
✅ Include error objects and stack traces for errors
✅ Use appropriate log levels
✅ Test after migrating each file
✅ Configure for production (warning+ only)

---

## 🧪 **Testing**

The logger is fully tested. Run tests with:

```bash
flutter test test/services/logger_service_test.dart
```

---

## 📊 **Current Status**

- ✅ LoggerService created
- ✅ Tests written and passing
- ✅ Documentation complete
- ⏳ Migration in progress (gradual)

---

**Next Steps:** Gradually migrate services starting with the most critical ones.



## Overview

We've implemented a centralized `LoggerService` to replace scattered `print` and `debugPrint` statements. This guide shows how to gradually migrate existing code.

---

## ✅ **Benefits**

- 🎯 **Structured logging** with log levels (debug, info, warning, error)
- 🔍 **Better debugging** with tags, timestamps, and stack traces
- 🚀 **Production-ready** with configurable log levels
- 📊 **Crash reporting** integration ready (Firebase Crashlytics)
- ⚡ **Performance tracking** built-in

---

## 📖 **Usage Examples**

### **Basic Logging**

```dart
// BEFORE
print('User logged in');
debugPrint('Data loaded: $data');

// AFTER
LoggerService.info('User logged in', tag: 'Auth');
LoggerService.debug('Data loaded: $data', tag: 'DataService');
```

### **Error Logging**

```dart
// BEFORE
try {
  await loadData();
} catch (e) {
  print('Error loading data: $e');
}

// AFTER
try {
  await loadData();
} catch (e, stackTrace) {
  LoggerService.error(
    'Error loading data',
    error: e,
    stackTrace: stackTrace,
    tag: 'DataService',
  );
}
```

### **Warning Logging**

```dart
// BEFORE
print('⚠️ Cache size exceeds 100MB');

// AFTER
LoggerService.warning('Cache size exceeds 100MB', tag: 'CacheService');
```

### **Performance Tracking**

```dart
// BEFORE
final stopwatch = Stopwatch()..start();
await heavyOperation();
stopwatch.stop();
print('Operation took: ${stopwatch.elapsedMilliseconds}ms');

// AFTER
await LoggerService.measureAsync('Heavy operation', () async {
  await heavyOperation();
});
```

### **User Actions (for Analytics)**

```dart
// Track user interactions
LoggerService.logUserAction('work_order_created', parameters: {
  'priority': 'high',
  'asset_id': assetId,
});
```

### **HTTP Requests/Responses**

```dart
LoggerService.logRequest(
  method: 'GET',
  url: 'https://api.example.com/data',
  headers: headers,
);

LoggerService.logResponse(
  statusCode: 200,
  url: 'https://api.example.com/data',
  duration: elapsed,
);
```

---

## 🔧 **Configuration**

### **Development Mode**

```dart
// In main.dart or app initialization
LoggerService.configure(
  minimumLogLevel: LogLevel.debug, // Show all logs
  enableTimestamps: true,
  enableStackTraces: true,
);
```

### **Production Mode**

```dart
LoggerService.configure(
  minimumLogLevel: LogLevel.warning, // Only warnings and errors
  enableTimestamps: false,
  enableStackTraces: false,
);
```

### **With Crash Reporting**

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

LoggerService.configure(
  crashReporter: (error, stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  },
);
```

---

## 🔄 **Migration Strategy**

### **Phase 1: New Code** ✅

- Use `LoggerService` for all new code
- NO MORE `print` or `debugPrint` in new files

### **Phase 2: Critical Services** (Gradual)

Migrate existing services one at a time:

1. Start with most frequently used services
2. Replace `print` with `LoggerService.info/error`
3. Test after each migration
4. Commit changes

**Priority Services to Migrate:**

- `unified_data_service.dart`
- `firebase_firestore_service.dart`
- `unified_data_provider.dart`
- `auth_provider.dart`
- `work_order_provider.dart`

### **Phase 3: UI Layer** (Gradual)

- Migrate screens and widgets
- Focus on error handling in UI

---

## 📝 **Migration Checklist for a Service**

```dart
// 1. Import LoggerService
import 'package:qauto_cmms/services/logger_service.dart';

// 2. Replace print statements
// BEFORE:
print('🔥 Firestore: Creating work order');

// AFTER:
LoggerService.info('Creating work order', tag: 'Firestore');

// 3. Replace error handling
// BEFORE:
print('❌ Error: $e');

// AFTER:
LoggerService.error('Operation failed', error: e, stackTrace: stackTrace, tag: 'Firestore');

// 4. Replace debug prints
// BEFORE:
debugPrint('Data: $data');

// AFTER:
LoggerService.debug('Data: $data', tag: 'ServiceName');
```

---

## 🎯 **Log Level Guidelines**

| Level       | When to Use                               | Example                                           |
| ----------- | ----------------------------------------- | ------------------------------------------------- |
| **Debug**   | Detailed debugging info, temporary traces | `LoggerService.debug('User data: $user')`         |
| **Info**    | General informational messages            | `LoggerService.info('Sync completed')`            |
| **Warning** | Potentially harmful situations            | `LoggerService.warning('API rate limit at 80%')`  |
| **Error**   | Error events, exceptions                  | `LoggerService.error('Failed to load', error: e)` |

---

## ⚠️ **DO NOT**

❌ Remove existing logging until tested
❌ Mix `print` and `LoggerService` in the same file (migrate completely)
❌ Log sensitive user data (passwords, tokens, etc.)
❌ Log in tight loops (performance impact)

---

## ✅ **DO**

✅ Add meaningful tags to identify log sources
✅ Include error objects and stack traces for errors
✅ Use appropriate log levels
✅ Test after migrating each file
✅ Configure for production (warning+ only)

---

## 🧪 **Testing**

The logger is fully tested. Run tests with:

```bash
flutter test test/services/logger_service_test.dart
```

---

## 📊 **Current Status**

- ✅ LoggerService created
- ✅ Tests written and passing
- ✅ Documentation complete
- ⏳ Migration in progress (gradual)

---

**Next Steps:** Gradually migrate services starting with the most critical ones.



## Overview

We've implemented a centralized `LoggerService` to replace scattered `print` and `debugPrint` statements. This guide shows how to gradually migrate existing code.

---

## ✅ **Benefits**

- 🎯 **Structured logging** with log levels (debug, info, warning, error)
- 🔍 **Better debugging** with tags, timestamps, and stack traces
- 🚀 **Production-ready** with configurable log levels
- 📊 **Crash reporting** integration ready (Firebase Crashlytics)
- ⚡ **Performance tracking** built-in

---

## 📖 **Usage Examples**

### **Basic Logging**

```dart
// BEFORE
print('User logged in');
debugPrint('Data loaded: $data');

// AFTER
LoggerService.info('User logged in', tag: 'Auth');
LoggerService.debug('Data loaded: $data', tag: 'DataService');
```

### **Error Logging**

```dart
// BEFORE
try {
  await loadData();
} catch (e) {
  print('Error loading data: $e');
}

// AFTER
try {
  await loadData();
} catch (e, stackTrace) {
  LoggerService.error(
    'Error loading data',
    error: e,
    stackTrace: stackTrace,
    tag: 'DataService',
  );
}
```

### **Warning Logging**

```dart
// BEFORE
print('⚠️ Cache size exceeds 100MB');

// AFTER
LoggerService.warning('Cache size exceeds 100MB', tag: 'CacheService');
```

### **Performance Tracking**

```dart
// BEFORE
final stopwatch = Stopwatch()..start();
await heavyOperation();
stopwatch.stop();
print('Operation took: ${stopwatch.elapsedMilliseconds}ms');

// AFTER
await LoggerService.measureAsync('Heavy operation', () async {
  await heavyOperation();
});
```

### **User Actions (for Analytics)**

```dart
// Track user interactions
LoggerService.logUserAction('work_order_created', parameters: {
  'priority': 'high',
  'asset_id': assetId,
});
```

### **HTTP Requests/Responses**

```dart
LoggerService.logRequest(
  method: 'GET',
  url: 'https://api.example.com/data',
  headers: headers,
);

LoggerService.logResponse(
  statusCode: 200,
  url: 'https://api.example.com/data',
  duration: elapsed,
);
```

---

## 🔧 **Configuration**

### **Development Mode**

```dart
// In main.dart or app initialization
LoggerService.configure(
  minimumLogLevel: LogLevel.debug, // Show all logs
  enableTimestamps: true,
  enableStackTraces: true,
);
```

### **Production Mode**

```dart
LoggerService.configure(
  minimumLogLevel: LogLevel.warning, // Only warnings and errors
  enableTimestamps: false,
  enableStackTraces: false,
);
```

### **With Crash Reporting**

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

LoggerService.configure(
  crashReporter: (error, stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  },
);
```

---

## 🔄 **Migration Strategy**

### **Phase 1: New Code** ✅

- Use `LoggerService` for all new code
- NO MORE `print` or `debugPrint` in new files

### **Phase 2: Critical Services** (Gradual)

Migrate existing services one at a time:

1. Start with most frequently used services
2. Replace `print` with `LoggerService.info/error`
3. Test after each migration
4. Commit changes

**Priority Services to Migrate:**

- `unified_data_service.dart`
- `firebase_firestore_service.dart`
- `unified_data_provider.dart`
- `auth_provider.dart`
- `work_order_provider.dart`

### **Phase 3: UI Layer** (Gradual)

- Migrate screens and widgets
- Focus on error handling in UI

---

## 📝 **Migration Checklist for a Service**

```dart
// 1. Import LoggerService
import 'package:qauto_cmms/services/logger_service.dart';

// 2. Replace print statements
// BEFORE:
print('🔥 Firestore: Creating work order');

// AFTER:
LoggerService.info('Creating work order', tag: 'Firestore');

// 3. Replace error handling
// BEFORE:
print('❌ Error: $e');

// AFTER:
LoggerService.error('Operation failed', error: e, stackTrace: stackTrace, tag: 'Firestore');

// 4. Replace debug prints
// BEFORE:
debugPrint('Data: $data');

// AFTER:
LoggerService.debug('Data: $data', tag: 'ServiceName');
```

---

## 🎯 **Log Level Guidelines**

| Level       | When to Use                               | Example                                           |
| ----------- | ----------------------------------------- | ------------------------------------------------- |
| **Debug**   | Detailed debugging info, temporary traces | `LoggerService.debug('User data: $user')`         |
| **Info**    | General informational messages            | `LoggerService.info('Sync completed')`            |
| **Warning** | Potentially harmful situations            | `LoggerService.warning('API rate limit at 80%')`  |
| **Error**   | Error events, exceptions                  | `LoggerService.error('Failed to load', error: e)` |

---

## ⚠️ **DO NOT**

❌ Remove existing logging until tested
❌ Mix `print` and `LoggerService` in the same file (migrate completely)
❌ Log sensitive user data (passwords, tokens, etc.)
❌ Log in tight loops (performance impact)

---

## ✅ **DO**

✅ Add meaningful tags to identify log sources
✅ Include error objects and stack traces for errors
✅ Use appropriate log levels
✅ Test after migrating each file
✅ Configure for production (warning+ only)

---

## 🧪 **Testing**

The logger is fully tested. Run tests with:

```bash
flutter test test/services/logger_service_test.dart
```

---

## 📊 **Current Status**

- ✅ LoggerService created
- ✅ Tests written and passing
- ✅ Documentation complete
- ⏳ Migration in progress (gradual)

---

**Next Steps:** Gradually migrate services starting with the most critical ones.


