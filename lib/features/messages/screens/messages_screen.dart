import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../inbox/screens/inbox_screen.dart';
import '../../inbox/controllers/inbox_controller.dart';
import '../../chat/views/chat_screen.dart';
import '../../chat/services/websocket_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InboxController inboxController = Get.find<InboxController>();
  late final WebSocketService _wsService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _wsService = Get.find<WebSocketService>();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox),
                  const SizedBox(width: 8),
                  const Text('Inbox'),
                  // Unread badge - calculate from dmUnreadCounts for real-time updates
                  Obx(() {
                    // Sum all unread counts from DM conversations
                    final totalInboxUnread = inboxController
                        .dmUnreadCounts
                        .values
                        .fold<int>(0, (sum, count) => sum + count);
                    // Also watch the main unreadCount for server-fetched count
                    final serverUnread = inboxController.unreadCount.value;
                    final displayCount = totalInboxUnread > 0
                        ? totalInboxUnread
                        : serverUnread;

                    if (displayCount > 0) {
                      return Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$displayCount',
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
            // Event Chats tab with unread badge
            Obx(() {
              // Watch for real-time updates
              // ignore: unused_local_variable
              final trigger = _wsService.countUpdateTrigger.value;

              // Sum all unread counts across all events
              final totalGroupUnread = _wsService.unreadCounts.values.fold<int>(
                0,
                (sum, count) => sum + count,
              );

              return Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.group),
                    const SizedBox(width: 8),
                    const Text('Event Chats'),
                    if (totalGroupUnread > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$totalGroupUnread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [InboxScreen(), ChatScreen()],
      ),
    );
  }
}
