import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:get/get.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/storage_service.dart';
import '../models/inbox_message_model.dart';
import '../controllers/inbox_controller.dart';
import '../services/inbox_service.dart';

/// WebSocket message model for direct messages
class DMChatMessage {
  final int id;
  final String content;
  final String senderName;
  final int senderId;
  final int recipientId;
  final DateTime timestamp;
  final String title;
  final String messageType;
  final bool isRead;

  DMChatMessage({
    required this.id,
    required this.content,
    required this.senderName,
    required this.senderId,
    required this.recipientId,
    required this.timestamp,
    this.title = 'Direct Message',
    this.messageType = 'DIRECT',
    this.isRead = false,
  });

  factory DMChatMessage.fromJson(Map<String, dynamic> json) {
    return DMChatMessage(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      senderName: json['sender_name'] ?? 'Unknown',
      senderId: json['sender_id'] ?? 0,
      recipientId: json['recipient_id'] ?? 0,
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      title: json['title'] ?? 'Direct Message',
      messageType: json['message_type'] ?? 'DIRECT',
      isRead: json['is_read'] ?? false,
    );
  }

  /// Convert to InboxMessage for display
  InboxMessage toInboxMessage() {
    return InboxMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      messageType: messageType,
      messageTypeDisplay: messageType == 'DIRECT'
          ? 'Direct Message'
          : messageType,
      title: title,
      content: content,
      isRead: isRead,
      createdAt: timestamp,
    );
  }
}

/// WebSocket service for direct messages (1-on-1 chat)
class DMWebSocketService extends GetxController {
  WebSocketChannel? _channel;
  final RxList<DMChatMessage> messages = <DMChatMessage>[].obs;
  final RxBool isConnected = false.obs;
  final RxBool isConnecting = false.obs;
  final RxBool isLoadingHistory = false.obs;
  final RxString typingStatus = ''.obs;
  final RxString connectionError = ''.obs;

  final InboxService _inboxService = InboxService();

  int? _currentRecipientId;
  String? _currentRecipientName;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 3;

  /// Flag to indicate if we should save messages to cache on disconnect
  bool _saveOnDisconnect = true;

  /// Connect to DM WebSocket for a specific user
  void connectToDM(int recipientId, {String? recipientName}) {
    _currentRecipientId = recipientId;
    _currentRecipientName = recipientName;
    _reconnectAttempts = 0;
    connectionError.value = '';
    _saveOnDisconnect = true;

    // Load message history from REST API first
    loadMessageHistory(recipientId);

    // Then connect to WebSocket for real-time updates
    _connect();
  }

  /// Load message history from REST API
  Future<void> loadMessageHistory(int recipientId) async {
    try {
      isLoadingHistory.value = true;

      final historyMessages = await _inboxService.getConversationHistory(
        recipientId,
      );
      final currentUserId = Get.find<StorageService>().getUser()?['id'] ?? 0;
      
      print('DEBUG: Loading message history for recipientId=$recipientId');
      print('DEBUG: Current user ID=$currentUserId');

      // Clear existing messages and load from history
      messages.clear();

      for (final msg in historyMessages) {
        print('DEBUG: Message id=${msg.id}, senderId=${msg.senderId}, senderName=${msg.senderName}');
        messages.add(
          DMChatMessage(
            id: msg.id,
            content: msg.content,
            senderName: msg.senderName ?? 'Unknown',
            senderId: msg.senderId ?? 0,
            recipientId: msg.senderId == currentUserId
                ? recipientId
                : currentUserId,
            timestamp: msg.createdAt,
            title: msg.title,
            messageType: msg.messageType,
            isRead: msg.isRead,
          ),
        );
      }

      // Sort by timestamp (oldest first for chat display)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Update cache
      _saveCachedMessages();
    } catch (e) {
      print('Error loading message history: $e');
      // Fall back to cached messages if REST fails
      _loadCachedMessages(recipientId);
    } finally {
      isLoadingHistory.value = false;
    }
  }

