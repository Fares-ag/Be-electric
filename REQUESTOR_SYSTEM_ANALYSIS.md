# Requestor System - Complete Workflow Analysis

## Overview
The requestor system is a comprehensive maintenance request management solution that allows users with the "requestor" role to create, manage, track, and analyze their maintenance requests throughout the entire lifecycle.

---

## 1. System Entry & Authentication

### Login Flow
1. **User Authentication** (`lib/screens/auth/login_screen.dart`)
   - User logs in with credentials
   - Firebase Authentication validates credentials
   - User role is retrieved from Firestore

2. **Role-Based Routing** (`lib/widgets/role_based_navigation.dart`)
   ```dart
   switch (user.role.toLowerCase()) {
     case 'requestor':
       return const RequestorMainScreen();
     // ... other roles
   }
   ```
   - System automatically routes requestors to `RequestorMainScreen`
   - No manual navigation needed

---

## 2. Requestor Main Screen (`lib/screens/requestor/requestor_main_screen.dart`)

### Initial Checks
- **Work Email Validation**: 
  - Checks if user has a work email (`user.workEmail`)
  - If missing, shows email validation prompt
  - Blocks request creation until email is provided
  - Purpose: Ensures proper identification and notification delivery

### Main Screen Features

#### A. AppBar Actions (4 buttons)
1. **Notifications** (🔔)
   - Shows unread notification count badge
   - Opens `NotificationListScreen`
   - Real-time updates via `NotificationBadge` widget

2. **View My Requests** (📋)
   - Opens `RequestorStatusScreen`
   - Shows all user's requests (active + history)

3. **Analytics** (📊)
   - Opens `RequestorAnalyticsScreen`
   - Personal performance dashboard

4. **Notification Settings** (⚙️)
   - Opens `RequestorNotificationSettingsScreen`
   - Configure notification preferences

#### B. Main Content
- **Welcome Header**: Instructions and branding
- **Quick Status Overview**: 
  - Shows count of active requests
  - Links to full status screen
  - Real-time via `Consumer<UnifiedDataProvider>`

- **Asset Selection Options** (3 methods):
  1. **QR Code Scanner** → Opens AssetSelectionScreen (tab 0)
  2. **Search Assets** → Opens AssetSelectionScreen (tab 1)
  3. **Enter Asset ID** → Opens AssetSelectionScreen (tab 2)

---

## 3. Asset Selection (`lib/screens/requestor/asset_selection_screen.dart`)

### Tab-Based Interface

#### Tab 0: QR Code Scanning
- Uses `MobileQRScannerWidget`
- Scans QR code from asset
- Extracts asset ID from various QR formats:
  - Direct asset ID (e.g., "2025_00001")
  - JSON format with assetId field
  - URL format with ID parameter
  - Text format with ID embedded
- Automatically finds asset and navigates to request creation

#### Tab 1: Search Assets
- Loads all assets from `AssetDatabaseService`
- Real-time search by:
  - Asset name
  - Location
  - Asset ID
  - Description
- Displays asset cards with:
  - Status indicator (active/inactive)
  - Asset name, ID, location
  - Description preview
- Tap asset → Navigate to request creation

#### Tab 2: Manual Entry
- Text field for direct asset ID input
- Validates and finds asset
- Error handling if asset not found
- Submit → Navigate to request creation

### Navigation Flow
```dart
AssetSelectionScreen → (returns Asset) → CreateMaintenanceRequestScreen
```

---

## 4. Create Maintenance Request (`lib/screens/requestor/create_maintenance_request_screen.dart`)

### Form Fields

#### A. Asset Information (Read-only)
- Asset Name
- Asset ID
- Location
- Department (if available)
- Current Condition (if available)

#### B. Problem Description (Required)
- Multi-line text field
- Validation: Minimum 10 characters
- Describes the maintenance issue

#### C. Priority Selection (Required)
- Dropdown with options:
  - LOW
  - MEDIUM
  - HIGH
  - URGENT
  - CRITICAL
- Default: MEDIUM

#### D. Category Selection (Required)
- Dropdown with options:
  - Mechanical HVAC
  - Electrical
  - Structural
  - Plumbing
  - Interior
  - Exterior
  - IT Low Voltage
  - Specialized Equipment
  - Safety Compliance
  - Emergency
  - Preventive
  - Reactive
