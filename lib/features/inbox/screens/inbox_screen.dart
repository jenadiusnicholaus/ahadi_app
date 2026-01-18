import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/inbox_controller.dart';
import '../../events/controllers/events_controller.dart';
import '../../events/models/participant_model.dart';
import 'direct_message_chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({Key? key}) : super(key: key);

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final InboxController inboxController = Get.find<InboxController>();
  late final EventsController eventsController;
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  final RxBool _isLoadingParticipants = false.obs;
  final RxList<ParticipantModel> _allParticipants = <ParticipantModel>[].obs;

  @override
  void initState() {
    super.initState();
    eventsController = Get.find<EventsController>();
    _loadAllParticipants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllParticipants() async {
    _isLoadingParticipants.value = true;
    try {
      // Collect participants from all user's events
      final Set<int> loadedParticipantIds = {};
      final List<ParticipantModel> participants = [];

      // Load participants from my events and invited events
      final allEvents = [
        ...eventsController.myEvents,
        ...eventsController.invitedEvents,
      ];

      for (final event in allEvents) {
        await eventsController.loadEventParticipants(event.id);
        for (final participant in eventsController.currentEventParticipants) {
          // Avoid duplicates by checking userId or participant id
          final uniqueKey = participant.userId ?? participant.id;
          if (!loadedParticipantIds.contains(uniqueKey)) {
            loadedParticipantIds.add(uniqueKey);
            participants.add(participant);
          }
        }
      }

      _allParticipants.value = participants;
    } catch (e) {
      debugPrint('Error loading participants: $e');
    } finally {
      _isLoadingParticipants.value = false;
    }
  }

  List<ParticipantModel> get _filteredParticipants {
    if (_searchQuery.value.isEmpty) {
      return _allParticipants;
    }
    final query = _searchQuery.value.toLowerCase();
    return _allParticipants.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.email.toLowerCase().contains(query) ||
          p.phone.contains(query);
    }).toList();
  }

  // Get unread count for a specific participant
  int _getUnreadCountForParticipant(ParticipantModel participant) {
    // Skip if participant has no userId
    if (participant.userId == null) return 0;

    // First check the dmUnreadCounts map for real-time updates
    final dmCount = inboxController.dmUnreadCounts[participant.userId!] ?? 0;
    if (dmCount > 0) return dmCount;

    // Fall back to conversation data
    final conversation = inboxController.conversations.firstWhereOrNull(
      (c) => c.senderId == participant.userId,
    );
    return conversation?.unreadCount ?? 0;
  }

  // Get message count for a specific participant
  int _getMessageCountForParticipant(ParticipantModel participant) {
    // Log all conversations and their senderIds
    debugPrint('[InboxScreen] Participant: ${participant.name} (userId=${participant.userId}, participantId=${participant.id})');
    for (final conv in inboxController.conversations) {
      debugPrint('[InboxScreen]   -> Conversation: senderId=${conv.senderId}, name=${conv.senderName}, msgCount=${conv.messages.length}');
    }
    
    final conversation = inboxController.conversations.firstWhereOrNull(
      (c) => c.senderId == participant.userId,
    );
    debugPrint('[InboxScreen] Match for ${participant.name}: ${conversation != null ? "YES (${conversation.messages.length} msgs)" : "NO"}');
    return conversation?.messages.length ?? 0;
  }

  // Check if participant has any messages
  SenderConversation? _getConversationForParticipant(
    ParticipantModel participant,
  ) {
    return inboxController.conversations.firstWhereOrNull(
      (c) => c.senderId == participant.userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await inboxController.refresh();
          await _loadAllParticipants();
        },
        child: Obx(() {
          // Show loading spinner when either is loading
          if (inboxController.isLoading.value || _isLoadingParticipants.value) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error state if there's an error
          if (inboxController.error.value.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load inbox',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      inboxController.error.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      inboxController.refresh();
                      _loadAllParticipants();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => _searchQuery.value = value,
                    decoration: InputDecoration(
                      hintText: 'Search participants...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: Obx(
                        () => _searchQuery.value.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchQuery.value = '';
                                },
                              )
                            : const SizedBox.shrink(),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),

              // Messages section header (only show if there are messages)
              if (inboxController.conversations.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.mail, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Recent Messages',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const Spacer(),
                        if (inboxController.unreadCount.value > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${inboxController.unreadCount.value} unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Messages list
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final conversation = inboxController.conversations[index];
                    return _ConversationTile(
                      conversation: conversation,
                      onTap: () => _openConversation(conversation),
                    );
                  }, childCount: inboxController.conversations.length),
                ),
                const SliverToBoxAdapter(child: Divider(height: 32)),
              ],

              // All participants section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.people, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'All Participants',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_filteredParticipants.length} people',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Participants list or empty state
              Obx(() {
                // Watch the update counter to force rebuilds when conversations change
                final updateCount = inboxController.conversationUpdateCounter.value;
                final _ = inboxController.dmUnreadCounts.length;
                final convCount = inboxController.conversations.length;
                
                debugPrint('[InboxScreen] Rebuilding: updateCount=$updateCount, convCount=$convCount');
                
                final participants = _filteredParticipants;

                if (participants.isEmpty && _allParticipants.isEmpty) {
                  return SliverFillRemaining(child: _buildEmptyState());
                }

                if (participants.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No participants found for "${_searchQuery.value}"',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final participant = participants[index];
                    final conversation = _getConversationForParticipant(
                      participant,
                    );
                    final unreadCount = _getUnreadCountForParticipant(
                      participant,
                    );
                    final messageCount = _getMessageCountForParticipant(
                      participant,
                    );

                    return _ParticipantTile(
                      participant: participant,
                      unreadCount: unreadCount,
                      messageCount: messageCount,
                      onTap: () {
                        if (conversation != null) {
                          _openConversation(conversation);
                        } else {
                          _openComposeMessage(participant);
                        }
                      },
                    );
                  }, childCount: participants.length),
                );
              }),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No participants yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Join or create events to see participants',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _openConversation(SenderConversation conversation) {
    // Mark only received unread messages as read (where sender is the conversation partner)
    // We only need to mark messages where we are the RECIPIENT, not the sender
    for (final message in conversation.messages) {
      if (!message.isRead && message.senderId == conversation.senderId) {
        // This is a message FROM them TO us - mark it as read
        inboxController.markAsRead(message.id);
      }
    }

    // Navigate to direct message chat screen and refresh on return
    Get.to(
      () => DirectMessageChatScreen(
        recipientId: conversation.senderId,
        recipientName: conversation.senderName,
        existingMessages: conversation.messages,
      ),
    )?.then((_) {
      // Refresh conversations when returning from chat
      debugPrint('[InboxScreen] Returned from chat, forcing refresh');
      inboxController.conversationUpdateCounter.value++;
      inboxController.conversations.refresh();
    });
  }

  void _openComposeMessage(ParticipantModel participant) {
    if (participant.userId == null) {
      Get.snackbar(
        'Cannot Message',
        'This participant is not a registered user',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Open direct message chat screen for new conversation and refresh on return
    Get.to(
      () => DirectMessageChatScreen(
        recipientId: participant.userId!,
        recipientName: participant.name,
      ),
    )?.then((_) {
      // Refresh conversations when returning from chat
      debugPrint('[InboxScreen] Returned from compose, forcing refresh');
      inboxController.conversationUpdateCounter.value++;
      inboxController.conversations.refresh();
    });
  }
}

/// Tile widget to display a participant
class _ParticipantTile extends StatelessWidget {
  final ParticipantModel participant;
  final int unreadCount;
  final int messageCount;
  final VoidCallback onTap;

  const _ParticipantTile({
    required this.participant,
    required this.unreadCount,
    required this.messageCount,
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
          color: hasUnread ? Colors.blue.shade50 : Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    participant.name.isNotEmpty
                        ? participant.name[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                // Unread badge
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
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
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          participant.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (messageCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: hasUnread
                                ? AppColors.primary
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$messageCount',
                            style: TextStyle(
                              fontSize: 11,
                              color: hasUnread
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (participant.email.isNotEmpty) ...[
                        Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            participant.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else if (participant.phone.isNotEmpty) ...[
                        Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          participant.phone,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ] else
                        Text(
                          'Tap to send message',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Message icon
            Icon(
              messageCount > 0 ? Icons.chat_bubble : Icons.chat_bubble_outline,
              color: messageCount > 0 ? AppColors.primary : Colors.grey[400],
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile widget to display a conversation with a sender
class _ConversationTile extends StatelessWidget {
  final SenderConversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hasUnread ? Colors.blue.shade50 : Colors.white,
        ),
        child: Row(
          children: [
            // Avatar with initials or system icon
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: conversation.isSystem
                      ? Colors.orange.shade100
                      : Colors.blue.shade100,
                  child: conversation.isSystem
                      ? Icon(
                          Icons.campaign,
                          color: Colors.orange.shade700,
                          size: 28,
                        )
                      : Text(
                          _getInitials(conversation.senderName),
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                ),
                // Unread badge
                if (conversation.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        conversation.unreadCount > 9
                            ? '9+'
                            : '${conversation.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.senderName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(conversation.lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnread ? Colors.blue : Colors.grey[500],
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Message count and preview
                  Row(
                    children: [
                      if (conversation.messages.length > 1) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conversation.messages.length}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          conversation.lastMessagePreview,
                          style: TextStyle(
                            fontSize: 14,
                            color: hasUnread
                                ? Colors.black87
                                : Colors.grey[600],
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // Show if can't reply
                  if (!conversation.canReply) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'System message',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Chevron
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return '?';
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }
}