  /// Load messages from InboxController cache (fallback)
  void _loadCachedMessages(int recipientId) {
    try {
      final inboxController = Get.find<InboxController>();
      final cachedMessages = inboxController.getCachedMessages(recipientId);

      if (cachedMessages.isNotEmpty && messages.isEmpty) {
        // Convert InboxMessage to DMChatMessage
        final currentUserId = Get.find<StorageService>().getUser()?['id'] ?? 0;

        for (final msg in cachedMessages) {
          messages.add(
            DMChatMessage(
              id: msg.id,
              content: msg.content,
              senderName: msg.senderName ?? 'Unknown',
              senderId: msg.senderId ?? 0,
              recipientId: msg.senderId == currentUserId
                  ? recipientId
                  : currentUserId,
              timestamp: msg.createdAt,
              title: msg.title,
              messageType: msg.messageType,
              isRead: msg.isRead,
            ),
          );
        }

        // Sort by timestamp
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
    } catch (e) {
      print('Error loading cached messages: $e');
    }
  }

  /// Save messages to InboxController cache
  void _saveCachedMessages() {
    if (_currentRecipientId == null) return;

    try {
      final inboxController = Get.find<InboxController>();
      final inboxMessages = messages.map((m) => m.toInboxMessage()).toList();
      inboxController.updateCachedMessages(_currentRecipientId!, inboxMessages);
    } catch (e) {
      print('Error saving cached messages: $e');
    }
  }

  void _connect() async {
    if (_currentRecipientId == null) return;

    // Don't try to reconnect indefinitely
    if (_reconnectAttempts >= maxReconnectAttempts) {
      connectionError.value =
          'Unable to connect to chat server. Please check your connection and try again.';
      isConnecting.value = false;
      return;
    }

    try {
      isConnecting.value = true;
      connectionError.value = '';

      // Get authentication token
      final storageService = Get.find<StorageService>();
      final token = await storageService.getAccessToken();

      if (token == null) {
        connectionError.value = 'Authentication required. Please log in.';
        isConnecting.value = false;
        return;
      }

      // Connect to Django Channels WebSocket for DM
      final wsUrl =
          '${AppConfig.websocketBaseUrl}/ws/chat/dm/$_currentRecipientId/?token=$token';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Wait a bit to see if connection succeeds
      await Future.delayed(const Duration(milliseconds: 500));

      isConnected.value = true;
      isConnecting.value = false;
      _reconnectAttempts = 0;

      // Listen for messages
      _channel!.stream.listen(
        (data) => _handleMessage(data),
        onDone: () {
          isConnected.value = false;
          connectionError.value = 'Connection lost';
          _reconnectAttempts++;
          if (_reconnectAttempts < maxReconnectAttempts &&
              _currentRecipientId != null) {
            Future.delayed(const Duration(seconds: 3), () {
              if (_currentRecipientId != null) _connect();
            });
          } else {
            connectionError.value = 'Disconnected from chat server';
          }
        },
        onError: (error) {
          print('DM WebSocket error: $error');
          isConnected.value = false;
          isConnecting.value = false;
          connectionError.value =
              'Chat server unavailable. Messages will not sync in real-time.';
          _reconnectAttempts++;
        },
        cancelOnError: true,
      );
    } catch (e) {
      print('Failed to connect to DM chat: $e');
      isConnected.value = false;
      isConnecting.value = false;
      connectionError.value =
          'Chat server is offline. Messages will be available once server is running.';
      _reconnectAttempts++;
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data);
      final messageType = json['type'];

      switch (messageType) {
        case 'connected':
          print('Connected to DM room: ${json['room']}');
          break;

        case 'chat_message':
          final message = DMChatMessage.fromJson(json['message']);

          // Check if message already exists
          final existsByRealId =
              message.id > 0 && messages.any((m) => m.id == message.id);
          final existsByContent = messages.any(
            (m) =>
                m.content == message.content &&
                m.timestamp.difference(message.timestamp).abs().inSeconds < 5,
          );

          if (existsByRealId) {
            print('Skipping duplicate message: ${message.id}');
            return;
          }

          if (existsByContent) {
            // Update optimistic message with real data
            final index = messages.indexWhere(
              (m) =>
                  m.content == message.content &&
                  m.timestamp.difference(message.timestamp).abs().inSeconds < 5,
            );
            if (index != -1) {
              messages[index] = message;
            }
          } else {
            // New message
            messages.add(message);

            // Update inbox controller cache and unread count
            _updateInboxOnNewMessage(message);
          }
          break;

        case 'typing':
          final userName = json['user_name'];
          final isTyping = json['is_typing'];
          if (isTyping) {
            typingStatus.value = '$userName is typing...';
          } else {
            typingStatus.value = '';
          }
          break;

        case 'messages_read':
          // The other user read our messages
          print('Messages read by user: ${json['user_id']}');
          break;

        case 'error':
          print('WebSocket error: ${json['message']}');
          break;
      }
    } catch (e) {
      print('Error handling DM message: $e');
    }
  }

