import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../events/controllers/events_controller.dart';
import '../../events/models/event_model.dart';
import '../services/websocket_service.dart';
import 'event_chat_screen.dart';

/// Shows a list of event chat rooms the user is part of
class ChatRoomsListScreen extends StatelessWidget {
  final Function(int eventId, String eventTitle)? onChatSelected;

  const ChatRoomsListScreen({super.key, this.onChatSelected});

  @override
  Widget build(BuildContext context) {
    final eventsController = Get.find<EventsController>();
    final wsService = Get.find<WebSocketService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        // Watch for real-time updates - this trigger changes when counts update
        // ignore: unused_local_variable
        final trigger = wsService.countUpdateTrigger.value;

        if (eventsController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Combine my events and invited events for chat rooms
        final allEvents = [
          ...eventsController.myEvents,
          ...eventsController.invitedEvents,
        ];

        if (allEvents.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => eventsController.loadInitialData(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: allEvents.length,
            itemBuilder: (context, index) {
              final event = allEvents[index];
              final messageCount = wsService.messageCounts[event.id] ?? 0;
              final unreadCount = wsService.unreadCounts[event.id] ?? 0;

              return _ChatRoomTile(
                event: event,
                messageCount: messageCount,
                unreadCount: unreadCount,
                onTap: () {
                  // Clear unread count when opening chat
                  wsService.unreadCounts[event.id] = 0;

                  if (onChatSelected != null) {
                    onChatSelected!(event.id, event.title);
                  } else {
                    Get.to(
                      () => EventChatScreen(
                        eventId: event.id,
                        eventTitle: event.title,
                      ),
                    );
                  }
                },
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Event Chats Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Join or create an event to start chatting with participants',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final EventModel event;
  final int messageCount;
  final int unreadCount;
  final VoidCallback onTap;

  const _ChatRoomTile({
    required this.event,
    required this.messageCount,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hasUnread
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            // Event image/avatar with unread badge
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                  child: event.coverImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: CachedNetworkImage(
                            imageUrl: event.coverImage!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _buildPlaceholder(),
                            errorWidget: (_, __, ___) => _buildPlaceholder(),
                          ),
                        )
                      : _buildPlaceholder(),
                ),
                // Unread badge
                if (hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
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
            ),
            const SizedBox(width: 12),
            // Event info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: TextStyle(
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatDate(event.startDate ?? event.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnread
                              ? AppColors.primary
                              : Colors.grey.shade500,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getEventIcon(event.eventType?.name ?? ''),
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.eventType?.name ?? 'Event',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Message count
                      if (messageCount > 0)
                        Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              messageCount > 999
                                  ? '999+'
                                  : messageCount.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        _getEventIcon(event.eventType?.name ?? ''),
        size: 28,
        color: AppColors.primary,
      ),
    );
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'wedding':
        return Icons.favorite;
      case 'birthday':
        return Icons.cake;
      case 'graduation':
        return Icons.school;
      case 'funeral':
        return Icons.local_florist;
      case 'baby_shower':
        return Icons.child_care;
      default:
        return Icons.celebration;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return DateFormat.jm().format(date);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat.E().format(date);
    } else {
      return DateFormat.MMMd().format(date);
    }
  }
}
