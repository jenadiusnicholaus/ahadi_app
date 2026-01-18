import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../services/websocket_service.dart';
import '../../events/services/event_service.dart';
import '../../auth/controllers/auth_controller.dart';

class ChatScreen extends StatefulWidget {
  final dynamic eventId;
  final String? eventTitle;
  final bool showAppBar;

  const ChatScreen({
    super.key,
    this.eventId,
    this.eventTitle,
    this.showAppBar = true,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final WebSocketService _chatService;
  late final EventService _eventService;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final RxBool _isLoading = true.obs;
  final RxString _errorMessage = ''.obs;
  bool _showEmojiPicker = false;
  int? _eventId;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadEventId();
  }

  void _initializeServices() {
    _chatService = Get.find<WebSocketService>();
    _eventService = Get.find<EventService>();
    _setupMessageListener();
  }

  void _loadEventId() {
    _eventId = widget.eventId is int
        ? widget.eventId
        : (widget.eventId != null
              ? int.tryParse(widget.eventId.toString())
              : null);

    if (_eventId == null) {
      final args = Get.arguments as Map<String, dynamic>?;
      final argEventId = args?['eventId'];
      _eventId = argEventId is int
          ? argEventId
          : (argEventId != null ? int.tryParse(argEventId.toString()) : null);
    }

    if (_eventId != null) {
      _loadMessages(_eventId!);
      _chatService.connectToEventChat(_eventId!);
    } else {
      _errorMessage.value = 'Invalid event ID';
      _isLoading.value = false;
    }
  }

  void _setupMessageListener() {
    _chatService.messages.listen((_) => _scrollToBottom());
  }

  Future<void> _loadMessages(int eventId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final messages = await _eventService.getEventMessages(eventId);
      _chatService.messages.clear();

      for (var msg in messages.reversed) {
        _chatService.messages.add(
          ChatMessage(
            id: msg.id,
            content: msg.content,
            senderName: msg.senderName ?? 'Unknown',
            senderId: msg.senderId ?? 0,
            timestamp: msg.createdAt,
            type: 'message',
            isRead: msg.toJson()['is_read'] ?? false,
          ),
        );
      }

      // Update the cache with loaded messages
      _chatService.updateCachedMessages(
        eventId,
        List.from(_chatService.messages),
      );

      _isLoading.value = false;
      await _eventService.markMessagesAsRead(eventId);

      // Reset unread count for this event
      _chatService.unreadCounts[eventId] = 0;

      _scrollToBottom();
    } catch (e) {
      _isLoading.value = false;
      _errorMessage.value = _parseErrorMessage(e.toString());
    }
  }

  String _parseErrorMessage(String error) {
    if (error.contains('Chat is not enabled')) return 'Chat is not enabled';
    if (error.contains('403')) return 'Access denied';
    if (error.contains('404')) return 'Event not found';
    return 'Failed to load messages';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _chatService.sendMessage(text);
    _messageController.clear();
    _scrollToBottom();
  }

  void _toggleEmojiPicker() {
    setState(() => _showEmojiPicker = !_showEmojiPicker);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,

      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Use dashboard controller if available, otherwise use Get.back()
            if (Get.isRegistered<DashboardController>()) {
              Get.find<DashboardController>().goBack();
            } else {
              Get.back();
            }
          },
        ),
        title: Text(
          widget.eventTitle ?? 'Event Chat',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              Get.snackbar(
                value,
                'Coming soon',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'View Event', child: Text('View Event')),
              PopupMenuItem(value: 'Mute', child: Text('Mute Notifications')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (_isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_errorMessage.value.isNotEmpty) {
                return _buildErrorView();
              }

              if (_chatService.messages.isEmpty) {
                return _buildEmptyView();
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                itemCount: _chatService.messages.length,
                itemBuilder: (context, index) {
                  return _MessageBubble(message: _chatService.messages[index]);
                },
              );
            }),
          ),
          _buildInputArea(),
          if (_showEmojiPicker) _buildEmojiPicker(),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              _errorMessage.value,
              style: TextStyle(color: Colors.red.shade600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  _eventId != null ? _loadMessages(_eventId!) : null,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _showEmojiPicker
                    ? Icons.keyboard
                    : Icons.emoji_emotions_outlined,
                color: Colors.grey.shade600,
              ),
              onPressed: _toggleEmojiPicker,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: _sendMessage,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: const Icon(Icons.send, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 250,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          _messageController.text += emoji.emoji;
        },
        config: const Config(
          emojiViewConfig: EmojiViewConfig(columns: 7, emojiSizeMax: 32),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final isMe = message.senderId == (authController.user.value?.id ?? 0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  Text(message.content, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 16,
                          color: message.isRead
                              ? const Color(0xFF34B7F1)
                              : Colors.grey.shade500,
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
