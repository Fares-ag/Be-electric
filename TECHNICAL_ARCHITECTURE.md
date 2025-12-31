# Q-AUTO CMMS Technical Architecture

## 🏗️ System Overview

The Q-AUTO CMMS is a hybrid mobile application that combines local data storage with external API integration to provide a robust, offline-capable maintenance management system.

## 📊 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Q-AUTO CMMS SYSTEM                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌──────────────────┐    ┌─────────────┐ │
│  │   Q-AUTO API    │    │   CMMS App       │    │Local Storage│ │
│  │ (Firebase)      │    │                  │    │             │ │
│  │                 │    │                  │    │             │ │
│  │ • Assets        │◄──►│ • AssetApiService│◄──►│ • Work Orders│ │
│  │ • Staff         │    │ • QAutoAPIClient │    │ • PM Tasks  │ │
│  │ • Maintenance   │    │ • SyncService    │    │ • Users     │ │
│  │ • Statistics    │    │ • DatabaseService│    │ • Settings  │ │
│  └─────────────────┘    └──────────────────┘    └─────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 🔧 Technology Stack

### Frontend (Mobile App)

- **Framework**: Flutter 3.0+
- **Language**: Dart
- **State Management**: Provider Pattern
- **UI Framework**: Material Design
- **Local Database**: SQLite (Mobile) / SharedPreferences (Web)
- **HTTP Client**: Dart HTTP Package
- **QR Scanner**: qr_code_scanner
- **Image Picker**: image_picker
- **Signatures**: signature package

### Backend (API)

- **Platform**: Firebase Cloud Functions
- **Runtime**: Node.js 18
- **Framework**: Firebase Functions
- **Database**: Firebase Firestore (for API data)
- **Authentication**: Firebase Auth (optional)
- **CORS**: cors package

### Infrastructure

- **Hosting**: Firebase Hosting
- **Functions**: Firebase Cloud Functions
- **Storage**: Firebase Storage (for file uploads)
- **Analytics**: Firebase Analytics
- **Crash Reporting**: Firebase Crashlytics

## 📱 Mobile App Architecture

### Layer Structure

```
┌─────────────────────────────────────┐
│           Presentation Layer        │
│  (Screens, Widgets, UI Components)  │
├─────────────────────────────────────┤
│           Business Logic Layer      │
│     (Providers, State Management)   │
├─────────────────────────────────────┤
│            Data Access Layer        │
│    (Services, API Clients, DB)      │
├─────────────────────────────────────┤
│            Data Storage Layer       │
│    (SQLite, SharedPreferences)      │
└─────────────────────────────────────┘
```

### Key Components

#### 1. Presentation Layer

- **Screens**: UI screens for different features
- **Widgets**: Reusable UI components
- **Theme**: Consistent design system
- **Navigation**: App routing and navigation

#### 2. Business Logic Layer

- **Providers**: State management using Provider pattern
- **Models**: Data models and business entities
- **Services**: Business logic and data processing
- **Utils**: Utility functions and helpers

#### 3. Data Access Layer

- **API Services**: External API communication
- **Database Services**: Local data persistence
- **Sync Services**: Data synchronization logic
- **Cache Services**: Data caching and offline support

#### 4. Data Storage Layer

- **SQLite**: Primary local database (mobile)
- **SharedPreferences**: Simple key-value storage (web)
- **File System**: Image and document storage
- **Memory Cache**: In-memory data caching

## 🔄 Data Flow Architecture

### 1. Asset Data Flow

```
User Action → QR Scan → API Call → Q-AUTO API → Asset Data → Local Cache → UI Display
```

### 2. Work Order Flow

```
User Input → Local Validation → Local Storage → Sync Queue → API Sync → Q-AUTO API
```

### 3. Offline Flow

```
Offline Mode → Local Storage → Sync Flag → Online Detection → Auto Sync → API Update
```

## 🗄️ Database Schema

### Local Database (SQLite)

#### Users Table

```sql
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    role TEXT NOT NULL,
    department TEXT,
    phone TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT
);
```

#### Work Orders Table

