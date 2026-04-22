// Enhanced Asset Details Screen - Full-screen view with all asset information
// Organized in expandable sections with rich visual formatting

import 'package:flutter/material.dart';
import '../../models/asset.dart';
import '../../utils/app_theme.dart';
import '../../widgets/enhanced_asset_display_widget.dart';

class EnhancedAssetDetailsScreen extends StatefulWidget {
  const EnhancedAssetDetailsScreen({
    required this.asset,
    super.key,
    this.connectionMethod = 'direct',
    this.onEditAsset,
    this.onSelectAsset,
  });
  final Asset asset;
  final String connectionMethod;
  final Function(Asset)? onEditAsset;
  final Function(Asset)? onSelectAsset;

  @override
  State<EnhancedAssetDetailsScreen> createState() =>
      _EnhancedAssetDetailsScreenState();
}

class _EnhancedAssetDetailsScreenState
    extends State<EnhancedAssetDetailsScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Asset Details - ${widget.asset.name}'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          actions: [
            if (widget.onEditAsset != null)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => widget.onEditAsset!(widget.asset),
                tooltip: 'Edit Asset',
              ),
            if (widget.onSelectAsset != null)
              IconButton(
                icon: const Icon(Icons.check_circle),
                onPressed: () {
                  widget.onSelectAsset!(widget.asset);
                  Navigator.pop(context);
                },
                tooltip: 'Select Asset',
              ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildAssetImage(),
              _buildAssetInfo(),
            ],
          ),
        ),
      );

  Widget _buildAssetImage() {
    if (widget.asset.imageUrl != null && widget.asset.imageUrl!.isNotEmpty) {
      return SizedBox(
        height: 200,
        width: double.infinity,
        child: Image.network(
          widget.asset.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildImagePlaceholder(),
        ),
      );
    }
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() => Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          border:
              Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getAssetIcon(),
              size: 64,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              widget.asset.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      );

  IconData _getAssetIcon() {
    final category = widget.asset.category?.toLowerCase() ?? '';
    if (category.contains('vehicle') || category.contains('car')) {
      return Icons.directions_car;
    } else if (category.contains('furniture')) {
      return Icons.chair;
    } else if (category.contains('equipment') || category.contains('machine')) {
      return Icons.precision_manufacturing;
    } else if (category.contains('computer') || category.contains('laptop')) {
      return Icons.computer;
    } else if (category.contains('tool')) {
      return Icons.build;
    } else {
      return Icons.inventory_2;
    }
  }

  Widget _buildAssetInfo() => ComprehensiveAssetDisplayWidget(
        asset: widget.asset,
        connectionMethod: widget.connectionMethod,
        showActions: false,
      );
}
