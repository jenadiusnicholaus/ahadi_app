import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../inbox/screens/inbox_screen.dart';
import '../../inbox/controllers/inbox_controller.dart';
import '../services/websocket_service.dart';
import 'chat_rooms_list.dart';
import 'event_chat_screen.dart';

/// Main Messages screen with Inbox and Groups tabs
class MessagesTabScreen extends StatefulWidget {
  const MessagesTabScreen({super.key});

  @override
  State<MessagesTabScreen> createState() => _MessagesTabScreenState();
}

class _MessagesTabScreenState extends State<MessagesTabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InboxController inboxController = Get.find<InboxController>();
  final WebSocketService wsService = Get.find<WebSocketService>();

  // Track if we're viewing a specific chat
  int? _selectedEventId;
  String? _selectedEventTitle;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openChat(int eventId, String eventTitle) {
    setState(() {
      _selectedEventId = eventId;
      _selectedEventTitle = eventTitle;
    });
  }

  void _closeChat() {
    setState(() {
      _selectedEventId = null;
      _selectedEventTitle = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If a chat is selected, show that chat
    if (_selectedEventId != null) {
      return EventChatScreen(
        eventId: _selectedEventId!,
        eventTitle: _selectedEventTitle,
        onBack: _closeChat,
      );
    }

    // Otherwise show the tabbed view
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mail_outline, size: 20),
                  const SizedBox(width: 8),
                  const Text('Inbox'),
                  // Unread badge
                  Obx(() {
                    if (inboxController.unreadCount.value > 0) {
                      return Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${inboxController.unreadCount.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.group_outlined, size: 20),
                  const SizedBox(width: 8),
                  const Text('Event Chats'),
                  // Unread badge for event chats
                  Obx(() {
                    // Watch trigger for updates
                    // ignore: unused_local_variable
                    final _ = wsService.countUpdateTrigger.value;
                    final totalUnread = wsService.unreadCounts.values.fold(0, (sum, count) => sum + count);
                    if (totalUnread > 0) {
                      return Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          totalUnread > 99 ? '99+' : '$totalUnread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const InboxScreen(),
          ChatRoomsListScreen(onChatSelected: _openChat),
        ],
      ),
    );
  }
}
