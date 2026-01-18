/// Model for wedding invitation card templates
class InvitationCardTemplateModel {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String category;
  final String templateType; // 'HTML' or 'CANVAS'
  final String? canvasStyle; // floral, modern, elegant, classic, geometric
  final String? templateFile;
  final String? previewImage;
  final String? backgroundImage;
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final String fontFamily;
  final Map<String, dynamic> designConfig;
  final bool isPremium;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  InvitationCardTemplateModel({
    required this.id,
    required this.name,
    this.slug = '',
    this.description = '',
    required this.category,
    this.templateType = 'HTML',
    this.canvasStyle,
    this.templateFile,
    this.previewImage,
    this.backgroundImage,
    this.primaryColor = '#D4AF37',
    this.secondaryColor = '#1a1a2e',
    this.accentColor = '#f5f5f5',
    this.fontFamily = 'Playfair Display',
    this.designConfig = const {},
    this.isPremium = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if this is a Canvas/ReportLab template
  bool get isCanvasTemplate => templateType == 'CANVAS';
  
  /// Check if this is an HTML template
  bool get isHtmlTemplate => templateType == 'HTML';

  /// Get category display name
  String get categoryDisplay {
    switch (category) {
      case 'ELEGANT':
        return 'Elegant';
      case 'MODERN':
        return 'Modern';
      case 'TRADITIONAL':
        return 'Traditional';
      case 'FLORAL':
        return 'Floral';
      case 'MINIMALIST':
        return 'Minimalist';
      case 'ROMANTIC':
        return 'Romantic';
      case 'CULTURAL':
        return 'Cultural';
      default:
        return category;
    }
  }

  factory InvitationCardTemplateModel.fromJson(Map<String, dynamic> json) {
    return InvitationCardTemplateModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'ELEGANT',
      templateType: json['template_type'] ?? 'HTML',
      canvasStyle: json['canvas_style'],
      templateFile: json['template_file'],
      previewImage: json['preview_image'],
      backgroundImage: json['background_image'],
      primaryColor: json['primary_color'] ?? '#D4AF37',
      secondaryColor: json['secondary_color'] ?? '#1a1a2e',
      accentColor: json['accent_color'] ?? '#f5f5f5',
      fontFamily: json['font_family'] ?? 'Playfair Display',
      designConfig: json['design_config'] ?? {},
      isPremium: json['is_premium'] ?? false,
      isActive: json['is_active'] ?? true,
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
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'category': category,
      'template_type': templateType,
      'canvas_style': canvasStyle,
      'template_file': templateFile,
      'preview_image': previewImage,
      'background_image': backgroundImage,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'accent_color': accentColor,
      'font_family': fontFamily,
      'design_config': designConfig,
      'is_premium': isPremium,
      'is_active': isActive,
    };
  }
}

/// Model for template categories
class TemplateCategoryModel {
  final String code;
  final String name;

  TemplateCategoryModel({required this.code, required this.name});

  factory TemplateCategoryModel.fromJson(Map<String, dynamic> json) {
    return TemplateCategoryModel(
      // API returns 'value' and 'label', map to code and name
      code: json['value'] ?? json['code'] ?? '',
      name: json['label'] ?? json['name'] ?? '',
    );
  }
}

/// Wedding details for event
class WeddingDetails {
  final String? groomName;
  final String? brideName;
  final String? ceremonyTime;
  final String? receptionTime;
  final String? ceremonyVenue;
  final String? receptionVenue;
  final String? dressCode;
  final String? rsvpPhone;
  final DateTime? startDate;
  final DateTime? endDate;

  WeddingDetails({
    this.groomName,
    this.brideName,
    this.ceremonyTime,
    this.receptionTime,
    this.ceremonyVenue,
    this.receptionVenue,
    this.dressCode,
    this.rsvpPhone,
    this.startDate,
    this.endDate,
  });

  factory WeddingDetails.fromJson(Map<String, dynamic> json) {
    return WeddingDetails(
      groomName: json['groom_name'],
      brideName: json['bride_name'],
      ceremonyTime: json['ceremony_time'],
      receptionTime: json['reception_time'],
      ceremonyVenue: json['ceremony_venue'],
      receptionVenue: json['reception_venue'],
      dressCode: json['dress_code'],
      rsvpPhone: json['rsvp_phone'],
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (groomName != null) 'wedding_groom_name': groomName,
      if (brideName != null) 'wedding_bride_name': brideName,
      if (ceremonyTime != null) 'wedding_ceremony_time': ceremonyTime,
      if (receptionTime != null) 'wedding_reception_time': receptionTime,
      if (receptionVenue != null) 'wedding_reception_venue': receptionVenue,
      if (dressCode != null) 'wedding_dress_code': dressCode,
      if (rsvpPhone != null) 'wedding_rsvp_phone': rsvpPhone,
    };
  }
}

/// Extended invitation model for wedding invitations with card data
class WeddingInvitationModel {
  final int id;
  final int eventId;
  final int? participantId;
  final String? participantName;
  final String? participantPhone;
  final String message;
  final String status;
  final String? sentVia;
  final DateTime? sentAt;
  final DateTime? viewedAt;
  final String? pdfUrl;
  final String? shareLink;
  final String? shortCode;
  final int? cardTemplateId;
  final InvitationCardTemplateModel? cardTemplate;
  final Map<String, dynamic> cardData;
  final String? cardImageUrl;
  final WeddingDetails? weddingDetails;
  final DateTime createdAt;

  WeddingInvitationModel({
    required this.id,
    required this.eventId,
    this.participantId,
    this.participantName,
    this.participantPhone,
    this.message = '',
    this.status = 'DRAFT',
    this.sentVia,
    this.sentAt,
    this.viewedAt,
    this.pdfUrl,
    this.shareLink,
    this.shortCode,
    this.cardTemplateId,
    this.cardTemplate,
    this.cardData = const {},
    this.cardImageUrl,
    this.weddingDetails,
    required this.createdAt,
  });

  String get guestName => cardData['guest_name'] ?? participantName ?? 'Guest';

  factory WeddingInvitationModel.fromJson(Map<String, dynamic> json) {
    return WeddingInvitationModel(
      id: json['id'] ?? 0,
      eventId: json['event'] ?? 0,
      participantId: json['participant'],
      participantName: json['participant_name'],
      participantPhone: json['participant_phone'],
      message: json['message'] ?? '',
      status: json['status'] ?? 'DRAFT',
      sentVia: json['sent_via'],
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
      viewedAt: json['viewed_at'] != null
          ? DateTime.parse(json['viewed_at'])
          : null,
      pdfUrl: json['pdf_url'],
      shareLink: json['share_link'],
      shortCode: json['short_code'],
      cardTemplateId: json['card_template'],
      cardTemplate: json['card_template_details'] != null
          ? InvitationCardTemplateModel.fromJson(json['card_template_details'])
          : null,
      cardData: json['card_data'] ?? {},
      cardImageUrl: json['card_image_url'],
      weddingDetails: json['event_details'] != null
          ? WeddingDetails.fromJson(json['event_details'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event': eventId,
      if (participantId != null) 'participant': participantId,
      'message': message,
      if (cardTemplateId != null) 'card_template': cardTemplateId,
      'card_data': cardData,
    };
  }
}
