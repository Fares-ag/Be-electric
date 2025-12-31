import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class WebReportsScreen extends StatelessWidget {
  const WebReportsScreen({super.key});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assessment_outlined,
                size: 64,
                color: AppTheme.secondaryTextColor,
              ),
              SizedBox(height: 16),
              Text(
                'Reports & Exports',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Coming Soon',
                style: TextStyle(color: AppTheme.secondaryTextColor),
              ),
            ],
          ),
        ),
      );
}
