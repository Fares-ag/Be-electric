# QAuto CMMS Mobile App - Complete Documentation

## 📱 **App Overview**

The QAuto CMMS Mobile App is a comprehensive maintenance management system designed for mobile devices. It integrates with the Q-AUTO Asset Management System to provide real-time asset data and maintenance tracking.

## 🏗️ **Architecture**

### **Technology Stack**

- **Framework**: Flutter 3.0+
- **Language**: Dart
- **Database**: SQLite (local) + Q-AUTO API (remote)
- **State Management**: Provider
- **Authentication**: Firebase Auth
- **Push Notifications**: Firebase Messaging
- **Analytics**: Custom Analytics Service

### **App Structure**

```
lib/
├── config/                 # Configuration files
├── models/                 # Data models
├── providers/              # State management
├── screens/                # UI screens
├── services/               # Business logic
├── utils/                  # Utilities and themes
├── widgets/                # Reusable widgets
└── main_mobile.dart        # Mobile app entry point
```

## 🔧 **Core Features**

### **1. User Authentication**

- Email/password login
- Role-based access (Technician, Manager)
- Session management
- Auto-logout for security

### **2. Work Order Management**

- Create work requests
- Assign and track work orders
- Update work progress
- Complete with signatures
- Photo documentation

### **3. Preventive Maintenance**

- PM task scheduling
- Checklist management
- Completion tracking
- Maintenance history

### **4. Asset Management**

- QR code scanning
- Asset search
- Real-time asset data from Q-AUTO
- Asset maintenance history

### **5. Offline Capability**

- Local SQLite database
- Offline work order creation
- Automatic sync when online
- Data integrity protection

## 📊 **Database Schema**

### **Users Table**

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL,
  password TEXT NOT NULL,
  department TEXT,
  phone TEXT,
  isActive INTEGER NOT NULL DEFAULT 1,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  lastLoginAt TEXT
);
```

### **Assets Table**

```sql
CREATE TABLE assets (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  location TEXT NOT NULL,
  description TEXT,
  category TEXT,
  manufacturer TEXT,
  model TEXT,
  serialNumber TEXT,
  installationDate TEXT,
  lastMaintenanceDate TEXT,
  nextMaintenanceDate TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  qrCode TEXT,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
);
```

### **Work Orders Table**

```sql
CREATE TABLE work_orders (
  id TEXT PRIMARY KEY,
  ticketNumber TEXT UNIQUE NOT NULL,
  assetId TEXT NOT NULL,
  problemDescription TEXT NOT NULL,
  requestorId TEXT NOT NULL,
  assignedTechnicianId TEXT,
  priority TEXT NOT NULL DEFAULT 'medium',
  status TEXT NOT NULL DEFAULT 'open',
  scheduledDate TEXT,
  startedAt TEXT,
  completedAt TEXT,
  correctiveActions TEXT,
  recommendations TEXT,
  nextMaintenanceDate TEXT,
  requestorSignature TEXT,
  technicianSignature TEXT,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  FOREIGN KEY (assetId) REFERENCES assets (id),
  FOREIGN KEY (requestorId) REFERENCES users (id),
  FOREIGN KEY (assignedTechnicianId) REFERENCES users (id)
);
```

### **PM Tasks Table**

```sql
CREATE TABLE pm_tasks (
  id TEXT PRIMARY KEY,
  assetId TEXT NOT NULL,
  taskName TEXT NOT NULL,
  description TEXT,
  frequency TEXT NOT NULL,
  lastCompleted TEXT,
  nextDue TEXT,
  assignedTechnicianId TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  checklist TEXT,
  completedAt TEXT,
  technicianSignature TEXT,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  FOREIGN KEY (assetId) REFERENCES assets (id),
  FOREIGN KEY (assignedTechnicianId) REFERENCES users (id)
);
```

## 🔌 **API Integration**

### **Q-AUTO API Endpoints**

- `GET /getAssets` - Get all assets
- `GET /getVehicleAssets` - Get vehicle assets
- `GET /getAssetMaintenance/{id}` - Get maintenance records
- `POST /addMaintenance` - Add maintenance record
- `PUT /updateAssetCondition/{id}` - Update asset condition
- `GET /getMaintenanceReminders` - Get maintenance reminders

### **Authentication**

- Bearer token authentication
- Automatic token refresh
- Fallback to local data

### **Data Synchronization**

- Manual sync trigger
- Automatic sync on app start
- Conflict resolution
- Offline queue management

## 📱 **Mobile-Specific Features**

### **Camera Integration**

- QR code scanning
- Photo capture for work documentation
- Image compression and optimization
- Gallery integration

### **Push Notifications**

- New work order assignments
- Overdue task alerts
- PM reminders
- System notifications

### **Offline Mode**

- Local data storage
- Offline work order creation
- Sync queue management
- Data integrity checks

### **Device Permissions**

- Camera access
- Storage access
- Location access (optional)
- Notification permissions

## 🎨 **UI/UX Design**

### **Design System**

- **Colors**: Black, white, and grey only
- **Typography**: Clear, readable fonts
- **Spacing**: Consistent 8px grid
- **Components**: Material Design 3
- **Accessibility**: WCAG 2.1 compliant

### **Navigation**

- Bottom navigation bar
- Tab-based navigation
- Breadcrumb navigation
- Deep linking support

### **Responsive Design**

- Adaptive layouts
- Screen size optimization
- Orientation support
- Accessibility features

## 🔒 **Security**

### **Data Protection**

- Local data encryption
- Secure API communication
- User session management
- Biometric authentication (optional)

### **Access Control**

- Role-based permissions
- Feature-level access control
- Data isolation
- Audit logging

### **Privacy**

- GDPR compliance
- Data minimization
- User consent management
- Data retention policies

## 📈 **Analytics and Monitoring**

### **User Analytics**

- Screen view tracking
- User interaction tracking
- Feature usage analytics
- Performance metrics

### **Business Analytics**

- Work order completion rates
- PM task adherence
- Asset utilization
- User productivity metrics

### **Error Tracking**

- Crash reporting
- Error logging
- Performance monitoring
- User feedback collection

## 🚀 **Deployment**

### **Build Configuration**

```yaml
# pubspec.yaml
version: 1.0.0+1
environment:
  sdk: ">=3.0.0 <4.0.0"
