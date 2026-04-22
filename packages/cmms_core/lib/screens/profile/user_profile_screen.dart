import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/cmms_app_mode_scope.dart';
import '../../config/cmms_app_mode.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_database_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/requestor_home_navigation.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/requestor_more_menu.dart';

/// Read-only account summary for the signed-in user.
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String? _companyName;
  bool _companyLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_companyLoaded) {
      _companyLoaded = true;
      unawaited(_loadCompanyName()); // fire-and-forget load
    }
  }

  Future<void> _loadCompanyName() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final id = user?.companyId;
    if (id == null || id.isEmpty) {
      if (mounted) setState(() {});
      return;
    }
    final company = await SupabaseDatabaseService.instance.getCompanyById(id);
    if (mounted) {
      setState(() {
        _companyName = company?.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        final user = auth.currentUser;
        if (user == null) {
          return Scaffold(
            appBar: CustomAppBar(
              title: 'Profile',
              usePageTitle: true,
              showMenu: false,
              showBackButton: true,
              onMoreTap: CmmsAppModeScope.maybeOf(context) == CmmsAppMode.requestor
                  ? () {
                      showRequestorMoreMenu(
                        context,
                        primaryLabel: 'Home',
                        primaryIcon: Icons.home_outlined,
                        onPrimaryNav: () => navigateToRequestorMain(context),
                      );
                    }
                  : null,
            ),
            body: const Center(
              child: Text('Not signed in'),
            ),
          );
        }
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: CustomAppBar(
            title: 'Profile',
            usePageTitle: true,
            showMenu: false,
            showBackButton: true,
            onMoreTap: CmmsAppModeScope.maybeOf(context) == CmmsAppMode.requestor
                ? () {
                    showRequestorMoreMenu(
                      context,
                      primaryLabel: 'Home',
                      primaryIcon: Icons.home_outlined,
                      onPrimaryNav: () => navigateToRequestorMain(context),
                    );
                  }
                : null,
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            children: [
              _ProfileHeader(user: user),
              const SizedBox(height: AppTheme.spacingL),
              _InfoCard(
                title: 'Account',
                children: [
                  _profileInfoRow(Icons.person_outline, 'Name', user.name),
                  _profileInfoRow(Icons.email_outlined, 'Email', user.email),
                  if (user.workEmail != null && user.workEmail!.isNotEmpty)
                    _profileInfoRow(
                      Icons.work_outline,
                      'Work email',
                      user.workEmail!,
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              _InfoCard(
                title: 'Organization',
                children: [
                  _profileInfoRow(
                    Icons.badge_outlined,
                    'Role',
                    _formatUserRole(user.role),
                  ),
                  if (user.department != null &&
                      user.department!.trim().isNotEmpty)
                    _profileInfoRow(
                      Icons.apartment,
                      'Department',
                      user.department!.trim(),
                    ),
                  _profileInfoRow(
                    Icons.business,
                    'Company',
                    _companyName ??
                        (user.companyId != null && user.companyId!.isNotEmpty
                            ? 'Loading…'
                            : '—'),
                  ),
                  if (user.companyId != null && user.companyId!.isNotEmpty)
                    _profileInfoRow(
                      Icons.tag,
                      'Company ID',
                      user.companyId!,
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              _InfoCard(
                title: 'Account status',
                children: [
                  _profileInfoRow(
                    Icons.verified_user_outlined,
                    'Status',
                    user.isActive ? 'Active' : 'Inactive',
                  ),
                  _profileInfoRow(
                    Icons.calendar_today_outlined,
                    'Member since',
                    _formatUserDate(user.createdAt),
                  ),
                  if (user.lastLoginAt != null)
                    _profileInfoRow(
                      Icons.login,
                      'Last sign-in',
                      _formatUserDate(user.lastLoginAt!),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final trimmed = user.name.trim();
    final initial =
        trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';

    return Card(
      elevation: AppTheme.elevationS,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppTheme.accentGreen.withValues(alpha: 0.2),
              child: Text(
                initial,
                style: AppTheme.heading1.copyWith(
                  color: AppTheme.accentGreen,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: AppTheme.heading2),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: AppTheme.bodyText.copyWith(
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppTheme.elevationS,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTheme.heading2.copyWith(fontSize: 16),
            ),
            const SizedBox(height: AppTheme.spacingS),
            ...children,
          ],
        ),
      ),
    );
  }
}

Widget _profileInfoRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.accentGreen),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.captionText.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTheme.bodyText,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String _formatUserRole(String role) {
  if (role.isEmpty) {
    return '—';
  }
  return role[0].toUpperCase() + role.substring(1);
}

String _formatUserDate(DateTime d) {
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
