import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:get/get.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/api_service.dart';

class ChatMessage {
  final int id;
  final String content;
  final String senderName;
  final int senderId;
  final DateTime timestamp;
  final String type;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderName,
    required this.senderId,
    required this.timestamp,
    this.type = 'message',
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Handle both REST API format (sender: int) and WebSocket format (sender: {id, full_name})
    final senderData = json['sender'];
    final senderId = senderData is Map
        ? (senderData['id'] ?? 0)
        : (senderData ?? json['sender_id'] ?? 0);

    final senderName =
        json['sender_name'] ??
        (senderData is Map ? (senderData['full_name'] ?? '') : '');

    return ChatMessage(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      senderName: senderName.isNotEmpty ? senderName : 'Unknown',
      senderId: senderId is int
          ? senderId
          : int.tryParse(senderId.toString()) ?? 0,
      timestamp: DateTime.parse(json['created_at']),
      type: json['type'] ?? 'message',
      isRead: json['is_read'] ?? false,
    );
  }
}

class WebSocketService extends GetxController {
  WebSocketChannel? _channel;
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isConnected = false.obs;
  final RxBool isConnecting = false.obs;
  final RxString typingStatus = ''.obs;
  final RxString connectionError = ''.obs;

  // Track unread counts per event
  final RxMap<int, int> unreadCounts = <int, int>{}.obs;

  // Track total message counts per event (for display)
  final RxMap<int, int> messageCounts = <int, int>{}.obs;

  // Trigger for UI updates - increment this when counts change
  final RxInt countUpdateTrigger = 0.obs;

  // Cache messages per event - persists when leaving chat
  final RxMap<int, List<ChatMessage>> messageCache =
      <int, List<ChatMessage>>{}.obs;

  int? _currentEventId;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 3;

  /// Flag to indicate if we should save messages to cache on disconnect
  bool _saveOnDisconnect = true;

  /// Fetch unread message count for an event
  Future<int> getUnreadCount(int eventId) async {
    try {
      final api = Get.find<ApiService>();
      final response = await api.dio.get(ApiEndpoints.chatUnreadCount(eventId));
      final count = response.data['unread_count'] ?? 0;
      unreadCounts[eventId] = count;
      return count;
    } catch (e) {
      print('Failed to get unread count: $e');
      return 0;
    }
  }

  /// Fetch unread counts for multiple events
  Future<void> fetchUnreadCounts(List<int> eventIds) async {
    for (final eventId in eventIds) {
      await getUnreadCount(eventId);
    }
  }

  /// Mark messages as read for an event
  Future<void> markMessagesRead(int eventId) async {
    try {
      final api = Get.find<ApiService>();
      await api.dio.post(ApiEndpoints.markMessagesRead(eventId));
      unreadCounts[eventId] = 0;
    } catch (e) {
      print('Failed to mark messages as read: $e');
    }
  }

  void connectToEventChat(int eventId) {
    _currentEventId = eventId;
    _reconnectAttempts = 0;
    connectionError.value = '';
    _saveOnDisconnect = true;

    // Load cached messages for this event
    _loadCachedMessages(eventId);

    // Mark messages as read when opening
    markMessagesRead(eventId);

    _connect();
  }

  /// Load messages from cache
  void _loadCachedMessages(int eventId) {
    final cached = messageCache[eventId];
    if (cached != null && cached.isNotEmpty && messages.isEmpty) {
      messages.addAll(cached);
    }
  }

  /// Save messages to cache
  void _saveMessagesToCache() {
    if (_currentEventId != null && messages.isNotEmpty) {
      messageCache[_currentEventId!] = List.from(messages);
    }
  }

  /// Get cached messages for an event
  List<ChatMessage> getCachedMessages(int eventId) {
    return messageCache[eventId] ?? [];
  }

  /// Update cached messages for an event
  void updateCachedMessages(int eventId, List<ChatMessage> newMessages) {
    messageCache[eventId] = newMessages;
    messageCache.refresh();
  }

