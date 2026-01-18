class SubscriptionPlanModel {
  final int id;
  final String name;
  final String slug;
  final String planType;
  final double priceMonthly;
  final double priceYearly;
  final String currency;
  final int maxEvents;
  final int maxParticipantsPerEvent;
  final int maxAdminsPerEvent;
  final PlanFeatures features;
  final double transactionFeePercent;
  final String description;

  SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.planType,
    required this.priceMonthly,
    required this.priceYearly,
    required this.currency,
    required this.maxEvents,
    required this.maxParticipantsPerEvent,
    required this.maxAdminsPerEvent,
    required this.features,
    required this.transactionFeePercent,
    required this.description,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      planType: json['plan_type'] ?? 'FREE',
      priceMonthly: double.tryParse(json['price_monthly']?.toString() ?? '0') ?? 0,
      priceYearly: double.tryParse(json['price_yearly']?.toString() ?? '0') ?? 0,
      currency: json['currency'] ?? 'TZS',
      maxEvents: json['max_events'] ?? 1,
      maxParticipantsPerEvent: json['max_participants_per_event'] ?? 50,
      maxAdminsPerEvent: json['max_admins_per_event'] ?? 1,
      features: PlanFeatures.fromJson(json['features'] ?? {}),
      transactionFeePercent: double.tryParse(json['transaction_fee_percent']?.toString() ?? '5') ?? 5.0,
      description: json['description'] ?? '',
    );
  }

  bool get isFree => priceMonthly == 0;
  
  String get formattedMonthlyPrice => 
      isFree ? 'Free' : '$currency ${priceMonthly.toStringAsFixed(0)}';
  
  String get formattedYearlyPrice => 
      isFree ? 'Free' : '$currency ${priceYearly.toStringAsFixed(0)}';
  
  String get formattedFee => '${transactionFeePercent.toStringAsFixed(1)}%';
}

class PlanFeatures {
  final bool chatEnabled;
  final bool invitationsEnabled;
  final bool remindersEnabled;
  final bool reportsEnabled;
  final bool customBranding;
  final bool apiAccess;
  final bool prioritySupport;

  PlanFeatures({
    this.chatEnabled = false,
    this.invitationsEnabled = false,
    this.remindersEnabled = false,
    this.reportsEnabled = false,
    this.customBranding = false,
    this.apiAccess = false,
    this.prioritySupport = false,
  });

  factory PlanFeatures.fromJson(Map<String, dynamic> json) {
    return PlanFeatures(
      chatEnabled: json['chat_enabled'] ?? false,
      invitationsEnabled: json['invitations_enabled'] ?? false,
      remindersEnabled: json['reminders_enabled'] ?? false,
      reportsEnabled: json['reports_enabled'] ?? false,
      customBranding: json['custom_branding'] ?? false,
      apiAccess: json['api_access'] ?? false,
      prioritySupport: json['priority_support'] ?? false,
    );
  }

  List<String> toFeatureList() {
    final features = <String>[];
    if (chatEnabled) features.add('Event Chat');
    if (invitationsEnabled) features.add('SMS/WhatsApp Invitations');
    if (remindersEnabled) features.add('Automated Reminders');
    if (reportsEnabled) features.add('Reports & Analytics');
    if (customBranding) features.add('Custom Branding');
    if (apiAccess) features.add('API Access');
    if (prioritySupport) features.add('Priority Support');
    return features;
  }
}

class UserSubscriptionModel {
  final String planName;
  final String planType;
  final String status;
  final String billingCycle;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final bool autoRenew;
  final double transactionFeePercent;

  UserSubscriptionModel({
    required this.planName,
    required this.planType,
    required this.status,
    required this.billingCycle,
    this.startedAt,
    this.expiresAt,
    required this.autoRenew,
    required this.transactionFeePercent,
  });

  factory UserSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionModel(
      planName: json['plan_name'] ?? 'Free',
      planType: json['plan_type'] ?? 'FREE',
      status: json['status'] ?? 'ACTIVE',
      billingCycle: json['billing_cycle'] ?? 'MONTHLY',
      startedAt: json['started_at'] != null 
          ? DateTime.tryParse(json['started_at']) 
          : null,
      expiresAt: json['expires_at'] != null 
          ? DateTime.tryParse(json['expires_at']) 
          : null,
      autoRenew: json['auto_renew'] ?? false,
      transactionFeePercent: double.tryParse(
          json['transaction_fee_percent']?.toString() ?? '5') ?? 5.0,
    );
  }

  bool get isActive => status == 'ACTIVE';
  bool get isExpired => status == 'EXPIRED';
  
  int get daysRemaining {
    if (expiresAt == null) return 0;
    return expiresAt!.difference(DateTime.now()).inDays;
  }
}
