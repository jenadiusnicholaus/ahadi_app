import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../../features/auth/controllers/auth_controller.dart';

/// Navigation item for the sidebar
class NavItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final String? route;
  final VoidCallback? onTap;

  const NavItem({
    required this.id,
    required this.label,
    required this.icon,
    this.activeIcon,
    this.route,
    this.onTap,
  });
}

/// Shared dashboard layout for all authenticated pages
class DashboardLayout extends StatelessWidget {
  final String currentRoute;
  final Widget content;
  final Widget? sidebarContent;
  final List<Widget>? actions;
  final String? title;
  final Widget? breadcrumb;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? floatingActionButton;

  const DashboardLayout({
    super.key,
    required this.currentRoute,
    required this.content,
    this.sidebarContent,
    this.actions,
    this.title,
    this.breadcrumb,
    this.showBackButton = false,
    this.onBack,
    this.floatingActionButton,
  });

  static const List<NavItem> mainNavItems = [
    NavItem(
      id: 'events',
      label: 'My Events',
      icon: Icons.event_outlined,
      activeIcon: Icons.event,
      route: AppRoutes.events,
    ),
    NavItem(
      id: 'discover',
      label: 'Discover',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      route: AppRoutes.publicEvents,
    ),
    NavItem(
      id: 'calendar',
      label: 'Calendar',
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month,
    ),
    NavItem(
      id: 'messages',
      label: 'Messages',
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      route: AppRoutes.chat,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Mobile layout - return content directly with optional FAB
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: content,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildUserMenu(AuthController authController) {
    final user = authController.user.value;
    final initial = (user?.fullName?.isNotEmpty == true)
        ? user!.fullName![0].toUpperCase()
        : 'U';

    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              user?.fullName ?? 'User',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, color: Colors.grey.shade700),
              const SizedBox(width: 12),
              const Text('Profile'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, color: Colors.grey.shade700),
              const SizedBox(width: 12),
              const Text('Settings'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red.shade400),
              const SizedBox(width: 12),
              Text('Logout', style: TextStyle(color: Colors.red.shade400)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'profile':
            Get.toNamed(AppRoutes.profile);
            break;
          case 'settings':
            // Get.toNamed(AppRoutes.settings);
            break;
          case 'logout':
            authController.signOut();
            break;
        }
      },
    );
  }

  Widget _buildNavItem(NavItem item) {
    final isActive =
        currentRoute == item.id ||
        (item.route != null && Get.currentRoute == item.route);

    return InkWell(
      onTap: () {
        if (item.onTap != null) {
          item.onTap!();
        } else if (item.route != null && Get.currentRoute != item.route) {
          Get.offAllNamed(item.route!);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? (item.activeIcon ?? item.icon) : item.icon,
              size: 20,
              color: isActive ? AppColors.primary : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Text(
              item.label,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.primary : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: mainNavItems.take(4).map((item) {
              final isActive =
                  currentRoute == item.id ||
                  (item.route != null && Get.currentRoute == item.route);
              return InkWell(
                onTap: () {
                  if (item.onTap != null) {
                    item.onTap!();
                  } else if (item.route != null &&
                      Get.currentRoute != item.route) {
                    Get.offAllNamed(item.route!);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? (item.activeIcon ?? item.icon) : item.icon,
                      color: isActive
                          ? AppColors.primary
                          : Colors.grey.shade500,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isActive
                            ? AppColors.primary
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Helper widget for building breadcrumbs
class DashboardBreadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const DashboardBreadcrumb({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == items.length - 1;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.onTap != null && !isLast)
              InkWell(
                onTap: item.onTap,
                child: Text(
                  item.label,
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              )
            else
              Flexible(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontWeight: isLast ? FontWeight.w500 : FontWeight.normal,
                    color: isLast ? Colors.grey.shade800 : Colors.grey.shade500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;

  const BreadcrumbItem({required this.label, this.onTap});
}
