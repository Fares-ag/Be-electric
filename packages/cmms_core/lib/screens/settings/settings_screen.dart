import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
// Pruned imports to keep only Notifications, Language, Theme in settings

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.darkTextColor,
        elevation: AppTheme.elevationS,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Information',
                    style: AppTheme.heading1.copyWith(
                      color: AppTheme.darkTextColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'Name: ${user?.name ?? 'Unknown'}',
                    style: AppTheme.bodyText.copyWith(
                      color: AppTheme.darkTextColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Email: ${user?.email ?? 'Unknown'}',
                    style: AppTheme.bodyText.copyWith(
                      color: AppTheme.darkTextColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Role: ${user?.role.toUpperCase() ?? 'Unknown'}',
                    style: AppTheme.bodyText.copyWith(
                      color: AppTheme.darkTextColor,
                    ),
                  ),
                  if (user?.workEmail != null) ...[
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      'Work Email: ${user!.workEmail}',
                      style: AppTheme.bodyText.copyWith(
                        color: AppTheme.darkTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingL),

            // Sync Status Section - Removed (using Supabase now)

            const SizedBox(height: AppTheme.spacingL),

            // Settings Options (only Notifications, Language, Theme)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Settings',
                    style: AppTheme.heading2.copyWith(
                      color: AppTheme.darkTextColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  ListTile(
                    leading: const Icon(
                      Icons.notifications,
                      color: AppTheme.accentBlue,
                    ),
                    title: const Text('Notifications'),
                    subtitle: const Text('Manage notification preferences'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Implement notifications settings
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.language, color: AppTheme.accentBlue),
                    title: const Text('Language'),
                    subtitle: const Text('Change app language'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Implement language settings
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.dark_mode, color: AppTheme.accentBlue),
                    title: const Text('Theme'),
                    subtitle: const Text('Change app appearance'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Implement theme settings
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingL),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingM,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
