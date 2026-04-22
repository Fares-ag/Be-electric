import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/unified_data_provider.dart';
import '../../utils/app_theme.dart';
import 'individual_technician_dashboard.dart';

class TechnicianViewerScreen extends StatefulWidget {
  const TechnicianViewerScreen({super.key});

  @override
  State<TechnicianViewerScreen> createState() => _TechnicianViewerScreenState();
}

class _TechnicianViewerScreenState extends State<TechnicianViewerScreen> {
  // No state needed - using Consumer for real-time data!

  void _viewTechnicianDashboard(User technician) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            IndividualTechnicianDashboard(technician: technician),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Consumer<UnifiedDataProvider>(
        builder: (context, unifiedProvider, child) {
          final technicians = unifiedProvider.users
              .where((user) => user.role.toLowerCase() == 'technician')
              .toList();

          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
              title: Text('Technician Performance (${technicians.length})'),
              backgroundColor: AppTheme.surfaceColor,
              foregroundColor: AppTheme.darkTextColor,
              elevation: AppTheme.elevationS,
            ),
            body: technicians.isEmpty
                ? _buildEmptyState()
                : _buildTechniciansList(technicians),
          );
        },
      );

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.people_outline,
                size: 80,
                color: AppTheme.secondaryTextColor,
              ),
              const SizedBox(height: AppTheme.spacingL),
              Text(
                'No Technicians Found',
                style: AppTheme.heading1.copyWith(
                  color: AppTheme.darkTextColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'Create technician accounts to view their performance and analytics.',
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXL),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Create Technician'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingL,
                    vertical: AppTheme.spacingM,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildTechniciansList(List<User> technicians) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.analytics,
                        color: AppTheme.accentBlue,
                        size: 24,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(
                        'Technician Performance Overview',
                        style: AppTheme.heading1.copyWith(
                          color: AppTheme.darkTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Select a technician to view their individual dashboard, tasks, and performance analytics.',
                    style: AppTheme.bodyText.copyWith(
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingL),

            // Technicians List
            Expanded(
              child: ListView.builder(
                itemCount: technicians.length,
                itemBuilder: (context, index) {
                  final technician = technicians[index];
                  return _buildTechnicianCard(technician);
                },
              ),
            ),
          ],
        ),
      );

  Widget _buildTechnicianCard(User technician) => Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
        child: Card(
          elevation: AppTheme.elevationS,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: InkWell(
            onTap: () => _viewTechnicianDashboard(technician),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.accentBlue.withOpacity(0.2),
                    child: const Icon(
                      Icons.build,
                      color: AppTheme.accentBlue,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: AppTheme.spacingL),

                  // Technician Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          technician.name,
                          style: AppTheme.heading2.copyWith(
                            color: AppTheme.darkTextColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(
                          technician.email,
                          style: AppTheme.smallText.copyWith(
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                        if (technician.department != null) ...[
                          const SizedBox(height: AppTheme.spacingXS),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingS,
                              vertical: AppTheme.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentBlue.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusS),
                            ),
                            child: Text(
                              technician.department!,
                              style: AppTheme.smallText.copyWith(
                                color: AppTheme.accentBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // View Button
                  Column(
                    children: [
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.secondaryTextColor,
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        'View',
                        style: AppTheme.smallText.copyWith(
                          color: AppTheme.accentBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
