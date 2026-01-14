import 'package:ahadi/features/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../services/websocket_service.dart';
import '../../events/services/event_service.dart';

class ChatScreen extends StatefulWidget {
  final dynamic eventId;
  final String? eventTitle;
  
  const ChatScreen({
    super.key,
    this.eventId,
    this.eventTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final WebSocketService chatService = Get.put(WebSocketService());
  final EventService eventService = Get.find<EventService>();
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final RxBool isLoadingMessages = true.obs;
  final RxString loadError = ''.obs;
  bool _showEmojiPicker = false;
  
  @override
  void initState() {
    super.initState();
    
    dynamic eventId = widget.eventId;
    
    if (eventId == null) {
      final args = Get.arguments as Map<String, dynamic>?;
      eventId = args?['eventId'];
    }
    
    if (eventId != null) {
      final eventIdInt = eventId is int ? eventId : int.parse(eventId.toString());
      _loadInitialMessages(eventIdInt);
      chatService.connectToEventChat(eventIdInt);
    }
    
    chatService.messages.listen((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }
  
  Future<void> _loadInitialMessages(int eventId) async {
    try {
      isLoadingMessages.value = true;
      loadError.value = '';
      
      final messages = await eventService.getEventMessages(eventId);
      
      chatService.messages.clear();
      for (var msg in messages.reversed) {
        chatService.messages.add(ChatMessage(
          id: msg.id,
          content: msg.content,
          senderName: msg.senderName ?? 'Unknown',
          senderId: msg.senderId ?? 0,
          timestamp: msg.createdAt,
          type: 'message',
          isRead: msg.toJson()['is_read'] ?? false,
        ));
      }
      
      isLoadingMessages.value = false;
      
      eventService.markMessagesAsRead(eventId).catchError((error) {
        debugPrint('Failed to mark messages as read: $error');
      });
      
      Future.delayed(const Duration(milliseconds: 100), () {
        if (scrollController.hasClients) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('Chat is not enabled')) {
        loadError.value = 'Chat is not enabled for this event';
      } else if (errorMsg.contains('403')) {
        loadError.value = 'Access denied.';
      } else if (errorMsg.contains('404')) {
        loadError.value = 'Event not found';
      } else {
        loadError.value = 'Failed to load messages.';
      }
      isLoadingMessages.value = false;
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    
    chatService.sendMessage(text);
    messageController.clear();
    chatService.sendTyping(false);
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // Try dashboard navigation first, fallback to Get.back()
              try {
                final dashboardController = Get.find<DashboardController>();
                dashboardController.goBack();
              } catch (_) {
                Get.back();
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.eventTitle ?? 'Event Chat',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Obx(() => Text(
              chatService.isConnected.value ? 'Tap for event details' : 'Connecting...',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            )),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              Get.snackbar(value, 'Feature coming soon', snackPosition: SnackPosition.BOTTOM);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'View Event', child: Text('View Event')),
              const PopupMenuItem(value: 'Mute', child: Text('Mute')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: Container(
              color: const Color(0xFFECE5DD),
              child: Obx(() {
                if (isLoadingMessages.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (loadError.value.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                        const SizedBox(height: 16),
                        Text(loadError.value, style: TextStyle(color: Colors.red.shade600)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            final eventId = widget.eventId;
                            if (eventId != null) {
                              final eventIdInt = eventId is int ? eventId : int.parse(eventId.toString());
                              _loadInitialMessages(eventIdInt);
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (chatService.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('No messages yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Text('Start the conversation!', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatService.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatService.messages[index];
                    return _buildMessageBubble(message);
                  },
                );
              }),
            ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined),
                  onPressed: () => setState(() => _showEmojiPicker = !_showEmojiPicker),
                ),
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Message',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
          // Emoji
          if (_showEmojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  messageController.text += emoji.emoji;
                },
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final authController = Get.find<AuthController>();
    final currentUserId = authController.user.value?.id ?? 0;
    final isMe = message.senderId == currentUserId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : 'U',
                style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          if (!isMe) const SizedBox(width: 4),
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message.senderName,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  Text(message.content, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.isRead ? const Color(0xFF34B7F1) : Colors.grey.shade500,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
