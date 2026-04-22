import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../utils/app_theme.dart';

class ConnectivityTestScreen extends StatefulWidget {
  const ConnectivityTestScreen({super.key});

  @override
  State<ConnectivityTestScreen> createState() => _ConnectivityTestScreenState();
}

class _ConnectivityTestScreenState extends State<ConnectivityTestScreen> {
  bool _isLoading = false;
  List<String> _testResults = [];

  @override
  void initState() {
    super.initState();
    _runConnectivityTests();
  }

  Future<void> _runConnectivityTests() async {
    setState(() {
      _isLoading = true;
      _testResults = [];
    });

    final results = <String>[];

    try {
      // Test 1: Basic internet connectivity
      results.add('ðŸ” Testing basic internet connectivity...');
      try {
        final response = await http
            .get(
              Uri.parse('https://www.google.com'),
            )
            .timeout(const Duration(seconds: 5));
        results.add('âœ… Google.com: ${response.statusCode}');
      } catch (e) {
        results.add('âŒ Google.com: $e');
      }

      // Test 2: Firebase connectivity
      results.add('ðŸ” Testing Firebase connectivity...');
      try {
        final response = await http
            .get(
              Uri.parse('https://firestore.googleapis.com'),
            )
            .timeout(const Duration(seconds: 5));
        results.add('âœ… Firebase: ${response.statusCode}');
      } catch (e) {
        results.add('âŒ Firebase: $e');
      }

      // Test 3: Your API connectivity
      results.add('ðŸ” Testing your API connectivity...');
      try {
        final response = await http
            .get(
              Uri.parse('https://api.qauto.com'),
            )
            .timeout(const Duration(seconds: 5));
        results.add('âœ… API: ${response.statusCode}');
      } catch (e) {
        results.add('âŒ API: $e');
      }

      // Test 4: Specific API endpoint
      results.add('ðŸ” Testing API assets endpoint...');
      try {
        final response = await http.get(
          Uri.parse('https://api.qauto.com/assets?limit=1'),
          headers: {
            'Authorization': 'Bearer cmms-maintenance',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 5));
        results.add('âœ… API Assets: ${response.statusCode}');
        if (response.statusCode == 200) {
          results.add('ðŸ“Š Response: ${response.body.substring(0, 100)}...');
        }
      } catch (e) {
        results.add('âŒ API Assets: $e');
      }

      // Test 5: Firebase Firestore endpoint
      results.add('ðŸ” Testing Firebase Firestore endpoint...');
      try {
        final response = await http
            .get(
              Uri.parse(
                'https://firestore.googleapis.com/v1/projects/qauto-dam/databases/(default)/documents?pageSize=1',
              ),
            )
            .timeout(const Duration(seconds: 5));
        results.add('âœ… Firestore: ${response.statusCode}');
      } catch (e) {
        results.add('âŒ Firestore: $e');
      }
    } catch (e) {
      results.add('âŒ Connectivity test error: $e');
    }

    setState(() {
      _isLoading = false;
      _testResults = results;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Connectivity Test'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _runConnectivityTests,
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
                              'Connectivity Test Results',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_testResults.isNotEmpty)
                              ..._testResults.map(
                                (result) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    result,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
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
                              'Troubleshooting',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '1. If Google.com fails: Check your internet connection',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '2. If Firebase fails: Check if Firebase is accessible from your network',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '3. If API fails: Check if api.qauto.com is accessible',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '4. If Firestore fails: Check your Firebase project configuration',
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
                        onPressed: _runConnectivityTests,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Run Tests Again'),
                        style: AppTheme.elevatedButtonStyle,
                      ),
                    ),
                  ],
                ),
              ),
      );
}
