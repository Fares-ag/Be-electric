import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/cmms_package_assets.dart';

/// Custom AppBar with BE-ELECTRIC logo, hamburger menu, and ellipsis menu
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.onMenuTap,
    this.onMoreTap,
    this.actions,
    this.title,
    this.usePageTitle = false,
    this.automaticallyImplyLeading = false,
    this.showMenu = true,
    this.showBackButton = false,
  });

  final VoidCallback? onMenuTap;
  final VoidCallback? onMoreTap;
  final List<Widget>? actions;
  final String? title;
  /// When true and [title] is set, show centered text (subpages). Otherwise show logo.
  final bool usePageTitle;
  final bool automaticallyImplyLeading;
  final bool showMenu;
  final bool showBackButton;

  @override
  Size get preferredSize => const Size.fromHeight(80);

  Widget? _buildLeading(BuildContext context) {
    if (showBackButton) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Back',
      );
    }
    if (showMenu) {
      return IconButton(
        icon: const Icon(Icons.menu),
        onPressed: onMenuTap ?? () {
          Scaffold.of(context).openDrawer();
        },
        tooltip: 'Menu',
      );
    }
    return null;
  }

  Widget? _buildTitleWidget() {
    if (usePageTitle && title != null && title!.isNotEmpty) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          title!,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.heading2.copyWith(
            color: AppTheme.darkTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Image.asset(
      'assets/images/beElectricLogo.png',
      package: kCmmsCoreAssetPackage,
      height: 140,
      width: 140,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.bolt,
          color: AppTheme.accentGreen,
          size: 120,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.darkTextColor,
      elevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: _buildLeading(context),
      title: _buildTitleWidget(),
      toolbarHeight: 80,
      centerTitle: true,
      actions: [
        ...?actions,
        // Only show default 3-dots menu if onMoreTap is provided AND actions don't already include a menu
        if (onMoreTap != null) 
          Builder(
            builder: (context) {
              // Check if actions already include a PopupMenuButton
              final hasMenu = actions != null && 
                  actions!.isNotEmpty &&
                  actions!.any((action) => action is PopupMenuButton);
              
              // Only show default menu if no menu already exists
              if (!hasMenu) {
                return IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: onMoreTap,
                  tooltip: 'More options',
                );
              }
              return const SizedBox.shrink();
            },
          ),
      ],
    );
  }
}

