import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Custom AppBar with BE-ELECTRIC logo, hamburger menu, and ellipsis menu
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.onMenuTap,
    this.onMoreTap,
    this.actions,
    this.title,
    this.automaticallyImplyLeading = false,
    this.showMenu = true,
  });

  final VoidCallback? onMenuTap;
  final VoidCallback? onMoreTap;
  final List<Widget>? actions;
  final String? title;
  final bool automaticallyImplyLeading;
  final bool showMenu;

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.darkTextColor,
      elevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: showMenu
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenuTap ?? () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: 'Menu',
            )
          : null,
      title: Image.asset(
        'assets/images/beElectricLogo.png',
        height: 140,
        width: 140,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image fails
          return const Icon(
            Icons.bolt,
            color: AppTheme.accentGreen,
            size: 120,
          );
        },
      ),
      toolbarHeight: 80,
      centerTitle: true,
      actions: [
        ...?actions,
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: onMoreTap,
          tooltip: 'More options',
        ),
      ],
    );
  }
}

