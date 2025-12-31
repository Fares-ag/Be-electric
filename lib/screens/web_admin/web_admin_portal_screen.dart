import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import 'web_analytics_screen.dart';
import 'web_dashboard_screen.dart';
import 'web_inventory_screen.dart';
import 'web_pm_tasks_screen.dart';
import 'web_reports_screen.dart';
import 'web_technicians_screen.dart';
import 'web_users_screen.dart';
import 'web_work_orders_screen.dart';

class WebAdminPortalScreen extends StatefulWidget {
  const WebAdminPortalScreen({super.key});

  @override
  State<WebAdminPortalScreen> createState() => _WebAdminPortalScreenState();
}

class _WebAdminPortalScreenState extends State<WebAdminPortalScreen> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  final List<_NavItem> _navItems = [
    _NavItem('Dashboard', Icons.dashboard, Icons.dashboard_outlined),
    _NavItem('Work Orders', Icons.work, Icons.work_outline),
    _NavItem('PM Tasks', Icons.schedule, Icons.schedule_outlined),
    _NavItem('Analytics', Icons.analytics, Icons.analytics_outlined),
    _NavItem('Inventory', Icons.inventory_2, Icons.inventory_2_outlined),
    _NavItem('Technicians', Icons.engineering, Icons.engineering_outlined),
    _NavItem('Users', Icons.people, Icons.people_outline),
    _NavItem('Reports', Icons.assessment, Icons.assessment_outlined),
  ];

  final List<Widget> _screens = const [
    WebDashboardScreen(),
    WebWorkOrdersScreen(),
    WebPMTasksScreen(),
    WebAnalyticsScreen(),
    WebInventoryScreen(),
    WebTechniciansScreen(),
    WebUsersScreen(),
    WebReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          // Collapsible Sidebar
          _buildSidebar(),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                _buildTopBar(user),
                Expanded(
                  child: _screens[_selectedIndex],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final sidebarWidth = _isSidebarCollapsed ? 80.0 : 280.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo/Brand Area
          _buildSidebarHeader(),
          const Divider(height: 1),
          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;

                return _buildNavItem(item, isSelected, index);
              },
            ),
          ),
          // Collapse Button
          _buildCollapseButton(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() => Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        child: _isSidebarCollapsed
            ? Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings_suggest,
                    color: AppTheme.accentBlue,
                    size: 28,
                  ),
                ),
              )
            : Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.accentBlue, AppTheme.primaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.settings_suggest,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Be Electric',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkTextColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Maintenance Portal',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.secondaryTextColor,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      );

  Widget _buildNavItem(_NavItem item, bool isSelected, int index) => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: _isSidebarCollapsed ? 12 : 16,
          vertical: 4,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accentBlue.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.accentBlue.withOpacity(0.3)
                      : Colors.transparent,
                ),
              ),
              child: _isSidebarCollapsed
                  ? Center(
                      child: Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        color: isSelected
                            ? AppTheme.accentBlue
                            : AppTheme.secondaryTextColor,
                        size: 24,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            color: isSelected
                                ? AppTheme.accentBlue
                                : AppTheme.secondaryTextColor,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppTheme.accentBlue
                                    : AppTheme.darkTextColor,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppTheme.accentBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      );

  Widget _buildCollapseButton() => Padding(
        padding: const EdgeInsets.all(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _isSidebarCollapsed = !_isSidebarCollapsed;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  _isSidebarCollapsed
                      ? Icons.keyboard_arrow_right
                      : Icons.keyboard_arrow_left,
                  color: AppTheme.secondaryTextColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildTopBar(user) => Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            // Page Title
            Text(
              _navItems[_selectedIndex].label,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkTextColor,
              ),
            ),
            const Spacer(),
            // Search Bar
            Container(
              width: 300,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Notifications
            IconButton(
              onPressed: () {},
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_outlined, size: 24),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // User Profile
            PopupMenuButton<String>(
              offset: const Offset(0, 50),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.accentBlue.withOpacity(0.1),
                    child: Text(
                      user?.name?.substring(0, 1).toUpperCase() ?? 'A',
                      style: const TextStyle(
                        color: AppTheme.accentBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user?.name ?? 'Admin',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkTextColor,
                        ),
                      ),
                      Text(
                        user?.role?.toUpperCase() ?? 'ADMIN',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down, size: 20),
                ],
              ),
              onSelected: (value) {
                if (value == 'logout') {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline),
                      SizedBox(width: 12),
                      Text('Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 12),
                      Text('Settings'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Logout', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _NavItem {
  _NavItem(this.label, this.selectedIcon, this.icon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
