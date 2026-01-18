import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../../chat/views/chat_screen.dart';
import '../../chat/services/websocket_service.dart';
import '../../inbox/controllers/inbox_controller.dart';
import '../../inbox/screens/compose_message_screen.dart';
import '../../payments/views/event_wallet_screen.dart';
import '../../payments/views/event_transactions_screen.dart';
import '../controllers/events_controller.dart';
import '../models/event_model.dart';
import '../models/invitation_card_template_model.dart';
import '../models/participant_model.dart';
import '../models/contribution_model.dart';
import '../widgets/event_calendar_card.dart';
import '../widgets/participants_list.dart';
import 'invitation_templates_screen.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventsController controller = Get.find<EventsController>();
  late PageController _pageController;
  int _currentPageIndex = 0;
  int _unreadCount = 0;
  WebSocketService? _wsService;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    final args = Get.arguments as Map<String, dynamic>?;
    final eventId = args?['eventId'] as int?;
    if (eventId != null) {
      controller.loadEventDetail(eventId);
      _loadUnreadCount(eventId);
    }
  }

  Future<void> _loadUnreadCount(int eventId) async {
    try {
      _wsService = Get.find<WebSocketService>();
      final count = await _wsService!.getUnreadCount(eventId);
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    } catch (e) {
      print('Failed to load unread count: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

      // Use PageView for mobile
      return _buildPageViewLayout(event);
    });
  }

  Widget _buildPageViewLayout(EventModel event) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_getPageTitle()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareEvent(event),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        children: [
          _buildOverviewPage(event),
          _buildContributionsPage(event),
          _buildParticipantsPage(event),
        ],
      ),
      bottomNavigationBar: Obx(() {
        // Watch unreadCounts to trigger rebuild
        final eventId = controller.currentEvent.value?.id;
        final _ = eventId != null ? _wsService?.unreadCounts[eventId] : 0;

        return BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentPageIndex,
          onTap: (index) {
            if (index == 3) {
              // Navigate to chat as separate page
              Get.to(
                () => ChatScreen(
                  eventId: event.id,
                  eventTitle: event.title,
                  showAppBar: true,
                ),
              )?.then((_) {
                // Mark messages as read and reset count when returning
                _wsService?.markMessagesRead(event.id);
                setState(() => _unreadCount = 0);
              });
            } else {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.info_outline),
              activeIcon: Icon(Icons.info),
              label: 'Overview',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.volunteer_activism_outlined),
              activeIcon: Icon(Icons.volunteer_activism),
              label: 'Contribute',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'People',
            ),
            BottomNavigationBarItem(
              icon: _buildChatIconWithBadge(false),
              activeIcon: _buildChatIconWithBadge(true),
              label: 'Chat',
            ),
          ],
        );
      }),
      floatingActionButton: _currentPageIndex == 1
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

  Widget _buildChatIconWithBadge(bool isActive) {
    // Use the reactive unreadCounts map from WebSocketService
    final eventId = controller.currentEvent.value?.id;
    final unreadCount = eventId != null
        ? (_wsService?.unreadCounts[eventId] ?? _unreadCount)
        : _unreadCount;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(isActive ? Icons.chat_bubble : Icons.chat_bubble_outline),
        if (unreadCount > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  String _getPageTitle() {
    switch (_currentPageIndex) {
      case 0:
        return 'Event Details';
      case 1:
        return 'Contributions';
      case 2:
        return 'Participants';
      default:
        return 'Event';
    }
  }

  Widget _buildOverviewPage(EventModel event) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.displayCoverImage.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                event.displayCoverImage,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.event,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          Text(
            event.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (event.description.isNotEmpty) ...[
            Text(
              event.description,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
          ],
          if (event.contributionTarget != null && event.contributionTarget! > 0)
            _buildMobileProgressSection(event),
          const SizedBox(height: 20),
          // Quick Actions for Event Owner
          _buildOwnerQuickActions(event),
          const SizedBox(height: 20),
          // Invitation Template Section (show for wedding events or events with template)
          _buildInvitationTemplateSection(event),
          const SizedBox(height: 20),
          EventCalendarCard(
            event: event,
            onAddToCalendar: () => _addEventToCalendar(event),
          ),
        ],
      ),
    );
  }

  /// Build invitation template section for wedding events
  Widget _buildInvitationTemplateSection(EventModel event) {
    final template = event.invitationCardTemplate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard, color: Colors.pink.shade400, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Invitation Card Template',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (template != null) ...[
            // Show selected template preview
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.pink.shade200, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    child: template.isCanvasTemplate
                        ? _buildCanvasTemplatePreview(template)
                        : (template.previewImage != null
                              ? Image.network(
                                  template.previewImage!,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildTemplateFallback(template, 120),
                                )
                              : _buildTemplateFallback(template, 120)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                template.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                template.categoryDisplay,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _changeTemplate(event),
                          icon: const Icon(Icons.swap_horiz, size: 18),
                          label: const Text('Change'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.pink.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // No template selected
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.pink.shade100),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.style_outlined,
                    size: 40,
                    color: Colors.pink.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No template selected',
                    style: TextStyle(
                      color: Colors.pink.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose a beautiful template for your wedding invitations',
                    style: TextStyle(color: Colors.pink.shade400, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _changeTemplate(event),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Select Template'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink.shade400,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build canvas template preview
  Widget _buildCanvasTemplatePreview(InvitationCardTemplateModel template) {
    final primaryColor = _parseTemplateColor(template.primaryColor);
    final secondaryColor = _parseTemplateColor(template.secondaryColor);
    final accentColor = _parseTemplateColor(template.accentColor);
    final style = template.canvasStyle ?? 'elegant';

    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accentColor, accentColor.withValues(alpha: 0.95)],
        ),
      ),
      child: Stack(
        children: [
          if (style == 'floral') ...[
            Positioned(
              top: 8,
              left: 8,
              child: Text('🌸', style: TextStyle(fontSize: 16)),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Text('🌺', style: TextStyle(fontSize: 16)),
            ),
          ],
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: primaryColor, width: 1),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'WEDDING INVITATION',
                  style: TextStyle(
                    color: secondaryColor.withValues(alpha: 0.6),
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Names Here',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 6),
                Container(width: 30, height: 1, color: primaryColor),
              ],
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Canvas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build template fallback when image fails
  Widget _buildTemplateFallback(
    InvitationCardTemplateModel template,
    double height,
  ) {
    return Container(
      height: height,
      color: _parseTemplateColor(template.primaryColor),
      child: const Center(
        child: Icon(Icons.card_giftcard, size: 40, color: Colors.white),
      ),
    );
  }

  /// Parse template hex color
  Color _parseTemplateColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  /// Navigate to template selection and update event
  Future<void> _changeTemplate(EventModel event) async {
    final result = await Get.to<InvitationCardTemplateModel>(
      () => const InvitationTemplatesScreen(),
      arguments: {
        'selectionMode': true,
        'selectedTemplateId': event.invitationCardTemplateId,
        'eventId': event.id,
        'eventTitle': event.title,
      },
    );

    if (result != null) {
      // Update the event with new template
      try {
        await controller.updateEventTemplate(event.id, result.id);
        Get.snackbar(
          'Success',
          'Invitation template updated to ${result.name}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to update template: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  /// Build quick actions for event owner (wallet, invite, etc.)
  Widget _buildOwnerQuickActions(EventModel event) {
    // Check if current user is the event owner
    final currentUserId = Get.find<StorageService>().getUser()?['id'] ?? 0;
    final isOwner = event.ownerId == currentUserId;

    // Only show owner-specific actions if user is the owner
    if (!isOwner) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Owner Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          // First row: Wallet & Transactions
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.account_balance_wallet,
                  label: 'Event Wallet',
                  color: Colors.green,
                  onTap: () => Get.to(() => EventWalletScreen(event: event)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.receipt_long,
                  label: 'Transactions',
                  color: Colors.purple,
                  onTap: () => Get.to(() => EventTransactionsScreen(event: event)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Second row: Invite & Share
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.person_add,
                  label: 'Invite',
                  color: Colors.blue,
                  onTap: () => _showInviteDialog(event),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.share,
                  label: 'Share',
                  color: Colors.orange,
                  onTap: () => _shareEvent(event),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionsPage(EventModel event) {
    return _buildContributionsTab(event);
  }

  Widget _buildParticipantsPage(EventModel event) {
    return ParticipantsList(
      eventId: event.id.toString(),
      compact: false,
      onSendMessage: (participant) =>
          _sendMessageToParticipant(participant, event),
    );
  }

  Widget _buildChatPage(EventModel event) {
    if (!event.chatEnabled) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text('Chat is disabled', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'The event organizer has disabled chat',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ChatScreen(
      eventId: event.id,
      eventTitle: event.title,
      showAppBar: false,
    );
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
        _buildSidebarAction(
          Icons.account_balance_wallet,
          'Event Wallet',
          () => Get.to(() => EventWalletScreen(event: event)),
        ),
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
  // ==================== TAB VIEWS ====================
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
              Icon(
                Icons.volunteer_activism,
                size: 64,
                color: Colors.grey.shade400,
              ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          (contribution.participantName ?? 'A')[0]
                              .toUpperCase(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contribution.participantName ?? 'Anonymous',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'MMM d, y',
                              ).format(contribution.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'TZS ${_formatAmount(contribution.amount)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _sendMessageToContributor(contribution, event),
                      icon: Icon(
                        Icons.message_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        'Send Message',
                        style: TextStyle(color: AppColors.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
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
            const PopupMenuItem(
              value: 'send_invitations',
              child: Row(
                children: [
                  Icon(Icons.mail_outline, size: 20),
                  SizedBox(width: 8),
                  Text('Send Invitations'),
                ],
              ),
            ),
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
                child: _buildMobileActionButton(Icons.mail, 'Invitations', () {
                  final event = controller.currentEvent.value;
                  if (event != null) {
                    Get.toNamed(
                      AppRoutes.invitations,
                      arguments: {
                        'eventId': event.id,
                        'eventTitle': event.title,
                        'eventTypeSlug': event.eventType?.slug,
                      },
                    );
                  }
                }),
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
                  () => Get.to(
                    () => ChatScreen(
                      eventId: event.id,
                      eventTitle: event.title,
                      showAppBar: true,
                    ),
                  ),
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
    final shareText =
        '''
🎉 You're invited to "${event.title}"!

Join using code: ${event.joinCode}

Powered by Ahadi - Event Contributions Made Easy
''';

    // On mobile, use native share
    Share.share(shareText, subject: 'Join ${event.title}');
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildCalendarInfoRow(
              Icons.schedule,
              'Start',
              event.startDate != null
                  ? DateFormat(
                      'EEEE, MMM d, y • h:mm a',
                    ).format(event.startDate!)
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
            if (event.location.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildCalendarInfoRow(
                Icons.location_on,
                'Location',
                event.location,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'This will open your device calendar app to add this event.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
      () => ChatScreen(eventId: event.id.toString(), eventTitle: event.title),
    );
  }

  void _showContributeDialog(EventModel event) {
    Get.toNamed(AppRoutes.paymentCheckout, arguments: {'event': event});
  }

  void _handleMenuAction(String action, EventModel event) {
    switch (action) {
      case 'edit':
        break;
      case 'settings':
        break;
      case 'send_invitations':
        _showSendInvitationsDialog(event);
        break;
      case 'delete':
        _confirmDelete(event);
        break;
    }
  }

  void _showSendInvitationsDialog(EventModel event) {
    // Check if event has invitation template
    if (event.invitationCardTemplate == null) {
      Get.dialog(
        AlertDialog(
          title: const Text('No Invitation Template'),
          content: const Text(
            'This event does not have an invitation card template set up. '
            'Please create one first before sending invitations.',
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Send Invitations'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send invitation cards to participants of this event.'),
            const SizedBox(height: 16),
            Text(
              'Template: ${event.invitationCardTemplate!.name}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () async {
              Get.back();
              await _sendInvitations(event);
            },
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Send to All'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendInvitations(EventModel event) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final inboxController = Get.find<InboxController>();
      await inboxController.sendInvitation(eventId: event.id, sendToSelf: true);

      Get.back(); // Close loading
      Get.snackbar(
        'Success',
        'Invitation cards are being sent to participants',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back(); // Close loading
      Get.snackbar(
        'Error',
        'Failed to send invitations: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _sendMessageToParticipant(
    ParticipantModel participant,
    EventModel event,
  ) {
    if (participant.userId == null) {
      // Show contact options dialog for participants without user accounts
      _showContactOptionsDialog(
        name: participant.name,
        phone: participant.phone,
        email: participant.email,
      );
      return;
    }

    Get.to(
      () => ComposeMessageScreen(
        recipientId: participant.userId,
        recipientName: participant.name,
        event: event,
      ),
    );
  }

  void _sendMessageToContributor(
    ContributionModel contribution,
    EventModel event,
  ) {
    // Find the participant to get contact info
    final participant = controller.participants.firstWhereOrNull(
      (p) => p.id == contribution.participantId,
    );

    if (participant?.userId == null) {
      // Show contact options dialog
      _showContactOptionsDialog(
        name: contribution.contributorName,
        phone: contribution.participantPhone ?? participant?.phone ?? '',
        email: participant?.email ?? '',
      );
      return;
    }

    Get.to(
      () => ComposeMessageScreen(
        recipientId: participant!.userId,
        recipientName: contribution.contributorName,
        event: event,
      ),
    );
  }

  void _showContactOptionsDialog({
    required String name,
    required String phone,
    required String email,
  }) {
    Get.dialog(
      AlertDialog(
        title: Text('Contact $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This person doesn\'t have an app account. You can contact them via:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (phone.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: Text(phone),
                subtitle: const Text('Call or SMS'),
                onTap: () {
                  Get.back();
                  _launchPhone(phone);
                },
              ),
            if (email.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),
                title: Text(email),
                subtitle: const Text('Send email'),
                onTap: () {
                  Get.back();
                  _launchEmail(email);
                },
              ),
            if (phone.isEmpty && email.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No contact information available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
