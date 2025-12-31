import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_theme.dart';

class UriTestScreen extends StatefulWidget {
  const UriTestScreen({super.key});

  @override
  State<UriTestScreen> createState() => _UriTestScreenState();
}

class _UriTestScreenState extends State<UriTestScreen> {
  final List<Map<String, String>> _testUrls = [
    {
      'name': 'Firebase Collections',
      'url':
          'https://firestore.googleapis.com/v1/projects/qauto-dam/databases/(default)/documents?pageSize=1',
      'description': 'Test Firebase project access',
    },
    {
      'name': 'Firebase Items Collection',
      'url':
          'https://firestore.googleapis.com/v1/projects/qauto-dam/databases/(default)/documents/items?pageSize=1',
      'description': 'Test Firebase items collection',
    },
    {
      'name': 'API Assets Endpoint',
      'url': 'https://api.qauto.com/assets?limit=1',
      'description': 'Test your API server',
    },
    {
      'name': 'Google (Basic Internet)',
      'url': 'https://www.google.com',
      'description': 'Test basic internet connectivity',
    },
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('URI Test'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'URI Test Instructions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap each URL below to test if it opens in your browser. This will tell us if the URIs are correct and accessible.',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Expected Results:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'â€¢ Google: Should open Google homepage\nâ€¢ Firebase: Should show JSON or error message\nâ€¢ API: Should show JSON or error message',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ..._testUrls.map(
                (testUrl) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.link, color: AppTheme.accentBlue),
                    title: Text(testUrl['name']!),
                    subtitle: Text(testUrl['description']!),
                    trailing: const Icon(Icons.open_in_browser),
                    onTap: () async {
                      final uri = Uri.parse(testUrl['url']!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Cannot open ${testUrl['name']}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
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
                        'What to Look For:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'âœ… Google opens: Internet works',
                        style: TextStyle(fontSize: 14, color: Colors.green),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'âœ… Firebase shows JSON: Project exists and accessible',
                        style: TextStyle(fontSize: 14, color: Colors.green),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'âœ… API shows JSON: Your API server is working',
                        style: TextStyle(fontSize: 14, color: Colors.green),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'âŒ Any URL fails to open: Network connectivity issue',
                        style: TextStyle(fontSize: 14, color: Colors.red),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'âŒ Firebase shows error: Project/database issue',
                        style: TextStyle(fontSize: 14, color: Colors.red),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'âŒ API shows error: Server down or wrong URL',
                        style: TextStyle(fontSize: 14, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
