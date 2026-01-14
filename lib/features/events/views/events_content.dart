import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../controllers/events_controller.dart';
import '../models/event_model.dart';

/// Events list content - renders inside DashboardShell
class EventsContent extends StatefulWidget {
  final Function(EventModel) onEventTap;
  final int? initialTab;

  const EventsContent({
    super.key, 
    required this.onEventTap,
    this.initialTab,
  });

  @override
  State<EventsContent> createState() => _EventsContentState();
}

class _EventsContentState extends State<EventsContent> {
  @override
  void initState() {
    super.initState();
    // Set initial tab if provided
    if (widget.initialTab != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final controller = Get.find<EventsController>();
        controller.tabController.index = widget.initialTab!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EventsController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = kIsWeb && screenWidth >= 800;

    return Obx(() {
      if (controller.isLoading.value &&
          controller.myEvents.isEmpty &&
          controller.invitedEvents.isEmpty &&
          controller.publicEvents.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      List<EventModel> events;
      switch (controller.selectedTabIndex.value) {
        case 0:
          events = controller.myEvents;
          break;
        case 1:
          events = controller.invitedEvents;
          break;
        case 2:
          events = controller.publicEvents;
          break;
        default:
          events = controller.myEvents;
      }

      if (events.isEmpty) {
        return _buildEmptyState(
          context,
          controller.selectedTabIndex.value,
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.refreshCurrentTab(),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(isWideScreen ? 32 : 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getTabTitle(controller.selectedTabIndex.value),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${events.length} events',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Events grid/list
                    isWideScreen
                        ? _buildEventsGrid(context, events)
                        : _buildEventsList(context, events),
                  ],
                ),
              ),
            ),
            // Fill remaining space to enable pull-to-refresh
            SliverFillRemaining(hasScrollBody: false, child: Container()),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context, int tabIndex) {
    String title, description;
    IconData icon;
    String buttonText;
    VoidCallback? onPressed;

    switch (tabIndex) {
      case 0: // My Events
        title = 'No events yet';
        description = 'Create your first event to get started';
        icon = Icons.event_note;
        buttonText = 'Create Event';
        onPressed = () {
          Get.find<DashboardController>().navigateTo(
            DashboardContent.createEvent,
          );
        };
        break;
      case 1: // Invited Events
        title = 'No joined events';
        description = 'Join an event using a join code';
        icon = Icons.group;
        buttonText = 'Join Event';
        onPressed = null;
        break;
      case 2: // Public Events
        title = 'No public events';
        description = 'Check back later for public events';
        icon = Icons.explore_outlined;
        buttonText = 'Refresh';
        onPressed = () {
          Get.find<EventsController>().refreshCurrentTab();
        };
        break;
      default:
        title = 'No events';
        description = '';
        icon = Icons.event_note;
        buttonText = '';
        onPressed = null;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (onPressed != null) ...[              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(tabIndex == 0 ? Icons.add : Icons.refresh),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEventsGrid(BuildContext context, List<EventModel> events) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 3
            : constraints.maxWidth > 800
            ? 2
            : 1;

        // Calculate card width based on available space
        final spacing = 20.0;
        final totalSpacing = spacing * (crossAxisCount - 1);
        final cardWidth =
            (constraints.maxWidth - totalSpacing) / crossAxisCount;
        final cardHeight =
            cardWidth / 0.9; // Taller cards for more content space

        return Align(
          alignment: Alignment.topLeft,
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: events.map((event) {
              return SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _buildEventCard(context, event),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEventsList(BuildContext context, List<EventModel> events) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _buildEventListTile(context, events[index]),
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => widget.onEventTap(event),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  event.displayCoverImage.isNotEmpty
                      ? Image.network(
                          event.displayCoverImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                  // Status badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(event.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.statusDisplay,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (event.startDate != null)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, y').format(event.startDate!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    // Description (trimmed)
                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Progress bar - show contribution info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TZS ${_formatAmount(event.totalContributions)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (event.contributionTarget != null &&
                            event.contributionTarget! > 0)
                          Text(
                            '${event.progressPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                    if (event.contributionTarget != null &&
                        event.contributionTarget! > 0) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (event.progressPercentage / 100).clamp(
                            0.0,
                            1.0,
                          ),
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventListTile(BuildContext context, EventModel event) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => widget.onEventTap(event),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: event.displayCoverImage.isNotEmpty
                      ? Image.network(
                          event.displayCoverImage,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.primary.withOpacity(0.1),
                          child: Icon(Icons.event, color: AppColors.primary),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (event.startDate != null)
                      Text(
                        DateFormat('MMM d, y').format(event.startDate!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              event.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            event.statusDisplay,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(event.status),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${event.participantCount} participants',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.event,
          size: 40,
          color: AppColors.primary.withOpacity(0.5),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'DRAFT':
        return Colors.orange;
      case 'COMPLETED':
        return Colors.blue;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _getTabTitle(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'My Events';
      case 1:
        return 'Joined Events';
      case 2:
        return 'Public Events';
      default:
        return 'Events';
    }
  }
}
