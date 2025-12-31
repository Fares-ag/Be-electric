import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/cleanup_unknown_users.dart';

class CleanupUsersScreen extends StatefulWidget {
  const CleanupUsersScreen({super.key});

  @override
  State<CleanupUsersScreen> createState() => _CleanupUsersScreenState();
}

class _CleanupUsersScreenState extends State<CleanupUsersScreen> {
  bool _isProcessing = false;
  bool _isAnalyzing = false;
  Map<String, int>? _results;
  Map<String, dynamic>? _duplicateAnalysis;
  bool _includeDuplicates = false;

  Future<void> _analyzeDuplicates() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final analysis = await CleanupUnknownUsers.analyzeDuplicates();

      setState(() {
        _duplicateAnalysis = analysis;
        _isAnalyzing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Found ${analysis['duplicateCount']} duplicate users across ${analysis['uniqueEmails']} emails',
            ),
            backgroundColor: AppTheme.accentBlue,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing duplicates: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _runCleanup() async {
    setState(() {
      _isProcessing = true;
      _results = null;
    });

    try {
      final results = await CleanupUnknownUsers.cleanupAll(
        includeDuplicates: _includeDuplicates,
      );

      setState(() {
        _results = results;
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Deleted ${results['total']} Unknown users!',
            ),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during cleanup: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Cleanup Unknown Users'),
          backgroundColor: AppTheme.surfaceColor,
          foregroundColor: AppTheme.darkTextColor,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cleaning_services,
                  size: 80,
                  color: _results != null
                      ? AppTheme.accentGreen
                      : AppTheme.accentOrange,
                ),
                const SizedBox(height: 24),
                Text(
                  'Database Cleanup Utility',
                  style: AppTheme.heading1.copyWith(
                    color: AppTheme.darkTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'This will remove all "Unknown" users that were\nautomatically created by the system.',
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Duplicate detection option
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          title: const Text(
                            'Also remove duplicate emails',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            'Keeps the newest user for each email',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _includeDuplicates,
                          onChanged: (value) {
                            setState(() {
                              _includeDuplicates = value ?? false;
                            });
                          },
                        ),
                        if (_duplicateAnalysis != null) ...[
                          const Divider(),
                          Text(
                            'Found ${_duplicateAnalysis!['duplicateCount']} duplicates in ${_duplicateAnalysis!['totalUsers']} users',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Analyze button
                OutlinedButton.icon(
                  onPressed: _isAnalyzing ? null : _analyzeDuplicates,
                  icon: _isAnalyzing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(
                      _isAnalyzing ? 'Analyzing...' : 'Check for Duplicates',),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_results != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.accentGreen,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cleanup Complete!',
                          style: AppTheme.heading2.copyWith(
                            color: AppTheme.accentGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildResultRow('Local Database', _results!['local']!),
                        _buildResultRow('Firestore', _results!['firestore']!),
                        const Divider(height: 24),
                        _buildResultRow('Total Deleted', _results!['total']!,
                            isBold: true,),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _runCleanup,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.delete_sweep),
                  label: Text(_isProcessing ? 'Cleaning...' : 'Run Cleanup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to User Management'),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildResultRow(String label, int count, {bool isBold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isBold ? 16 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: AppTheme.darkTextColor,
              ),
            ),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: isBold ? 18 : 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentGreen,
              ),
            ),
          ],
        ),
      );
}
