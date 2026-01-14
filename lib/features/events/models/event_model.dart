import 'event_type_model.dart';

class EventModel {
  final int id;
  final String title;
  final String description;
  final EventTypeModel? eventType;
  final int? eventTypeId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String location;
  final String venueName;
  final String status;
  final String visibility;
  final double? contributionTarget;
  final String currency;
  final String? coverImage;
  final String? coverImageUrl;
  final String? coverImageBase64; // For sending base64 encoded image
  final int ownerId;
  final String? ownerName;
  final String? ownerPhone;
  final bool chatEnabled;
  final bool invitationsEnabled;
  final bool remindersEnabled;
  final bool reportsEnabled;
  final bool autoDisburseEnabled;
  final String autoDisbursePhone;
  final String autoDisburseProvider;
  final String joinCode;
  final bool allowPublicJoin;
  final double totalContributions;
  final int participantCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.id,
    required this.title,
    this.description = '',
    this.eventType,
    this.eventTypeId,
    this.startDate,
    this.endDate,
    this.location = '',
    this.venueName = '',
    this.status = 'DRAFT',
    this.visibility = 'PRIVATE',
    this.contributionTarget,
    this.currency = 'TZS',
    this.coverImage,
    this.coverImageUrl,
    this.coverImageBase64,
    required this.ownerId,
    this.ownerName,
    this.ownerPhone,
    this.chatEnabled = false,
    this.invitationsEnabled = false,
    this.remindersEnabled = false,
    this.reportsEnabled = false,
    this.autoDisburseEnabled = true,
    this.autoDisbursePhone = '',
    this.autoDisburseProvider = 'Mpesa',
    this.joinCode = '',
    this.allowPublicJoin = true,
    this.totalContributions = 0,
    this.participantCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayCoverImage {
    if (coverImageUrl != null && coverImageUrl!.isNotEmpty) {
      return coverImageUrl!;
    }
    if (coverImage != null && coverImage!.isNotEmpty) {
      return coverImage!;
    }
    return '';
  }

  double get progressPercentage {
    if (contributionTarget == null || contributionTarget == 0) return 0;
    return (totalContributions / contributionTarget!) * 100;
  }

  bool get isOwner => false; // Will be computed based on current user

