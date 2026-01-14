import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/dashboard_layout.dart';
import '../../chat/views/chat_screen.dart';
import '../controllers/events_controller.dart';
import '../models/event_model.dart';
import '../models/participant_model.dart';
import '../widgets/event_calendar_card.dart';
import '../widgets/participants_list.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> with SingleTickerProviderStateMixin {
  final EventsController controller = Get.find<EventsController>();
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    final args = Get.arguments as Map<String, dynamic>?;
    final eventId = args?['eventId'] as int?;
    if (eventId != null) {
      controller.loadEventDetail(eventId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = kIsWeb && screenWidth >= 800;

    return Obx(() {
      if (controller.isLoading.value && controller.currentEvent.value == null) {
        return const Scaffold(
          backgroundColor: Color(0xFFF8FAFC),
          body: Center(child: CircularProgressIndicator()),
        );
      }

      final event = controller.currentEvent.value;
      if (event == null) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('Event not found', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        );
      }

      if (isWideScreen) {
        return DashboardLayout(
          currentRoute: 'event-detail',
          showBackButton: true,
          onBack: () => Get.back(),
          breadcrumb: DashboardBreadcrumb(
            items: [
              BreadcrumbItem(
                label: 'Events',
                onTap: () => Get.offAllNamed(AppRoutes.events),
              ),
              BreadcrumbItem(label: event.title),
            ],
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () => _shareEvent(event),
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Share'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showContributeDialog(event),
              icon: const Icon(Icons.volunteer_activism, size: 18),
              label: const Text('Contribute'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
          sidebarContent: _buildEventSidebarContent(event),
          content: _buildWebContent(context, event, screenWidth),
        );
      }

      // Mobile layout
      return _buildMobileLayout(context, event);
    });
  }

  // ==================== WEB SIDEBAR CONTENT ====================
  Widget _buildEventSidebarContent(EventModel event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Event Cover
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                event.displayCoverImage.isNotEmpty
                    ? Image.network(event.displayCoverImage, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        child: Icon(
                          Icons.event,
                          size: 48,
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: _buildBadge(
                    event.statusDisplay,
                    _getStatusColor(event.status),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Title
        Text(
          event.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // Type
        if (event.eventType != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              event.eventType!.name,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 16),
        // Info
        Text(
          'EVENT INFO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        _buildSidebarInfo(
          Icons.calendar_today,
          'Date',
          event.startDate != null
              ? DateFormat('MMM dd, yyyy').format(event.startDate!)
              : 'Not set',
        ),
        _buildSidebarInfo(
          Icons.access_time,
          'Time',
          event.startDate != null
              ? DateFormat('h:mm a').format(event.startDate!)
              : 'Not set',
        ),
        if (event.location.isNotEmpty)
          _buildSidebarInfo(Icons.location_on, 'Location', event.location),
        _buildSidebarInfo(
          Icons.person,
          'Organizer',
          event.ownerName ?? 'Unknown',
        ),
        _buildSidebarInfo(
          Icons.visibility,
          'Visibility',
          event.visibilityDisplay,
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 16),
        // Quick Actions
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
        _buildSidebarAction(
          Icons.payments,
          'View Contributions',
          () => Get.toNamed(AppRoutes.contributions, arguments: event),
        ),
        _buildSidebarAction(
          Icons.person_add,
          'Invite Participants',
          () => _showInviteDialog(event),
        ),
        _buildSidebarAction(
          Icons.content_copy,
          'Copy Join Code',
          () => _copyJoinCode(event),
        ),
        if (event.chatEnabled)
          _buildSidebarAction(Icons.chat, 'Open Chat', () => _openChat(event)),
        _buildSidebarAction(Icons.edit, 'Edit Event', () {}),
      ],
    );
  }

  Widget _buildSidebarInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarAction(IconData icon, String label, VoidCallback onTap) {
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

  // ==================== WEB MAIN CONTENT ====================
  Widget _buildWebContent(
    BuildContext context,
    EventModel event,
    double screenWidth,
  ) {
    final contentWidth = screenWidth - 280;
    final showTwoColumns = contentWidth >= 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Card
          if (event.contributionTarget != null && event.contributionTarget! > 0)
            _buildWebProgressCard(event),
          const SizedBox(height: 24),
          // Two column layout
          if (showTwoColumns)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildAboutSection(event)),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: _buildDetailsCard(event)),
              ],
            )
          else ...[
            _buildAboutSection(event),
            const SizedBox(height: 24),
            _buildDetailsCard(event),
          ],
          const SizedBox(height: 24),
          // Participants
          _buildWebParticipantsSection(event),
        ],
      ),
    );
  }

  Widget _buildWebProgressCard(EventModel event) {
    final progress = event.progressPercentage;
    final collected = event.totalContributions;
    final target = event.contributionTarget!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Raised',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '${event.currency} ${_formatAmount(collected)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'of ${event.currency} ${_formatAmount(target)} goal',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (progress / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${progress.toStringAsFixed(0)}% funded',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${event.participantCount} contributors',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${progress.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Funded',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(EventModel event) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            event.description.isNotEmpty
                ? event.description
                : 'No description provided.',
            style: TextStyle(color: Colors.grey.shade700, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(EventModel event) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Event Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Join Code', event.joinCode, copyable: true),
          _buildDetailRow(
            'Public Join',
            event.allowPublicJoin ? 'Enabled' : 'Disabled',
          ),
          _buildDetailRow('Status', event.statusDisplay),
          if (event.endDate != null)
            _buildDetailRow('Ends', _getRemainingDays(event.endDate!)),
          if (event.autoDisburseEnabled)
            _buildDetailRow(
              'Auto Disbursement',
              '${event.autoDisburseProvider} - ${event.autoDisbursePhone}',
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Row(
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
              if (copyable) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    Get.snackbar(
                      'Copied!',
                      'Copied to clipboard',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  child: Icon(Icons.copy, size: 16, color: AppColors.primary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebParticipantsSection(EventModel event) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Participants (${event.participantCount})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.people, size: 18),
                label: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            final participants = controller.currentEventParticipants;
            if (participants.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No participants yet',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: participants
                  .take(10)
                  .map((p) => _buildParticipantChip(p))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildParticipantChip(ParticipantModel participant) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              participant.name.isNotEmpty
                  ? participant.name[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            participant.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Text(
            'TZS ${_formatAmount(participant.totalContributions)}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout(BuildContext context, EventModel event) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(event.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareEvent(event),
          ),
        ],
      ),
      body: Column(
        children: [
          // Event Cover
          if (event.displayCoverImage.isNotEmpty)
            Image.network(
              event.displayCoverImage,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey.shade300,
                  child: Icon(
                    Icons.event,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                );
              },
            ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDiscoverTab(event),
                _buildContributionsTab(event),
                _buildMessagesTab(event),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _selectedTabIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showContributeDialog(event),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.volunteer_activism, color: Colors.white),
              label: const Text(
                'Contribute',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedTabIndex,
      onTap: (index) {
        _tabController.animateTo(index);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: 'Discover',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.volunteer_activism),
          label: 'Contributions',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: 'Messages',
        ),
      ],
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
    );
  }

  // ==================== TAB VIEWS ====================
  Widget _buildDiscoverTab(EventModel event) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats
          if (event.contributionTarget != null && event.contributionTarget! > 0)
            _buildMobileProgressSection(event),
          const SizedBox(height: 20),
          // Calendar section
          EventCalendarCard(
            event: event,
            onAddToCalendar: () => _addEventToCalendar(event),
          ),
          const SizedBox(height: 20),
          // Participants List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Participants',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _showFullEventDetails(event),
                child: const Text('View Full Details'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ParticipantsList(
            eventId: event.id.toString(),
            compact: true,
            onViewAll: () => Get.toNamed(AppRoutes.participants, arguments: {
              'eventId': event.id,
              'eventTitle': event.title,
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionsTab(EventModel event) {
    return Obx(() {
      if (controller.contributions.isEmpty) {
        controller.loadEventContributions(event.id);
      }
      
      final contributions = controller.contributions;
      
      if (contributions.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.volunteer_activism, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No contributions yet',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to contribute!',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      }
      
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: contributions.length,
        itemBuilder: (context, index) {
          final contribution = contributions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(
                  Icons.volunteer_activism,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                contribution.participantName ?? 'Anonymous',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                DateFormat('MMM d, y').format(contribution.createdAt),
              ),
              trailing: Text(
                'TZS ${_formatAmount(contribution.amount)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildMessagesTab(EventModel event) {
    if (!event.chatEnabled) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Chat is not enabled',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'The event organizer has disabled chat',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    
    // Show a preview with button to open full chat (like WhatsApp)
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat, size: 64, color: AppColors.primary.withOpacity(0.7)),
          const SizedBox(height: 16),
          const Text(
            'Event Chat',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Chat with other participants',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.to(
              () => ChatScreen(
                eventId: event.id.toString(),
                eventTitle: event.title,
              ),
            ),
            icon: const Icon(Icons.chat_bubble),
            label: const Text('Open Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullEventDetails(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Event Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _buildMobileEventHeader(event),
                const SizedBox(height: 20),
                _buildMobileDescriptionSection(event),
                const SizedBox(height: 20),
                _buildMobileDetailsSection(event),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileAppBar(EventModel event) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            event.displayCoverImage.isNotEmpty
                ? Image.network(event.displayCoverImage, fit: BoxFit.cover)
                : Container(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    child: Icon(
                      Icons.event,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBadge(
                    event.statusDisplay,
                    _getStatusColor(event.status),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _shareEvent(event),
        ),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, event),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit Event')),
            const PopupMenuItem(value: 'settings', child: Text('Settings')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete Event', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileEventHeader(EventModel event) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.eventType != null)
            Chip(
              avatar: const Icon(Icons.category, size: 16),
              label: Text(event.eventType!.name),
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            ),
          const SizedBox(height: 12),
          if (event.startDate != null)
            _buildMobileInfoRow(
              Icons.calendar_today,
              DateFormat('EEEE, MMMM d, yyyy').format(event.startDate!),
              DateFormat('h:mm a').format(event.startDate!),
            ),
          if (event.location.isNotEmpty)
            _buildMobileInfoRow(
              Icons.location_on,
              event.location,
              event.venueName.isNotEmpty ? event.venueName : null,
            ),
          _buildMobileInfoRow(
            Icons.person,
            event.ownerName ?? 'Organizer',
            null,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInfoRow(IconData icon, String title, String? subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileProgressSection(EventModel event) {
    final progress = event.progressPercentage;
    final collected = event.totalContributions;
    final target = event.contributionTarget!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${event.currency} ${_formatAmount(collected)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'raised of ${event.currency} ${_formatAmount(target)} goal',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 4,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${progress.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (progress / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 100 ? Colors.green : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${event.participantCount} contributors',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              if (event.endDate != null)
                Text(
                  _getRemainingDays(event.endDate!),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileQuickActions(EventModel event) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMobileActionButton(
                  Icons.payments,
                  'Contributions',
                  () => Get.toNamed(AppRoutes.contributions, arguments: event),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMobileActionButton(
                  Icons.people,
                  'Participants',
                  () {
                    // TODO: Add participants route to AppRoutes
                    Get.snackbar(
                      'Coming Soon',
                      'Participants view will be available soon',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMobileActionButton(
                  Icons.mail,
                  'Invitations',
                  () {
                    // TODO: Add invitations route to AppRoutes
                    Get.snackbar(
                      'Coming Soon',
                      'Invitations view will be available soon',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMobileActionButton(
                  Icons.campaign,
                  'Announcements',
                  () {
                    // TODO: Add announcements route to AppRoutes
                    Get.snackbar(
                      'Coming Soon',
                      'Announcements view will be available soon',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMobileActionButton(
                  Icons.link,
                  'Copy Link',
                  () => _copyJoinCode(event),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMobileActionButton(
                  Icons.chat,
                  'Chat',
                  () => Get.to(() => const ChatScreen(), 
                    arguments: {'eventId': event.id}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileActionButton(
    IconData icon,
    String label,
    VoidCallback? onTap, {
    bool disabled = false,
  }) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: disabled
                ? Colors.grey.shade300
                : AppColors.primary.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: disabled ? Colors.grey : AppColors.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: disabled ? Colors.grey : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDescriptionSection(EventModel event) {
    if (event.description.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            event.description,
            style: TextStyle(color: Colors.grey.shade700, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDetailsSection(EventModel event) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildMobileDetailItem('Visibility', event.visibilityDisplay),
          _buildMobileDetailItem('Join Code', event.joinCode),
          _buildMobileDetailItem(
            'Public Join',
            event.allowPublicJoin ? 'Enabled' : 'Disabled',
          ),
          if (event.autoDisburseEnabled)
            _buildMobileDetailItem(
              'Auto Disbursement',
              '${event.autoDisburseProvider} - ${event.autoDisbursePhone}',
            ),
        ],
      ),
    );
  }

  Widget _buildMobileDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }



  // ==================== HELPERS ====================
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'COMPLETED':
        return Colors.grey;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return NumberFormat('#,##0').format(amount);
  }

  String _getRemainingDays(DateTime endDate) {
    final days = endDate.difference(DateTime.now()).inDays;
    if (days < 0) return 'Ended';
    if (days == 0) return 'Ends today';
    if (days == 1) return '1 day left';
    return '$days days left';
  }

  void _shareEvent(EventModel event) {
    final shareLink = '${AppConfig.webAppBaseUrl}/join/${event.joinCode}';
    final shareText =
        '''
🎉 You're invited to "${event.title}"!

Join using this link:
$shareLink

Or use code: ${event.joinCode}

Powered by Ahadi - Event Contributions Made Easy
''';

    if (kIsWeb) {
      // On web, copy to clipboard and show dialog with options
      _showShareDialog(event, shareLink, shareText);
    } else {
      // On mobile, use native share
      Share.share(shareText, subject: 'Join ${event.title}');
    }
  }

  void _showShareDialog(EventModel event, String shareLink, String shareText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.share, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Share Event'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share this link with others to invite them:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      shareLink,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: shareLink));
                      Get.snackbar(
                        'Copied!',
                        'Link copied to clipboard',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    tooltip: 'Copy link',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.qr_code_2, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Join Code: ${event.joinCode}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: event.joinCode));
                    Get.snackbar(
                      'Copied!',
                      'Join code copied to clipboard',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: shareText));
              Navigator.pop(context);
              Get.snackbar(
                'Copied!',
                'Full invite message copied to clipboard',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            icon: const Icon(Icons.content_copy),
            label: const Text('Copy Message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _copyJoinCode(EventModel event) {
    Clipboard.setData(ClipboardData(text: event.joinCode));
    Get.snackbar(
      'Copied!',
      'Join code copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _addEventToCalendar(EventModel event) {
    // For now, show a simple dialog with event details
    // In a real implementation, you'd integrate with device calendar
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Add to Calendar'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildCalendarInfoRow(
              Icons.schedule,
              'Start',
              event.startDate != null 
                ? DateFormat('EEEE, MMM d, y • h:mm a').format(event.startDate!)
                : 'Not set',
            ),
            if (event.endDate != null) ...[
              const SizedBox(height: 8),
              _buildCalendarInfoRow(
                Icons.schedule,
                'End',
                DateFormat('EEEE, MMM d, y • h:mm a').format(event.endDate!),
              ),
            ],
            if (event.location?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              _buildCalendarInfoRow(
                Icons.location_on,
                'Location',
                event.location!,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'This will open your device calendar app to add this event.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // In a real app, you'd integrate with device calendar here
              Get.snackbar(
                'Coming Soon',
                'Calendar integration will be available soon',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                colorText: AppColors.primary,
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Event'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showInviteDialog(EventModel event) {
    // TODO: Implement invite dialog
    Get.snackbar(
      'Coming Soon',
      'Invite feature will be available soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  
  void _openChat(EventModel event) {
    Get.to(
      () => ChatScreen(
        eventId: event.id.toString(),
        eventTitle: event.title,
      ),
    );
  }
  
  void _showContributeDialog(EventModel event) {
    Get.toNamed(
      AppRoutes.paymentCheckout,
      arguments: {'event': event},
    );
  }

  void _handleMenuAction(String action, EventModel event) {
    switch (action) {
      case 'edit':
        break;
      case 'settings':
        break;
      case 'delete':
        _confirmDelete(event);
        break;
    }
  }

  void _confirmDelete(EventModel event) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Event?'),
        content: Text(
          'Are you sure you want to delete "${event.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Get.back();
              final success = await controller.deleteEvent(event.id);
              if (success) Get.back();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
