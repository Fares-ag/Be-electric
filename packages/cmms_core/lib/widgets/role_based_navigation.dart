import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/cmms_app_mode.dart';
import '../providers/auth_provider.dart';
import '../screens/admin/admin_main_screen.dart';
import '../screens/auth/wrong_app_role_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/requestor/requestor_main_screen.dart';
import '../screens/technician/technician_main_screen.dart';

class RoleBasedNavigation extends StatelessWidget {
  const RoleBasedNavigation({super.key, required this.appMode});

  final CmmsAppMode appMode;

  @override
  Widget build(BuildContext context) => Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;

          if (user == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final role = user.role.toLowerCase();

          switch (appMode) {
            case CmmsAppMode.requestor:
              if (role == 'requestor') {
                return const RequestorMainScreen();
              }
              return WrongAppRoleScreen(
                message:
                    'This account (${user.role}) is not for the requestor app. '
                    'Install the technician app, or use a requestor account.',
              );
            case CmmsAppMode.technician:
              switch (role) {
                case 'technician':
                  return const TechnicianMainScreen();
                case 'manager':
                case 'admin':
                  return const AdminMainScreen();
                case 'requestor':
                  return const WrongAppRoleScreen(
                    message:
                        'This is a requestor account. Open the requestor app to create maintenance requests.',
                  );
                default:
                  return const DashboardScreen();
              }
          }
        },
      );
}
