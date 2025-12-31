import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/admin/admin_main_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/requestor/requestor_main_screen.dart';
import '../screens/technician/technician_main_screen.dart';

class RoleBasedNavigation extends StatelessWidget {
  const RoleBasedNavigation({super.key});

  @override
  Widget build(BuildContext context) => Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;

          if (user == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Route based on user role
          switch (user.role.toLowerCase()) {
            case 'requestor':
              return const RequestorMainScreen();
            case 'technician':
              return const TechnicianMainScreen();
            case 'manager':
            case 'admin':
              return const AdminMainScreen();
            default:
              // Fallback to dashboard for unknown roles
              return const DashboardScreen();
          }
        },
      );
}