```

### **Android Build**

```bash
flutter build apk --release
flutter build appbundle --release
```

### **iOS Build**

```bash
flutter build ios --release
flutter build ipa --release
```

### **Distribution**

- **Android**: Google Play Store, Enterprise distribution
- **iOS**: App Store, TestFlight, Enterprise distribution
- **Internal**: APK/IPA distribution

## 🔧 **Configuration**

### **Production Configuration**

```dart
class ProductionConfig {
  static const String qautoBaseUrl = 'https://us-central1-your-project.cloudfunctions.net';
  static const String? qautoApiKey = 'your-api-key';
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = true;
  // ... other settings
}
```

### **Environment Variables**

- API endpoints
- Authentication keys
- Feature flags
- Debug settings

## 📊 **Performance Optimization**

### **App Performance**

- Lazy loading
- Image optimization
- Memory management
- Battery optimization

### **Network Optimization**

- Request batching
- Caching strategies
- Compression
- Retry mechanisms

### **Database Optimization**

- Indexing
- Query optimization
- Data pagination
- Cleanup routines

## 🧪 **Testing**

### **Unit Tests**

- Business logic testing
- Model validation
- Service testing
- Utility function testing

### **Integration Tests**

- API integration testing
- Database testing
- User flow testing
- Cross-platform testing

### **UI Tests**

- Widget testing
- Screen testing
- User interaction testing
- Accessibility testing

## 📚 **Development Guide**

### **Setting Up Development Environment**

1. Install Flutter SDK
2. Install Android Studio / Xcode
3. Configure Firebase project
4. Set up Q-AUTO API
5. Clone repository
6. Run `flutter pub get`
7. Configure environment variables

### **Code Standards**

- Dart style guide compliance
- Consistent naming conventions
- Comprehensive documentation
- Error handling best practices

### **Git Workflow**

- Feature branch development
- Code review process
- Automated testing
- Continuous integration

## 🆘 **Troubleshooting**

### **Common Issues**

#### **Build Issues**

- Flutter version compatibility
- Dependency conflicts
- Platform-specific issues
- Configuration errors

#### **Runtime Issues**

- Memory leaks
- Performance problems
- Network connectivity
- Database corruption

#### **Integration Issues**

- API authentication
- Data synchronization
- Push notification delivery
- Camera functionality

### **Debug Tools**

- Flutter Inspector
- Network monitoring
- Database browser
- Log analysis tools

## 📞 **Support and Maintenance**

### **Support Channels**

- Email support
- Phone support
- In-app feedback
- Documentation portal

### **Maintenance Schedule**

- Regular updates
- Security patches
- Feature enhancements
- Performance optimizations

### **Monitoring**

- App performance monitoring
- Error tracking
- User analytics
- System health checks

## 🔮 **Future Enhancements**

### **Planned Features**

- Advanced reporting
- Machine learning insights
- IoT integration
- Augmented reality

### **Platform Expansion**

- Web application
- Desktop application
- Wearable device support
- Smart display integration

### **Integration Opportunities**

- ERP systems
- IoT sensors
- Third-party APIs
- Cloud services

---

## 📋 **Quick Reference**

### **Key Commands**

```bash
# Development
flutter run
flutter test
flutter analyze

# Building
flutter build apk
flutter build ios
flutter build web

# Dependencies
flutter pub get
flutter pub upgrade
flutter pub outdated
```

### **Important Files**

- `lib/main_mobile.dart` - App entry point
- `lib/config/production_config.dart` - Configuration
- `lib/services/mobile_database_service.dart` - Database
- `lib/services/qauto_api_client.dart` - API client
- `pubspec.yaml` - Dependencies

### **Contact Information**

- **Development Team**: `dev@qauto.com`
- **Support**: `support@qauto.com`
- **Documentation**: `https://docs.qauto.com`

---

This documentation provides a comprehensive overview of the QAuto CMMS Mobile App. For specific implementation details, refer to the source code and inline documentation.






















