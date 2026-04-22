import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/requestor_home_navigation.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/requestor_more_menu.dart';
import 'requestor_status_screen.dart';

class SubmissionSuccessScreen extends StatelessWidget {
  const SubmissionSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        showMenu: false,
        onMoreTap: () {
          showRequestorMoreMenu(
            context,
            primaryLabel: 'Home',
            primaryIcon: Icons.home_outlined,
            onPrimaryNav: () => navigateToRequestorMain(context),
          );
        },
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppTheme.accentGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              Text(
                'Your request has been sent.',
                style: AppTheme.heading2.copyWith(
                  color: AppTheme.darkTextColor,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXL),
              // View my requests (then pop success so back goes to main)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RequestorStatusScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.list, size: 20),
                label: const Text('View my requests'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXL,
                    vertical: AppTheme.spacingM,
                  ),
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              TextButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Text(
                  'Done',
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

