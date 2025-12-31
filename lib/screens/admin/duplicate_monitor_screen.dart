import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';

class DuplicateMonitorScreen extends StatefulWidget {
  const DuplicateMonitorScreen({super.key});

  @override
  State<DuplicateMonitorScreen> createState() => _DuplicateMonitorScreenState();
}

class _DuplicateMonitorScreenState extends State<DuplicateMonitorScreen> {
  bool _loading = true;
  String? _error;
  Map<String, int> _dupeCounts = {
    'usersByEmail': 0,
    'assetsByNameLocation': 0,
    'inventoryBySku': 0,
    'workOrdersByIdem': 0,
    'pmTasksByIdem': 0,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;

      // Users: duplicates by email
      final usersResponse = await client.from('users').select();
      final emailCounts = <String, int>{};
      for (final d in (usersResponse as List)) {
        final data = Map<String, dynamic>.from(d);
        final email = (data['email'] ?? '').toString().toLowerCase().trim();
        if (email.isEmpty) continue;
        emailCounts[email] = (emailCounts[email] ?? 0) + 1;
      }
      final usersDupes = emailCounts.values
          .where((c) => c > 1)
          .fold<int>(0, (a, b) => a + (b - 1));

      // Assets: duplicates by name+location
      final assetsResponse = await client.from('assets').select();
      final nameLocCounts = <String, int>{};
      for (final d in (assetsResponse as List)) {
        final data = Map<String, dynamic>.from(d);
        final key =
            '${(data['name'] ?? '').toString().toLowerCase().trim()}::${(data['location'] ?? '').toString().toLowerCase().trim()}';
        if (key == '::') continue;
        nameLocCounts[key] = (nameLocCounts[key] ?? 0) + 1;
      }
      final assetsDupes = nameLocCounts.values
          .where((c) => c > 1)
          .fold<int>(0, (a, b) => a + (b - 1));

      // Inventory: duplicates by sku
      final invResponse = await client.from('inventory_items').select();
      final skuCounts = <String, int>{};
      for (final d in (invResponse as List)) {
        final data = Map<String, dynamic>.from(d);
        final sku = (data['sku'] ?? '').toString().toUpperCase().trim();
        if (sku.isEmpty) continue;
        skuCounts[sku] = (skuCounts[sku] ?? 0) + 1;
      }
      final invDupes = skuCounts.values
          .where((c) => c > 1)
          .fold<int>(0, (a, b) => a + (b - 1));

      // Work Orders: duplicates by idempotencyKey
      final woResponse = await client
          .from('work_orders')
          .select()
          .neq('idempotencyKey', '');
      final idemCounts = <String, int>{};
      for (final d in (woResponse as List)) {
        final data = Map<String, dynamic>.from(d);
        final key = (data['idempotencyKey'] ?? '').toString();
        if (key.isEmpty) continue;
        idemCounts[key] = (idemCounts[key] ?? 0) + 1;
      }
      final woDupes = idemCounts.values
          .where((c) => c > 1)
          .fold<int>(0, (a, b) => a + (b - 1));

      // PM Tasks: duplicates by idempotencyKey
      final pmResponse = await client
          .from('pm_tasks')
          .select()
          .neq('idempotencyKey', '');
      final pmIdemCounts = <String, int>{};
      for (final d in (pmResponse as List)) {
        final data = Map<String, dynamic>.from(d);
        final key = (data['idempotencyKey'] ?? '').toString();
        if (key.isEmpty) continue;
        pmIdemCounts[key] = (pmIdemCounts[key] ?? 0) + 1;
      }
      final pmDupes = pmIdemCounts.values
          .where((c) => c > 1)
          .fold<int>(0, (a, b) => a + (b - 1));

      setState(() {
        _dupeCounts = {
          'usersByEmail': usersDupes,
          'assetsByNameLocation': assetsDupes,
          'inventoryBySku': invDupes,
          'workOrdersByIdem': woDupes,
          'pmTasksByIdem': pmDupes,
        };
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Duplicate Monitor'),
          backgroundColor: AppTheme.backgroundColor,
          iconTheme: const IconThemeData(color: AppTheme.textColor),
        ),
        backgroundColor: AppTheme.backgroundColor,
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              )
            : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.errorColor),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _tile('Users (by email)',
                            _dupeCounts['usersByEmail'] ?? 0, Icons.person,),
                        _tile(
                            'Assets (by name + location)',
                            _dupeCounts['assetsByNameLocation'] ?? 0,
                            Icons.devices,),
                        _tile(
                            'Inventory (by SKU)',
                            _dupeCounts['inventoryBySku'] ?? 0,
                            Icons.inventory_2,),
                        _tile(
                            'Work Orders (by idempotencyKey)',
                            _dupeCounts['workOrdersByIdem'] ?? 0,
                            Icons.assignment,),
                        _tile(
                            'PM Tasks (by idempotencyKey)',
                            _dupeCounts['pmTasksByIdem'] ?? 0,
                            Icons.rule_folder,),
                        const SizedBox(height: 12),
                        Text(
                          'Tip: Deterministic IDs and idempotency keys are enabled. Use this monitor to verify zero duplicates in production.',
                          style: TextStyle(
                              color: AppTheme.textColor.withOpacity(0.75),),
                        ),
                      ],
                    ),
                  ),
      );

  Widget _tile(String title, int count, IconData icon) => Card(
        color: AppTheme.cardColor,
        child: ListTile(
          leading: Icon(icon, color: AppTheme.primaryColor),
          title: Text(
            title,
            style: const TextStyle(
                color: AppTheme.textColor, fontWeight: FontWeight.w600,),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: count == 0
                  ? Colors.green.withOpacity(0.15)
                  : Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: count == 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
}


