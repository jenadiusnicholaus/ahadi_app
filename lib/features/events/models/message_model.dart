class MessageModel {
  final int id;
  final int eventId;
  final int? senderId;
  final String? senderName;
  final String? senderAvatar;
  final String messageType; // TEXT, IMAGE, ANNOUNCEMENT, SYSTEM
  final String content;
  final String? imageUrl;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  MessageModel({
    required this.id,
    required this.eventId,
    this.senderId,
    this.senderName,
    this.senderAvatar,
    this.messageType = 'TEXT',
    required this.content,
    this.imageUrl,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  String get messageTypeDisplay {
    switch (messageType) {
      case 'TEXT':
        return 'Text';
      case 'IMAGE':
        return 'Image';
      case 'ANNOUNCEMENT':
        return 'Announcement';
      case 'SYSTEM':
        return 'System';
      default:
        return messageType;
    }
  }

  bool get isText => messageType == 'TEXT';
  bool get isImage => messageType == 'IMAGE';
  bool get isAnnouncement => messageType == 'ANNOUNCEMENT';
  bool get isSystem => messageType == 'SYSTEM';
  bool get isFromCurrentUser => false; // Will be computed based on current user

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? 0,
      eventId: json['event'] ?? 0,
      senderId: json['sender'],
      senderName: json['sender_name'],
      senderAvatar: json['sender_avatar'],
      messageType: json['message_type'] ?? 'TEXT',
      content: json['content'] ?? '',
      imageUrl: json['image_url'],
      isPinned: json['is_pinned'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event': eventId,
      'message_type': messageType,
      'content': content,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }

  MessageModel copyWith({
    int? id,
    int? eventId,
    int? senderId,
    String? senderName,
    String? senderAvatar,
    String? messageType,
    String? content,
    String? imageUrl,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Message type options
class MessageType {
  static const String text = 'TEXT';
  static const String image = 'IMAGE';
  static const String announcement = 'ANNOUNCEMENT';
  static const String system = 'SYSTEM';
}

/// Announcement model for event-wide announcements
class AnnouncementModel {
  final int id;
  final int eventId;
  final int? authorId;
  final String? authorName;
  final String title;
  final String content;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnnouncementModel({
    required this.id,
    required this.eventId,
    this.authorId,
    this.authorName,
    required this.title,
    required this.content,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] ?? 0,
      eventId: json['event'] ?? 0,
      authorId: json['author'],
      authorName: json['author_name'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      isPinned: json['is_pinned'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event': eventId,
      'title': title,
      'content': content,
      'is_pinned': isPinned,
    };
  }

  AnnouncementModel copyWith({
    int? id,
    int? eventId,
    int? authorId,
    String? authorName,
    String? title,
    String? content,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      title: title ?? this.title,
      content: content ?? this.content,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
