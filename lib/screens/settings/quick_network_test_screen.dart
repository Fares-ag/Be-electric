import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../utils/app_theme.dart';

class QuickNetworkTestScreen extends StatefulWidget {
  const QuickNetworkTestScreen({super.key});

  @override
  State<QuickNetworkTestScreen> createState() => _QuickNetworkTestScreenState();
}

class _QuickNetworkTestScreenState extends State<QuickNetworkTestScreen> {
  bool _isLoading = false;
  List<String> _results = [];

  @override
  void initState() {
    super.initState();
    _runQuickTest();
  }

  Future<void> _runQuickTest() async {
    setState(() {
      _isLoading = true;
      _results = [];
    });

    final results = <String>[];

    // Test 1: Basic internet
    results.add('ðŸ” Testing basic internet...');
    try {
      final response = await http
          .get(
            Uri.parse('https://www.google.com'),
          )
          .timeout(const Duration(seconds: 3));
      results.add('âœ… Internet: OK (${response.statusCode})');
    } catch (e) {
      results.add('âŒ Internet: FAILED - $e');
    }

    // Test 2: Your API
    results.add('ðŸ” Testing your API...');
    try {
      final response = await http.get(
        Uri.parse('https://api.qauto.com/assets?limit=1'),
        headers: {
          'Authorization': 'Bearer cmms-maintenance',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));
      results.add('âœ… API: OK (${response.statusCode})');
      if (response.statusCode == 200) {
        results.add('ðŸ“Š API Response: ${response.body.length} characters');
      }
    } catch (e) {
      results.add('âŒ API: FAILED - $e');
    }

    // Test 3: Firebase
    results.add('ðŸ” Testing Firebase...');
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://firestore.googleapis.com/v1/projects/qauto-dam/databases/(default)/documents?pageSize=1',
            ),
          )
          .timeout(const Duration(seconds: 5));
      results.add('âœ… Firebase: OK (${response.statusCode})');
    } catch (e) {
      results.add('âŒ Firebase: FAILED - $e');
    }

    setState(() {
      _isLoading = false;
      _results = results;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Quick Network Test'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _runQuickTest,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Network Test Results',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_results.isNotEmpty)
                              ..._results.map(
                                (result) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    result,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 14,
                                      color: result.startsWith('âŒ')
                                          ? Colors.red
                                          : result.startsWith('âœ…')
                                              ? Colors.green
                                              : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Fixes to Try:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '1. If Internet fails: Check your WiFi/network connection',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '2. If API fails: Check if api.qauto.com is accessible in your browser',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '3. If Firebase fails: Check if Firebase is accessible',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '4. Try restarting your router/modem',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '5. Try using mobile data instead of WiFi',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _runQuickTest,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Test Again'),
                        style: AppTheme.elevatedButtonStyle,
                      ),
                    ),
                  ],
                ),
              ),
      );
}
