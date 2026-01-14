import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/events_controller.dart';
import '../models/event_model.dart';
import '../models/participant_model.dart';

/// Event detail content - renders inside DashboardShell
class EventDetailContent extends StatefulWidget {
  final EventModel event;
  final VoidCallback onContributionsTap;
  final VoidCallback onParticipantsTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onContributeTap;

  const EventDetailContent({
    super.key,
    required this.event,
    required this.onContributionsTap,
    required this.onParticipantsTap,
    this.onEditTap,
    this.onContributeTap,
  });

  @override
  State<EventDetailContent> createState() => _EventDetailContentState();
}

class _EventDetailContentState extends State<EventDetailContent> {
  final EventsController controller = Get.find<EventsController>();

  @override
  void initState() {
    super.initState();
    controller.loadEventDetail(widget.event.id);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = kIsWeb && screenWidth >= 800;

    return Obx(() {
      final event = controller.currentEvent.value ?? widget.event;

      return SingleChildScrollView(
        padding: EdgeInsets.all(isWideScreen ? 32 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and actions
            _buildHeader(context, event, isWideScreen),
            const SizedBox(height: 24),

            // Main content
            if (isWideScreen)
              _buildWideContent(context, event)
            else
              _buildMobileContent(context, event),
          ],
        ),
      );
    });
  }

  Widget _buildHeader(
    BuildContext context,
    EventModel event,
    bool isWideScreen,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(event.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.statusDisplay,
                      style: TextStyle(
                        color: _getStatusColor(event.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (event.eventType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.eventType!.name,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                event.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (event.location.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.location,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (isWideScreen) ...[
          OutlinedButton.icon(
            onPressed: () => _shareEvent(event),
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showContributeDialog(event),
            icon: const Icon(Icons.volunteer_activism, size: 18),
            label: const Text('Contribute'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWideContent(BuildContext context, EventModel event) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column - Main info
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressCard(event),
              const SizedBox(height: 24),
              _buildAboutSection(event),
              const SizedBox(height: 24),
              _buildParticipantsSection(event),
            ],
          ),
        ),
        const SizedBox(width: 32),

        // Right column - Details & actions
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildDetailsCard(event),
              const SizedBox(height: 16),
              _buildQuickActionsCard(event),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileContent(BuildContext context, EventModel event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover image
        if (event.displayCoverImage.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(event.displayCoverImage, fit: BoxFit.cover),
            ),
          ),
        const SizedBox(height: 16),

        _buildProgressCard(event),
        const SizedBox(height: 16),

        // Quick actions
        _buildMobileQuickActions(event),
        const SizedBox(height: 16),

        _buildAboutSection(event),
        const SizedBox(height: 16),

        _buildDetailsCard(event),
        const SizedBox(height: 16),

        _buildParticipantsSection(event),
      ],
    );
  }

  Widget _buildProgressCard(EventModel event) {
    if (event.contributionTarget == null || event.contributionTarget == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TZS ${_formatAmount(event.totalContributions)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'of TZS ${_formatAmount(event.contributionTarget!)} target',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${event.progressPercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (event.progressPercentage / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${event.participantCount} participants',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: widget.onContributionsTap,
                  child: const Text('View all contributions'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(EventModel event) {
    if (event.description.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              event.description,
              style: TextStyle(color: Colors.grey.shade700, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(EventModel event) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (event.startDate != null)
              _buildDetailRow(
                Icons.calendar_today,
                'Start Date',
                DateFormat('EEEE, MMMM d, y').format(event.startDate!),
              ),
            if (event.endDate != null)
              _buildDetailRow(
                Icons.event,
                'End Date',
                DateFormat('EEEE, MMMM d, y').format(event.endDate!),
              ),
            if (event.location.isNotEmpty)
              _buildDetailRow(Icons.location_on, 'Location', event.location),
            if (event.venueName.isNotEmpty)
              _buildDetailRow(Icons.place, 'Venue', event.venueName),
            _buildDetailRow(
              Icons.visibility,
              'Visibility',
              event.visibilityDisplay,
            ),
            if (event.joinCode.isNotEmpty)
              _buildDetailRow(
                Icons.qr_code,
                'Join Code',
                event.joinCode,
                onTap: () => _copyJoinCode(event),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.copy, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(EventModel event) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              Icons.payments,
              'View Contributions',
              widget.onContributionsTap,
            ),
            _buildActionButton(
              Icons.people,
              'Manage Participants',
              widget.onParticipantsTap,
            ),
            if (widget.onEditTap != null)
              _buildActionButton(Icons.edit, 'Edit Event', widget.onEditTap!),
            _buildActionButton(
              Icons.share,
              'Share Event',
              () => _shareEvent(event),
            ),
            if (event.chatEnabled)
              _buildActionButton(Icons.chat, 'Open Chat', () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileQuickActions(EventModel event) {
    return Row(
      children: [
        Expanded(
          child: _buildMobileActionTile(
            Icons.payments,
            'Contributions',
            widget.onContributionsTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMobileActionTile(
            Icons.people,
            'Participants',
            widget.onParticipantsTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMobileActionTile(
            Icons.share,
            'Share',
            () => _shareEvent(event),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileActionTile(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsSection(EventModel event) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Participants',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: widget.onParticipantsTap,
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() {
              final participants = controller.participants.take(5).toList();
              if (participants.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No participants yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                );
              }

              return Column(
                children: participants
                    .map((p) => _buildParticipantTile(p))
                    .toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantTile(ParticipantModel participant) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Text(
          participant.name.isNotEmpty ? participant.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        participant.name.isNotEmpty ? participant.name : 'Anonymous',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'TZS ${_formatAmount(participant.totalContributions)}',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: _getParticipantStatusColor(
            participant.status,
          ).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          participant.statusDisplay,
          style: TextStyle(
            fontSize: 11,
            color: _getParticipantStatusColor(participant.status),
          ),
        ),
      ),
    );
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
      // On web, copy to clipboard and show dialog
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
            const Text('Share this link with others:'),
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
                        'Link copied',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Join Code: ${event.joinCode}',
              style: const TextStyle(fontWeight: FontWeight.bold),
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
                'Invite message copied',
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

  void _showContributeDialog(EventModel event) {
    if (widget.onContributeTap != null) {
      widget.onContributeTap!();
    }
  }

  void _copyJoinCode(EventModel event) {
    Clipboard.setData(ClipboardData(text: event.joinCode));
    Get.snackbar(
      'Copied!',
      'Join code copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
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

  Color _getParticipantStatusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'DECLINED':
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
}