  String get statusDisplay {
    switch (status) {
      case 'DRAFT':
        return 'Draft';
      case 'ACTIVE':
        return 'Active';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get visibilityDisplay {
    switch (visibility) {
      case 'PUBLIC':
        return 'Public';
      case 'PRIVATE':
        return 'Private';
      case 'INVITE_ONLY':
        return 'Invite Only';
      default:
        return visibility;
    }
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    // Handle event_type which can be either an int (ID) or an object
    EventTypeModel? eventType;
    int? eventTypeId;

    final eventTypeData = json['event_type'];
    if (eventTypeData != null) {
      if (eventTypeData is Map<String, dynamic>) {
        eventType = EventTypeModel.fromJson(eventTypeData);
        eventTypeId = eventType.id;
      } else if (eventTypeData is int) {
        eventTypeId = eventTypeData;
        // Create minimal EventTypeModel from event_type_name if available
        final typeName = json['event_type_name'];
        if (typeName != null) {
          eventType = EventTypeModel(
            id: eventTypeData,
            name: typeName,
            slug: typeName.toString().toLowerCase().replaceAll(' ', '-'),
          );
        }
      }
    }

    // Handle cover_image - API returns it directly, not as cover_image_url
    final coverImageValue = json['cover_image'];
    final coverImageUrlValue = json['cover_image_url'];

    return EventModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      eventType: eventType,
      eventTypeId: eventTypeId ?? json['event_type_id'],
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      location: json['location'] ?? '',
      venueName: json['venue_name'] ?? '',
      status: json['status'] ?? 'DRAFT',
      visibility: json['visibility'] ?? 'PRIVATE',
      contributionTarget: json['contribution_target'] != null
          ? double.tryParse(json['contribution_target'].toString())
          : null,
      currency: json['currency'] ?? 'TZS',
      coverImage: coverImageValue is String ? coverImageValue : null,
      coverImageUrl:
          coverImageUrlValue ??
          (coverImageValue is String ? coverImageValue : null),
      ownerId: json['owner'] ?? 0,
      ownerName: json['owner_name'] ?? json['organizer_name'],
      ownerPhone: json['owner_phone'],
      chatEnabled: json['chat_enabled'] ?? false,
      invitationsEnabled: json['invitations_enabled'] ?? false,
      remindersEnabled: json['reminders_enabled'] ?? false,
      reportsEnabled: json['reports_enabled'] ?? false,
      autoDisburseEnabled: json['auto_disburse_enabled'] ?? true,
      autoDisbursePhone: json['auto_disburse_phone'] ?? '',
      autoDisburseProvider: json['auto_disburse_provider'] ?? 'Mpesa',
      joinCode: json['join_code'] ?? '',
      allowPublicJoin: json['allow_public_join'] ?? true,
      totalContributions:
          double.tryParse(json['total_contributions']?.toString() ?? '0') ?? 0,
      participantCount: json['participant_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'title': title,
      'description': description,
      'event_type': eventTypeId ?? eventType?.id, // Django expects 'event_type' not 'event_type_id'
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'location': location,
      'venue_name': venueName,
      'status': status,
      'visibility': visibility,
      'contribution_target': contributionTarget,
      'currency': currency,
      'chat_enabled': chatEnabled,
      'invitations_enabled': invitationsEnabled,
      'reminders_enabled': remindersEnabled,
      'reports_enabled': reportsEnabled,
      'auto_disburse_enabled': autoDisburseEnabled,
      'auto_disburse_phone': autoDisbursePhone,
      'auto_disburse_provider': autoDisburseProvider,
      'allow_public_join': allowPublicJoin,
    };

    // Add cover_image if base64 is provided
    if (coverImageBase64 != null && coverImageBase64!.isNotEmpty) {
      json['cover_image'] = coverImageBase64;
    } else if (coverImageUrl != null && coverImageUrl!.isNotEmpty) {
      json['cover_image_url'] = coverImageUrl;
    }

    return json;
  }

  EventModel copyWith({
    int? id,
    String? title,
    String? description,
    EventTypeModel? eventType,
    int? eventTypeId,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? venueName,
    String? status,
    String? visibility,
    double? contributionTarget,
    String? currency,
    String? coverImage,
    String? coverImageUrl,
    String? coverImageBase64,
    int? ownerId,
    String? ownerName,
    String? ownerPhone,
    bool? chatEnabled,
    bool? invitationsEnabled,
    bool? remindersEnabled,
    bool? reportsEnabled,
    bool? autoDisburseEnabled,
    String? autoDisbursePhone,
    String? autoDisburseProvider,
    String? joinCode,
    bool? allowPublicJoin,
    double? totalContributions,
    int? participantCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      eventTypeId: eventTypeId ?? this.eventTypeId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      venueName: venueName ?? this.venueName,
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
      contributionTarget: contributionTarget ?? this.contributionTarget,
      currency: currency ?? this.currency,
      coverImage: coverImage ?? this.coverImage,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      coverImageBase64: coverImageBase64 ?? this.coverImageBase64,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      invitationsEnabled: invitationsEnabled ?? this.invitationsEnabled,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reportsEnabled: reportsEnabled ?? this.reportsEnabled,
      autoDisburseEnabled: autoDisburseEnabled ?? this.autoDisburseEnabled,
      autoDisbursePhone: autoDisbursePhone ?? this.autoDisbursePhone,
      autoDisburseProvider: autoDisburseProvider ?? this.autoDisburseProvider,
      joinCode: joinCode ?? this.joinCode,
      allowPublicJoin: allowPublicJoin ?? this.allowPublicJoin,
      totalContributions: totalContributions ?? this.totalContributions,
      participantCount: participantCount ?? this.participantCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