  void _connect() async {
    if (_currentEventId == null) return;

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

      // Connect to Django Channels WebSocket using configured URL with token
      final wsUrl =
          '${AppConfig.websocketBaseUrl}/ws/chat/event/$_currentEventId/?token=$token';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Wait a bit to see if connection succeeds
      await Future.delayed(const Duration(milliseconds: 500));

      isConnected.value = true;
      isConnecting.value = false;
      _reconnectAttempts = 0; // Reset on successful connection

      // Listen for messages
      _channel!.stream.listen(
        (data) => _handleMessage(data),
        onDone: () {
          isConnected.value = false;
          connectionError.value = 'Connection lost';
          // Try to reconnect after 3 seconds
          _reconnectAttempts++;
          if (_reconnectAttempts < maxReconnectAttempts &&
              _currentEventId != null) {
            Future.delayed(const Duration(seconds: 3), () {
              if (_currentEventId != null) _connect();
            });
          } else {
            connectionError.value = 'Disconnected from chat server';
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          isConnected.value = false;
          isConnecting.value = false;
          connectionError.value =
              'Chat server unavailable. Messages will not sync.';
          _reconnectAttempts++;
        },
        cancelOnError: true,
      );
    } catch (e) {
      print('Failed to connect to chat: $e');
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
        case 'chat_message':
          final message = ChatMessage.fromJson(json['message']);

          // Check if message already exists by ID (from REST API) or content+timestamp (from optimistic update)
          final existsByRealId =
              message.id > 0 && messages.any((m) => m.id == message.id);
          final existsByContent = messages.any(
            (m) =>
                m.content == message.content &&
                m.timestamp.difference(message.timestamp).abs().inSeconds < 5,
          );

          if (existsByRealId) {
            // Message already loaded from REST API, skip it
            print(
              'Skipping duplicate message (already in history): ${message.id}',
            );
            return;
          }

          if (existsByContent) {
            // This is our optimistic message, update it with real data from server
            final index = messages.indexWhere(
              (m) =>
                  m.content == message.content &&
                  m.timestamp.difference(message.timestamp).abs().inSeconds < 5,
            );
            if (index != -1) {
              print(
                'Updating optimistic message with server data: ${message.id}',
              );
              messages[index] = message;
            }
          } else {
            // New message from another user or another session
            print('Adding new WebSocket message: ${message.id}');
            messages.add(message);
            
            // Update message count for this event
            if (_currentEventId != null) {
              messageCounts[_currentEventId!] = messages.length;
              messageCounts.refresh();
              
              // Increment unread if message is from someone else
              final storage = Get.find<StorageService>();
              final currentUserId = storage.getUser()?['id'] ?? 0;
              if (message.senderId != currentUserId) {
                unreadCounts[_currentEventId!] = (unreadCounts[_currentEventId!] ?? 0) + 1;
                unreadCounts.refresh();
              }
            }
          }
          break;
        case 'typing':
          final userName = json['user_name'];
          final isTyping = json['typing'];
          if (isTyping) {
            typingStatus.value = '$userName is typing...';
          } else {
            typingStatus.value = '';
          }
          break;
      }
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  void sendMessage(String content) {
    if (_channel == null || !isConnected.value) return;

    // Get current user ID for optimistic message
    final storage = Get.find<StorageService>();
    final userData = storage.getUser();
    final currentUserId = userData?['id'] ?? 0;

    // Optimistically add message to UI immediately
    final optimisticMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
      content: content,
      senderName: 'You',
      senderId: currentUserId, // Use actual current user ID
      timestamp: DateTime.now(),
      type: 'message',
      isRead: false, // Not read yet
    );
    messages.add(optimisticMessage);
    
    // Update message count immediately
    if (_currentEventId != null) {
      messageCounts[_currentEventId!] = messages.length;
      messageCounts.refresh();
    }

    final message = {
      'type': 'chat_message',
      'content': content, // Changed from 'message' to 'content'
    };

    _channel!.sink.add(jsonEncode(message));
  }

  void sendTyping(bool isTyping) {
    if (_channel == null || !isConnected.value) return;

    final message = {'type': 'typing', 'typing': isTyping};

    _channel!.sink.add(jsonEncode(message));
  }

  void disconnect() {
    // Save messages to cache before clearing
    if (_saveOnDisconnect) {
      _saveMessagesToCache();
    }

    _channel?.sink.close(1000);
    _channel = null;
    isConnected.value = false;
    _currentEventId = null;
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