- Default: Reactive

#### E. Photo Upload (Optional)
- **Take Photo**: Opens camera
- **From Gallery**: Opens image picker
- Photo preview with remove option
- Uploads to Firebase Storage:
  - Folder: `work_orders/request_photos/`
  - Filename: `request_{timestamp}.jpg`
- Photo URL stored in work order

### Submission Process

1. **Validation**
   - Form validation runs
   - Ensures required fields are filled

2. **Photo Upload** (if photo selected)
   - Uploads to Firebase Storage via `FirebaseStorageService`
   - Gets download URL
   - Handles upload errors gracefully

3. **Work Order Creation**
   ```dart
   await unifiedProvider.createWorkOrder(
     problemDescription: ...,
     requestorId: user.id,
     assetId: asset.id,
     asset: asset,
     priority: _selectedPriority,
     category: _selectedCategory,
     photoPath: photoUrl,
   );
   ```

4. **Backend Processing** (`lib/providers/unified_data_provider.dart`)
   - Generates unique work order ID (UUID)
   - Creates ticket number: `WO-YYYYMMDD-{sequence}`
   - Sets initial status: `WorkOrderStatus.open`
   - Sets timestamps: `createdAt`, `updatedAt`
   - Saves to Firestore via `UnifiedDataService`
   - Adds to real-time cache
   - Triggers `notifyListeners()` for UI updates

5. **Notification** (if configured)
   - `EnhancedNotificationService.notifyWorkOrderCreated()`
   - Creates in-app notification
   - Can trigger push/email/SMS based on preferences

6. **Success & Navigation**
   - Shows success message
   - Navigates back to main screen
   - Real-time sync updates all screens automatically

---

## 5. Request Management (`lib/screens/requestor/requestor_status_screen.dart`)

### Screen Layout

#### AppBar
- Title: "My Requests ({count})"
- Filter button (🔍) → Opens filter dialog

#### Tabs
1. **Active Tab**: Open, Assigned, In Progress requests
2. **History Tab**: Completed, Closed requests

#### Filtering System
- **Search**: By ticket number, description, asset ID/name
- **Status Filter**: Filter by work order status
- **Priority Filter**: Filter by priority level
- **Filter Chips**: Show active filters, can remove individually
- **Clear All**: Resets all filters

### Request Card Display

Each request shows:
- **Ticket Number**: Unique identifier
- **Status Badge**: Color-coded status indicator
- **Problem Description**: Truncated preview
- **Asset Info**: Asset ID
- **Priority**: Icon + text
- **Created Date**: Formatted timestamp
- **Assigned Technician**: If assigned
- **Completed Date**: If completed

### Action Buttons (for Open/Assigned requests)
- **Edit Button**: Opens `EditRequestScreen`
- **Cancel Button**: Opens cancellation dialog

---

## 6. Edit Request (`lib/screens/requestor/edit_request_screen.dart`)

### Edit Capabilities
- **Problem Description**: Can be updated
- **Priority**: Can be changed
- **Category**: Can be changed
- **Photo**: Can add/replace photo

### Restrictions
- Only editable when status is:
  - `WorkOrderStatus.open`
  - `WorkOrderStatus.assigned`
- Cannot edit once work has started (`inProgress`)

### Edit Process
1. Loads current request data
2. Pre-fills form fields
3. User makes changes
4. Photo upload (if new photo selected)
5. Updates work order via `unifiedProvider.updateWorkOrder()`
6. Updates Firestore
7. Real-time sync updates all screens
8. Success message and navigation back

---

## 7. Cancel Request

### Cancellation Flow
1. User clicks "Cancel" button
2. Confirmation dialog appears
3. **Reason Required**: User must provide cancellation reason
4. Updates work order:
   - Status → `WorkOrderStatus.cancelled`
   - Notes → "Cancelled by requestor. Reason: {reason}"
   - `updatedAt` → Current timestamp
5. Saves to Firestore
6. Real-time sync updates UI
7. Success notification

### Notes
- Cancellation is permanent
- Reason is stored for audit trail
- Request disappears from active list, appears in history

---

## 8. Notifications System

### Notification Service (`lib/services/enhanced_notification_service.dart`)

