import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/assignment_diagnostic.dart';

class AssignmentDiagnosticScreen extends StatefulWidget {
  const AssignmentDiagnosticScreen({super.key});

  @override
  State<AssignmentDiagnosticScreen> createState() =>
      _AssignmentDiagnosticScreenState();
}

class _AssignmentDiagnosticScreenState
    extends State<AssignmentDiagnosticScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _diagnostics;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _isLoading = true);

    try {
      final results = await AssignmentDiagnostic.runDiagnostics();
      setState(() {
        _diagnostics = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error running diagnostics: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Assignment Diagnostics'),
          backgroundColor: AppTheme.surfaceColor,
          foregroundColor: AppTheme.darkTextColor,
          elevation: AppTheme.elevationS,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _runDiagnostics,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
                ),
              )
            : _diagnostics == null
                ? _buildErrorState()
                : _buildDiagnosticReport(),
      );

  Widget _buildErrorState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'Failed to run diagnostics',
              style: AppTheme.heading1.copyWith(
                color: AppTheme.darkTextColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            ElevatedButton.icon(
              onPressed: _runDiagnostics,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );

  Widget _buildDiagnosticReport() {
    final totalUsers = _diagnostics!['totalUsers'] as int;
    final totalTechnicians = _diagnostics!['totalTechnicians'] as int;
    final roleDistribution =
        _diagnostics!['roleDistribution'] as Map<String, int>;
    final totalWorkOrders = _diagnostics!['totalWorkOrders'] as int;
    final assignedWorkOrders = _diagnostics!['assignedWorkOrders'] as int;
    final unassignedWorkOrders = _diagnostics!['unassignedWorkOrders'] as int;
    final orphanedAssignments =
        _diagnostics!['orphanedAssignments'] as List<dynamic>;
    final totalPMTasks = _diagnostics!['totalPMTasks'] as int;
    final assignedPMTasks = _diagnostics!['assignedPMTasks'] as int;
    final unassignedPMTasks = _diagnostics!['unassignedPMTasks'] as int;
    final orphanedPMAssignments =
        _diagnostics!['orphanedPMAssignments'] as List<dynamic>;
    final techniciansList = _diagnostics!['techniciansList'] as List<dynamic>;
    final technicianWorkload =
        _diagnostics!['technicianWorkload'] as Map<String, dynamic>;

    final hasIssues = totalTechnicians == 0 ||
        orphanedAssignments.isNotEmpty ||
        orphanedPMAssignments.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              color: hasIssues
                  ? AppTheme.accentRed.withValues(alpha: 0.1)
                  : AppTheme.accentGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(
                color: hasIssues ? AppTheme.accentRed : AppTheme.accentGreen,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasIssues ? Icons.warning : Icons.check_circle,
                  color: hasIssues ? AppTheme.accentRed : AppTheme.accentGreen,
                  size: 40,
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasIssues ? '⚠️ Issues Detected' : '✅ No Issues Found',
                        style: AppTheme.heading1.copyWith(
                          color: hasIssues
                              ? AppTheme.accentRed
                              : AppTheme.accentGreen,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        hasIssues
                            ? 'Assignment issues detected. See details below.'
                            : 'All assignment systems are functioning correctly.',
                        style: AppTheme.bodyText.copyWith(
                          color: AppTheme.darkTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingL),

          // User Statistics
          _buildSectionTitle('👥 User Statistics'),
          _buildStatCard('Total Users', totalUsers.toString(), Icons.people),
          _buildStatCard(
            'Total Technicians',
            totalTechnicians.toString(),
            Icons.build_circle,
          ),

          const SizedBox(height: AppTheme.spacingL),

          // Role Distribution
          _buildSectionTitle('📊 Role Distribution'),
          ...roleDistribution.entries.map(
            (entry) => _buildDetailRow(
              entry.key.toUpperCase(),
              '${entry.value} users',
            ),
          ),

          const SizedBox(height: AppTheme.spacingL),

          // Work Order Statistics
          _buildSectionTitle('🔧 Work Order Statistics'),
          _buildStatCard(
            'Total Work Orders',
            totalWorkOrders.toString(),
            Icons.work,
          ),
          _buildStatCard(
            'Assigned',
            assignedWorkOrders.toString(),
            Icons.assignment_ind,
          ),
          _buildStatCard(
            'Unassigned',
            unassignedWorkOrders.toString(),
            Icons.assignment_late,
          ),
          if (orphanedAssignments.isNotEmpty) ...[
            _buildStatCard(
              'Orphaned Assignments ⚠️',
              orphanedAssignments.length.toString(),
              Icons.warning,
              color: AppTheme.accentRed,
            ),
          ],

          const SizedBox(height: AppTheme.spacingL),

          // PM Task Statistics
          _buildSectionTitle('🗓️ PM Task Statistics'),
          _buildStatCard(
            'Total PM Tasks',
            totalPMTasks.toString(),
            Icons.calendar_month,
          ),
          _buildStatCard(
            'Assigned',
            assignedPMTasks.toString(),
            Icons.assignment_ind,
          ),
          _buildStatCard(
            'Unassigned',
            unassignedPMTasks.toString(),
            Icons.assignment_late,
          ),
          if (orphanedPMAssignments.isNotEmpty) ...[
            _buildStatCard(
              'Orphaned Assignments ⚠️',
              orphanedPMAssignments.length.toString(),
              Icons.warning,
              color: AppTheme.accentRed,
            ),
          ],

          const SizedBox(height: AppTheme.spacingL),

          // Technicians List
          if (techniciansList.isNotEmpty) ...[
            _buildSectionTitle('👨‍🔧 Registered Technicians'),
            ...techniciansList.map((tech) {
              final techId = tech['id'] as String;
              final workload =
                  technicianWorkload[techId] as Map<String, dynamic>? ?? {};
              final woCount = workload['workOrders'] as int? ?? 0;
              final pmCount = workload['pmTasks'] as int? ?? 0;

              return _buildTechnicianCard(
                name: tech['name'] as String,
                email: tech['email'] as String,
                id: techId,
                workOrders: woCount,
                pmTasks: pmCount,
              );
            }),
          ],

          if (totalTechnicians == 0) ...[
            const SizedBox(height: AppTheme.spacingL),
            _buildWarningCard(
              '⚠️ No Technicians Found!',
              'No users with the "technician" role were found.\n\n'
                  'Possible causes:\n'
                  '1. No technicians have been created\n'
                  '2. Role field has wrong casing\n'
                  "3. Data hasn't loaded from Firestore yet\n\n"
                  'Please create technician users in User Management.',
            ),
          ],

          if (orphanedAssignments.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingL),
            _buildWarningCard(
              '⚠️ Orphaned Work Order Assignments',
              'These work orders reference technicians that no longer exist:\n\n${orphanedAssignments.map(
                (wo) {
                  final missingIds = wo['missingTechnicianIds'];
                  final ids = missingIds ?? wo['assignedTechnicianIds'];
                  final idText = _formatTechnicianList(ids);
                  return '• ${wo['ticketNumber']} → Missing: $idText';
                },
              ).join('\n')}',
            ),
          ],

          if (orphanedPMAssignments.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingL),
            _buildWarningCard(
              '⚠️ Orphaned PM Task Assignments',
              'These PM tasks reference technicians that no longer exist:\n\n${orphanedPMAssignments.map(
                (pm) {
                  final missingIds = pm['missingTechnicianIds'];
                  final ids = missingIds ?? pm['assignedTechnicianIds'];
                  final idText = _formatTechnicianList(ids);
                  return '• ${pm['taskName']} → Missing: $idText';
                },
              ).join('\n')}',
            ),
          ],

          const SizedBox(height: AppTheme.spacingXL),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
        child: Text(
          title,
          style: AppTheme.heading2.copyWith(
            color: AppTheme.darkTextColor,
          ),
        ),
      );

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    final cardColor = color ?? AppTheme.accentBlue;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: cardColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: cardColor, size: 32),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.smallText.copyWith(
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
                Text(
                  value,
                  style: AppTheme.heading1.copyWith(
                    color: cardColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.darkTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.accentBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  Widget _buildTechnicianCard({
    required String name,
    required String email,
    required String id,
    required int workOrders,
    required int pmTasks,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.accentBlue.withValues(alpha: 0.2),
                  child: const Icon(Icons.build, color: AppTheme.accentBlue),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTheme.bodyText.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkTextColor,
                        ),
                      ),
                      Text(
                        email,
                        style: AppTheme.smallText.copyWith(
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
            Row(
              children: [
                _buildMiniStat('Work Orders', workOrders, Icons.work),
                const SizedBox(width: AppTheme.spacingM),
                _buildMiniStat('PM Tasks', pmTasks, Icons.calendar_month),
              ],
            ),
          ],
        ),
      );

  Widget _buildMiniStat(String label, int value, IconData icon) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingS),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.accentBlue),
              const SizedBox(width: AppTheme.spacingXS),
              Text(
                '$value $label',
                style: AppTheme.smallText.copyWith(
                  color: AppTheme.darkTextColor,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildWarningCard(String title, String message) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: AppTheme.accentRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: AppTheme.accentRed,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTheme.heading2.copyWith(
                color: AppTheme.accentRed,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              message,
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.darkTextColor,
              ),
            ),
          ],
        ),
      );

  String _formatTechnicianList(dynamic value) {
    if (value is List && value.isNotEmpty) {
      return value.join(', ');
    }
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return 'Unknown';
  }
}
