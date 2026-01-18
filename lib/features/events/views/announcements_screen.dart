import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dashboard_layout.dart';
import '../controllers/events_controller.dart';
import '../services/event_service.dart';
import '../models/message_model.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final EventsController controller = Get.find<EventsController>();
  final EventService _eventService = Get.find<EventService>();
  
  int? eventId;
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = false;
  String? _errorMessage;

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
    if (eventId == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _announcements = await _eventService.getEventAnnouncements(eventId!);
      // Sort: pinned first, then by date
      _announcements.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Failed to load announcements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnnouncements,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_announcements.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _announcements.length,
        itemBuilder: (context, index) {
          final announcement = _announcements[index];
          return _buildAnnouncementCard(announcement);
        },
      ),
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel announcement) {
    final isPinned = announcement.isPinned;

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
                      Text(
                        announcement.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                            announcement.authorName ?? 'Unknown',
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
                            _formatDate(announcement.createdAt),
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
              announcement.content,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade800,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
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
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    bool isPinned = false;
    bool isLoading = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('New Announcement'),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter announcement title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                      hintText: 'Enter announcement content',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Pin this announcement'),
                    subtitle: const Text('Pinned announcements appear at the top'),
                    value: isPinned,
                    onChanged: (value) {
                      setDialogState(() => isPinned = value ?? false);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Get.back(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (titleController.text.isEmpty ||
                            contentController.text.isEmpty) {
                          Get.snackbar(
                            'Error',
                            'Please fill in all fields',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        setDialogState(() => isLoading = true);

                        try {
                          final announcement = AnnouncementModel(
                            id: 0,
                            eventId: eventId!,
                            title: titleController.text,
                            content: contentController.text,
                            isPinned: isPinned,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );
                          await _eventService.createAnnouncement(announcement);
                          Get.back();
                          Get.snackbar(
                            'Success',
                            'Announcement created successfully',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
                          _loadAnnouncements();
                        } catch (e) {
                          setDialogState(() => isLoading = false);
                          Get.snackbar(
                            'Error',
                            e.toString(),
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _togglePin(AnnouncementModel announcement) {
    // TODO: Implement toggle pin API when available
    Get.snackbar(
      'Coming Soon',
      'Pin toggle will be available soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _deleteAnnouncement(AnnouncementModel announcement) {
    Get.defaultDialog(
      title: 'Delete Announcement',
      middleText: 'Are you sure you want to delete "${announcement.title}"?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        try {
          await _eventService.deleteAnnouncement(announcement.id);
          Get.snackbar(
            'Success',
            'Announcement deleted successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          _loadAnnouncements();
        } catch (e) {
          Get.snackbar(
            'Error',
            e.toString(),
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
    );
  }
}
