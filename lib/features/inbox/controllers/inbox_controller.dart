import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/inbox_message_model.dart';
import '../services/inbox_service.dart';

/// Represents a grouped conversation with a sender
class SenderConversation {
  final int senderId;
  final String senderName;
  final List<InboxMessage> messages;
  final int unreadCount;
  final DateTime lastMessageTime;
  final String lastMessagePreview;
  final bool isSystem;

  SenderConversation({
    required this.senderId,
    required this.senderName,
    required this.messages,
    required this.unreadCount,
    required this.lastMessageTime,
    required this.lastMessagePreview,
    required this.isSystem,
  });

  bool get canReply => !isSystem && senderId > 0;

  /// Create a copy with updated values
  SenderConversation copyWith({
    int? senderId,
    String? senderName,
    List<InboxMessage>? messages,
    int? unreadCount,
    DateTime? lastMessageTime,
    String? lastMessagePreview,
    bool? isSystem,
  }) {
    return SenderConversation(
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      messages: messages ?? this.messages,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      isSystem: isSystem ?? this.isSystem,
    );
  }
}

class InboxController extends GetxController {
  final InboxService _inboxService = InboxService();

  final RxList<InboxMessage> messages = <InboxMessage>[].obs;
  final RxList<SenderConversation> conversations = <SenderConversation>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString error = ''.obs;
  
  /// Counter that increments on every conversation update - used to trigger UI rebuilds
  final RxInt conversationUpdateCounter = 0.obs;

  /// Cache for direct message conversations - persists when leaving chat
  /// Key: recipientId, Value: List of messages
  final RxMap<int, List<InboxMessage>> dmMessageCache =
      <int, List<InboxMessage>>{}.obs;

