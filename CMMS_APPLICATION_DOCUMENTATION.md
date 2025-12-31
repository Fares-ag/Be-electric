# Q-AUTO CMMS Mobile Application Documentation

## 📋 Table of Contents

1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Features](#features)
4. [Installation & Setup](#installation--setup)
5. [User Guide](#user-guide)
6. [API Documentation](#api-documentation)
7. [Development Guide](#development-guide)
8. [Deployment Guide](#deployment-guide)
9. [Troubleshooting](#troubleshooting)
10. [Support](#support)

---

## 🎯 Overview

The Q-AUTO CMMS (Computerized Maintenance Management System) is a cross-platform mobile application built with Flutter that enables maintenance technicians to manage work orders, preventive maintenance tasks, and asset information. The application integrates with the Q-AUTO asset tagging and tracking system via RESTful API.

### Key Benefits

- **Offline Capability**: Works without internet connection
- **Real-time Asset Data**: Integrates with Q-AUTO system
- **Mobile-First Design**: Optimized for field technicians
- **Comprehensive Categories**: 12 repair categories for better organization
- **Digital Signatures**: Capture technician and requestor signatures
- **Photo Attachments**: Document issues with images

---

## 🏗️ System Architecture

### High-Level Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Q-AUTO API    │    │   CMMS App       │    │  Local Storage  │
│ (Firebase)      │    │                  │    │ (SQLite/Web)    │
│                 │    │                  │    │                 │
│ • Assets        │◄──►│ • AssetApiService│◄──►│ • Work Orders   │
│ • Staff         │    │ • SyncService    │    │ • PM Tasks      │
│ • Maintenance   │    │ • DatabaseService│    │ • Users         │
│ • Statistics    │    │                  │    │ • App Settings  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### Technology Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase Cloud Functions (Node.js)
- **Database**: SQLite (Mobile) / SharedPreferences (Web)
- **State Management**: Provider Pattern
- **API Integration**: HTTP/REST
- **Authentication**: Local user management
- **Deployment**: Firebase Hosting + Functions

---

## ✨ Features

### 🔐 User Management

- **Role-based Access**: Technician and Manager roles
- **Local Authentication**: Email/password login
- **User Profiles**: Name, department, contact information
- **Session Management**: Persistent login sessions

### 📱 Work Order Management

- **Create Work Requests**: QR code scanning or manual asset search
- **Repair Categories**: 12 comprehensive categories
- **Priority Levels**: Low, Medium, High, Critical
- **Status Tracking**: Open → Assigned → In Progress → Completed → Closed
- **Photo Attachments**: Document issues with camera or gallery
- **Digital Signatures**: Capture requestor and technician signatures

### 🔧 Preventive Maintenance

- **PM Task Scheduling**: Recurring maintenance tasks
- **Interactive Checklists**: Step-by-step task completion
- **Frequency Management**: Daily, Weekly, Monthly, Quarterly, Annually
- **Due Date Tracking**: Overdue task identification
- **Completion Notes**: Detailed work documentation

### 📊 Asset Integration

- **QR Code Scanning**: Quick asset identification
- **Asset Search**: Manual asset lookup
- **Real-time Data**: Live asset information from Q-AUTO API
- **Asset Details**: Comprehensive asset information display
- **Location Tracking**: Asset location and specifications

### 🔄 Data Synchronization

- **Offline Mode**: Full functionality without internet
- **Auto-sync**: Automatic data synchronization when online
- **Conflict Resolution**: Handles sync conflicts gracefully
- **Status Tracking**: Monitor sync status and pending items

### 📈 Reporting & Analytics

- **Dashboard**: Overview of tasks and statistics
- **Filtering**: Filter by status, priority, category, technician
- **Sorting**: Sort by date, priority, due date
- **Statistics**: Work order counts, completion rates, overdue items

---

## 🚀 Installation & Setup

### Prerequisites

- Flutter SDK (3.0+)
- Android Studio or VS Code
- Firebase CLI
- Node.js (for API development)

### Installation Steps

1. **Clone Repository**

   ```bash
   git clone <repository-url>
   cd qauto-cmms
   ```

2. **Install Dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   ```bash
   firebase login
   firebase use --add
   ```

4. **Deploy API**

   ```bash
   cd functions
   npm install
   cd ..
   firebase deploy --only functions
   ```

5. **Build Application**

   ```bash
   # Debug build
   flutter build apk --debug

   # Release build
   flutter build apk --release
   ```

### Configuration

#### API Configuration

1. Open the app
2. Go to Settings → API Configuration
3. Enter Firebase Functions URL:
   ```
   https://us-central1-qauto-cmms-api.cloudfunctions.net
   ```
4. Test connection

#### User Setup

1. Create user accounts in the app
2. Assign roles (Technician/Manager)
3. Configure departments and contact information

---

## 👥 User Guide

### Getting Started

#### Login

1. Open the CMMS app
2. Enter email and password
3. Select role (Technician/Manager)
4. Tap "Login"

#### Dashboard

- **Overview**: See assigned tasks and statistics
- **Quick Actions**: Create work request, view tasks
- **Navigation**: Access all app features

### Creating Work Orders

#### Method 1: QR Code Scanning

1. Tap the "+" button on dashboard
2. Tap "Scan QR Code"
3. Point camera at asset QR code
4. Asset information auto-populates
5. Fill in problem description
6. Select repair category
7. Attach photo (optional)
8. Set priority level
9. Submit request

#### Method 2: Manual Asset Search

1. Tap the "+" button on dashboard
2. Tap "Search Asset"
3. Enter asset name or ID
4. Select from search results
5. Complete form as above

### Managing Work Orders

#### For Technicians

1. **View Assigned Tasks**: Go to Work Orders → Assigned
2. **Start Work**: Tap work order → "Start Work"
3. **Complete Work**: Fill out completion form
4. **Add Signatures**: Capture digital signatures
5. **Close Ticket**: Mark as completed

#### For Managers

1. **View All Work Orders**: Go to Work Orders → All
2. **Assign Tasks**: Select work order → Assign to technician
3. **Monitor Progress**: Track completion status
4. **Filter & Sort**: Use filters to organize work

### Preventive Maintenance

#### Viewing PM Tasks

1. Go to PM Tasks from dashboard
2. View tasks by due date
3. Filter by status or technician
4. Identify overdue tasks

#### Completing PM Tasks

1. Select PM task from list
2. Review task details and checklist
3. Perform maintenance work
4. Check off checklist items
5. Add completion notes
6. Capture technician signature
7. Mark as completed

### Asset Management

#### QR Code Scanning

1. Use QR scanner from any screen
2. Point camera at asset QR code
3. View comprehensive asset details
4. Create work orders for the asset
5. View maintenance history

#### Asset Search

1. Use search function
2. Enter asset name, ID, or location
3. Browse search results
4. Select asset for details

---

## 🔌 API Documentation

### Q-AUTO API Endpoints

#### Base URL

```
https://us-central1-qauto-cmms-api.cloudfunctions.net
```

#### Authentication

- **Method**: Bearer Token or API Key
- **Header**: `Authorization: Bearer <token>` or `X-API-Key: <key>`

#### Endpoints

##### Health Check

```
GET /health
```

**Response**: `{"status": "healthy", "timestamp": "2024-01-01T00:00:00Z"}`

##### Get Assets

```
GET /getAssets
```

**Response**: Array of asset objects

##### Get Asset by ID

```
GET /getAsset/{assetId}
```

**Response**: Single asset object

##### Search Assets

```
GET /searchAssets?q={query}
```

**Response**: Filtered array of assets

##### Get Staff

```
GET /getStaff
```

**Response**: Array of staff members

##### Get Maintenance Reminders

```
GET /getMaintenanceReminders
```

**Response**: Array of maintenance reminders

##### Get Statistics

```
GET /getAssetStatistics
GET /getMaintenanceStatistics
GET /getDepartmentStatistics
```

**Response**: Statistics objects

### Data Models

#### Asset

```json
{
  "id": "string",
  "name": "string",
  "location": "string",
  "category": "string",
  "status": "string",
  "specifications": "object",
  "lastMaintenance": "datetime",
  "nextMaintenance": "datetime"
}
```

#### Work Order

```json
{
  "id": "string",
  "ticketNumber": "string",
  "assetId": "string",
  "problemDescription": "string",
  "category": "string",
  "priority": "string",
  "status": "string",
  "requestorId": "string",
  "assignedTechnicianId": "string",
  "createdAt": "datetime",
  "completedAt": "datetime"
}
```

#### PM Task

```json
{
  "id": "string",
  "assetId": "string",
  "description": "string",
  "frequency": "string",
  "status": "string",
  "dueDate": "datetime",
  "assignedTechnicianId": "string",
  "checklist": "array"
}
```

---

## 💻 Development Guide

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user.dart
│   ├── asset.dart
│   ├── work_order.dart
│   ├── pm_task.dart
│   └── qauto_models.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   ├── work_order_provider.dart
│   └── pm_task_provider.dart
├── screens/                  # UI screens
│   ├── auth/
│   ├── dashboard/
│   ├── work_orders/
│   ├── pm_tasks/
│   ├── assets/
│   └── settings/
├── services/                 # Business logic
│   ├── database_service.dart
│   ├── asset_api_service.dart
│   ├── qauto_api_client.dart
│   └── sync_service.dart
├── widgets/                  # Reusable widgets
│   ├── qr_scanner_widget.dart
│   ├── asset_search_widget.dart
│   └── signature_widget.dart
└── utils/                    # Utilities
    └── app_theme.dart
```

### Key Components

#### State Management

- **Provider Pattern**: Used for state management
- **ChangeNotifier**: Notifies UI of state changes
- **Consumer**: Listens to provider changes

#### Database Services

- **WebDatabaseService**: SharedPreferences for web
- **MobileDatabaseService**: SQLite for mobile
- **SyncService**: Handles data synchronization

#### API Integration

- **AssetApiService**: Main API service
- **QAutoAPIClient**: Q-AUTO specific client
- **HTTP Client**: Standard HTTP requests

### Adding New Features

#### 1. Create Data Model

```dart
class NewModel {
  final String id;
  final String name;

  NewModel({required this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  factory NewModel.fromMap(Map<String, dynamic> map) {
    return NewModel(id: map['id'], name: map['name']);
  }
}
```

#### 2. Create Provider

```dart
class NewModelProvider with ChangeNotifier {
  List<NewModel> _items = [];

  List<NewModel> get items => _items;

  Future<void> loadItems() async {
    // Load data logic
    notifyListeners();
  }
}
```

#### 3. Create UI Screen

```dart
class NewModelScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<NewModelProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(title: Text('New Model')),
          body: ListView.builder(
            itemCount: provider.items.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(provider.items[index].name),
              );
            },
          ),
        );
      },
    );
  }
}
```

### Testing

#### Unit Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:qauto_cmms/models/work_order.dart';

void main() {
  group('WorkOrder', () {
    test('should create work order from map', () {
      final map = {'id': '1', 'ticketNumber': 'WO-001'};
      final workOrder = WorkOrder.fromMap(map);
      expect(workOrder.id, '1');
      expect(workOrder.ticketNumber, 'WO-001');
    });
  });
}
```

#### Widget Tests

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qauto_cmms/screens/dashboard/dashboard_screen.dart';

void main() {
  testWidgets('Dashboard displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: DashboardScreen()));
    expect(find.text('QAuto CMMS'), findsOneWidget);
  });
}
```

---

## 🚀 Deployment Guide

### Prerequisites

- Firebase project created
- Flutter SDK installed
- Android Studio configured
- Firebase CLI installed

### API Deployment

#### 1. Deploy Firebase Functions

```bash
# Navigate to functions directory
cd functions

# Install dependencies
npm install

# Deploy functions
firebase deploy --only functions
```

#### 2. Test API Deployment

```bash
# Open test page
start test_api_deployment.html

# Or test manually
curl https://us-central1-qauto-cmms-api.cloudfunctions.net/health
```

### Mobile App Deployment

#### 1. Build APK

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# App bundle for Play Store
flutter build appbundle --release
```

#### 2. Install on Device

```bash
# Install debug APK
flutter install

# Or install manually
adb install build/app/outputs/flutter-apk/app-debug.apk
```

#### 3. Configure App

1. Open app on device
2. Go to Settings → API Configuration
3. Enter Firebase Functions URL
4. Test connection
5. Create user accounts

### Production Deployment

#### Google Play Store

1. Build app bundle: `flutter build appbundle --release`
2. Upload to Google Play Console
3. Configure store listing
4. Submit for review

#### Internal Distribution

1. Build APK: `flutter build apk --release`
2. Distribute APK to team
3. Install on test devices
4. Gather feedback

---

## 🔧 Troubleshooting

### Common Issues

#### API Connection Issues

**Problem**: API not responding
**Solutions**:

- Check Firebase project is active
- Verify functions are deployed
- Test with `test_api_deployment.html`
- Check internet connection

#### Build Failures

**Problem**: Flutter build fails
**Solutions**:

- Run `flutter clean`
- Run `flutter pub get`
- Check `flutter doctor` for issues
- Update Flutter SDK

#### App Crashes

**Problem**: App crashes on startup
**Solutions**:

- Check device logs: `flutter logs`
- Test on different devices
- Verify API configuration
- Check for null pointer exceptions

#### Sync Issues

**Problem**: Data not syncing
**Solutions**:

- Check internet connection
- Verify API endpoints
- Check sync status in app
- Restart app

### Debugging

#### Enable Debug Mode

```dart
// In main.dart
void main() {
  runApp(MyApp());
  // Enable debug mode
  debugPrint('Debug mode enabled');
}
```

#### Check Logs

```bash
# Flutter logs
flutter logs

# Firebase logs
firebase functions:log
```

#### Test API Manually

```bash
# Test health endpoint
curl https://us-central1-qauto-cmms-api.cloudfunctions.net/health

# Test with authentication
curl -H "Authorization: Bearer <token>" \
     https://us-central1-qauto-cmms-api.cloudfunctions.net/getAssets
```

---

## 📞 Support

### Getting Help

#### Documentation

- **API Documentation**: See API Documentation section
- **User Guide**: See User Guide section
- **Development Guide**: See Development Guide section

#### Testing

- **API Testing**: Use `test_api_deployment.html`
- **App Testing**: Use debug builds for testing
- **Integration Testing**: Test complete workflows

#### Common Solutions

1. **Check Firebase Console**: Verify project status
2. **Review Logs**: Check Flutter and Firebase logs
3. **Test API**: Use provided test tools
4. **Restart Services**: Restart app and services

### Contact Information

- **Technical Issues**: Check troubleshooting section
- **Feature Requests**: Document in project repository
- **Bug Reports**: Include logs and steps to reproduce

---

## 📊 Performance Metrics

### Key Performance Indicators

- **API Response Time**: < 2 seconds
- **App Startup Time**: < 3 seconds
- **Offline Sync Time**: < 30 seconds
- **Memory Usage**: < 100MB
- **Battery Usage**: Optimized for field use

### Monitoring

- **Firebase Analytics**: Track app usage
- **Crashlytics**: Monitor crashes
- **Performance Monitoring**: Track performance metrics
- **Custom Events**: Track business metrics

---

## 🔄 Version History

### Version 1.0.0 (Current)

- Initial release
- Work order management
- Preventive maintenance
- Asset integration
- Offline capability
- 12 repair categories
- Digital signatures
- Photo attachments

### Future Versions

- **v1.1.0**: Enhanced reporting
- **v1.2.0**: Advanced analytics
- **v2.0.0**: Multi-tenant support

---

## 📝 License

This application is proprietary software developed for Q-AUTO CMMS system. All rights reserved.

---

## 🎯 Conclusion

The Q-AUTO CMMS mobile application provides a comprehensive solution for maintenance management with offline capability, real-time asset integration, and mobile-optimized workflows. The system is designed to scale with your organization's needs while maintaining reliability and performance.

For additional support or questions, refer to the troubleshooting section or contact the development team.

---

_Last Updated: January 2024_
_Version: 1.0.0_





















