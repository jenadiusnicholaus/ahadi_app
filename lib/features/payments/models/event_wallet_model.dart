/// Event-level wallet model
/// Shows the financial summary for a specific event
class EventWalletModel {
  final int eventId;
  final String eventTitle;
  final String organizerName;
  final String subscriptionPlan;
  final String feePercent;
  final String currency;
  final double grossAmount; // Total contributions received
  final double totalFees; // Platform fees to be deducted
  final double netAmount; // Amount available after fees
  final double totalDisbursed; // Already withdrawn
  final double availableBalance; // Can be withdrawn now
  final double pendingWithdrawals;
  final int contributionsCount;
  final List<EventDisbursementModel> disbursements;

  EventWalletModel({
    required this.eventId,
    required this.eventTitle,
    this.organizerName = '',
    this.subscriptionPlan = 'Free',
    this.feePercent = '3.00',
    this.currency = 'TZS',
    this.grossAmount = 0,
    this.totalFees = 0,
    this.netAmount = 0,
    this.totalDisbursed = 0,
    this.availableBalance = 0,
    this.pendingWithdrawals = 0,
    this.contributionsCount = 0,
    this.disbursements = const [],
  });

  factory EventWalletModel.fromJson(Map<String, dynamic> json) {
    // Handle the summary nested object
    final summary = json['summary'] as Map<String, dynamic>? ?? json;
    final disbursementsList = json['disbursements'] as List? ?? [];

    return EventWalletModel(
      eventId: json['event_id'] ?? 0,
      eventTitle: json['event_title'] ?? '',
      organizerName: json['organizer'] ?? '',
      subscriptionPlan: json['subscription_plan'] ?? 'Free',
      feePercent: json['fee_percent']?.toString() ?? '3.00',
      currency: summary['currency'] ?? json['currency'] ?? 'TZS',
      grossAmount: _parseDouble(
        summary['gross_amount'] ?? json['gross_amount'],
      ),
      totalFees: _parseDouble(summary['total_fees'] ?? json['total_fees']),
      netAmount: _parseDouble(summary['net_amount'] ?? json['net_amount']),
      totalDisbursed: _parseDouble(
        summary['total_disbursed'] ?? json['total_disbursed'],
      ),
      availableBalance: _parseDouble(
        summary['available_balance'] ?? json['available_balance'],
      ),
      pendingWithdrawals: _parseDouble(
        summary['pending_withdrawals'] ?? json['pending_withdrawals'],
      ),
      contributionsCount:
          summary['contributions_count'] ?? json['contributions_count'] ?? 0,
      disbursements: disbursementsList
          .map((d) => EventDisbursementModel.fromJson(d))
          .toList(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  /// Percentage of target reached (for display)
  double get feePercentValue => double.tryParse(feePercent) ?? 3.0;

  /// Has money available for withdrawal
  bool get canWithdraw => availableBalance >= 1000; // Min 1000 TZS

  /// Has pending withdrawal request
  bool get hasPendingWithdrawal => pendingWithdrawals > 0;
}

/// Disbursement/withdrawal record for an event
class EventDisbursementModel {
  final String id;
  final String reference;
  final int eventId;
  final String eventTitle;
  final String recipientName;
  final String recipientPhone;
  final double grossAmount;
  final double feeAmount;
  final double netAmount;
  final String currency;
  final String method; // MOBILE_MONEY, BANK
  final String provider; // Mpesa, Airtel, etc.
  final String status; // PENDING, PROCESSING, COMPLETED, FAILED
  final String? statusMessage;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? initiatedBy;

  EventDisbursementModel({
    required this.id,
    required this.reference,
    required this.eventId,
    this.eventTitle = '',
    required this.recipientName,
    required this.recipientPhone,
    this.grossAmount = 0,
    this.feeAmount = 0,
    required this.netAmount,
    this.currency = 'TZS',
    this.method = 'MOBILE_MONEY',
    this.provider = 'Mpesa',
    required this.status,
    this.statusMessage,
    this.transactionId,
    required this.createdAt,
    this.completedAt,
    this.initiatedBy,
  });

  factory EventDisbursementModel.fromJson(Map<String, dynamic> json) {
    return EventDisbursementModel(
      id: json['id']?.toString() ?? '',
      reference: json['reference'] ?? '',
      eventId: json['event_id'] ?? 0,
      eventTitle: json['event_title'] ?? '',
      recipientName: json['recipient_name'] ?? '',
      recipientPhone: json['recipient_phone'] ?? '',
      grossAmount: _parseDouble(json['gross_amount']),
      feeAmount: _parseDouble(json['fee_amount']),
      netAmount: _parseDouble(json['net_amount']),
      currency: json['currency'] ?? 'TZS',
      method: json['method'] ?? 'MOBILE_MONEY',
      provider: json['provider'] ?? 'Mpesa',
      status: json['status'] ?? 'PENDING',
      statusMessage: json['status_message'],
      transactionId: json['transaction_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      initiatedBy: json['initiated_by'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String get statusDisplay {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'PROCESSING':
        return 'Processing';
      case 'COMPLETED':
        return 'Completed';
      case 'FAILED':
        return 'Failed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get methodDisplay {
    switch (method) {
      case 'MOBILE_MONEY':
        return 'Mobile Money';
      case 'BANK':
        return 'Bank Transfer';
      default:
        return method;
    }
  }

  bool get isPending => status == 'PENDING';
  bool get isProcessing => status == 'PROCESSING';
  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed => status == 'FAILED';
  bool get isInProgress => status == 'PENDING' || status == 'PROCESSING';
}

/// Event transaction (contribution payment)
class EventTransactionModel {
  final String id;
  final String reference;
  final String? externalId;
  final String? transactionId;
  final int eventId;
  final String payerPhone;
  final String payerName;
  final double amount;
  final String currency;
  final String paymentMethod; // MOBILE_MONEY, BANK
  final String? providerName;
  final String status; // PENDING, PROCESSING, COMPLETED, FAILED
  final String? statusMessage;
  final DateTime createdAt;
  final DateTime? completedAt;

  EventTransactionModel({
    required this.id,
    required this.reference,
    this.externalId,
    this.transactionId,
    required this.eventId,
    required this.payerPhone,
    this.payerName = '',
    required this.amount,
    this.currency = 'TZS',
    required this.paymentMethod,
    this.providerName,
    required this.status,
    this.statusMessage,
    required this.createdAt,
    this.completedAt,
  });

  factory EventTransactionModel.fromJson(Map<String, dynamic> json) {
    return EventTransactionModel(
      id: json['id']?.toString() ?? '',
      reference: json['reference'] ?? '',
      externalId: json['external_id'],
      transactionId: json['transaction_id'],
      eventId: json['event'] ?? 0,
      payerPhone: json['payer_phone'] ?? '',
      payerName: json['payer_name'] ?? 'Anonymous',
      amount: _parseDouble(json['amount']),
      currency: json['currency'] ?? 'TZS',
      paymentMethod: json['payment_method'] ?? 'MOBILE_MONEY',
      providerName: json['provider_name'],
      status: json['status'] ?? 'PENDING',
      statusMessage: json['status_message'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String get statusDisplay {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'PROCESSING':
        return 'Processing';
      case 'COMPLETED':
        return 'Completed';
      case 'FAILED':
        return 'Failed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get methodDisplay {
    switch (paymentMethod) {
      case 'MOBILE_MONEY':
        return providerName ?? 'Mobile Money';
      case 'BANK':
        return providerName ?? 'Bank Transfer';
      default:
        return paymentMethod;
    }
  }

  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed => status == 'FAILED';
}
