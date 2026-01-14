import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../../features/auth/controllers/auth_controller.dart';

/// Dashboard content types
enum DashboardContent {
  events,
  createEvent,
  editEvent,
  eventDetail,
  contributions,
  addContribution,
  paymentCheckout,
  participants,
  invitations,
  messages,
  discover,
  calendar,
  settings,
  profile,
}

/// Controller to manage dashboard state and navigation
class DashboardController extends GetxController {
  final Rx<DashboardContent> currentContent = DashboardContent.events.obs;
  final RxList<DashboardContent> navigationStack = <DashboardContent>[].obs;
  final RxMap<String, dynamic> contentArgs = <String, dynamic>{}.obs;

  // Breadcrumb items
  final RxList<BreadcrumbItem> breadcrumbs = <BreadcrumbItem>[].obs;

  void navigateTo(DashboardContent content, {Map<String, dynamic>? args}) {
    navigationStack.add(currentContent.value);
    currentContent.value = content;
    if (args != null) {
      contentArgs.value = args;
    }
    _updateBreadcrumbs();
  }

  void goBack() {
    if (navigationStack.isNotEmpty) {
      currentContent.value = navigationStack.removeLast();
      _updateBreadcrumbs();
    }
  }

  void goToRoot(DashboardContent content) {
    navigationStack.clear();
    currentContent.value = content;
    contentArgs.clear();
    _updateBreadcrumbs();
  }

  bool get canGoBack => navigationStack.isNotEmpty;

  void _updateBreadcrumbs() {
    final items = <BreadcrumbItem>[];

    // Always add root
    items.add(
      BreadcrumbItem(
        label: 'Events',
        onTap: () => goToRoot(DashboardContent.events),
      ),
    );

    switch (currentContent.value) {
      case DashboardContent.eventDetail:
        final eventTitle = contentArgs['eventTitle'] as String? ?? 'Event';
        items.add(BreadcrumbItem(label: eventTitle));
        break;
      case DashboardContent.contributions:
        final eventTitle = contentArgs['eventTitle'] as String? ?? 'Event';
        items.add(BreadcrumbItem(label: eventTitle, onTap: () => goBack()));
        items.add(BreadcrumbItem(label: 'Contributions'));
        break;
      case DashboardContent.addContribution:
        final eventTitle = contentArgs['eventTitle'] as String? ?? 'Event';
        items.add(
          BreadcrumbItem(
            label: eventTitle,
            onTap: () {
              goBack();
              goBack();
            },
          ),
        );
        items.add(
          BreadcrumbItem(label: 'Contributions', onTap: () => goBack()),
        );
        items.add(BreadcrumbItem(label: 'Add'));
        break;
      case DashboardContent.paymentCheckout:
        final eventTitle = contentArgs['eventTitle'] as String? ?? 'Event';
        items.add(
          BreadcrumbItem(
            label: eventTitle,
            onTap: () {
              goBack();
              goBack();
            },
          ),
        );
        items.add(
          BreadcrumbItem(label: 'Contributions', onTap: () => goBack()),
        );
        items.add(BreadcrumbItem(label: 'Payment'));
        break;
      case DashboardContent.participants:
        final eventTitle = contentArgs['eventTitle'] as String? ?? 'Event';
        items.add(BreadcrumbItem(label: eventTitle, onTap: () => goBack()));
        items.add(BreadcrumbItem(label: 'Participants'));
        break;
      case DashboardContent.createEvent:
        items.add(BreadcrumbItem(label: 'Create Event'));
        break;
      case DashboardContent.editEvent:
        final eventTitle = contentArgs['eventTitle'] as String? ?? 'Event';
        items.add(BreadcrumbItem(label: eventTitle, onTap: () => goBack()));
        items.add(BreadcrumbItem(label: 'Edit'));
        break;
      default:
        break;
    }

    breadcrumbs.value = items;
  }
}

/// Breadcrumb item data
class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;

  BreadcrumbItem({required this.label, this.onTap});
}

/// Navigation item for the sidebar
class NavItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final DashboardContent? content;
  final VoidCallback? onTap;

  const NavItem({
    required this.id,
    required this.label,
    required this.icon,
    this.activeIcon,
    this.content,
    this.onTap,
  });
}

