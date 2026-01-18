import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../events/controllers/events_controller.dart';
import '../../events/models/event_model.dart';
import '../../events/views/widgets/event_card.dart';
import '../../events/views/widgets/empty_events_widget.dart';
import '../../../core/routes/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late EventsController _eventsController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Use Get.find if already registered, otherwise put a new one
    if (Get.isRegistered<EventsController>()) {
      _eventsController = Get.find<EventsController>();
    } else {
      _eventsController = Get.put(EventsController());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final user = authController.user.value;
          return Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: user?.fullName != null && user!.fullName!.isNotEmpty
                    ? Text(
                        user.fullName![0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Welcome',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Ahadi',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'logout') {
                await authController.signOut();
                Get.offAllNamed(AppRoutes.publicEvents);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Events'),
            Tab(text: 'Joined'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMyEventsTab(), _buildJoinedEventsTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.createEvent),
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
    );
  }

  Widget _buildMyEventsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        _eventsController.myEventsPagingController.refresh();
      },
      child: PagedListView<int, EventModel>(
        pagingController: _eventsController.myEventsPagingController,
        padding: const EdgeInsets.all(16),
        builderDelegate: PagedChildBuilderDelegate<EventModel>(
          itemBuilder: (context, event, index) => EventCard(
            event: event,
            onTap: () => Get.toNamed(
              AppRoutes.eventDetail,
              arguments: {'eventId': event.id},
            ),
          ),
          firstPageProgressIndicatorBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          newPageProgressIndicatorBuilder: (_) => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          firstPageErrorIndicatorBuilder: (context) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Failed to load events', style: AppTextStyles.bodyLarge),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () =>
                      _eventsController.myEventsPagingController.refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          noItemsFoundIndicatorBuilder: (_) => EmptyEventsWidget(
            title: 'No Events Yet',
            subtitle:
                'Create your first event to start collecting contributions',
            icon: Icons.event_note,
            actionLabel: 'Create Event',
            onAction: () => Get.toNamed(AppRoutes.createEvent),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinedEventsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        _eventsController.invitedEventsPagingController.refresh();
      },
      child: PagedListView<int, EventModel>(
        pagingController: _eventsController.invitedEventsPagingController,
        padding: const EdgeInsets.all(16),
        builderDelegate: PagedChildBuilderDelegate<EventModel>(
          itemBuilder: (context, event, index) => EventCard(
            event: event,
            onTap: () => Get.toNamed(
              AppRoutes.eventDetail,
              arguments: {'eventId': event.id},
            ),
          ),
          firstPageProgressIndicatorBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          newPageProgressIndicatorBuilder: (_) => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          firstPageErrorIndicatorBuilder: (context) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Failed to load events', style: AppTextStyles.bodyLarge),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () =>
                      _eventsController.invitedEventsPagingController.refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          noItemsFoundIndicatorBuilder: (_) => EmptyEventsWidget(
            title: 'No Joined Events',
            subtitle: 'Events you join will appear here',
            icon: Icons.group_outlined,
            actionLabel: 'Browse Events',
            onAction: () => Get.offAllNamed(AppRoutes.publicEvents),
          ),
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    // TODO: Implement search functionality
    Get.snackbar(
      'Coming Soon',
      'Search functionality will be available soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
