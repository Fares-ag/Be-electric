// Professional Asset Details Screen - Clean and sophisticated design
// Full-screen asset information with modern UI patterns

import 'package:flutter/material.dart';
import '../../models/asset.dart';
import '../../theme/unified_design_system.dart';

class ProfessionalAssetDetailsScreen extends StatelessWidget {
  const ProfessionalAssetDetailsScreen({
    required this.asset,
    super.key,
    this.connectionMethod = 'direct',
  });

  final Asset asset;
  final String connectionMethod;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: UnifiedDesignSystem.background,
        appBar: AppBar(
          title: Text(asset.name),
          backgroundColor: UnifiedDesignSystem.surface,
          foregroundColor: UnifiedDesignSystem.primary,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: UnifiedDesignSystem.borderColor,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(UnifiedDesignSystem.spaceM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: UnifiedDesignSystem.spaceL),
              _buildBasicInfo(),
              const SizedBox(height: UnifiedDesignSystem.spaceL),
              _buildTechnicalInfo(),
              const SizedBox(height: UnifiedDesignSystem.spaceL),
              _buildFinancialInfo(),
              const SizedBox(height: UnifiedDesignSystem.spaceL),
              _buildMaintenanceInfo(),
              if (asset.notes != null && asset.notes!.isNotEmpty) ...[
                const SizedBox(height: UnifiedDesignSystem.spaceL),
                _buildNotes(),
              ],
            ],
          ),
        ),
      );

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.all(UnifiedDesignSystem.spaceL),
        decoration: BoxDecoration(
          color: UnifiedDesignSystem.surface,
          borderRadius: BorderRadius.circular(UnifiedDesignSystem.radiusL),
          border: Border.all(
            color: UnifiedDesignSystem.borderColor,
          ),
        ),
        child: Row(
          children: [
            _buildAssetIcon(),
            const SizedBox(width: UnifiedDesignSystem.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    style: UnifiedDesignSystem.heading2,
                  ),
                  const SizedBox(height: UnifiedDesignSystem.spaceXS),
                  Text(
                    asset.location,
                    style: UnifiedDesignSystem.bodyLarge.copyWith(
                      color: UnifiedDesignSystem.textSecondary,
                    ),
                  ),
                  const SizedBox(height: UnifiedDesignSystem.spaceS),
                  _buildStatusChip(),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildAssetIcon() => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: _getCategoryColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(UnifiedDesignSystem.radiusL),
        ),
        child: Icon(
          _getCategoryIcon(),
          color: _getCategoryColor(),
          size: 32,
        ),
      );

  Widget _buildStatusChip() => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: UnifiedDesignSystem.spaceM,
          vertical: UnifiedDesignSystem.spaceS,
        ),
        decoration: BoxDecoration(
          color: _getStatusColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(UnifiedDesignSystem.radiusM),
          border: Border.all(
            color: _getStatusColor().withOpacity(0.3),
          ),
        ),
        child: Text(
          asset.status.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _getStatusColor(),
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _buildBasicInfo() => _buildInfoSection(
        title: 'Basic Information',
        icon: Icons.info_outline,
        children: [
          _buildInfoRow('Asset ID', asset.id),
          if (asset.category != null)
            _buildInfoRow('Category', asset.category!),
          if (asset.description != null)
            _buildInfoRow('Description', asset.description!),
          if (asset.assignedStaff != null)
            _buildInfoRow('Assigned To', asset.assignedStaff!),
          if (asset.department != null)
            _buildInfoRow('Department', asset.department!),
        ],
      );

  Widget _buildTechnicalInfo() => _buildInfoSection(
        title: 'Technical Details',
        icon: Icons.engineering,
        children: [
          if (asset.manufacturer != null)
            _buildInfoRow('Manufacturer', asset.manufacturer!),
          if (asset.model != null) _buildInfoRow('Model', asset.model!),
          if (asset.serialNumber != null)
            _buildInfoRow('Serial Number', asset.serialNumber!),
          if (asset.itemType != null)
            _buildInfoRow('Item Type', asset.itemType!),
          if (asset.condition != null)
            _buildInfoRow('Condition', asset.condition!),
        ],
      );

  Widget _buildFinancialInfo() => _buildInfoSection(
        title: 'Financial Information',
        icon: Icons.attach_money,
        children: [
          if (asset.purchasePrice != null)
            _buildInfoRow(
              'Purchase Price',
              'QAR ${asset.purchasePrice!.toStringAsFixed(2)}',
            ),
          if (asset.currentValue != null)
            _buildInfoRow(
              'Current Value',
              'QAR ${asset.currentValue!.toStringAsFixed(2)}',
            ),
          if (asset.supplier != null)
            _buildInfoRow('Supplier', asset.supplier!),
          if (asset.vendor != null) _buildInfoRow('Vendor', asset.vendor!),
          if (asset.warranty != null)
            _buildInfoRow('Warranty', asset.warranty!),
        ],
      );

  Widget _buildMaintenanceInfo() => _buildInfoSection(
        title: 'Maintenance Information',
        icon: Icons.build,
        children: [
          if (asset.lastMaintenanceDate != null)
            _buildInfoRow(
              'Last Maintenance',
              _formatDate(asset.lastMaintenanceDate!),
            ),
          if (asset.nextMaintenanceDate != null)
            _buildInfoRow(
              'Next Maintenance',
              _formatDate(asset.nextMaintenanceDate!),
            ),
          if (asset.maintenanceSchedule != null)
            _buildInfoRow('Schedule', asset.maintenanceSchedule!),
          if (asset.installationDate != null)
            _buildInfoRow(
              'Installation Date',
              _formatDate(asset.installationDate!),
            ),
          if (asset.mileage != null)
            _buildInfoRow('Mileage', '${asset.mileage} miles'),
        ],
      );

  Widget _buildNotes() => _buildInfoSection(
        title: 'Notes',
        icon: Icons.note,
        children: [
          _buildInfoRow('Notes', asset.notes!),
        ],
      );

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) =>
      Container(
        padding: const EdgeInsets.all(UnifiedDesignSystem.spaceL),
        decoration: BoxDecoration(
          color: UnifiedDesignSystem.surface,
          borderRadius: BorderRadius.circular(UnifiedDesignSystem.radiusL),
          border: Border.all(
            color: UnifiedDesignSystem.borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: UnifiedDesignSystem.accentBlue,
                  size: 20,
                ),
                const SizedBox(width: UnifiedDesignSystem.spaceS),
                Text(
                  title,
                  style: UnifiedDesignSystem.heading3,
                ),
              ],
            ),
            const SizedBox(height: UnifiedDesignSystem.spaceM),
            ...children,
          ],
        ),
      );

  Widget _buildInfoRow(String label, String value) => Padding(
        padding:
            const EdgeInsets.symmetric(vertical: UnifiedDesignSystem.spaceS),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: UnifiedDesignSystem.bodyMedium.copyWith(
                  color: UnifiedDesignSystem.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: UnifiedDesignSystem.spaceM),
            Expanded(
              child: Text(
                value,
                style: UnifiedDesignSystem.bodyLarge,
              ),
            ),
          ],
        ),
      );

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  IconData _getCategoryIcon() {
    final category = asset.category?.toLowerCase() ?? '';
    switch (category) {
      case 'vehicle':
      case 'truck':
      case 'car':
        return Icons.directions_car;
      case 'equipment':
      case 'machine':
        return Icons.precision_manufacturing;
      case 'computer':
      case 'laptop':
        return Icons.computer;
      case 'phone':
      case 'mobile':
        return Icons.phone_android;
      case 'furniture':
        return Icons.chair;
      case 'tool':
        return Icons.build;
      default:
        return Icons.inventory_2;
    }
  }

  Color _getCategoryColor() {
    final category = asset.category?.toLowerCase() ?? '';
    switch (category) {
      case 'vehicle':
      case 'truck':
      case 'car':
        return UnifiedDesignSystem.accentBlue;
      case 'equipment':
      case 'machine':
        return UnifiedDesignSystem.accentOrange;
      case 'computer':
      case 'laptop':
        return UnifiedDesignSystem.accentGreen;
      case 'phone':
      case 'mobile':
        return UnifiedDesignSystem.accentRed;
      case 'furniture':
        return UnifiedDesignSystem.textSecondary;
      case 'tool':
        return UnifiedDesignSystem.primary;
      default:
        return UnifiedDesignSystem.textSecondary;
    }
  }

  Color _getStatusColor() {
    switch (asset.status.toLowerCase()) {
      case 'active':
        return UnifiedDesignSystem.accentGreen;
      case 'inactive':
        return UnifiedDesignSystem.textSecondary;
      case 'maintenance':
        return UnifiedDesignSystem.accentOrange;
      case 'pending':
        return UnifiedDesignSystem.accentBlue;
      case 'completed':
        return UnifiedDesignSystem.accentGreen;
      case 'cancelled':
        return UnifiedDesignSystem.accentRed;
      default:
        return UnifiedDesignSystem.textSecondary;
    }
  }
}
