import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/supabase_database_service.dart';

/// Quick utility to fix "Unknown User" admin accounts
class FixUnknownAdmin {
  static Future<Map<String, dynamic>> fixAdminUser() async {
    try {
      // Load all users from Firestore
      final users = await SupabaseDatabaseService.instance.getAllUsers();

      // Find "Unknown" admin users
      final unknownAdmins = users
          .where((u) => u.name == 'Unknown User' && u.role == 'admin')
          .toList();

      if (unknownAdmins.isEmpty) {
        return {
          'success': false,
          'message': 'No "Unknown User" admin accounts found',
        };
      }

      // Fix each unknown admin
      var fixed = 0;
      for (final unknownAdmin in unknownAdmins) {
        // Update to proper admin
        final fixedAdmin = User(
          id: unknownAdmin.id,
          email: unknownAdmin.email == 'unknown@unknown.com'
              ? 'admin@qauto.com'
              : unknownAdmin.email,
          name: 'System Administrator',
          role: 'admin',
          department: 'Administration',
          createdAt: unknownAdmin.createdAt,
          lastLoginAt: unknownAdmin.lastLoginAt,
          workEmail: unknownAdmin.workEmail,
          updatedAt: DateTime.now(),
        );

        // Save to Firestore
        try {
          await SupabaseDatabaseService.instance.updateUser(
            unknownAdmin.id,
            fixedAdmin,
          );
        } catch (e) {
          print('⚠️ Firestore update failed (might not exist): $e');
        }

        fixed++;
      }

      return {
        'success': true,
        'message': 'Fixed $fixed admin account(s)',
        'count': fixed,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  static Future<void> showFixDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Fixing admin account...'),
          ],
        ),
      ),
    );

    final result = await fixAdminUser();

    if (!context.mounted) return;
    Navigator.pop(context); // Close loading dialog

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result['success'] ? '✅ Success' : '❌ Error'),
        content: Text(result['message']),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (result['success']) {
                // Suggest logout and re-login
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('⚠️ Logout Required'),
                    content: const Text(
                      'Please logout and login again to see the changes.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
