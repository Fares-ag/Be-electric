import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import '../../providers/unified_data_provider.dart';
import '../../models/work_order.dart';
import '../../utils/app_theme.dart';

class WebWorkOrdersScreen extends StatefulWidget {
  const WebWorkOrdersScreen({super.key});

  @override
  State<WebWorkOrdersScreen> createState() => _WebWorkOrdersScreenState();
}

class _WebWorkOrdersScreenState extends State<WebWorkOrdersScreen> {
  String _searchQuery = '';
  WorkOrderStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) => Consumer<UnifiedDataProvider>(
        builder: (context, dataProvider, child) {
          var workOrders = dataProvider.workOrders;

          // Apply filters
          if (_searchQuery.isNotEmpty) {
            workOrders = workOrders
                .where((wo) =>
                    wo.ticketNumber
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ||
                    wo.problemDescription
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ||
                    (wo.asset?.name ?? '')
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()),)
                .toList();
          }

          if (_selectedStatus != null) {
            workOrders =
                workOrders.where((wo) => wo.status == _selectedStatus).toList();
          }

          return Column(
            children: [
              // Filters and Actions Bar
              _buildFilterBar(),
              // Data Table
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Table Header
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Text(
                              'All Work Orders',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkTextColor,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${workOrders.length} results',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Table Content
                      Expanded(
                        child: DataTable2(
                          columnSpacing: 12,
                          horizontalMargin: 20,
                          minWidth: 900,
                          headingRowColor: WidgetStateProperty.all(
                            Colors.grey.shade50,
                          ),
                          headingRowHeight: 56,
                          dataRowHeight: 72,
                          columns: const [
                            DataColumn2(
                              label: Text(
                                'Ticket #',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text(
                                'Asset',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            DataColumn2(
                              label: Text(
                                'Problem',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              size: ColumnSize.L,
                            ),
                            DataColumn2(
                              label: Text(
                                'Priority',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text(
                                'Status',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text(
                                'Assigned To',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            DataColumn2(
                              label: Text(
                                'Created',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              size: ColumnSize.S,
                            ),
                            DataColumn2(
                              label: Text(
                                'Actions',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              size: ColumnSize.S,
                            ),
                          ],
                          rows: workOrders
                              .map((wo) => DataRow2(
                                    cells: [
                                      DataCell(
                                        Text(
                                          wo.ticketNumber,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.accentBlue,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              wo.asset?.name ??
                                                  'General Maintenance',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (wo.asset?.location != null ||
                                                wo.location != null)
                                              Text(
                                                wo.assetLocation ?? 'N/A',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          wo.problemDescription,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DataCell(
                                          _buildPriorityBadge(wo.priority),),
                                      DataCell(_buildStatusBadge(wo.status)),
                                      DataCell(
                                        Text(
                                          wo.assignedTechnician?.name ??
                                              'Unassigned',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          DateFormat('MMM dd, yyyy')
                                              .format(wo.createdAt),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.visibility_outlined,
                                                  size: 18,),
                                              onPressed: () {
                                                // View details
                                              },
                                              tooltip: 'View Details',
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 18,),
                                              onPressed: () {
                                                // Edit work order
                                              },
                                              tooltip: 'Edit',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),)
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );

  Widget _buildFilterBar() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Search Bar
            Expanded(
              flex: 2,
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search work orders...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.accentBlue),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Status Filter
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<WorkOrderStatus?>(
                initialValue: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Filter by Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: [
                  const DropdownMenuItem(
                    child: Text('All Statuses'),
                  ),
                  ...WorkOrderStatus.values.map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(
                          status.name.toUpperCase(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            // Create Button
            ElevatedButton.icon(
              onPressed: () {
                // Create new work order
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Work Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Export Button
            OutlinedButton.icon(
              onPressed: () {
                // Export to CSV
              },
              icon: const Icon(Icons.download),
              label: const Text('Export'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildPriorityBadge(WorkOrderPriority priority) {
    final colors = {
      WorkOrderPriority.low: Colors.blue,
      WorkOrderPriority.medium: Colors.orange,
      WorkOrderPriority.high: Colors.red,
      WorkOrderPriority.urgent: Colors.deepOrange,
      WorkOrderPriority.critical: Colors.purple,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors[priority]!.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors[priority]!.withValues(alpha: 0.3)),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors[priority],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(WorkOrderStatus status) {
    final colors = {
      WorkOrderStatus.open: const Color(0xFF3B82F6),
      WorkOrderStatus.assigned: const Color(0xFF8B5CF6),
      WorkOrderStatus.inProgress: const Color(0xFFF59E0B),
      WorkOrderStatus.completed: const Color(0xFF10B981),
      WorkOrderStatus.closed: const Color(0xFF6B7280),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors[status]!.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors[status]!.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors[status],
        ),
      ),
    );
  }
}