#### Notification Types for Requestors
- `workOrderCreated`: When request is created
- `workOrderAssigned`: When technician is assigned
- `workOrderStarted`: When work begins
- `workOrderCompleted`: When work is finished
- `workOrderOverdue`: If request becomes overdue
- `workOrderUpdated`: When request details change

#### Notification Channels
- **In-App**: Always active
- **Push**: Configurable
- **Email**: Configurable
- **SMS**: Configurable (for critical)

### Notification Preferences (`lib/screens/requestor/requestor_notification_settings_screen.dart`)

#### Settings Saved
- Channel preferences (Push/Email/SMS)
- Event type preferences (what to notify about)
- Frequency (Immediate/Daily/Weekly digest)
- Stored in `SharedPreferences`

#### Integration Points
- Preferences checked before sending notifications
- Can be integrated with notification service
- Real-time preference updates

---

## 9. Analytics Dashboard (`lib/screens/requestor/requestor_analytics_screen.dart`)

### Overview Stats
- Total Requests
- Completed Count
- In Progress Count
- Pending Count

### Status Breakdown
- Visual breakdown of all statuses
- Count for each status
- Color-coded indicators

### Priority Breakdown
- Distribution by priority level
- Icon indicators
- Count display

### Performance Metrics
- **Average Resolution Time**: Mean time from creation to completion
- **Fastest Resolution**: Quickest completed request
- **Slowest Resolution**: Longest completed request
- Calculated from completed requests only

### Recent Trends
- **6-Month Request Chart**:
  - Groups requests by month
  - Shows request volume over time
  - Visual progress bars
  - Month labels (e.g., "Jan 2025")

### Top Assets
- **Most Requested Assets**:
  - Shows top 5 assets by request count
  - Asset name or ID
  - Request count per asset

### Data Source
- Real-time from `UnifiedDataProvider`
- Pull-to-refresh capability
- Automatic updates when data changes

---

## 10. Data Flow & Real-Time Sync

### UnifiedDataProvider Architecture

```
Firestore (Source of Truth)
    ↓
UnifiedDataService (Business Logic)
    ↓
UnifiedDataProvider (State Management)
    ↓
Consumer Widgets (UI Updates)
```

### Real-Time Features
- **Stream Subscriptions**: 
  - Work orders stream from Firestore
  - Automatic updates when data changes
  - No manual refresh needed

- **Cache Management**:
  - In-memory cache for fast access
  - De-duplication logic
  - Reference population (users, assets)

- **State Notifications**:
  - `notifyListeners()` triggers UI rebuilds
  - `Consumer<UnifiedDataProvider>` widgets auto-update
  - Efficient re-rendering

### Data Consistency
- Single source of truth (Firestore)
- Optimistic updates for better UX
- Error handling and rollback
- Offline support (if configured)

---

## 11. Complete Request Lifecycle

### State Transitions

```
1. CREATED (Open)
   ↓
2. ASSIGNED (Assigned to technician)
   ↓
3. IN_PROGRESS (Work started)
   ↓
4. COMPLETED (Work finished)
   ↓
5. CLOSED (Finalized)

OR

1. CREATED (Open)
   ↓
2. CANCELLED (By requestor or admin)
```

### Requestor Actions at Each Stage

#### Open/Assigned
- ✅ View request details
- ✅ Edit request (description, priority, category, photo)
- ✅ Cancel request
- ✅ View notifications

#### In Progress
- ✅ View request details
- ✅ View technician updates
- ✅ View progress
- ❌ Cannot edit
- ❌ Cannot cancel

#### Completed/Closed
- ✅ View request details
- ✅ View completion report
- ✅ View photos
- ✅ View signatures
- ✅ Rate/Provide feedback (if implemented)
- ❌ Cannot edit
- ❌ Cannot cancel

---

## 12. Integration Points

### With Other Systems

#### A. Asset Management
- Asset selection from asset database
- Asset details displayed in requests
- Asset history tracking

#### B. Technician System
- Automatic assignment notifications
- Technician updates visible to requestors
- Communication via notifications

#### C. Admin System
- Admins can view all requests
- Admins can assign technicians
- Admins can override requestor actions

#### D. Notification System
- Integrated with `EnhancedNotificationService`
- Supports multiple channels
- Configurable preferences

#### E. Storage System
- Photo uploads to Firebase Storage
- Secure file access
- URL storage in Firestore

---

## 13. Security & Permissions

