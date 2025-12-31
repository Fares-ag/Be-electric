import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/inventory_item.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/app_theme.dart';
import 'edit_inventory_item_screen.dart';

class InventoryDetailScreen extends StatefulWidget {
  const InventoryDetailScreen({required this.item, super.key});
  final InventoryItem item;

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.item.name),
          backgroundColor: AppTheme.surfaceColor,
          foregroundColor: AppTheme.darkTextColor,
          elevation: AppTheme.elevationS,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditInventoryItemScreen(item: widget.item),
                    ),
                  ).then((result) {
                    if (result == true) {
                      // Refresh the screen if item was updated
                      setState(() {});
                    }
                  });
                } else if (value == 'adjust') {
                  _showAdjustmentDialog();
                } else if (value == 'delete') {
                  _showDeleteDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'adjust',
                  child: Row(
                    children: [
                      Icon(Icons.tune),
                      SizedBox(width: 8),
                      Text('Adjust Stock'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stock Status Card
              _buildStockStatusCard(),
              const SizedBox(height: AppTheme.spacingM),

              // Basic Information Card
              _buildInfoCard(
                title: 'Basic Information',
                icon: Icons.info_outline,
                items: [
                  _buildInfoRow('Name', widget.item.name),
                  _buildInfoRow(
                    'Category',
                    _formatCategoryName(widget.item.category),
                  ),
                  _buildInfoRow(
                    'Description',
                    widget.item.description ?? 'No description',
                  ),
                  _buildInfoRow('Status', _formatStatus(widget.item.status)),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Stock Information Card
              _buildInfoCard(
                title: 'Stock Information',
                icon: Icons.inventory,
                items: [
                  _buildInfoRow(
                    'Current Quantity',
                    '${widget.item.quantity.toStringAsFixed(0)} ${widget.item.unit}',
                  ),
                  _buildInfoRow(
                    'Minimum Stock',
                    widget.item.minimumStock != null
                        ? '${widget.item.minimumStock!.toStringAsFixed(0)} ${widget.item.unit}'
                        : 'Not set',
                  ),
                  _buildInfoRow(
                    'Maximum Stock',
                    widget.item.maximumStock != null
                        ? '${widget.item.maximumStock!.toStringAsFixed(0)} ${widget.item.unit}'
                        : 'Not set',
                  ),
                  _buildInfoRow(
                    'Unit Cost',
                    widget.item.cost != null
                        ? 'QAR ${widget.item.cost!.toStringAsFixed(2)}'
                        : 'Not set',
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Identification Card
              _buildInfoCard(
                title: 'Identification',
                icon: Icons.qr_code,
                items: [
                  _buildInfoRow('SKU', widget.item.sku ?? 'Not set'),
                  _buildInfoRow(
                    'Part Number',
                    widget.item.partNumber ?? 'Not set',
                  ),
                  _buildInfoRow(
                    'Manufacturer',
                    widget.item.manufacturer ?? 'Not set',
                  ),
                  _buildInfoRow('Supplier', widget.item.supplier ?? 'Not set'),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Location Card
              _buildInfoCard(
                title: 'Location',
                icon: Icons.location_on,
                items: [
                  _buildInfoRow('Location', widget.item.location ?? 'Not set'),
                  _buildInfoRow('Shelf', widget.item.shelf ?? 'Not set'),
                  _buildInfoRow('Bin', widget.item.bin ?? 'Not set'),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Additional Information Card
              _buildInfoCard(
                title: 'Additional Information',
                icon: Icons.note,
                items: [
                  _buildInfoRow('Warranty', widget.item.warranty ?? 'Not set'),
                  _buildInfoRow('Created', _formatDate(widget.item.createdAt)),
                  _buildInfoRow(
                    'Last Updated',
                    widget.item.lastUpdated != null
                        ? _formatDate(widget.item.lastUpdated!)
                        : 'Never',
                  ),
                  _buildInfoRow('Notes', widget.item.notes ?? 'No notes'),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildStockStatusCard() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (widget.item.isOutOfStock) {
      statusColor = AppTheme.accentRed;
      statusText = 'Out of Stock';
      statusIcon = Icons.error;
    } else if (widget.item.isLowStock) {
      statusColor = AppTheme.accentOrange;
      statusText = 'Low Stock';
      statusIcon = Icons.warning;
    } else if (widget.item.isOverstocked) {
      statusColor = AppTheme.accentBlue;
      statusText = 'Overstocked';
      statusIcon = Icons.trending_up;
    } else {
      statusColor = AppTheme.accentGreen;
      statusText = 'In Stock';
      statusIcon = Icons.check_circle;
    }

    return Card(
      elevation: AppTheme.elevationM,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          gradient: LinearGradient(
            colors: [
              statusColor.withOpacity(0.1),
              statusColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 32,
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: AppTheme.heading2.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    '${widget.item.quantity.toStringAsFixed(0)} ${widget.item.unit}',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.item.cost != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Value',
                    style: AppTheme.secondaryText.copyWith(
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    'QAR ${(widget.item.quantity * widget.item.cost!).toStringAsFixed(2)}',
                    style: AppTheme.heading2.copyWith(
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> items,
  }) =>
      Card(
        elevation: AppTheme.elevationS,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppTheme.accentBlue),
                  const SizedBox(width: AppTheme.spacingS),
                  Text(
                    title,
                    style: AppTheme.heading2,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              ...items,
            ],
          ),
        ),
      );

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: AppTheme.secondaryText.copyWith(
                  color: AppTheme.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: AppTheme.bodyText,
              ),
            ),
          ],
        ),
      );

  void _showAdjustmentDialog() {
    final quantityController = TextEditingController();
    var selectedType = 'adjustment';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedType,
              decoration: const InputDecoration(
                labelText: 'Adjustment Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'in', child: Text('Stock In')),
                DropdownMenuItem(value: 'out', child: Text('Stock Out')),
                DropdownMenuItem(
                  value: 'adjustment',
                  child: Text('Adjustment'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  selectedType = value;
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (quantityController.text.isNotEmpty) {
                final quantity = double.parse(quantityController.text);
                final inventoryProvider =
                    Provider.of<InventoryProvider>(context, listen: false);

                await inventoryProvider.adjustInventory(
                  itemId: widget.item.id,
                  quantity: quantity,
                  type: selectedType,
                  notes: 'Manual adjustment',
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Stock adjusted successfully'),
                      backgroundColor: AppTheme.accentGreen,
                    ),
                  );
                }
              }
            },
            child: const Text('Adjust'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Inventory Item'),
        content: Text(
          'Are you sure you want to delete "${widget.item.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final inventoryProvider =
                  Provider.of<InventoryProvider>(context, listen: false);
              await inventoryProvider.deleteInventoryItem(widget.item.id);

              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Inventory item deleted successfully'),
                    backgroundColor: AppTheme.accentGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatCategoryName(String category) => category
      .split('_')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');

  String _formatStatus(String status) =>
      status[0].toUpperCase() + status.substring(1);

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