```sql
CREATE TABLE work_orders (
    id TEXT PRIMARY KEY,
    ticket_number TEXT UNIQUE NOT NULL,
    asset_id TEXT NOT NULL,
    problem_description TEXT NOT NULL,
    photo_path TEXT,
    requestor_id TEXT NOT NULL,
    assigned_technician_id TEXT,
    status TEXT NOT NULL,
    priority TEXT NOT NULL,
    category TEXT,
    created_at TEXT NOT NULL,
    assigned_at TEXT,
    started_at TEXT,
    completed_at TEXT,
    closed_at TEXT,
    corrective_actions TEXT,
    recommendations TEXT,
    next_maintenance_date TEXT,
    requestor_signature TEXT,
    technician_signature TEXT,
    notes TEXT,
    is_offline INTEGER DEFAULT 0,
    last_synced_at TEXT,
    FOREIGN KEY (requestor_id) REFERENCES users (id),
    FOREIGN KEY (assigned_technician_id) REFERENCES users (id)
);
```

#### PM Tasks Table

```sql
CREATE TABLE pm_tasks (
    id TEXT PRIMARY KEY,
    asset_id TEXT NOT NULL,
    description TEXT NOT NULL,
    frequency TEXT NOT NULL,
    status TEXT NOT NULL,
    due_date TEXT NOT NULL,
    assigned_technician_id TEXT,
    checklist TEXT,
    completion_notes TEXT,
    technician_signature TEXT,
    completed_at TEXT,
    is_offline INTEGER DEFAULT 0,
    last_synced_at TEXT,
    FOREIGN KEY (assigned_technician_id) REFERENCES users (id)
);
```

#### Assets Cache Table

```sql
CREATE TABLE assets_cache (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    location TEXT,
    category TEXT,
    status TEXT,
    specifications TEXT,
    last_maintenance TEXT,
    next_maintenance TEXT,
    cached_at TEXT NOT NULL
);
```

## 🔌 API Architecture

### Q-AUTO API Endpoints

#### Base Configuration

- **Base URL**: `https://us-central1-qauto-cmms-api.cloudfunctions.net`
- **Authentication**: Bearer Token or API Key
- **Content Type**: `application/json`
- **CORS**: Enabled for web access

#### Endpoint Structure

```
GET  /health                    # Health check
GET  /getAssets                 # Get all assets
GET  /getAsset/{id}             # Get specific asset
GET  /getVehicleAssets          # Get vehicle assets
GET  /searchAssets?q={query}    # Search assets
GET  /getMaintenanceReminders   # Get maintenance reminders
GET  /getStaff                  # Get staff members
GET  /getAssetStatistics        # Get asset statistics
GET  /getMaintenanceStatistics  # Get maintenance statistics
GET  /getDepartmentStatistics   # Get department statistics
```

#### Response Format

