import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/orphan_cleanup_service.dart';
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

            // Data Maintenance Section (Admin Only)
            if (user?.isAdmin ?? false) ...[
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
                      'Data Maintenance',
                      style: AppTheme.heading2.copyWith(
                        color: AppTheme.darkTextColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      'Clean up orphaned work orders and PM tasks that reference non-existent users or assets.',
                      style: AppTheme.bodyText.copyWith(
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showOrphanCleanupDialog(
                              context,
                              delete: false,
                            ),
                            icon: const Icon(Icons.fact_check),
                            label: const Text('Dry Run'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.accentGreen,
                              side: const BorderSide(
                                color: AppTheme.accentGreen,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: AppTheme.spacingM,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showOrphanCleanupDialog(
                              context,
                              delete: true,
                            ),
                            icon: const Icon(Icons.cleaning_services),
                            label: const Text('Delete Orphans'),
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
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
            ],

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

  static Future<void> _showOrphanCleanupDialog(
    BuildContext context, {
    required bool delete,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(delete ? 'Delete Orphaned Records?' : 'Dry Run Orphan Cleanup'),
        content: Text(
          delete
              ? 'This will permanently delete work orders and PM tasks whose requestors, technicians, or assets no longer exist. Continue?'
              : 'Run a scan to see how many orphaned work orders and PM tasks exist without deleting them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: delete ? AppTheme.errorColor : AppTheme.accentBlue,
              foregroundColor: Colors.white,
            ),
            child: Text(delete ? 'Delete' : 'Run'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    debugPrint('🧹 Settings Cleanup: User confirmed (delete=$delete)');

    // Show loading dialog (don't await - we'll close it manually)
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      debugPrint('🧹 Settings Cleanup: Starting OrphanCleanupService.run()...');
      final report = await OrphanCleanupService.instance.run(delete: delete);
      debugPrint('🧹 Settings Cleanup: OrphanCleanupService completed');
      if (!context.mounted) {
        debugPrint('⚠️ Settings Cleanup: Context not mounted, cannot show dialog');
        return;
      }
      
      // Close progress dialog if still open
      debugPrint('🧹 Settings Cleanup: Closing loading dialog...');
      Navigator.of(context, rootNavigator: true).pop();
      
      // Small delay to ensure dialog is closed
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!context.mounted) {
        debugPrint('⚠️ Settings Cleanup: Context not mounted after delay');
        return;
      }
      
      debugPrint(
        '🧹 Settings Cleanup: Showing completion dialog - '
        '${report.orphanedWorkOrders}/${report.totalWorkOrders} WOs, '
        '${report.orphanedPMTasks}/${report.totalPMTasks} PM tasks',
      );
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(delete ? 'Cleanup Complete' : 'Dry Run Complete'),
          content: SingleChildScrollView(
            child: Text(
              'Work Orders: ${report.orphanedWorkOrders}/${report.totalWorkOrders} orphaned\n'
              'PM Tasks: ${report.orphanedPMTasks}/${report.totalPMTasks} orphaned',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      debugPrint('🧹 Settings Cleanup: Completion dialog closed');
    } catch (e, stackTrace) {
      debugPrint('❌ Settings Cleanup Error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!context.mounted) return;
      
      // Close progress dialog if still open
      Navigator.of(context, rootNavigator: true).pop();
      
      // Small delay to ensure dialog is closed
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cleanup Failed'),
          content: SingleChildScrollView(
            child: Text('Error: $e'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}
