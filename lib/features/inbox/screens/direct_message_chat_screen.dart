import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/storage_service.dart';
import '../controllers/inbox_controller.dart';
import '../models/inbox_message_model.dart';
import '../services/dm_websocket_service.dart';

/// Direct message chat screen - real-time WebSocket chat for 1-on-1 messaging
class DirectMessageChatScreen extends StatefulWidget {
  final int recipientId;
  final String recipientName;
  final List<InboxMessage>? existingMessages;

  const DirectMessageChatScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.existingMessages,
  });

  @override
  State<DirectMessageChatScreen> createState() =>
      _DirectMessageChatScreenState();
}

class _DirectMessageChatScreenState extends State<DirectMessageChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final DMWebSocketService _dmService;
  final InboxController _inboxController = Get.find<InboxController>();

  bool _showEmojiPicker = false;
  int _currentUserId = 0;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    // Get current user ID
    final storage = Get.find<StorageService>();
    _currentUserId = storage.getUser()?['id'] ?? 0;

    // Initialize WebSocket service
    _dmService = Get.put(DMWebSocketService(), tag: 'dm_${widget.recipientId}');

    // Connect to WebSocket (this will also load message history via REST)
    _dmService.connectToDM(widget.recipientId, recipientName: widget.recipientName);

    // Listen for new messages to scroll
    _dmService.messages.listen((_) => _scrollToBottom());

    // Mark all messages from this sender as read
    _markConversationAsRead();

    // Send read receipt via WebSocket
    Future.delayed(const Duration(milliseconds: 500), () {
      _dmService.sendReadReceipt();
    });
  }

  /// Mark all messages in this conversation as read
  void _markConversationAsRead() {
    // Mark as read on the server and update local state
    _inboxController.markConversationAsRead(widget.recipientId);
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

  final RxBool _isSending = false.obs;

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    _isSending.value = true;

    try {
      await _dmService.sendMessage(content);
      _scrollToBottom();
      // Refresh inbox in background
      _inboxController.refresh();
    } catch (e) {
      // Put text back if sending failed
      _messageController.text = content;
      Get.snackbar(
        'Error',
        'Failed to send message. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isSending.value = false;
    }
  }

  void _toggleEmojiPicker() {
    setState(() => _showEmojiPicker = !_showEmojiPicker);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _dmService.disconnect();
    Get.delete<DMWebSocketService>(tag: 'dm_${widget.recipientId}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Connection status banner
          _buildConnectionStatus(),
          // Messages list
          Expanded(
            child: Obx(() {
              // Show loading indicator while fetching history
              if (_dmService.isLoadingHistory.value) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading messages...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              if (_dmService.messages.isEmpty) {
                return _buildEmptyView();
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 16,
                ),
                itemCount: _dmService.messages.length,
                itemBuilder: (context, index) {
                  final message = _dmService.messages[index];
                  final isMe = message.senderId == _currentUserId;
                  print('DEBUG Chat: messageId=${message.id}, senderId=${message.senderId}, currentUserId=$_currentUserId, isMe=$isMe');
                  return _MessageBubble(message: message, isMe: isMe);
                },
              );
            }),
          ),
          // Typing indicator
          _buildTypingIndicator(),
          // Input area
          _buildInputArea(),
          // Emoji picker
          if (_showEmojiPicker) _buildEmojiPicker(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              widget.recipientName.isNotEmpty
                  ? widget.recipientName[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipientName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Obx(() {
                  if (_dmService.typingStatus.value.isNotEmpty) {
                    return Text(
                      _dmService.typingStatus.value,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  }
                  return Text(
                    _dmService.isConnected.value ? 'Online' : 'Connecting...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Refresh button to reload from REST API
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () async {
            await _inboxController.refresh();
            final conversation = _inboxController.conversations
                .firstWhereOrNull((c) => c.senderId == widget.recipientId);
            if (conversation != null) {
              _dmService.loadExistingMessages(conversation.messages);
              _scrollToBottom();
            }
          },
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    return Obx(() {
      if (_dmService.connectionError.value.isNotEmpty) {
        return Container(
          color: Colors.orange[100],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.warning, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _dmService.connectionError.value,
                  style: TextStyle(color: Colors.orange[800], fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: () => _dmService.connectToDM(widget.recipientId, recipientName: widget.recipientName),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to ${widget.recipientName}',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Obx(() {
      if (_dmService.typingStatus.value.isEmpty) {
        return const SizedBox.shrink();
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.centerLeft,
        child: Text(
          _dmService.typingStatus.value,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    });
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Emoji button
            IconButton(
              icon: Icon(
                _showEmojiPicker
                    ? Icons.keyboard
                    : Icons.emoji_emotions_outlined,
                color: Colors.grey[600],
              ),
              onPressed: _toggleEmojiPicker,
            ),
            // Message input
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) {
                  // Send typing indicator
                  _dmService.sendTyping(value.isNotEmpty);
                },
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            Obx(
              () => (_dmService.isConnecting.value || _isSending.value)
                  ? const SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(Icons.send, color: Colors.white),
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
          _messageController.selection = TextSelection.fromPosition(
            TextPosition(offset: _messageController.text.length),
          );
        },
        config: Config(
          height: 250,
          checkPlatformCompatibility: true,
          viewOrderConfig: const ViewOrderConfig(),
          emojiViewConfig: EmojiViewConfig(backgroundColor: Colors.grey[100]!),
          skinToneConfig: const SkinToneConfig(),
          categoryViewConfig: CategoryViewConfig(
            backgroundColor: Colors.grey[100]!,
            indicatorColor: AppColors.primary,
            iconColorSelected: AppColors.primary,
          ),
          bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
          searchViewConfig: SearchViewConfig(
            backgroundColor: Colors.grey[100]!,
          ),
        ),
      ),
    );
  }
}

/// Message bubble widget for DM chat
class _MessageBubble extends StatelessWidget {
  final DMChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 64 : 8,
          right: isMe ? 8 : 64,
          bottom: 8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Sender name (only for received messages)
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            // Message content
            Text(message.content, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 4),
            // Time and status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead ? Colors.blue : Colors.grey[600],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    } else {
      return DateFormat('h:mm a').format(dateTime);
    }
  }
}