```json
{
  "success": true,
  "data": [...],
  "message": "Success",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

#### Error Format

```json
{
  "success": false,
  "error": "Error message",
  "code": "ERROR_CODE",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

## 🔄 Synchronization Architecture

### Sync Strategy

- **Bidirectional Sync**: Local ↔ API
- **Conflict Resolution**: Last-write-wins with timestamps
- **Offline Support**: Queue operations for later sync
- **Incremental Sync**: Only sync changed data

### Sync States

- **Online**: Real-time sync with API
- **Offline**: Local operations only
- **Syncing**: Background sync in progress
- **Error**: Sync failed, retry needed

### Sync Process

```
1. Detect Network Status
2. Check Sync Queue
3. Process Pending Operations
4. Update Local Data
5. Mark as Synced
6. Handle Errors
```

## 🎨 UI/UX Architecture

### Design System

- **Color Scheme**: Black, White, Grey only
- **Typography**: Roboto font family
- **Spacing**: 8px grid system
- **Components**: Material Design 3
- **Icons**: Material Icons

### Screen Architecture

```
App
├── AuthWrapper
│   ├── LoginScreen
│   └── MainApp
│       ├── DashboardScreen
│       ├── WorkOrderFlow
│       │   ├── WorkOrderListScreen
│       │   ├── CreateWorkRequestScreen
│       │   ├── WorkOrderDetailScreen
│       │   └── WorkOrderCompletionScreen
│       ├── PMTaskFlow
│       │   ├── PMTaskListScreen
│       │   ├── PMTaskDetailScreen
│       │   └── PMTaskCompletionScreen
│       ├── AssetFlow
│       │   ├── QRScannerWidget
│       │   ├── AssetSearchWidget
│       │   └── AssetDetailScreen
│       └── SettingsFlow
│           ├── ApiConfigScreen
│           └── SyncStatusScreen
```

### Navigation Architecture

- **Bottom Navigation**: Main app sections
- **App Bar**: Screen-specific actions
- **Drawer**: User profile and settings
- **Modal**: Overlay screens and dialogs

## 🔒 Security Architecture

### Authentication

- **Local Auth**: Email/password validation
- **Session Management**: Persistent login sessions
- **Role-based Access**: Technician vs Manager permissions
- **API Security**: Token-based authentication

### Data Security

- **Local Encryption**: SQLite database encryption
- **API Security**: HTTPS/TLS encryption
- **Data Validation**: Input sanitization and validation
- **Error Handling**: Secure error messages

### Privacy

- **Data Minimization**: Only collect necessary data
- **Local Storage**: Sensitive data stored locally
- **API Limits**: Rate limiting and request validation
- **Audit Trail**: Log important operations

## 📊 Performance Architecture

### Optimization Strategies

- **Lazy Loading**: Load data on demand
- **Caching**: Cache frequently accessed data
- **Image Optimization**: Compress and resize images
- **Database Indexing**: Optimize database queries
- **Memory Management**: Efficient memory usage

### Monitoring

- **Performance Metrics**: Track app performance
- **Error Tracking**: Monitor crashes and errors
- **Usage Analytics**: Track user behavior
- **API Monitoring**: Monitor API performance

## 🚀 Deployment Architecture

### Development Environment

- **Local Development**: Flutter development server
- **API Testing**: Firebase emulators
- **Database**: Local SQLite database
- **Version Control**: Git repository

### Staging Environment

- **App**: Debug builds for testing
- **API**: Staging Firebase project
- **Database**: Test data and configurations
- **Monitoring**: Development analytics

### Production Environment

- **App**: Release builds for distribution
- **API**: Production Firebase project
- **Database**: Production data and configurations
- **Monitoring**: Production analytics and crash reporting

## 🔧 Configuration Management

### Environment Configuration

```dart
class Config {
  static const String apiBaseUrl = 'https://us-central1-qauto-cmms-api.cloudfunctions.net';
  static const String appVersion = '1.0.0';
  static const bool debugMode = false;
  static const int syncInterval = 30000; // 30 seconds
}
```

### Feature Flags

```dart
class FeatureFlags {
  static const bool enableOfflineMode = true;
  static const bool enablePushNotifications = false;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
}
```

## 📈 Scalability Considerations

### Horizontal Scaling

- **API**: Firebase Functions auto-scale
- **Database**: Firebase Firestore scales automatically
- **Storage**: Firebase Storage scales with usage
- **CDN**: Firebase Hosting with global CDN

### Vertical Scaling

- **Local Database**: SQLite can handle large datasets
- **Memory Usage**: Efficient memory management
- **CPU Usage**: Optimized algorithms and data structures
- **Storage**: Efficient file storage and compression

## 🔄 Maintenance Architecture

### Code Maintenance

- **Modular Design**: Easy to maintain and extend
- **Documentation**: Comprehensive code documentation
- **Testing**: Unit and integration tests
- **Version Control**: Git-based version management

### System Maintenance

- **Monitoring**: Continuous system monitoring
- **Backup**: Regular data backups
- **Updates**: Automated dependency updates
- **Security**: Regular security audits

## 📋 Conclusion

The Q-AUTO CMMS technical architecture provides a robust, scalable, and maintainable foundation for the maintenance management system. The hybrid approach ensures offline capability while maintaining real-time integration with external systems.

Key architectural strengths:

- **Offline-First Design**: Works without internet connection
- **Modular Architecture**: Easy to maintain and extend
- **Scalable Infrastructure**: Firebase-based scalable backend
- **Security-First**: Comprehensive security measures
- **Performance Optimized**: Efficient data handling and caching

This architecture supports the current requirements while providing a foundation for future enhancements and scaling.





















