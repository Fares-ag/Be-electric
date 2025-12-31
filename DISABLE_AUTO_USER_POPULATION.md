# Disable Automatic User Population

## Problem
Users were automatically populating in the system from two sources:
1. **Auto-creation on login**: When someone signed in via Firebase Auth, they were automatically created in the local database if they didn't exist
2. **Auto-sync from Firestore**: The sync service automatically pulled all users from Firestore and created them locally

## Solution
Added configuration options to control automatic user population:

### Configuration Options

#### 1. `AUTO_POPULATE_USERS` (Default: `false`)
- **Purpose**: Controls whether users are automatically synced from Firestore
- **When disabled**: Users are only created explicitly by admins, not automatically synced
- **Usage**: Set via `--dart-define=AUTO_POPULATE_USERS=false`

#### 2. `AUTO_CREATE_USERS_ON_LOGIN` (Default: `false`)
- **Purpose**: Controls whether users are automatically created when they log in
- **When disabled**: Users must exist in the database before they can log in
- **Usage**: Set via `--dart-define=AUTO_CREATE_USERS_ON_LOGIN=false`

## How It Works

### Before (Automatic Population)
```dart
// User logs in via Firebase Auth
// → System automatically creates user in local DB
// → Sync service pulls all users from Firestore
// → All Firestore users appear in local database
```

### After (Controlled Population)
```dart
// User logs in via Firebase Auth
// → If AUTO_CREATE_USERS_ON_LOGIN=false: Login fails if user doesn't exist
// → If AUTO_POPULATE_USERS=false: Sync service skips user sync
// → Users are only created explicitly by admins
```

## Configuration

### Option 1: Disable Both (Recommended for Production)
```bash
flutter run --dart-define=AUTO_POPULATE_USERS=false --dart-define=AUTO_CREATE_USERS_ON_LOGIN=false
```

### Option 2: Allow Auto-Creation on Login Only
```bash
flutter run --dart-define=AUTO_POPULATE_USERS=false --dart-define=AUTO_CREATE_USERS_ON_LOGIN=true
```

### Option 3: Allow Auto-Sync from Firestore Only
```bash
flutter run --dart-define=AUTO_POPULATE_USERS=true --dart-define=AUTO_CREATE_USERS_ON_LOGIN=false
```

### Option 4: Enable Both (Original Behavior)
```bash
flutter run --dart-define=AUTO_POPULATE_USERS=true --dart-define=AUTO_CREATE_USERS_ON_LOGIN=true
```

## Code Changes

### 1. AppConfig (`lib/config/app_config.dart`)
Added two new configuration flags:
```dart
static bool get autoPopulateUsers =>
    const bool.fromEnvironment('AUTO_POPULATE_USERS', defaultValue: false);

static bool get autoCreateUsersOnLogin =>
    const bool.fromEnvironment('AUTO_CREATE_USERS_ON_LOGIN', defaultValue: false);
```

### 2. AuthProvider (`lib/providers/auth_provider.dart`)
- Checks `AUTO_CREATE_USERS_ON_LOGIN` before creating users on login
- Returns `false` (login fails) if user doesn't exist and auto-creation is disabled

### 3. FirebaseSyncService (`lib/services/firebase_sync_service.dart`)
- Checks `AUTO_POPULATE_USERS` before syncing users from Firestore
- Skips user sync entirely if auto-population is disabled

## Behavior by Configuration

| AUTO_POPULATE_USERS | AUTO_CREATE_USERS_ON_LOGIN | Behavior |
|---------------------|---------------------------|----------|
| `false` | `false` | **Strict mode**: Users must be created by admins. No auto-creation or sync. |
| `false` | `true` | Users created on login, but not synced from Firestore |
| `true` | `false` | Users synced from Firestore, but not created on login |
| `true` | `true` | **Original behavior**: Auto-create on login + auto-sync from Firestore |

## Recommended Settings

### Production
```bash
--dart-define=AUTO_POPULATE_USERS=false --dart-define=AUTO_CREATE_USERS_ON_LOGIN=false
```
- **Why**: Full control over user creation
- **Users must be**: Created explicitly by admins
- **Prevents**: Unauthorized users from appearing in the system

### Development/Testing
```bash
--dart-define=AUTO_POPULATE_USERS=true --dart-define=AUTO_CREATE_USERS_ON_LOGIN=true
```
- **Why**: Easier testing and development
- **Users are**: Automatically created and synced
- **Allows**: Quick user setup for testing

## Migration Notes

### Existing Installations
- **Default behavior**: Both flags default to `false` (strict mode)
- **Existing users**: Will continue to work
- **New users**: Must be created by admins if flags are disabled

### Upgrading
1. If you want to keep automatic population, set both flags to `true`
2. If you want strict control, leave defaults (`false`)
3. Users already in the system will continue to work

## Troubleshooting

### Users Not Appearing
- **Check**: `AUTO_POPULATE_USERS` flag
- **Solution**: Set to `true` if you want automatic sync, or create users manually

### Login Failing for New Users
- **Check**: `AUTO_CREATE_USERS_ON_LOGIN` flag
- **Solution**: Set to `true` to allow auto-creation, or create user before login

### Users Still Auto-Populating
- **Check**: Both flags are set correctly
- **Verify**: Configuration is applied (check logs for config values)
- **Solution**: Ensure flags are set in build command or environment

## Example Logs

### With Auto-Population Disabled
```
Firebase Sync: Auto-populate users is disabled. Skipping user sync.
```

### With Auto-Creation Disabled
```
⚠️ User not found in local DB and auto-creation is disabled. 
User must be created by an admin before they can log in.
```

## Benefits

1. **Security**: Prevents unauthorized users from appearing
2. **Control**: Admins have full control over user creation
3. **Flexibility**: Can be configured per environment
4. **Backward Compatible**: Defaults maintain strict control

## Future Enhancements

1. **Admin UI**: Add toggle in admin settings to change these flags
2. **Per-User Permissions**: Allow specific users to auto-create
3. **Whitelist**: Allow auto-creation for specific email domains
4. **Audit Log**: Track when users are auto-created vs manually created