  /// Update inbox controller when a new message arrives
  void _updateInboxOnNewMessage(DMChatMessage message) {
    try {
      final currentUserId = Get.find<StorageService>().getUser()?['id'] ?? 0;
      final inboxController = Get.find<InboxController>();

      // Determine the conversation partner
      final partnerId = message.senderId == currentUserId 
          ? message.recipientId 
          : message.senderId;
      
      // Get partner name - use stored recipient name for sent messages
      final partnerName = message.senderId == currentUserId 
          ? _currentRecipientName 
          : message.senderName;

      // Convert to InboxMessage
      final inboxMessage = message.toInboxMessage();

      debugPrint('[DMWebSocket] Updating inbox: partnerId=$partnerId, partnerName=$partnerName, isSent=${message.senderId == currentUserId}');

      // Add to conversation with real-time UI update
      inboxController.addMessageToConversation(
        partnerId, 
        inboxMessage,
        partnerName: partnerName,
      );

      // Only increment unread if the message is from the other user
      if (message.senderId != currentUserId) {
        inboxController.incrementUnreadCount(partnerId);
      }
    } catch (e) {
      print('Error updating inbox on new message: $e');
    }
  }

  /// Send a message via WebSocket (or REST API fallback)
  Future<void> sendMessage(
    String content, {
    String title = 'Direct Message',
  }) async {
    // Get current user info for optimistic update
    final storage = Get.find<StorageService>();
    final userData = storage.getUser();
    final currentUserId = userData?['id'] ?? 0;
    final currentUserName = userData?['full_name'] ?? 'You';

    // Optimistically add message to UI
    final optimisticMessage = DMChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      content: content,
      senderName: currentUserName,
      senderId: currentUserId,
      recipientId: _currentRecipientId ?? 0,
      timestamp: DateTime.now(),
      title: title,
      messageType: 'DIRECT',
      isRead: false,
    );
    messages.add(optimisticMessage);

    // Try WebSocket first
    if (_channel != null && isConnected.value) {
      final message = {
        'type': 'chat_message',
        'content': content,
        'title': title,
      };
      _channel!.sink.add(jsonEncode(message));
      
      // Update inbox conversation in real-time for sent message
      _updateInboxOnNewMessage(optimisticMessage);
    } else {
      // Fallback to REST API
      try {
        final inboxController = Get.find<InboxController>();
        final sentMessage = await inboxController.sendDirectMessage(
          recipientId: _currentRecipientId ?? 0,
          content: content,
          title: title,
        );

        // Update optimistic message with real data
        final realMessage = DMChatMessage(
          id: sentMessage.id,
          content: sentMessage.content,
          senderName: sentMessage.senderName ?? currentUserName,
          senderId: sentMessage.senderId ?? currentUserId,
          recipientId: _currentRecipientId ?? 0,
          timestamp: sentMessage.createdAt,
          title: sentMessage.title,
          messageType: sentMessage.messageType,
          isRead: sentMessage.isRead,
        );
        
        final index = messages.indexWhere((m) => m.id == optimisticMessage.id);
        if (index != -1) {
          messages[index] = realMessage;
        }
        
        // Update inbox conversation in real-time
        _updateInboxOnNewMessage(realMessage);
      } catch (e) {
        // Remove optimistic message on failure
        messages.removeWhere((m) => m.id == optimisticMessage.id);
        print('Failed to send message via REST: $e');
        rethrow;
      }
    }
  }

  /// Send typing indicator
  void sendTyping(bool isTyping) {
    if (_channel == null || !isConnected.value) return;

    final message = {'type': 'typing', 'is_typing': isTyping};

    _channel!.sink.add(jsonEncode(message));
  }

  /// Send read receipt
  void sendReadReceipt() {
    if (_channel == null || !isConnected.value) return;

    final message = {'type': 'read_receipt'};

    _channel!.sink.add(jsonEncode(message));
  }

  /// Load existing messages from InboxMessage list
  void loadExistingMessages(List<InboxMessage> existingMessages) {
    final currentUserId = Get.find<StorageService>().getUser()?['id'] ?? 0;

    messages.clear();
    for (final msg in existingMessages) {
      messages.add(
        DMChatMessage(
          id: msg.id,
          content: msg.content,
          senderName: msg.senderName ?? 'Unknown',
          senderId: msg.senderId ?? 0,
          recipientId: msg.senderId == currentUserId
              ? (_currentRecipientId ?? 0)
              : currentUserId,
          timestamp: msg.createdAt,
          title: msg.title,
          messageType: msg.messageType,
          isRead: msg.isRead,
        ),
      );
    }

    // Sort by timestamp
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Disconnect from WebSocket
  void disconnect() {
    // Save messages to cache before clearing
    if (_saveOnDisconnect) {
      _saveCachedMessages();
    }

    _channel?.sink.close(1000);
    _channel = null;
    isConnected.value = false;
    _currentRecipientId = null;
    _currentRecipientName = null;
    _reconnectAttempts = 0;
    messages.clear();
    typingStatus.value = '';
    connectionError.value = '';
  }

  /// Disconnect without saving (for cleanup)
  void disconnectWithoutSave() {
    _saveOnDisconnect = false;
    disconnect();
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