  /// Track unread counts per conversation partner
  final RxMap<int, int> dmUnreadCounts = <int, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadInboxMessages();
  }

  /// Group messages by sender to create conversations
  void _groupMessagesBySender(List<InboxMessage> inboxMessages) {
    final Map<int, List<InboxMessage>> grouped = {};
    final Map<int, String> senderNames = {};
    final Map<int, bool> isSystem = {};

    for (final message in inboxMessages) {
      final senderId = message.senderId ?? 0;
      final senderName = message.senderName ?? 'System';

      if (!grouped.containsKey(senderId)) {
        grouped[senderId] = [];
        senderNames[senderId] = senderName;
        isSystem[senderId] =
            senderId == 0 ||
            message.messageType == 'ANNOUNCEMENT' ||
            message.messageType == 'SYSTEM';
      }
      grouped[senderId]!.add(message);
    }

    final List<SenderConversation> result = [];

    grouped.forEach((senderId, senderMessages) {
      // Sort by date (newest first)
      senderMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final unread = senderMessages.where((m) => !m.isRead).length;
      final latest = senderMessages.first;

      result.add(
        SenderConversation(
          senderId: senderId,
          senderName: senderNames[senderId] ?? 'Unknown',
          messages: senderMessages,
          unreadCount: unread,
          lastMessageTime: latest.createdAt,
          lastMessagePreview: latest.content,
          isSystem: isSystem[senderId] ?? false,
        ),
      );

      // Update unread counts map for each sender
      dmUnreadCounts[senderId] = unread;
    });

    // Sort by last message time (newest first)
    result.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    conversations.value = result;
  }

  /// Load inbox messages using the new conversations endpoint
  Future<void> loadInboxMessages() async {
    try {
      isLoading.value = true;
      error.value = '';

      // Use the new conversations endpoint that returns both sent and received
      final conversationSummaries = await _inboxService.getConversations();
      
      // Convert to SenderConversation format
      final List<SenderConversation> convs = [];
      final List<InboxMessage> allMessages = [];
      
      for (final conv in conversationSummaries) {
        // Collect all messages
        allMessages.addAll(conv.messages);
        
        // Sort messages by date (newest first for preview)
        final sortedMessages = List<InboxMessage>.from(conv.messages)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        convs.add(SenderConversation(
          senderId: conv.partnerId,
          senderName: conv.partnerName,
          messages: sortedMessages,
          unreadCount: conv.unreadCount,
          lastMessageTime: conv.lastMessageTime ?? DateTime.now(),
          lastMessagePreview: conv.lastMessage ?? '',
          isSystem: false,
        ));
        
        // Update unread counts map
        dmUnreadCounts[conv.partnerId] = conv.unreadCount;
        
        // Cache messages
        dmMessageCache[conv.partnerId] = sortedMessages;
      }
      
      messages.value = allMessages;
      conversations.value = convs;

      // Also load unread count
      await loadUnreadCount();
    } catch (e) {
      error.value = 'Failed to load inbox messages: $e';
      print('Error in loadInboxMessages: $e');
      
      // Fall back to old method if new endpoint fails
      try {
        final inboxMessages = await _inboxService.getInboxMessages();
        messages.value = inboxMessages;
        _groupMessagesBySender(inboxMessages);
        _cacheConversationMessages(inboxMessages);
      } catch (e2) {
        print('Fallback also failed: $e2');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Cache messages for each conversation
  void _cacheConversationMessages(List<InboxMessage> inboxMessages) {
    // Group by sender and cache
    final Map<int, List<InboxMessage>> grouped = {};

    for (final message in inboxMessages) {
      final senderId = message.senderId ?? 0;
      if (senderId > 0) {
        // Skip system messages
        if (!grouped.containsKey(senderId)) {
          grouped[senderId] = [];
        }
        grouped[senderId]!.add(message);
      }
    }

    // Update cache
    grouped.forEach((senderId, msgs) {
      dmMessageCache[senderId] = msgs;
    });
  }

  /// Get cached messages for a conversation
  List<InboxMessage> getCachedMessages(int recipientId) {
    return dmMessageCache[recipientId] ?? [];
  }

  /// Update cached messages for a conversation
  void updateCachedMessages(int recipientId, List<InboxMessage> newMessages) {
    dmMessageCache[recipientId] = newMessages;
    dmMessageCache.refresh();
  }

  /// Add a message to the cache
  void addMessageToCache(int recipientId, InboxMessage message) {
    if (!dmMessageCache.containsKey(recipientId)) {
      dmMessageCache[recipientId] = [];
    }
    // Check if message already exists
    final exists = dmMessageCache[recipientId]!.any((m) => m.id == message.id);
    if (!exists) {
      dmMessageCache[recipientId]!.add(message);
      dmMessageCache.refresh();
    }
  }

  /// Get unread count for a specific user
  int getUnreadCountForUser(int userId) {
    return dmUnreadCounts[userId] ?? 0;
  }

  /// Mark conversation as read (locally and on server)
  Future<void> markConversationAsRead(int senderId) async {
    try {
      // Get all unread messages from this sender
      final conversation = conversations.firstWhereOrNull(
        (c) => c.senderId == senderId,
      );
      if (conversation == null) return;

      // Mark each unread message as read
      for (final message in conversation.messages) {
        if (!message.isRead) {
          await _inboxService.markAsRead(message.id);

          // Update local state
          final index = messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            messages[index] = messages[index].copyWith(
              isRead: true,
              readAt: DateTime.now(),
            );
          }
        }
      }

      // Update unread count for this sender
      dmUnreadCounts[senderId] = 0;
      dmUnreadCounts.refresh();

      // Re-group messages to update conversations
      _groupMessagesBySender(messages);

      // Update total unread count
      await loadUnreadCount();
    } catch (e) {
      print('Error marking conversation as read: $e');
    }
  }

  /// Increment unread count for a sender (when new message arrives)
  void incrementUnreadCount(int senderId) {
    dmUnreadCounts[senderId] = (dmUnreadCounts[senderId] ?? 0) + 1;
    unreadCount.value = unreadCount.value + 1;
    dmUnreadCounts.refresh();
  }

  /// Add a new message to conversation and update counts in real-time
  void addMessageToConversation(int partnerId, InboxMessage message, {String? partnerName}) {
    debugPrint('[InboxController] addMessageToConversation called: partnerId=$partnerId, partnerName=$partnerName');
    debugPrint('[InboxController] Message: id=${message.id}, content=${message.content}');
    
    // Add to messages list
    final existsInMessages = messages.any((m) => m.id == message.id);
    if (!existsInMessages) {
      messages.add(message);
    }
    
    // Add to cache
    addMessageToCache(partnerId, message);
    
    // Update or create conversation
    final existingConvIndex = conversations.indexWhere((c) => c.senderId == partnerId);
    debugPrint('[InboxController] Existing conversation index: $existingConvIndex');
    
    if (existingConvIndex != -1) {
      // Update existing conversation
      final existingConv = conversations[existingConvIndex];
      final updatedMessages = List<InboxMessage>.from(existingConv.messages);
      
      // Check if message already exists
      final existsInConv = updatedMessages.any((m) => m.id == message.id);
      if (!existsInConv) {
        updatedMessages.add(message);
        debugPrint('[InboxController] Added message. New count: ${updatedMessages.length}');
        // Sort by date (newest first)
        updatedMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        debugPrint('[InboxController] Message already exists in conversation');
      }
      
      conversations[existingConvIndex] = existingConv.copyWith(
        messages: updatedMessages,
        lastMessageTime: message.createdAt,
        lastMessagePreview: message.content,
        unreadCount: message.isRead ? existingConv.unreadCount : existingConv.unreadCount + 1,
      );
    } else {
      // Create new conversation
      debugPrint('[InboxController] Creating new conversation for partnerId=$partnerId');
      conversations.add(SenderConversation(
        senderId: partnerId,
        senderName: partnerName ?? message.senderName ?? 'Unknown',
        messages: [message],
        unreadCount: message.isRead ? 0 : 1,
        lastMessageTime: message.createdAt,
        lastMessagePreview: message.content,
        isSystem: false,
      ));
    }
    
    // Sort conversations by last message time
    conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    
    // Refresh to trigger UI updates
    final oldCounter = conversationUpdateCounter.value;
    conversationUpdateCounter.value = oldCounter + 1;
    debugPrint('[InboxController] Counter updated: $oldCounter -> ${conversationUpdateCounter.value}');
    conversations.refresh();
    messages.refresh();
  }

  /// Load unread count
  Future<void> loadUnreadCount() async {
    try {
      final count = await _inboxService.getUnreadCount();
      unreadCount.value = count;
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  /// Mark message as read
  Future<void> markAsRead(int messageId) async {
    try {
      await _inboxService.markAsRead(messageId);

      // Update local state
      final index = messages.indexWhere((m) => m.id == messageId);
      if (index != -1 && !messages[index].isRead) {
        messages[index] = messages[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        messages.refresh();

        // Decrement unread count
        if (unreadCount.value > 0) {
          unreadCount.value--;
        }

        // Re-group messages
        _groupMessagesBySender(messages);
      }
    } catch (e) {
      print('Error marking message as read: $e');
      Get.snackbar(
        'Error',
        'Failed to mark message as read',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Mark message as read locally (from WebSocket notification)
  void markMessageAsReadLocally(int messageId) {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index != -1 && !messages[index].isRead) {
      messages[index] = messages[index].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
      messages.refresh();

      // Decrement unread count
      if (unreadCount.value > 0) {
        unreadCount.value--;
      }

      // Update conversation unread count
      for (int i = 0; i < conversations.length; i++) {
        final conv = conversations[i];
        final msgIndex = conv.messages.indexWhere((m) => m.id == messageId);
        if (msgIndex != -1) {
          final updatedMessages = List<InboxMessage>.from(conv.messages);
          updatedMessages[msgIndex] = updatedMessages[msgIndex].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
          conversations[i] = conv.copyWith(
            messages: updatedMessages,
            unreadCount: (conv.unreadCount > 0) ? conv.unreadCount - 1 : 0,
          );
          break;
        }
      }
      conversations.refresh();
      conversationUpdateCounter.value++;
    }
  }

  /// Mark all messages as read
  Future<void> markAllAsRead() async {
    try {
      await _inboxService.markAllAsRead();

      // Update local state
      messages.value = messages.map((m) {
        if (!m.isRead) {
          return m.copyWith(isRead: true, readAt: DateTime.now());
        }
        return m;
      }).toList();
      messages.refresh();

      unreadCount.value = 0;

      // Re-group messages
      _groupMessagesBySender(messages);

      Get.snackbar(
        'Success',
        'All messages marked as read',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error marking all as read: $e');
      Get.snackbar(
        'Error',
        'Failed to mark all messages as read',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Send invitation
  Future<void> sendInvitation({
    required int eventId,
    List<int>? participantIds,
    bool sendToSelf = false,
  }) async {
    try {
      await _inboxService.sendInvitation(
        eventId: eventId,
        participantIds: participantIds,
        sendToSelf: sendToSelf,
      );

      Get.snackbar(
        'Success',
        'Invitation sent successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Reload messages after a delay to get the new invitation
      Future.delayed(Duration(seconds: 2), () {
        loadInboxMessages();
      });
    } catch (e) {
      print('Error sending invitation: $e');
      Get.snackbar(
        'Error',
        'Failed to send invitation',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Send direct message to another user
  Future<InboxMessage> sendDirectMessage({
    required int recipientId,
    required String content,
    String? title,
    int? eventId,
  }) async {
    try {
      final message = await _inboxService.sendDirectMessage(
        recipientId: recipientId,
        content: content,
        title: title,
        eventId: eventId,
      );

      // The message is sent, not received, so don't add to inbox
      // But if sending to self, refresh inbox
      return message;
    } catch (e) {
      print('Error sending direct message: $e');
      rethrow;
    }
  }

  /// Get unread messages
  List<InboxMessage> get unreadMessages {
    return messages.where((m) => !m.isRead).toList();
  }

  /// Get read messages
  List<InboxMessage> get readMessages {
    return messages.where((m) => m.isRead).toList();
  }

  /// Refresh
  Future<void> refresh() async {
    await loadInboxMessages();
  }
}
