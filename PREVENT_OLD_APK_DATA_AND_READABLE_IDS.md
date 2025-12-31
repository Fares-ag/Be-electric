# Prevent Old APK Data Sync & Readable IDs Implementation

## Overview
This implementation addresses two critical issues:
1. **Preventing old APK data from populating the database** - Old APK installations could sync stale data and overwrite newer information
2. **Making IDs readable and unique** - Work order and user IDs are now human-readable and easy to identify

## Changes Made

### 1. App Version Tracking (`lib/utils/app_version_tracker.dart`)
- **Purpose**: Track app version and build number to prevent old APK data from syncing
- **Features**:
  - Compares current app version with last sync version
  - Only allows sync if current version is newer or equal
  - Stores version info in SharedPreferences
  - Prevents downgraded APKs from overwriting newer data

**Usage**:
```dart
// Check if sync should proceed
final isNewer = await AppVersionTracker.isNewerVersion();
if (isNewer) {
  // Proceed with sync
  await syncAllData();
  await AppVersionTracker.markSyncCompleted();
}
```

### 2. Updated ID Generators (`lib/utils/deterministic_id_generator.dart`)

#### Work Order IDs
- **Old Format**: `wo_{hash}` (e.g., `wo_a1b2c3d4e5f6`)
- **New Format**: `WO-YYYY-NNNNN` (e.g., `WO-2025-00123`)
  - `YYYY` = Year (4 digits)
  - `NNNNN` = Sequential number (5 digits, padded with zeros)
  - Example: `WO-2025-00123`, `WO-2025-00124`

**Benefits**:
- Human-readable: You can immediately see the year
- Easy to sort chronologically
- Unique: Based on timestamp milliseconds
- Firestore-safe: No special characters

#### User IDs
- **Old Format**: `user_{hash}` (e.g., `user_a1b2c3d4e5f6`)
- **New Format**: `USER-{email_prefix}` (e.g., `USER-john.doe`)
  - Extracts email prefix (before @)
  - Sanitizes special characters
  - Adds hash suffix if email is too short
  - Example: `USER-john.doe`, `USER-admin`

**Benefits**:
- Human-readable: You can see who the user is
- Deterministic: Same email = same ID
- Unique: Hash suffix ensures uniqueness

### 3. Enhanced Sync Service (`lib/services/firebase_sync_service.dart`)

#### Version Check Integration
- Sync only proceeds if app version is newer than last sync
- Prevents old APK installations from overwriting newer data
- Logs version information for debugging

#### Timestamp-Based Conflict Resolution
- Only updates if source data is **significantly newer** (>1 second difference)
- Prevents race conditions and old data overwrites
- Logs time differences for debugging

**Example**:
```dart
// Only update if local is more than 1 second newer
if (localIsNewer && timeDiff.inSeconds > 1) {
  await _firestore.updateWorkOrder(localWorkOrder.id, localWorkOrder);
}
```

### 4. Updated Work Order Creation (`lib/services/unified_data_service.dart`)

- Automatically generates readable IDs in `WO-YYYY-NNNNN` format
- If ticket number is already in correct format, uses it as ID
- Updates ticket number to match generated ID if needed
- Ensures consistency between ticket number and document ID

### 5. Updated Firestore Service (`lib/services/firebase_firestore_service.dart`)

- Uses new readable ID format when creating work orders
- Passes `createdAt` timestamp to ID generator for accurate year

## Migration Notes

### Existing Data
- **Work Orders**: Existing work orders with old IDs (`wo_*`) will continue to work
- **Users**: Existing users with old IDs (`user_*`) will continue to work
- **New Records**: All new work orders and users will use the new readable format

### Backward Compatibility
- ID validation accepts both old and new formats
- Sync service handles both formats seamlessly
- No data migration required

## Testing

### Test App Version Tracking
1. Install app version 1.0.0
2. Create some data
3. Sync to Firestore
4. Install older APK (e.g., 0.9.0)
5. Verify sync is blocked
6. Install newer APK (e.g., 1.1.0)
7. Verify sync proceeds

### Test Readable IDs
1. Create a new work order
2. Verify ID format: `WO-2025-00123`
3. Create a new user with email `john.doe@example.com`
4. Verify ID format: `USER-john.doe`

### Test Conflict Resolution
1. Create work order on Device A
2. Update work order on Device B (newer timestamp)
3. Sync both devices
4. Verify Device B's version is kept (newer timestamp wins)

## Benefits

1. **Data Integrity**: Old APK data cannot overwrite newer data
2. **Readability**: IDs are human-readable and easy to identify
3. **Uniqueness**: IDs remain unique and deterministic
4. **Debugging**: Easier to identify records in logs and Firestore console
5. **User Experience**: Users can reference work orders by readable IDs

## Example IDs

### Work Orders
- `WO-2025-00123` - Work order #123 created in 2025
- `WO-2025-00124` - Next work order
- `WO-2024-99999` - Work order from 2024

### Users
- `USER-john.doe` - User with email `john.doe@example.com`
- `USER-admin` - User with email `admin@company.com`
- `USER-john.doe-a1b2c3` - User with short email prefix (hash added)

## Configuration

No configuration required. The system automatically:
- Tracks app versions
- Generates readable IDs
- Prevents old data sync
- Resolves conflicts intelligently

## Troubleshooting

### Sync Not Working
- Check app version: `await AppVersionTracker.getVersionInfo()`
- Verify version is newer than last sync
- Check logs for version comparison results

### ID Format Issues
- Old IDs (`wo_*`, `user_*`) still work
- New IDs are generated automatically
- No manual intervention needed

### Conflict Resolution
- Check timestamp differences in logs
- Verify `updatedAt` fields are set correctly
- Ensure clocks are synchronized across devices

## Future Enhancements

1. **Sequential Numbering**: Track sequential numbers per year in Firestore
2. **ID Prefixes**: Add prefixes for different work order types
3. **Migration Tool**: Optional tool to migrate old IDs to new format
4. **Version History**: Track version changes in audit logs




