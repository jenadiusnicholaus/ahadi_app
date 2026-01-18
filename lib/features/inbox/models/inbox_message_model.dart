class InboxMessage {
  final int id;
  final int? senderId;
  final String? senderName;
  final int? recipientId;
  final String? recipientName;
  final int? eventId;
  final String? eventTitle;
  final String messageType;
  final String messageTypeDisplay;
  final String title;
  final String content;
  final String? cardImageUrl;
  final String? cardPdfUrl;
  final String? mediaUrl;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  InboxMessage({
    required this.id,
    this.senderId,
    this.senderName,
    this.recipientId,
    this.recipientName,
    this.eventId,
    this.eventTitle,
    required this.messageType,
    required this.messageTypeDisplay,
    required this.title,
    required this.content,
    this.cardImageUrl,
    this.cardPdfUrl,
    this.mediaUrl,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory InboxMessage.fromJson(Map<String, dynamic> json) {
    // Parse sender_id - prefer explicit sender_id, fallback to sender
    int? parsedSenderId;
    if (json['sender_id'] != null) {
      parsedSenderId = json['sender_id'] as int;
    } else if (json['sender'] != null) {
      parsedSenderId = json['sender'] as int;
    }
    
    // Parse recipient_id - prefer explicit recipient_id, fallback to recipient
    int? parsedRecipientId;
    if (json['recipient_id'] != null) {
      parsedRecipientId = json['recipient_id'] as int;
    } else if (json['recipient'] != null) {
      parsedRecipientId = json['recipient'] as int;
    }
    
    print('DEBUG Model: Parsing message id=${json['id']}, parsedSenderId=$parsedSenderId, parsedRecipientId=$parsedRecipientId');
    
    return InboxMessage(
      id: json['id'] as int,
      senderId: parsedSenderId,
      senderName: json['sender_name'] as String?,
      recipientId: parsedRecipientId,
      recipientName: json['recipient_name'] as String?,
      eventId: json['event'] as int?,
      eventTitle: json['event_title'] as String?,
      messageType: json['message_type'] as String,
      messageTypeDisplay: json['message_type_display'] as String,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      cardImageUrl: json['card_image_url'] as String?,
      cardPdfUrl: json['card_pdf_url'] as String?,
      mediaUrl: json['media_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': senderId,
      'sender_id': senderId,
      'sender_name': senderName,
      'recipient': recipientId,
      'recipient_id': recipientId,
      'recipient_name': recipientName,
      'event': eventId,
      'event_title': eventTitle,
      'message_type': messageType,
      'message_type_display': messageTypeDisplay,
      'title': title,
      'content': content,
      'card_image_url': cardImageUrl,
      'card_pdf_url': cardPdfUrl,
      'media_url': mediaUrl,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  InboxMessage copyWith({
    int? id,
    int? senderId,
    String? senderName,
    int? recipientId,
    String? recipientName,
    int? eventId,
    String? eventTitle,
    String? messageType,
    String? messageTypeDisplay,
    String? title,
    String? content,
    String? cardImageUrl,
    String? cardPdfUrl,
    String? mediaUrl,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return InboxMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      messageType: messageType ?? this.messageType,
      messageTypeDisplay: messageTypeDisplay ?? this.messageTypeDisplay,
      title: title ?? this.title,
      content: content ?? this.content,
      cardImageUrl: cardImageUrl ?? this.cardImageUrl,
      cardPdfUrl: cardPdfUrl ?? this.cardPdfUrl,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
