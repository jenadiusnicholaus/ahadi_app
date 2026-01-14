class InvitationModel {
  final int id;
  final int eventId;
  final String? eventTitle;
  final int? participantId;
  final String? participantName;
  final String? participantPhone;
  final String? participantEmail;
  final String message;
  final String? template;
  final String status; // DRAFT, SENT, VIEWED, RESPONDED
  final String? pdfUrl;
  final String? shareLink;
  final DateTime? sentAt;
  final DateTime? viewedAt;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  InvitationModel({
    required this.id,
    required this.eventId,
    this.eventTitle,
    this.participantId,
    this.participantName,
    this.participantPhone,
    this.participantEmail,
    this.message = '',
    this.template,
    this.status = 'DRAFT',
    this.pdfUrl,
    this.shareLink,
    this.sentAt,
    this.viewedAt,
    this.respondedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  String get statusDisplay {
    switch (status) {
      case 'DRAFT':
        return 'Draft';
      case 'SENT':
        return 'Sent';
      case 'VIEWED':
        return 'Viewed';
      case 'RESPONDED':
        return 'Responded';
      default:
        return status;
    }
  }

  bool get isDraft => status == 'DRAFT';
  bool get isSent => status == 'SENT';
  bool get isViewed => status == 'VIEWED';
  bool get isResponded => status == 'RESPONDED';

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    return InvitationModel(
      id: json['id'] ?? 0,
      eventId: json['event'] ?? 0,
      eventTitle: json['event_title'],
      participantId: json['participant'],
      participantName: json['participant_name'],
      participantPhone: json['participant_phone'],
      participantEmail: json['participant_email'],
      message: json['message'] ?? '',
      template: json['template'],
      status: json['status'] ?? 'DRAFT',
      pdfUrl: json['pdf_url'],
      shareLink: json['share_link'],
      sentAt:
          json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
      viewedAt:
          json['viewed_at'] != null ? DateTime.parse(json['viewed_at']) : null,
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'])
          : null,
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
      if (participantId != null) 'participant': participantId,
      if (participantName != null) 'participant_name': participantName,
      if (participantPhone != null) 'participant_phone': participantPhone,
      if (participantEmail != null) 'participant_email': participantEmail,
      'message': message,
      if (template != null) 'template': template,
    };
  }

  InvitationModel copyWith({
    int? id,
    int? eventId,
    String? eventTitle,
    int? participantId,
    String? participantName,
    String? participantPhone,
    String? participantEmail,
    String? message,
    String? template,
    String? status,
    String? pdfUrl,
    String? shareLink,
    DateTime? sentAt,
    DateTime? viewedAt,
    DateTime? respondedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvitationModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      participantPhone: participantPhone ?? this.participantPhone,
      participantEmail: participantEmail ?? this.participantEmail,
      message: message ?? this.message,
      template: template ?? this.template,
      status: status ?? this.status,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      shareLink: shareLink ?? this.shareLink,
      sentAt: sentAt ?? this.sentAt,
      viewedAt: viewedAt ?? this.viewedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Invitation status options
class InvitationStatus {
  static const String draft = 'DRAFT';
  static const String sent = 'SENT';
  static const String viewed = 'VIEWED';
  static const String responded = 'RESPONDED';
}