### Requestor Permissions
- ✅ Create work orders
- ✅ View own work orders only
- ✅ Edit own requests (before assignment)
- ✅ Cancel own requests (before work starts)
- ✅ View own analytics
- ✅ Configure own notification preferences
- ❌ Cannot view other requestors' requests
- ❌ Cannot assign technicians
- ❌ Cannot complete work orders
- ❌ Cannot access admin features

### Data Isolation
- All queries filtered by `requestorId == currentUser.id`
- Firestore security rules enforce this
- UI prevents unauthorized access

---

## 14. Error Handling

### Common Error Scenarios

1. **Asset Not Found**
   - Clear error message
   - Suggestion to try different search
   - Option to retry

2. **Photo Upload Failure**
   - Error notification
   - Request can still be created without photo
   - Option to retry upload

3. **Network Issues**
   - Offline mode support (if configured)
   - Retry mechanisms
   - Clear error messages

4. **Validation Errors**
   - Inline form validation
   - Clear error messages
   - Prevents invalid submissions

5. **Permission Errors**
   - Graceful degradation
   - User-friendly messages
   - Fallback options

---

## 15. Performance Optimizations

### Caching
- Asset list cached after first load
- Work orders cached in memory
- Reduces Firestore reads

### Lazy Loading
- Assets loaded only when needed
- Photos loaded on demand
- Analytics calculated on-demand

### Efficient Updates
- Only affected widgets rebuild
- Consumer pattern for selective updates
- Debounced search inputs

### Image Optimization
- Photo compression before upload
- Max width: 1920px
- Quality: 85%
- Reduces storage and bandwidth

---

## 16. User Experience Features

### Visual Feedback
- Loading indicators during operations
- Success/error snackbars
- Progress indicators
- Empty states with helpful messages

### Navigation
- Intuitive flow
- Back button support
- Deep linking ready
- Breadcrumb navigation

### Accessibility
- Clear labels
- Icon + text buttons
- Color + text status indicators
- Screen reader friendly

### Responsive Design
- Works on different screen sizes
- Adaptive layouts
- Touch-friendly buttons
- Scrollable content

---

## 17. Future Enhancement Opportunities

### Already Implemented ✅
- Request editing
- Request cancellation
- Enhanced notifications
- Personal analytics
- Photo uploads
- QR code scanning
- Advanced filtering

### Potential Additions
- Request templates
- Recurring requests
- Request comments/chat
- Export functionality
- Mobile push notifications
- Email notifications
- SMS notifications
- Request ratings/feedback

---

## 18. Technical Architecture Summary

### Key Components

```
RequestorMainScreen (Entry Point)
├── AssetSelectionScreen (3 methods)
│   ├── QR Scanner Tab
│   ├── Search Tab
│   └── Manual Entry Tab
├── CreateMaintenanceRequestScreen
│   └── Photo Upload
├── RequestorStatusScreen
│   ├── Active Requests Tab
│   ├── History Tab
│   ├── EditRequestScreen
│   └── Cancel Dialog
├── RequestorAnalyticsScreen
│   ├── Overview Stats
│   ├── Status/Priority Breakdowns
│   ├── Performance Metrics
│   ├── Trends Chart
│   └── Top Assets
└── RequestorNotificationSettingsScreen
    ├── Channel Preferences
    ├── Event Preferences
    └── Frequency Settings
```

### Data Providers
- `UnifiedDataProvider`: Main state management
- `AuthProvider`: User authentication
- `EnhancedNotificationService`: Notifications

### Services
- `UnifiedDataService`: Business logic
- `FirebaseFirestoreService`: Database operations
- `FirebaseStorageService`: File storage
- `AssetDatabaseService`: Asset management
- `EnhancedNotificationService`: Notification handling

---

## Conclusion

The requestor system provides a **complete, end-to-end solution** for maintenance request management:

1. **Easy Request Creation**: Multiple asset selection methods
2. **Full Request Management**: View, edit, cancel requests
3. **Real-Time Updates**: Automatic synchronization
4. **Rich Analytics**: Personal performance insights
5. **Flexible Notifications**: Configurable preferences
6. **Professional UX**: Intuitive, responsive interface
7. **Secure & Isolated**: Proper permission enforcement
8. **Scalable Architecture**: Ready for future enhancements

The system is **production-ready** and provides a comprehensive solution for requestors to manage their maintenance needs efficiently.


