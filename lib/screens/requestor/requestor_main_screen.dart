import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/asset.dart';
import '../../models/work_order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/unified_data_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/notification_widget.dart';
import '../../widgets/custom_app_bar.dart';
import 'asset_selection_screen.dart';
import 'create_maintenance_request_screen.dart';
import 'requestor_analytics_screen.dart';
import 'requestor_notification_settings_screen.dart';
import 'requestor_status_screen.dart';

class RequestorMainScreen extends StatefulWidget {
  const RequestorMainScreen({super.key});

  @override
  State<RequestorMainScreen> createState() => _RequestorMainScreenState();
}

class _RequestorMainScreenState extends State<RequestorMainScreen> {

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFE5E7EB),
        appBar: CustomAppBar(
          title: 'Maintenance Request',
          showMenu: false,
          onMoreTap: () {
            final userId = Provider.of<AuthProvider>(context, listen: false)
                .currentUser
                ?.id;
            // Show more options menu
            showModalBottomSheet(
              context: context,
              builder: (context) => Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NotificationBadge(
                      userId: userId,
                      child: ListTile(
                        leading: const Icon(Icons.notifications),
                        title: const Text('Notifications'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const NotificationListScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('View My Requests'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RequestorStatusScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.analytics),
                      title: const Text('Analytics'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const RequestorAnalyticsScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications_active),
                      title: const Text('Notification Settings'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const RequestorNotificationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout, color: AppTheme.accentRed),
                      title: const Text('Logout'),
                      onTap: () {
                        Navigator.pop(context);
                        _handleLogout();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        body: _buildMainContent(),
      );

  Widget _buildMainContent() {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    final padding = ResponsiveLayout.getResponsivePadding(context);
    final maxWidth = ResponsiveLayout.getMaxContentWidth(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero card that extends all the way down
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      ResponsiveLayout.getResponsiveBorderRadius(context),
                    ),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/MaintenanceRequestBg.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and subtitle inside hero - icon on top, text below
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(
                              ResponsiveLayout.getResponsiveSpacing(
                                context,
                                mobile: AppTheme.spacingM,
                                tablet: AppTheme.spacingL,
                                desktop: AppTheme.spacingXL,
                              ),
                            ),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Icon(
                              Icons.build,
                              size: ResponsiveLayout.getResponsiveIconSize(
                                context,
                                mobile: 28,
                                tablet: 32,
                                desktop: 36,
                              ),
                              color: AppTheme.accentGreen,
                            ),
                          ),
                          SizedBox(height: ResponsiveLayout.getResponsiveSpacing(
                            context,
                            mobile: AppTheme.spacingL,
                            tablet: AppTheme.spacingXL,
                            desktop: AppTheme.spacingXXL,
                          )),
                          Text(
                            'Request Maintenance',
                            style: AppTheme.heading1.copyWith(
                              color: Colors.white,
                              fontSize: ResponsiveLayout.getResponsiveFontSize(
                                context,
                                mobile: 24,
                                tablet: 28,
                                desktop: 32,
                              ),
                            ),
                          ),
                          SizedBox(height: ResponsiveLayout.getResponsiveSpacing(
                            context,
                            mobile: AppTheme.spacingS,
                            tablet: AppTheme.spacingM,
                            desktop: AppTheme.spacingL,
                          )),
                          Text(
                            'Select an asset to request maintenance work',
                            style: AppTheme.bodyText.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: ResponsiveLayout.getResponsiveFontSize(
                                context,
                                mobile: 14,
                                tablet: 16,
                                desktop: 18,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Spacer to push cards to bottom
                      const Spacer(),

                      // Bottom section: label + two option cards
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose how to select an asset:',
                            style: AppTheme.heading2.copyWith(
                              color: Colors.white,
                              fontSize: ResponsiveLayout.getResponsiveFontSize(
                                context,
                                mobile: 18,
                                tablet: 20,
                                desktop: 22,
                              ),
                            ),
                          ),
                          SizedBox(height: ResponsiveLayout.getResponsiveSpacing(
                            context,
                            mobile: AppTheme.spacingM,
                            tablet: AppTheme.spacingL,
                            desktop: AppTheme.spacingXL,
                          )),
                          // Responsive layout: side-by-side on desktop/tablet, stacked on mobile
                          ResponsiveWidget(
                            mobile: Column(
                              children: [
                                _buildHeroActionCard(
                                  icon: Icons.qr_code_scanner,
                                  title: 'Siemens',
                                  description: '',
                                  imagePath: 'assets/images/SiemensCharger.png',
                                  onTap: () => _navigateToMaintenanceForm('Siemens'),
                                ),
                                SizedBox(height: ResponsiveLayout.getResponsiveSpacing(
                                  context,
                                  mobile: AppTheme.spacingM,
                                  tablet: AppTheme.spacingL,
                                  desktop: AppTheme.spacingXL,
                                )),
                                _buildHeroActionCard(
                                  icon: Icons.search,
                                  title: 'Kostad',
                                  description: '',
                                  imagePath: 'assets/images/KostadCharger.png',
                                  onTap: () => _navigateToMaintenanceForm('Kostad'),
                                ),
                              ],
                            ),
                            tablet: Row(
                              children: [
                                Expanded(
                                  child: _buildHeroActionCard(
                                    icon: Icons.qr_code_scanner,
                                    title: 'Siemens',
                                    description: '',
                                    imagePath: 'assets/images/SiemensCharger.png',
                                    onTap: () => _navigateToMaintenanceForm('Siemens'),
                                  ),
                                ),
                                SizedBox(width: ResponsiveLayout.getResponsiveSpacing(
                                  context,
                                  mobile: AppTheme.spacingM,
                                  tablet: AppTheme.spacingL,
                                  desktop: AppTheme.spacingXL,
                                )),
                                Expanded(
                                  child: _buildHeroActionCard(
                                    icon: Icons.search,
                                    title: 'Kostad',
                                    description: '',
                                    imagePath: 'assets/images/KostadCharger.png',
                                    onTap: () => _navigateToMaintenanceForm('Kostad'),
                                  ),
                                ),
                              ],
                            ),
                            desktop: Row(
                              children: [
                                Expanded(
                                  child: _buildHeroActionCard(
                                    icon: Icons.qr_code_scanner,
                                    title: 'Siemens',
                                    description: '',
                                    imagePath: 'assets/images/SiemensCharger.png',
                                    onTap: () => _navigateToMaintenanceForm('Siemens'),
                                  ),
                                ),
                                SizedBox(width: ResponsiveLayout.getResponsiveSpacing(
                                  context,
                                  mobile: AppTheme.spacingM,
                                  tablet: AppTheme.spacingL,
                                  desktop: AppTheme.spacingXL,
                                )),
                                Expanded(
                                  child: _buildHeroActionCard(
                                    icon: Icons.search,
                                    title: 'Kostad',
                                    description: '',
                                    imagePath: 'assets/images/KostadCharger.png',
                                    onTap: () => _navigateToMaintenanceForm('Kostad'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// White option card used inside the green hero panel, matching the design.
  Widget _buildHeroActionCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    String? imagePath,
  }) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    
    return Material(
      borderRadius: BorderRadius.circular(
        ResponsiveLayout.getResponsiveBorderRadius(context),
      ),
      color: Colors.white,
      elevation: ResponsiveLayout.getResponsiveElevation(context),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          ResponsiveLayout.getResponsiveBorderRadius(context),
        ),
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(
            minHeight: ResponsiveLayout.getResponsiveSpacing(
              context,
              mobile: 200,
              tablet: 220,
              desktop: 240,
            ),
          ),
          padding: EdgeInsets.all(
            ResponsiveLayout.getResponsiveSpacing(
              context,
              mobile: AppTheme.spacingM,
              tablet: AppTheme.spacingL,
              desktop: AppTheme.spacingXL,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show image if provided, otherwise show icon
              if (imagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    ResponsiveLayout.getResponsiveBorderRadius(context),
                  ),
                  child: Image.asset(
                    imagePath,
                    height: ResponsiveLayout.getResponsiveSpacing(
                      context,
                      mobile: 160,
                      tablet: 180,
                      desktop: 200,
                    ),
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to icon if image fails to load
                      return Container(
                        padding: EdgeInsets.all(
                          ResponsiveLayout.getResponsiveSpacing(
                            context,
                            mobile: AppTheme.spacingS,
                            tablet: AppTheme.spacingM,
                            desktop: AppTheme.spacingL,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                            ResponsiveLayout.getResponsiveBorderRadius(context),
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: ResponsiveLayout.getResponsiveIconSize(
                            context,
                            mobile: 24,
                            tablet: 28,
                            desktop: 32,
                          ),
                          color: AppTheme.accentGreen,
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveLayout.getResponsiveSpacing(
                      context,
                      mobile: AppTheme.spacingS,
                      tablet: AppTheme.spacingM,
                      desktop: AppTheme.spacingL,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(
                      ResponsiveLayout.getResponsiveBorderRadius(context),
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: ResponsiveLayout.getResponsiveIconSize(
                      context,
                      mobile: 24,
                      tablet: 28,
                      desktop: 32,
                    ),
                    color: AppTheme.accentGreen,
                  ),
                ),
              SizedBox(height: ResponsiveLayout.getResponsiveSpacing(
                context,
                mobile: AppTheme.spacingM,
                tablet: AppTheme.spacingL,
                desktop: AppTheme.spacingXL,
              )),
              Text(
                title,
                style: AppTheme.heading2.copyWith(
                  color: AppTheme.darkTextColor,
                  fontSize: ResponsiveLayout.getResponsiveFontSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  ),
                ),
              ),
              if (description.isNotEmpty) ...[
                SizedBox(height: ResponsiveLayout.getResponsiveSpacing(
                  context,
                  mobile: AppTheme.spacingXS,
                  tablet: AppTheme.spacingS,
                  desktop: AppTheme.spacingM,
                )),
                Text(
                  description,
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.secondaryTextColor,
                    fontSize: ResponsiveLayout.getResponsiveFontSize(
                      context,
                      mobile: 12,
                      tablet: 14,
                      desktop: 16,
                    ),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Card(
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: color,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.heading2.copyWith(
                          color: AppTheme.darkTextColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        description,
                        style: AppTheme.bodyText.copyWith(
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.secondaryTextColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _navigateToAssetSelection(int initialTab) async {
    final result = await Navigator.push<Asset?>(
      context,
      MaterialPageRoute(
        builder: (context) => AssetSelectionScreen(initialTab: initialTab),
      ),
    );

    // If an asset was selected, navigate to create maintenance request screen
    if (result != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateMaintenanceRequestScreen(
            asset: result,
            qrCode: '', // QR code can be passed if needed
          ),
        ),
      );
    }
  }

  /// Navigate directly to maintenance form with charger type
  void _navigateToMaintenanceForm(String chargerType) {
    // Create a placeholder asset for the charger
    final chargerAsset = Asset(
      id: chargerType.toLowerCase(),
      name: '$chargerType Charger',
      location: '',
      manufacturer: chargerType,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateMaintenanceRequestScreen(
          asset: chargerAsset,
          qrCode: '',
          chargerType: chargerType,
        ),
      ),
    );
  }

  Widget _buildQuickStatusOverview() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return const SizedBox.shrink();

    return Selector<UnifiedDataProvider, List<WorkOrder>>(
      selector: (_, provider) => provider.workOrders
          .where((wo) => wo.requestorId == user.id)
          .toList(),
      builder: (context, requests, child) {

        final activeRequests = requests
            .where(
              (r) =>
                  r.status != WorkOrderStatus.completed &&
                  r.status != WorkOrderStatus.closed,
            )
            .length;

        if (activeRequests == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.accentBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: AppTheme.accentBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.accentBlue,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Text(
                  'You have $activeRequests active maintenance request${activeRequests == 1 ? '' : 's'}.',
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.accentBlue,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RequestorStatusScreen(),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accentRed,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await authProvider.logout();
    }
  }
}
