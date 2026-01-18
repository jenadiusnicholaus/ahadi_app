import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:get/get.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/storage_service.dart';
import '../controllers/inbox_controller.dart';
import '../models/inbox_message_model.dart';

/// Global WebSocket service for receiving DM notifications across the app.
/// This stays connected and updates inbox counts in real-time.
class InboxNotificationService extends GetxService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  
  final RxBool isConnected = false.obs;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  @override
  void onInit() {
    super.onInit();
    // Connect when service initializes
    connect();
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }

  /// Connect to the global DM notification WebSocket
  Future<void> connect() async {
    final storage = Get.find<StorageService>();
    final token = await storage.getAccessToken();
    
    if (token == null || token.isEmpty) {
      debugPrint('[InboxNotification] No token, skipping WebSocket connection');
      return;
    }

    try {
      final wsUrl = '${AppConfig.websocketBaseUrl}/ws/chat/dm/notifications/?token=$token';
      debugPrint('[InboxNotification] Connecting to: $wsUrl');
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );
      
      isConnected.value = true;
      _reconnectAttempts = 0;
      
      // Start ping timer to keep connection alive
      _startPingTimer();
      
      debugPrint('[InboxNotification] Connected successfully');
    } catch (e) {
      debugPrint('[InboxNotification] Connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String);
      debugPrint('[InboxNotification] Received: ${json['type']}');
      
      switch (json['type']) {
        case 'new_message':
          _handleNewMessage(json);
          break;
        case 'message_read':
          _handleMessageRead(json);
          break;
        case 'pong':
          // Keep-alive response
          break;
      }
    } catch (e) {
      debugPrint('[InboxNotification] Error handling message: $e');
    }
  }

  void _handleNewMessage(Map<String, dynamic> json) {
    try {
      final inboxController = Get.find<InboxController>();
      final storage = Get.find<StorageService>();
      final currentUserId = storage.getUser()?['id'] ?? 0;
      
      final senderId = json['sender_id'] ?? 0;
      final recipientId = json['recipient_id'] ?? 0;
      final senderName = json['sender_name'] ?? 'Unknown';
      
      // Determine partner
      final partnerId = senderId == currentUserId ? recipientId : senderId;
      final partnerName = senderId == currentUserId ? (json['recipient_name'] ?? 'Unknown') : senderName;
      
      // Create InboxMessage
      final message = InboxMessage(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch,
        senderId: senderId,
        senderName: senderName,
        recipientId: recipientId,
        recipientName: json['recipient_name'],
        messageType: json['message_type'] ?? 'DIRECT',
        messageTypeDisplay: 'Direct Message',
        title: json['title'] ?? 'Direct Message',
        content: json['content'] ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        isRead: json['is_read'] ?? false,
      );
      
      debugPrint('[InboxNotification] New message from $partnerName (id=$partnerId)');
      
      // Add to conversation
      inboxController.addMessageToConversation(
        partnerId,
        message,
        partnerName: partnerName,
      );
      
      // Increment unread if message is from someone else
      if (senderId != currentUserId) {
        inboxController.incrementUnreadCount(partnerId);
      }
    } catch (e) {
      debugPrint('[InboxNotification] Error handling new message: $e');
    }
  }

  void _handleMessageRead(Map<String, dynamic> json) {
    try {
      final inboxController = Get.find<InboxController>();
      final messageId = json['message_id'];
      
      if (messageId != null) {
        // Update message read status locally
        inboxController.markMessageAsReadLocally(messageId);
      }
    } catch (e) {
      debugPrint('[InboxNotification] Error handling message read: $e');
    }
  }

  void _handleError(dynamic error) {
    debugPrint('[InboxNotification] WebSocket error: $error');
    isConnected.value = false;
    _scheduleReconnect();
  }

  void _handleDone() {
    debugPrint('[InboxNotification] WebSocket closed');
    isConnected.value = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      debugPrint('[InboxNotification] Max reconnect attempts reached');
      return;
    }
    
    _reconnectTimer?.cancel();
    final delay = Duration(seconds: (2 << _reconnectAttempts).clamp(2, 30));
    _reconnectAttempts++;
    
    debugPrint('[InboxNotification] Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');
    
    _reconnectTimer = Timer(delay, connect);
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_channel != null && isConnected.value) {
        _channel!.sink.add(jsonEncode({'type': 'ping'}));
      }
    });
  }

  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close(1000);
    _channel = null;
    isConnected.value = false;
    debugPrint('[InboxNotification] Disconnected');
  }

  /// Reconnect (e.g., after login)
  void reconnect() {
    disconnect();
    _reconnectAttempts = 0;
    connect();
  }
}
