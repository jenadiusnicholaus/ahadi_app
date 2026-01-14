import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:get/get.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/storage_service.dart';

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
    
    final senderName = json['sender_name'] ?? 
        (senderData is Map ? (senderData['full_name'] ?? '') : '');
    
    return ChatMessage(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      senderName: senderName.isNotEmpty ? senderName : 'Unknown',
      senderId: senderId is int ? senderId : int.tryParse(senderId.toString()) ?? 0,
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
  
  int? _currentEventId;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 3;
  
  void connectToEventChat(int eventId) {
    _currentEventId = eventId;
    _reconnectAttempts = 0;
    connectionError.value = '';
    _connect();
  }
  
  void _connect() async {
    if (_currentEventId == null) return;
    
    // Don't try to reconnect indefinitely
    if (_reconnectAttempts >= maxReconnectAttempts) {
      connectionError.value = 'Unable to connect to chat server. Please check your connection and try again.';
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
      final wsUrl = '${AppConfig.websocketBaseUrl}/ws/chat/event/$_currentEventId/?token=$token';
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
          if (_reconnectAttempts < maxReconnectAttempts && _currentEventId != null) {
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
          connectionError.value = 'Chat server unavailable. Messages will not sync.';
          _reconnectAttempts++;
        },
        cancelOnError: true,
      );
      
    } catch (e) {
      print('Failed to connect to chat: $e');
      isConnected.value = false;
      isConnecting.value = false;
      connectionError.value = 'Chat server is offline. Messages will be available once server is running.';
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
          final existsByRealId = message.id > 0 && messages.any((m) => m.id == message.id);
          final existsByContent = messages.any((m) => 
            m.content == message.content && 
            m.timestamp.difference(message.timestamp).abs().inSeconds < 5
          );
          
          if (existsByRealId) {
            // Message already loaded from REST API, skip it
            print('Skipping duplicate message (already in history): ${message.id}');
            return;
          }
          
          if (existsByContent) {
            // This is our optimistic message, update it with real data from server
            final index = messages.indexWhere((m) => 
              m.content == message.content && 
              m.timestamp.difference(message.timestamp).abs().inSeconds < 5
            );
            if (index != -1) {
              print('Updating optimistic message with server data: ${message.id}');
              messages[index] = message;
            }
          } else {
            // New message from another user or another session
            print('Adding new WebSocket message: ${message.id}');
            messages.add(message);
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
    
    final message = {
      'type': 'chat_message',
      'content': content, // Changed from 'message' to 'content'
    };
    
    _channel!.sink.add(jsonEncode(message));
  }
  
  void sendTyping(bool isTyping) {
    if (_channel == null || !isConnected.value) return;
    
    final message = {
      'type': 'typing',
      'typing': isTyping,
    };
    
    _channel!.sink.add(jsonEncode(message));
  }
  
  void disconnect() {
    _channel?.sink.close(1000);
    _channel = null;
    isConnected.value = false;
    _currentEventId = null;
    _reconnectAttempts = 0;
    messages.clear();
    typingStatus.value = '';
    connectionError.value = '';
  }
  
  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}