import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/events_controller.dart';
import '../models/event_model.dart';
import '../../profile/screens/profile_content.dart';
import '../../chat/views/messages_tab_screen.dart';
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
    // No sidebar on mobile
    return null;
  }

  Widget? _buildFAB(DashboardContent content) {
    switch (content) {
      case DashboardContent.events:
        return FloatingActionButton.extended(
          onPressed: () {
            dashboardController.navigateTo(DashboardContent.createEvent);
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Create Event',
            style: TextStyle(color: Colors.white),
          ),
        );

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
    // Show MessagesTabScreen with Inbox and Groups tabs
    return const MessagesTabScreen();
  }
}
