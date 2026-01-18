 import 'inbox_message_model.dart';

/// Model representing a conversation thread with a participant
class ConversationThread {
  final int participantId;
  final String participantName;
  final String? participantAvatar;
  final List<InboxMessage> messages;
  final int unreadCount;
  final DateTime lastMessageTime;
  final String lastMessagePreview;
  final bool isSystemSender;

  ConversationThread({
    required this.participantId,
    required this.participantName,
    this.participantAvatar,
    required this.messages,
    required this.unreadCount,
    required this.lastMessageTime,
    required this.lastMessagePreview,
    this.isSystemSender = false,
  });

  /// Check if the conversation can be replied to
  /// System messages (announcements, invitations without sender) cannot be replied to
  bool get canReply => !isSystemSender && participantId > 0;

  /// Get the latest message in the thread
  InboxMessage? get latestMessage =>
      messages.isNotEmpty ? messages.first : null;

  /// Create threads from a list of messages grouped by sender
  static List<ConversationThread> fromMessages(List<InboxMessage> messages) {
    // Group messages by sender
    final Map<int, List<InboxMessage>> groupedMessages = {};
    final Map<int, String> senderNames = {};
    final Map<int, bool> isSystem = {};

    for (final message in messages) {
      final senderId = message.senderId ?? 0;
      final senderName = message.senderName ?? 'System';

      if (!groupedMessages.containsKey(senderId)) {
        groupedMessages[senderId] = [];
        senderNames[senderId] = senderName;
        isSystem[senderId] =
            senderId == 0 ||
            message.messageType == 'ANNOUNCEMENT' ||
            message.messageType == 'SYSTEM';
      }
      groupedMessages[senderId]!.add(message);
    }

    // Create conversation threads
    final threads = <ConversationThread>[];

    groupedMessages.forEach((senderId, senderMessages) {
      // Sort messages by date (newest first)
      senderMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final unreadCount = senderMessages.where((m) => !m.isRead).length;
      final latestMessage = senderMessages.first;

      threads.add(
        ConversationThread(
          participantId: senderId,
          participantName: senderNames[senderId] ?? 'Unknown',
          messages: senderMessages,
          unreadCount: unreadCount,
          lastMessageTime: latestMessage.createdAt,
          lastMessagePreview: latestMessage.content,
          isSystemSender: isSystem[senderId] ?? false,
        ),
      );
    });

    // Sort threads by last message time (newest first)
    threads.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

    return threads;
  }
}