/// Main dashboard shell - single layout that renders all content
class DashboardShell extends StatelessWidget {
  final Widget content;
  final Widget? sidebarContent;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const DashboardShell({
    super.key,
    required this.content,
    this.sidebarContent,
    this.actions,
    this.floatingActionButton,
  });

  static final List<NavItem> mainNavItems = [
    NavItem(
      id: 'events',
      label: 'My Events',
      icon: Icons.event_outlined,
      activeIcon: Icons.event,
      content: DashboardContent.events,
    ),
    NavItem(
      id: 'discover',
      label: 'Discover',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      content: DashboardContent.discover,
    ),
    NavItem(
      id: 'messages',
      label: 'Messages',
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      content: DashboardContent.messages,
    ),
    NavItem(
      id: 'calendar',
      label: 'Calendar',
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month,
      content: DashboardContent.calendar,
    ),
    NavItem(
      id: 'profile',
      label: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      content: DashboardContent.profile,
    ),
  ];

  // Event detail specific navigation items
  static final List<NavItem> eventNavItems = [
    NavItem(
      id: 'overview',
      label: 'Overview',
      icon: Icons.info_outline,
      activeIcon: Icons.info,
      content: DashboardContent.eventDetail,
    ),
    NavItem(
      id: 'contributions',
      label: 'Contributions',
      icon: Icons.volunteer_activism_outlined,
      activeIcon: Icons.volunteer_activism,
      content: DashboardContent.contributions,
    ),
    NavItem(
      id: 'participants',
      label: 'Participants',
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      content: DashboardContent.participants,
    ),
    NavItem(
      id: 'messages',
      label: 'Messages',
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      content: DashboardContent.messages,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = kIsWeb && screenWidth >= 800;
    final dashboardController = Get.find<DashboardController>();

    if (isWideScreen) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            _buildNavbar(context, dashboardController),
            Expanded(
              child: Row(
                children: [
                  _buildSidebar(context, dashboardController),
                  Expanded(child: content),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    // Mobile layout
    return Obx(() {
      final current = dashboardController.currentContent.value;
      final hideBottomNav = current == DashboardContent.messages;
      
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildMobileAppBar(context, dashboardController),
        body: content,
        bottomNavigationBar: hideBottomNav ? null : _buildBottomNav(context, dashboardController),
        floatingActionButton: floatingActionButton,
      );
    });
  }

  PreferredSizeWidget _buildMobileAppBar(
    BuildContext context,
    DashboardController dashboardController,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Obx(() {
      final current = dashboardController.currentContent.value;
      final isMessagesView = current == DashboardContent.messages;
      
      if (isMessagesView) {
        // ChatScreen has its own AppBar, return empty
        return const SizedBox.shrink();
      }
      
      // Default AppBar for other views
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: dashboardController.canGoBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => dashboardController.goBack(),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Get.offAllNamed('/public/events'),
              ),
        title: () {
          final breadcrumbs = dashboardController.breadcrumbs;
          if (breadcrumbs.isEmpty) return const Text('Ahadi');
          return Text(
            breadcrumbs.last.label,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          );
        }(),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          // Profile button
          _buildProfileButton(),
          const SizedBox(width: 8),
        ],
      );
      }),
    );
  }

  /// Build profile button for mobile AppBar
  Widget _buildProfileButton() {
    final authController = Get.find<AuthController>();

    return Obx(() {
      final user = authController.user.value;
      final name = user?.fullName;
      final initial = (name != null && name.isNotEmpty)
          ? name[0].toUpperCase()
          : 'U';

      return PopupMenuButton<String>(
        offset: const Offset(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: user?.profilePicture != null
                ? CachedNetworkImage(
                    imageUrl: user!.profilePicture!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.person,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.person,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.primary.withOpacity(0.1),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ),
        itemBuilder: (context) => [
          // User info header
          PopupMenuItem(
            value: 'profile',
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: user?.profilePicture != null
                      ? NetworkImage(user!.profilePicture!)
                      : null,
                  child: user?.profilePicture == null
                      ? Text(
                          initial,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'User',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.phone ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          // Settings option
          const PopupMenuItem(
            value: 'settings',
            child: Row(
              children: [
                Icon(Icons.settings_outlined, size: 20),
                SizedBox(width: 12),
                Text('Settings'),
              ],
            ),
          ),
          // Logout option
          PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, size: 20, color: Colors.red.shade600),
                const SizedBox(width: 12),
                Text('Logout', style: TextStyle(color: Colors.red.shade600)),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          final dashboardController = Get.find<DashboardController>();
          if (value == 'logout') {
            authController.signOut();
          } else if (value == 'profile' || value == 'settings') {
            dashboardController.navigateTo(DashboardContent.profile);
          }
        },
      );
    });
  }

  Widget _buildNavbar(
    BuildContext context,
    DashboardController dashboardController,
  ) {
    final authController = Get.find<AuthController>();

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.celebration,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ahadi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 48),

          // Navigation items
          Expanded(
            child: Obx(
              () {
                // Determine which nav items to show based on current page
                final current = dashboardController.currentContent.value;
                final bool isEventContext = current == DashboardContent.eventDetail ||
                    current == DashboardContent.contributions ||
                    current == DashboardContent.addContribution ||
                    current == DashboardContent.paymentCheckout ||
                    current == DashboardContent.participants ||
                    current == DashboardContent.invitations ||
                    current == DashboardContent.messages;
                
                final navItems = isEventContext 
                    ? eventNavItems 
                    : mainNavItems.where((item) => item.id != 'messages').toList();
                
                return Row(
                  children: navItems.map((item) {
                    final isActive = _isNavItemActive(
                      item,
                      dashboardController.currentContent.value,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton.icon(
                        onPressed: () {
                          if (item.id == 'messages') {
                            // Special handling for messages - check if we have an event context
                            final event = dashboardController.contentArgs['event'];
                            if (event != null) {
                              dashboardController.navigateTo(
                                DashboardContent.messages,
                                args: {
                                  'event': event,
                                  'eventTitle': dashboardController.contentArgs['eventTitle'],
                                },
                              );
                            } else {
                              Get.snackbar(
                                'Select an Event',
                                'Please select an event from "My Events" to view its messages',
                                snackPosition: SnackPosition.BOTTOM,
                                duration: const Duration(seconds: 2),
                              );
                            }
                          } else if (item.content != null) {
                            if (isEventContext && item.content != null) {
                              // In event context, navigate with event args
                              final event = dashboardController.contentArgs['event'];
                              if (event != null) {
                                dashboardController.navigateTo(
                                  item.content!,
                                  args: {
                                    'event': event,
                                    'eventTitle': dashboardController.contentArgs['eventTitle'],
                                  },
                                );
                              }
                            } else {
                              dashboardController.goToRoot(item.content!);
                            }
                          }
                          item.onTap?.call();
                        },
                      icon: Icon(
                        isActive ? (item.activeIcon ?? item.icon) : item.icon,
                        size: 20,
                        color: isActive
                            ? AppColors.primary
                            : Colors.grey.shade600,
                      ),
                      label: Text(
                        item.label,
                        style: TextStyle(
                          color: isActive
                              ? AppColors.primary
                              : Colors.grey.shade600,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: isActive
                            ? AppColors.primary.withOpacity(0.1)
                            : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
              },
            ),
          ),

          // Actions
          if (actions != null) ...actions!,

          // Create Event button
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to create event inside dashboard
              final dashboardController = Get.find<DashboardController>();
              dashboardController.navigateTo(DashboardContent.createEvent);
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Event'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User menu
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Obx(() {
                  final name = authController.user.value?.fullName;
                  final initial = (name != null && name.isNotEmpty)
                      ? name[0].toUpperCase()
                      : 'U';
                  return CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage:
                        authController.user.value?.profilePicture != null
                        ? NetworkImage(
                            authController.user.value!.profilePicture!,
                          )
                        : null,
                    child: authController.user.value?.profilePicture == null
                        ? Text(
                            initial,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  );
                }),
                const SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
              ],
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(
                          () => Text(
                            authController.user.value?.fullName ?? 'User',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Obx(
                          () => Text(
                            authController.user.value?.phone ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red.shade600),
                    const SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                authController.signOut();
              } else if (value == 'profile' || value == 'settings') {
                dashboardController.navigateTo(DashboardContent.profile);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    DashboardController dashboardController,
  ) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Breadcrumbs
          Obx(() {
            final breadcrumbs = dashboardController.breadcrumbs;
            if (breadcrumbs.length <= 1) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  for (int i = 0; i < breadcrumbs.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    Flexible(
                      child: InkWell(
                        onTap: breadcrumbs[i].onTap,
                        child: Text(
                          breadcrumbs[i].label,
                          style: TextStyle(
                            fontSize: 13,
                            color: breadcrumbs[i].onTap != null
                                ? AppColors.primary
                                : Colors.grey.shade600,
                            fontWeight: i == breadcrumbs.length - 1
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

          // Sidebar content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child:
                  sidebarContent ?? _buildDefaultSidebar(dashboardController),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultSidebar(DashboardController dashboardController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NAVIGATION',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        ...mainNavItems.where((item) => item.id != 'messages').map((item) {
          return Obx(() {
            final isActive = _isNavItemActive(
              item,
              dashboardController.currentContent.value,
            );
            return ListTile(
              leading: Icon(
                isActive ? (item.activeIcon ?? item.icon) : item.icon,
                color: isActive ? AppColors.primary : Colors.grey.shade600,
              ),
              title: Text(
                item.label,
                style: TextStyle(
                  color: isActive ? AppColors.primary : Colors.grey.shade800,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isActive,
              selectedTileColor: AppColors.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onTap: () {
                if (item.content != null) {
                  dashboardController.goToRoot(item.content!);
                }
                item.onTap?.call();
              },
            );
          });
        }),
      ],
    );
  }

  Widget _buildBottomNav(
    BuildContext context,
    DashboardController dashboardController,
  ) {
    return Obx(
      () {
        final current = dashboardController.currentContent.value;
        
        // Determine which nav items to show based on current page
        final bool isEventContext = current == DashboardContent.eventDetail ||
            current == DashboardContent.contributions ||
            current == DashboardContent.addContribution ||
            current == DashboardContent.paymentCheckout ||
            current == DashboardContent.participants ||
            current == DashboardContent.invitations ||
            current == DashboardContent.messages;
        
        final navItems = isEventContext 
            ? eventNavItems 
            : mainNavItems.where((item) => item.id != 'messages').toList();
        
        return BottomNavigationBar(
          currentIndex: _getBottomNavIndex(current, isEventContext),
          onTap: (index) {
            if (isEventContext) {
              // Event context navigation
              final contents = [
                DashboardContent.eventDetail,
                DashboardContent.contributions,
                DashboardContent.participants,
                DashboardContent.messages,
              ];
              if (index < contents.length) {
                // Get current event from args
                final event = dashboardController.contentArgs['event'];
                if (event != null) {
                  dashboardController.navigateTo(
                    contents[index],
                    args: {'event': event, 'eventTitle': dashboardController.contentArgs['eventTitle']},
                  );
                }
              }
            } else {
              // Main dashboard navigation
              final contents = [
                DashboardContent.events,
                DashboardContent.discover,
                DashboardContent.calendar,
                DashboardContent.profile,
              ];
              if (index < contents.length) {
                dashboardController.goToRoot(contents[index]);
              }
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey.shade600,
          items: navItems.map((item) {
            final isActive = _isNavItemActive(
              item,
              current,
            );
            return BottomNavigationBarItem(
              icon: Icon(isActive ? (item.activeIcon ?? item.icon) : item.icon),
              label: item.label,
            );
          }).toList(),
        );
      },
    );
  }

  bool _isNavItemActive(NavItem item, DashboardContent current) {
    if (item.content == null) return false;

    // Events section includes event detail, contributions, etc.
    if (item.content == DashboardContent.events) {
      return current == DashboardContent.events ||
          current == DashboardContent.eventDetail ||
          current == DashboardContent.contributions ||
          current == DashboardContent.addContribution ||
          current == DashboardContent.paymentCheckout ||
          current == DashboardContent.participants ||
          current == DashboardContent.invitations;
    }

    return item.content == current;
  }

  int _getBottomNavIndex(DashboardContent current, bool isEventContext) {
    if (isEventContext) {
      // Event detail context
      switch (current) {
        case DashboardContent.eventDetail:
          return 0;
        case DashboardContent.contributions:
        case DashboardContent.addContribution:
        case DashboardContent.paymentCheckout:
          return 1;
        case DashboardContent.messages:
          return 2;
        default:
          return 0;
      }
    } else {
      // Main dashboard context
      switch (current) {
        case DashboardContent.events:
        case DashboardContent.createEvent:
        case DashboardContent.editEvent:
          return 0;
        case DashboardContent.discover:
          return 1;
        case DashboardContent.calendar:
          return 2;
        case DashboardContent.profile:
          return 3;
        default:
          return 0;
      }
    }
  }
}
