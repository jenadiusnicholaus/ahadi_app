class ReminderModel {
  final int id;
  final int eventId;
  final String? eventTitle;
  final String title;
  final String message;
  final String channel; // SMS, WHATSAPP, EMAIL, PUSH
  final DateTime scheduledFor;
  final String status; // PENDING, SENT, FAILED, CANCELLED
  final DateTime? sentAt;
  final int? recipientCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReminderModel({
    required this.id,
    required this.eventId,
    this.eventTitle,
    required this.title,
    required this.message,
    this.channel = 'SMS',
    required this.scheduledFor,
    this.status = 'PENDING',
    this.sentAt,
    this.recipientCount,
    required this.createdAt,
    required this.updatedAt,
  });

  String get channelDisplay {
    switch (channel) {
      case 'SMS':
        return 'SMS';
      case 'WHATSAPP':
        return 'WhatsApp';
      case 'EMAIL':
        return 'Email';
      case 'PUSH':
        return 'Push Notification';
      default:
        return channel;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'PENDING':
        return 'Scheduled';
      case 'SENT':
        return 'Sent';
      case 'FAILED':
        return 'Failed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  bool get isPending => status == 'PENDING';
  bool get isSent => status == 'SENT';
  bool get isFailed => status == 'FAILED';
  bool get isCancelled => status == 'CANCELLED';
  bool get canCancel => isPending && scheduledFor.isAfter(DateTime.now());

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] ?? 0,
      eventId: json['event'] ?? 0,
      eventTitle: json['event_title'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      channel: json['channel'] ?? 'SMS',
      scheduledFor: json['scheduled_for'] != null
          ? DateTime.parse(json['scheduled_for'])
          : DateTime.now(),
      status: json['status'] ?? 'PENDING',
      sentAt:
          json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
      recipientCount: json['recipient_count'],
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
      'message': message,
      'channel': channel,
      'scheduled_for': scheduledFor.toIso8601String(),
    };
  }

  ReminderModel copyWith({
    int? id,
    int? eventId,
    String? eventTitle,
    String? title,
    String? message,
    String? channel,
    DateTime? scheduledFor,
    String? status,
    DateTime? sentAt,
    int? recipientCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      title: title ?? this.title,
      message: message ?? this.message,
      channel: channel ?? this.channel,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      recipientCount: recipientCount ?? this.recipientCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Reminder channel options
class ReminderChannel {
  static const String sms = 'SMS';
  static const String whatsapp = 'WHATSAPP';
  static const String email = 'EMAIL';
  static const String push = 'PUSH';

  static List<Map<String, String>> get options => [
        {'value': sms, 'label': 'SMS'},
        {'value': whatsapp, 'label': 'WhatsApp'},
        {'value': email, 'label': 'Email'},
        {'value': push, 'label': 'Push Notification'},
      ];
}

/// Reminder status options
class ReminderStatus {
  static const String pending = 'PENDING';
  static const String sent = 'SENT';
  static const String failed = 'FAILED';
  static const String cancelled = 'CANCELLED';
}
