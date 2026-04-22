# Flutter App Modifications — Technician & Requestor Only

This document describes changes needed in the **existing Flutter app** so it only serves **Technician** and **Requestor** roles. Admin and Manager will use the web (React) app.

## 1. Role-Based Navigation

**File:** `lib/widgets/role_based_navigation.dart`

**Current:** Routes Admin/Manager to `AdminMainScreen`.

**Change:** Redirect Admin/Manager to web app or show a message:

```dart
switch (user.role.toLowerCase()) {
  case 'requestor':
    return const RequestorMainScreen();
  case 'technician':
    return const TechnicianMainScreen();
  case 'manager':
  case 'admin':
    return const WebAppRedirectScreen(); // New screen
  default:
    return const RequestorMainScreen();
}
```

## 2. Create WebAppRedirectScreen

**File:** `lib/screens/auth/web_app_redirect_screen.dart` (new)

```dart
class WebAppRedirectScreen extends StatelessWidget {
  const WebAppRedirectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Access')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.admin_panel_settings, size: 64, color: AppTheme.accentGreen),
              const SizedBox(height: AppTheme.spacingL),
              Text(
                'Admin & Manager access is available on the web app.',
                style: AppTheme.bodyText,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'Please use the web dashboard at:',
                style: AppTheme.secondaryText,
              ),
              const SizedBox(height: AppTheme.spacingS),
              SelectableText(
                'https://qauto-cmms.com', // Replace with your web URL
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.accentBlue,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              OutlinedButton(
                onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## 3. Remove Admin Screens from Navigation (Optional)

If you want to keep the codebase smaller for the mobile app:

- **Do not** remove admin screens from the repo — they may be useful for debugging or future use.
- **Do** ensure Admin/Manager users never reach `AdminMainScreen` from the mobile app (handled by step 1).

## 4. Screens to Keep (Technician + Requestor)

| Screen | Role | Location |
|--------|------|----------|
| RequestorMainScreen | Requestor | screens/requestor/ |
| CreateMaintenanceRequestScreen | Requestor | screens/requestor/ |
| RequestorStatusScreen | Requestor | screens/requestor/ |
| RequestorAnalyticsScreen | Requestor | screens/requestor/ |
| RequestorNotificationSettingsScreen | Requestor | screens/requestor/ |
| TechnicianMainScreen | Technician | screens/technician/ |
| WorkOrderListScreen (isTechnicianView) | Technician | screens/work_orders/ |
| PMTaskListScreen (isTechnicianView) | Technician | screens/pm_tasks/ |
| PartsRequestScreen | Technician | screens/inventory/ |
| MobileQRScannerWidget | Technician | widgets/ |
| ConsolidatedAnalyticsDashboard (isTechnicianView) | Technician | screens/analytics/ |
| NotificationListScreen | Both | widgets/ |

## 5. Routes to Keep

- `/create_maintenance_request` — with `asset`, `qrCode`, `chargerType`
- `/analytics_dashboard` — ConsolidatedAnalyticsDashboard

## 6. Demo Mode

If `DEMO_MODE` is enabled, ensure demo users still work:

- `requestor@qauto.com` → RequestorMainScreen
- `technician@qauto.com` → TechnicianMainScreen
- `admin@qauto.com` / `manager@qauto.com` → WebAppRedirectScreen

## 7. Build Targets

- **iOS / Android:** Technician + Requestor
- **Web (optional):** Could redirect to React app if desired

## Summary

No major refactoring required. The main change is in `RoleBasedNavigation` to redirect Admin/Manager to a "use web app" screen instead of `AdminMainScreen`. All other screens and services remain unchanged.
