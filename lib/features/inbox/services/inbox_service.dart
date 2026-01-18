import '../../../core/services/api_service.dart';
import '../models/inbox_message_model.dart';

/// Model for conversation summary
class ConversationSummary {
  final int partnerId;
  final String partnerName;
  final String partnerEmail;
  final List<InboxMessage> messages;
  final int unreadCount;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  ConversationSummary({
    required this.partnerId,
    required this.partnerName,
    required this.partnerEmail,
    required this.messages,
    required this.unreadCount,
    this.lastMessage,
    this.lastMessageTime,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    final messagesList = (json['messages'] as List<dynamic>?)
            ?.map((m) => InboxMessage.fromJson(m))
            .toList() ??
        [];

    return ConversationSummary(
      partnerId: json['partner_id'] as int,
      partnerName: json['partner_name'] as String? ?? 'Unknown',
      partnerEmail: json['partner_email'] as String? ?? '',
      messages: messagesList,
      unreadCount: json['unread_count'] as int? ?? 0,
      lastMessage: json['last_message'] as String?,
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'])
          : null,
    );
  }
}

class InboxService {
  final ApiService _apiService = ApiService();

  /// Get all conversations for current user (both sent and received)
  Future<List<ConversationSummary>> getConversations() async {
    try {
      final response = await _apiService.get('/inbox/conversations/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ConversationSummary.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load conversations');
      }
    } catch (e) {
      print('Error fetching conversations: $e');
      rethrow;
    }
  }

  /// Get all inbox messages for current user (received only - legacy)
  Future<List<InboxMessage>> getInboxMessages() async {
    try {
      final response = await _apiService.get('/inbox/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'] ?? response.data;
        return data.map((json) => InboxMessage.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load inbox messages');
      }
    } catch (e) {
      print('Error fetching inbox messages: $e');
      rethrow;
    }
  }

  /// Get a specific inbox message
  Future<InboxMessage> getInboxMessage(int messageId) async {
    try {
      final response = await _apiService.get('/inbox/$messageId/');

      if (response.statusCode == 200) {
        return InboxMessage.fromJson(response.data);
      } else {
        throw Exception('Failed to load inbox message');
      }
    } catch (e) {
      print('Error fetching inbox message: $e');
      rethrow;
    }
  }

  /// Mark a message as read
  Future<void> markAsRead(int messageId) async {
    try {
      final response = await _apiService.post('/inbox/$messageId/mark_read/');

      if (response.statusCode != 200) {
        throw Exception('Failed to mark message as read');
      }
    } catch (e) {
      print('Error marking message as read: $e');
      rethrow;
    }
  }

  /// Get unread message count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get('/inbox/unread_count/');

      if (response.statusCode == 200) {
        return response.data['unread_count'] as int;
      } else {
        throw Exception('Failed to load unread count');
      }
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  /// Mark all messages as read
  Future<void> markAllAsRead() async {
    try {
      final response = await _apiService.post('/inbox/mark_all_read/');

      if (response.statusCode != 200) {
        throw Exception('Failed to mark all messages as read');
      }
    } catch (e) {
      print('Error marking all messages as read: $e');
      rethrow;
    }
  }

  /// Send invitation to participants
  Future<void> sendInvitation({
    required int eventId,
    List<int>? participantIds,
    bool sendToSelf = false,
  }) async {
    try {
      final data = {
        if (participantIds != null && participantIds.isNotEmpty)
          'participant_ids': participantIds,
        'send_to_self': sendToSelf,
      };

      final response = await _apiService.post(
        '/events/$eventId/send-invitation/',
        data: data,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send invitation');
      }
    } catch (e) {
      print('Error sending invitation: $e');
      rethrow;
    }
  }

  /// Send a direct message to another user
  Future<InboxMessage> sendDirectMessage({
    required int recipientId,
    required String content,
    String? title,
    int? eventId,
  }) async {
    try {
      final data = {
        'recipient_id': recipientId,
        'content': content,
        if (title != null) 'title': title,
        if (eventId != null) 'event_id': eventId,
      };

      final response = await _apiService.post('/direct-messages/', data: data);

      if (response.statusCode == 201) {
        return InboxMessage.fromJson(response.data);
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      print('Error sending direct message: $e');
      rethrow;
    }
  }

  /// Get conversation history with a specific user
  Future<List<InboxMessage>> getConversationHistory(int userId) async {
    try {
      final response = await _apiService.get(
        '/direct-messages/conversation/$userId/',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'] ?? response.data;
        
        // Debug: Print raw JSON response
        print('DEBUG API: Raw conversation response:');
        for (var json in data) {
          print('DEBUG API: id=${json['id']}, sender=${json['sender']}, sender_id=${json['sender_id']}, recipient=${json['recipient']}, recipient_id=${json['recipient_id']}');
        }
        
        return data.map((json) => InboxMessage.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load conversation history');
      }
    } catch (e) {
      print('Error fetching conversation history: $e');
      rethrow;
    }
  }

  /// Mark conversation as read
  Future<void> markConversationRead(int userId) async {
    try {
      await _apiService.post('/direct-messages/conversation/$userId/read/');
    } catch (e) {
      print('Error marking conversation as read: $e');
      // Don't rethrow - this is not critical
    }
  }
}
