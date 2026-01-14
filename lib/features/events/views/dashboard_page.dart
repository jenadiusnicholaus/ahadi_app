import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/events_controller.dart';
import '../models/event_model.dart';
import '../../profile/screens/profile_content.dart';
import '../../chat/views/chat_screen.dart';
import '../widgets/event_calendar_card.dart';
import 'events_content.dart';
import 'event_detail_content.dart';
import 'contributions_content.dart';
import 'add_contribution_content.dart';
import 'payment_checkout_content.dart';
import 'participants_screen.dart';
import 'create_event_content.dart';
import 'edit_event_content.dart';

/// Main dashboard page - single entry point for all dashboard content
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late DashboardController dashboardController;
  late EventsController eventsController;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    if (!Get.isRegistered<DashboardController>()) {
      Get.put(DashboardController());
    }
    dashboardController = Get.find<DashboardController>();

    if (!Get.isRegistered<EventsController>()) {
      Get.put(EventsController());
    }
    eventsController = Get.find<EventsController>();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentContent = dashboardController.currentContent.value;

      return DashboardShell(
        sidebarContent: _buildSidebarContent(currentContent),
        floatingActionButton: _buildFAB(currentContent),
        content: _buildContent(currentContent),
      );
    });
  }

  Widget _buildContent(DashboardContent content) {
    switch (content) {
      case DashboardContent.events:
        return EventsContent(
          onEventTap: (event) {
            dashboardController.navigateTo(
              DashboardContent.eventDetail,
              args: {'event': event, 'eventTitle': event.title},
            );
          },
        );

      case DashboardContent.createEvent:
        return CreateEventContent(
          onCancel: () => dashboardController.goBack(),
          onSuccess: () {
            eventsController.refreshCurrentTab(); // Refresh events list
            dashboardController.navigateTo(DashboardContent.events);
          },
        );

      case DashboardContent.editEvent:
        final event = dashboardController.contentArgs['event'] as EventModel?;
        if (event == null) {
          return const Center(child: Text('Event not found'));
        }
        return EditEventContent(
          event: event,
          onCancel: () => dashboardController.goBack(),
          onSuccess: () {
            eventsController.refreshCurrentTab();
            dashboardController.goBack(); // Go back to event detail
          },
        );

      case DashboardContent.eventDetail:
        final event = dashboardController.contentArgs['event'] as EventModel?;
        if (event == null) {
          return const Center(child: Text('Event not found'));
        }
        return EventDetailContent(
          event: event,
          onContributionsTap: () {
            dashboardController.navigateTo(
              DashboardContent.contributions,
              args: {'event': event, 'eventTitle': event.title},
            );
          },
          onParticipantsTap: () {
            dashboardController.navigateTo(
              DashboardContent.participants,
              args: {'event': event, 'eventTitle': event.title},
            );
          },
          onEditTap: () {
            dashboardController.navigateTo(
              DashboardContent.editEvent,
              args: {'event': event, 'eventTitle': event.title},
            );
          },
          onContributeTap: () {
            dashboardController.navigateTo(
              DashboardContent.addContribution,
              args: {'event': event, 'eventTitle': event.title},
            );
          },
        );

      case DashboardContent.contributions:
        final event = dashboardController.contentArgs['event'] as EventModel?;
        if (event == null) {
          return const Center(child: Text('Event not found'));
        }
        return ContributionsContent(
          event: event,
          onAddContribution: () {
            dashboardController.navigateTo(
              DashboardContent.addContribution,
              args: {'event': event, 'eventTitle': event.title},
            );
          },
          onPaymentCheckout: () {
            dashboardController.navigateTo(
              DashboardContent.paymentCheckout,
              args: {'event': event, 'eventTitle': event.title},
            );
          },
        );

      case DashboardContent.addContribution:
        final event = dashboardController.contentArgs['event'] as EventModel?;
        if (event == null) {
          return const Center(child: Text('Event not found'));
        }
        return AddContributionContent(
          event: event,
          onCancel: () => dashboardController.goBack(),
          onSuccess: () => dashboardController.goBack(),
        );

      case DashboardContent.paymentCheckout:
        final event = dashboardController.contentArgs['event'] as EventModel?;
        if (event == null) {
          return const Center(child: Text('Event not found'));
        }
        return PaymentCheckoutContent(
          event: event,
          onCancel: () => dashboardController.goBack(),
          onSuccess: () => dashboardController.goBack(),
        );

      case DashboardContent.participants:
        final event = dashboardController.contentArgs['event'] as EventModel?;
        if (event == null) {
          return const Center(child: Text('Event not found'));
        }
        return ParticipantsScreen();

      case DashboardContent.discover:
        return _buildDiscoverContent();

      case DashboardContent.calendar:
        return _buildCalendarContent();

      case DashboardContent.messages:
        return _buildMessagesContent();

      case DashboardContent.profile:
        return const ProfileContent();

      default:
        return const Center(child: Text('Coming Soon'));
    }
  }

  Widget? _buildSidebarContent(DashboardContent content) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = kIsWeb && screenWidth >= 800;

    if (!isWideScreen) return null;

    switch (content) {
      case DashboardContent.events:
        return _buildEventsSidebar();

      case DashboardContent.eventDetail:
        final event = dashboardController.contentArgs['event'] as EventModel?;
        if (event == null) return null;
        return _buildEventDetailSidebar(event);

      case DashboardContent.contributions:
        final event = dashboardController.contentArgs['event'] as EventModel?;
        if (event == null) return null;
        return _buildContributionsSidebar(event);

      default:
        return null;
    }
  }

  Widget? _buildFAB(DashboardContent content) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = kIsWeb && screenWidth >= 800;

    if (isWideScreen) return null;

    switch (content) {
      case DashboardContent.eventDetail:
        return FloatingActionButton.extended(
          onPressed: () {
            final event =
                dashboardController.contentArgs['event'] as EventModel?;
            if (event != null) {
              dashboardController.navigateTo(
                DashboardContent.addContribution,
                args: {'event': event, 'eventTitle': event.title},
              );
            }
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.volunteer_activism, color: Colors.white),
          label: const Text(
            'Contribute',
            style: TextStyle(color: Colors.white),
          ),
        );

      case DashboardContent.contributions:
        return FloatingActionButton.extended(
          onPressed: () {
            final event =
                dashboardController.contentArgs['event'] as EventModel?;
            if (event != null) {
              dashboardController.navigateTo(
                DashboardContent.addContribution,
                args: {'event': event, 'eventTitle': event.title},
              );
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Add'),
          backgroundColor: AppColors.primary,
        );

      default:
        return null;
    }
  }

  // ============ SIDEBAR BUILDERS ============

  Widget _buildEventsSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildStatItem(
                      '${eventsController.myEvents.length}',
                      'My Events',
                      Icons.event,
                    ),
                    const SizedBox(width: 16),
                    _buildStatItem(
                      '${eventsController.invitedEvents.length}',
                      'Joined',
                      Icons.group,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Filters
        Text(
          'FILTER BY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),

        // Tabs
        Obx(
          () => Column(
            children: [
              _buildFilterTile(
                'My Events',
                Icons.event_outlined,
                eventsController.selectedTabIndex.value == 0,
                () => eventsController.tabController.animateTo(0),
              ),
              _buildFilterTile(
                'Joined Events',
                Icons.group_outlined,
                eventsController.selectedTabIndex.value == 1,
                () => eventsController.tabController.animateTo(1),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Status filter
        Text(
          'STATUS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(
                'All',
                eventsController.selectedStatus.value == null,
                () => eventsController.setStatusFilter(null),
              ),
              _buildChip(
                'Active',
                eventsController.selectedStatus.value == 'ACTIVE',
                () => eventsController.setStatusFilter('ACTIVE'),
              ),
              _buildChip(
                'Draft',
                eventsController.selectedStatus.value == 'DRAFT',
                () => eventsController.setStatusFilter('DRAFT'),
              ),
              _buildChip(
                'Completed',
                eventsController.selectedStatus.value == 'COMPLETED',
                () => eventsController.setStatusFilter('COMPLETED'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventDetailSidebar(EventModel event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Event cover
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: event.displayCoverImage.isNotEmpty
                ? Image.network(event.displayCoverImage, fit: BoxFit.cover)
                : Container(
                    color: AppColors.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.event,
                      size: 48,
                      color: AppColors.primary.withOpacity(0.5),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // Progress
        if (event.contributionTarget != null &&
            event.contributionTarget! > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TZS ${_formatAmount(event.totalContributions)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${event.progressPercentage.toStringAsFixed(0)}%',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (event.progressPercentage / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'of TZS ${_formatAmount(event.contributionTarget!)} target',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
        ],

        // Quick actions
        Text(
          'QUICK ACTIONS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        _buildActionTile(Icons.payments, 'View Contributions', () {
          dashboardController.navigateTo(
            DashboardContent.contributions,
            args: {'event': event, 'eventTitle': event.title},
          );
        }),
        _buildActionTile(Icons.people, 'Participants', () {
          dashboardController.navigateTo(
            DashboardContent.participants,
            args: {'event': event, 'eventTitle': event.title},
          );
        }),
        _buildActionTile(Icons.content_copy, 'Copy Join Code', () {
          // Copy join code
        }),
        if (event.chatEnabled) _buildActionTile(Icons.chat, 'Open Chat', () {}),
        _buildActionTile(Icons.edit, 'Edit Event', () {}),
      ],
    );
  }

  Widget _buildContributionsSidebar(EventModel event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Collected',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                'TZS ${_formatAmount(event.totalContributions)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Actions
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              dashboardController.navigateTo(
                DashboardContent.addContribution,
                args: {'event': event, 'eventTitle': event.title},
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Contribution'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              dashboardController.navigateTo(
                DashboardContent.paymentCheckout,
                args: {'event': event, 'eventTitle': event.title},
              );
            },
            icon: const Icon(Icons.phone_android),
            label: const Text('Mobile Payment'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // ============ HELPER WIDGETS ============

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTile(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : Colors.grey.shade600,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.primary : Colors.grey.shade800,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        margin: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  // ============ PAGE CONTENT BUILDERS ============
  
  Widget _buildDiscoverContent() {
    // Show public events list (tab index 2)
    return EventsContent(
      initialTab: 2,
      onEventTap: (event) {
        dashboardController.navigateTo(
          DashboardContent.eventDetail,
          args: {'event': event, 'eventTitle': event.title},
        );
      },
    );
  }

  Widget _buildCalendarContent() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calendar',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your upcoming events',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Obx(() {
                // Use the observable lists directly
                final allEvents = [...eventsController.myEvents, ...eventsController.invitedEvents];
                
                if (allEvents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Events',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create or join events to see them here',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                // Sort events by date
                final sortedEvents = List<EventModel>.from(allEvents)
                  ..sort((a, b) {
                    final aDate = a.startDate ?? DateTime.now();
                    final bDate = b.startDate ?? DateTime.now();
                    return aDate.compareTo(bDate);
                  });

                return ListView.builder(
                  itemCount: sortedEvents.length,
                  itemBuilder: (context, index) {
                    final event = sortedEvents[index];
                    return EventCalendarCard(
                      event: event,
                      onTap: () {
                        dashboardController.navigateTo(
                          DashboardContent.eventDetail,
                          args: {'event': event, 'eventTitle': event.title},
                        );
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesContent() {
    // Check if we're in event context
    final event = dashboardController.contentArgs['event'] as EventModel?;
    final eventTitle = dashboardController.contentArgs['eventTitle'] as String?;
    
    if (event != null) {
      // Show event-specific chat
      return ChatScreen(
        eventId: event.id,
        eventTitle: eventTitle ?? event.title,
      );
    }
    
    // Show placeholder if no event context
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Messages',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select an event to view messages',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Event Selected',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Open an event to chat with participants',
                    style: TextStyle(color: Colors.grey.shade600),
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
