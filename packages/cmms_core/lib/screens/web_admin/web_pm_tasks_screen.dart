import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import '../../providers/unified_data_provider.dart';
import '../../utils/app_theme.dart';

class WebPMTasksScreen extends StatelessWidget {
  const WebPMTasksScreen({super.key});

  @override
  Widget build(BuildContext context) => Consumer<UnifiedDataProvider>(
        builder: (context, dataProvider, child) {
          final pmTasks = dataProvider.pmTasks;

          return Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Text(
                        'Preventive Maintenance Tasks',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkTextColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${pmTasks.length} tasks',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 20,
                    minWidth: 800,
                    columns: const [
                      DataColumn2(
                        label: Text(
                          'Task Name',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataColumn2(
                        label: Text(
                          'Asset',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataColumn2(
                        label: Text(
                          'Frequency',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataColumn2(
                        label: Text(
                          'Next Due',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataColumn2(
                        label: Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    rows: pmTasks
                        .map((pm) => DataRow2(
                              cells: [
                                DataCell(Text(pm.taskName)),
                                DataCell(Text(pm.asset?.name ?? 'N/A')),
                                DataCell(Text(pm.frequency.name)),
                                DataCell(Text(
                                  pm.nextDueDate != null
                                      ? DateFormat('MMM dd, yyyy')
                                          .format(pm.nextDueDate!)
                                      : 'N/A',
                                ),),
                                DataCell(Text(pm.status.name)),
                              ],
                            ),)
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        },
      );
}
