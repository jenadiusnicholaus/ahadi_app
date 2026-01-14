import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dashboard_layout.dart';
import '../controllers/events_controller.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final EventsController controller = Get.find<EventsController>();
  int? eventId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    eventId = args?['eventId'] as int?;
    if (eventId != null) {
      _loadAnnouncements();
    }
  }

  Future<void> _loadAnnouncements() async {
    // TODO: Implement load announcements from API
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentRoute: 'announcements',
      showBackButton: true,
      onBack: () => Get.back(),
      breadcrumb: DashboardBreadcrumb(
        items: [
          BreadcrumbItem(label: 'Events', onTap: () => Get.back()),
          BreadcrumbItem(label: 'Announcements'),
        ],
      ),
      content: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Announcements',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Important updates for event participants',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateAnnouncementDialog(),
                  icon: const Icon(Icons.campaign, size: 18),
                  label: const Text('New Announcement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Announcements List
          Expanded(
            child: _buildAnnouncementsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsList() {
    // Mock data for demonstration
    final announcements = _getMockAnnouncements();

    if (announcements.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: announcements.length,
      itemBuilder: (context, index) {
        final announcement = announcements[index];
        return _buildAnnouncementCard(announcement);
      },
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    final isPinned = announcement['pinned'] as bool;
    final priority = announcement['priority'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isPinned ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPinned
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: isPinned ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (isPinned) ...[
                  Icon(
                    Icons.push_pin,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildPriorityBadge(priority),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              announcement['title'] as String,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            announcement['author'] as String,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            announcement['time'] as String,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'pin') {
                      _togglePin(announcement);
                    } else if (value == 'edit') {
                      _editAnnouncement(announcement);
                    } else if (value == 'delete') {
                      _deleteAnnouncement(announcement);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'pin',
                      child: Row(
                        children: [
                          Icon(
                            isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(isPinned ? 'Unpin' : 'Pin'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              announcement['content'] as String,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade800,
                height: 1.5,
              ),
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  '${announcement['views']} views',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                if (announcement['notificationSent'] as bool)
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        size: 16,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Notified',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    IconData icon;

    switch (priority.toLowerCase()) {
      case 'high':
        color = Colors.red;
        icon = Icons.error;
        break;
      case 'medium':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case 'low':
        color = Colors.blue;
        icon = Icons.info;
        break;
      default:
        color = Colors.grey;
        icon = Icons.announcement;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            priority.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No announcements yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first announcement to keep participants informed',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateAnnouncementDialog(),
            icon: const Icon(Icons.campaign, size: 18),
            label: const Text('Create Announcement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateAnnouncementDialog() {
    Get.snackbar(
      'Coming Soon',
      'Create announcement functionality will be implemented',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _togglePin(Map<String, dynamic> announcement) {
    final isPinned = announcement['pinned'] as bool;
    Get.snackbar(
      'Success',
      isPinned ? 'Announcement unpinned' : 'Announcement pinned',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _editAnnouncement(Map<String, dynamic> announcement) {
    Get.snackbar(
      'Coming Soon',
      'Edit announcement functionality will be implemented',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _deleteAnnouncement(Map<String, dynamic> announcement) {
    Get.defaultDialog(
      title: 'Delete Announcement',
      middleText: 'Are you sure you want to delete this announcement?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        Get.snackbar(
          'Success',
          'Announcement deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      },
    );
  }

  List<Map<String, dynamic>> _getMockAnnouncements() {
    return [
      {
        'title': 'Venue Change Notification',
        'content':
            'Dear participants, please note that the venue has been changed to Grand Ballroom, Hotel Kilimanjaro. The date and time remain the same. Thank you for your understanding.',
        'author': 'Event Organizer',
        'time': '2 hours ago',
        'priority': 'high',
        'pinned': true,
        'views': 45,
        'notificationSent': true,
      },
      {
        'title': 'Contribution Milestone Reached!',
        'content':
            'We are thrilled to announce that we have reached 75% of our contribution target! Thank you all for your generous support. Let\'s reach our goal together!',
        'author': 'John Doe',
        'time': '1 day ago',
        'priority': 'medium',
        'pinned': false,
        'views': 67,
        'notificationSent': true,
      },
      {
        'title': 'Event Program Schedule',
        'content':
            'The event program schedule is now available. Please check your email for the detailed schedule of activities. Looking forward to seeing everyone there!',
        'author': 'Event Organizer',
        'time': '3 days ago',
        'priority': 'low',
        'pinned': false,
        'views': 89,
        'notificationSent': true,
      },
    ];
  }
}
