import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:get/get.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/storage_service.dart';
import 'websocket_service.dart';

/// Global WebSocket service for receiving group chat notifications across the app.
/// This stays connected and updates message counts in real-time for all events.
class GroupNotificationService extends GetxService {
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
    print('🔔🔔🔔 [GroupNotification] SERVICE INITIALIZED 🔔🔔🔔');
    connect();
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }

  /// Connect to the global group notification WebSocket
  Future<void> connect() async {
    final storage = Get.find<StorageService>();
    final token = await storage.getAccessToken();

    if (token == null || token.isEmpty) {
      print('🔔 [GroupNotification] No token, skipping WebSocket connection');
      return;
    }

    try {
      final wsUrl =
          '${AppConfig.websocketBaseUrl}/ws/chat/group/notifications/?token=$token';
      print('🔔🔔🔔 [GroupNotification] CONNECTING TO: ${AppConfig.websocketBaseUrl}/ws/chat/group/notifications/ 🔔🔔🔔');

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

      print('🔔🔔🔔 [GroupNotification] CONNECTED SUCCESSFULLY 🔔🔔🔔');
    } catch (e) {
      print('🔔 [GroupNotification] Connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String);
      print('🔔🔔🔔 [GroupNotification] RECEIVED MESSAGE: ${json['type']} 🔔🔔🔔');
      print('🔔 [GroupNotification] Full data: $json');

      switch (json['type']) {
        case 'new_message':
          print('🔔 [GroupNotification] Processing new_message...');
          _handleNewMessage(json);
          break;
        case 'pong':
          // Keep-alive response
          break;
        default:
          print('🔔 [GroupNotification] Unknown message type: ${json['type']}');
      }
    } catch (e) {
      print('🔔 [GroupNotification] Error handling message: $e');
      print('🔔 [GroupNotification] Raw data: $data');
    }
  }

  void _handleNewMessage(Map<String, dynamic> json) {
    try {
      final wsService = Get.find<WebSocketService>();
      final storage = Get.find<StorageService>();
      final currentUserId = storage.getUser()?['id'] ?? 0;

      // Parse event_id and sender_id - they may come as String or int
      final eventId = json['event_id'] is int 
          ? json['event_id'] 
          : int.tryParse(json['event_id']?.toString() ?? '0') ?? 0;
      final senderId = json['sender_id'] is int 
          ? json['sender_id'] 
          : int.tryParse(json['sender_id']?.toString() ?? '0') ?? 0;

      print('[GroupNotification] New message in event $eventId from sender $senderId (current user: $currentUserId)');

      // Increment message count for this event
      wsService.messageCounts[eventId] =
          (wsService.messageCounts[eventId] ?? 0) + 1;

      // Increment unread count if message is from someone else
      if (senderId != currentUserId) {
        wsService.unreadCounts[eventId] =
            (wsService.unreadCounts[eventId] ?? 0) + 1;
        print('[GroupNotification] Unread count for event $eventId: ${wsService.unreadCounts[eventId]}');
      }

      // Trigger UI update
      wsService.countUpdateTrigger.value++;
      print('[GroupNotification] ✅ Triggered UI update, trigger: ${wsService.countUpdateTrigger.value}');
    } catch (e, stack) {
      print('[GroupNotification] Error handling new message: $e');
      print('[GroupNotification] Stack: $stack');
    }
  }

  void _handleError(dynamic error) {
    debugPrint('[GroupNotification] WebSocket error: $error');
    isConnected.value = false;
    _scheduleReconnect();
  }

  void _handleDone() {
    debugPrint('[GroupNotification] WebSocket closed');
    isConnected.value = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      debugPrint('[GroupNotification] Max reconnect attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    final delay = Duration(seconds: (2 << _reconnectAttempts).clamp(2, 30));
    _reconnectAttempts++;

    debugPrint(
      '[GroupNotification] Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)',
    );

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
    debugPrint('[GroupNotification] Disconnected');
  }

  /// Reconnect (e.g., after login)
  void reconnect() {
    disconnect();
    _reconnectAttempts = 0;
    connect();
  }
}
