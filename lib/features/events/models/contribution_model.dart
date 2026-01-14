class ContributionModel {
  final int id;
  final int eventId;
  final int? participantId;
  final String? participantName;
  final String? participantPhone;
  final double amount;
  final String currency;
  final String kind; // CASH, MOBILE_MONEY, BANK_TRANSFER, ITEM, SERVICE
  final String status; // PENDING, CONFIRMED, FAILED, REFUNDED
  final String disbursementStatus; // PENDING, DISBURSED, FAILED
  final String? itemDescription;
  final double? estimatedValue;
  final String? paymentReference;
  final String? transactionId;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContributionModel({
    required this.id,
    required this.eventId,
    this.participantId,
    this.participantName,
    this.participantPhone,
    required this.amount,
    this.currency = 'TZS',
    this.kind = 'CASH',
    this.status = 'PENDING',
    this.disbursementStatus = 'PENDING',
    this.itemDescription,
    this.estimatedValue,
    this.paymentReference,
    this.transactionId,
    this.paidAt,
    required this.createdAt,
    required this.updatedAt,
  });

  String get kindDisplay {
    switch (kind) {
      case 'CASH':
        return 'Cash';
      case 'MOBILE_MONEY':
        return 'Mobile Money';
      case 'BANK_TRANSFER':
        return 'Bank Transfer';
      case 'ITEM':
        return 'Item';
      case 'SERVICE':
        return 'Service';
      default:
        return kind;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'FAILED':
        return 'Failed';
      case 'REFUNDED':
        return 'Refunded';
      default:
        return status;
    }
  }

  String get disbursementStatusDisplay {
    switch (disbursementStatus) {
      case 'PENDING':
        return 'Pending';
      case 'DISBURSED':
        return 'Disbursed';
      case 'FAILED':
        return 'Failed';
      default:
        return disbursementStatus;
    }
  }

  bool get isConfirmed => status == 'CONFIRMED';
  bool get isPending => status == 'PENDING';
  bool get isMobileMoney => kind == 'MOBILE_MONEY';
  bool get isInKind => kind == 'ITEM' || kind == 'SERVICE';

  // Helper getters for compatibility
  String get contributorName => participantName ?? '';
  String get paymentMethodDisplay => kindDisplay;
  String get message => itemDescription ?? '';

  factory ContributionModel.fromJson(Map<String, dynamic> json) {
    return ContributionModel(
      id: json['id'] ?? 0,
      eventId: json['event'] ?? 0,
      participantId: json['participant'],
      participantName: json['participant_name'],
      participantPhone: json['participant_phone'],
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      currency: json['currency'] ?? 'TZS',
      kind: json['kind'] ?? 'CASH',
      status: json['status'] ?? 'PENDING',
      disbursementStatus: json['disbursement_status'] ?? 'PENDING',
      itemDescription: json['item_description'],
      estimatedValue: double.tryParse(
        json['estimated_value']?.toString() ?? '',
      ),
      paymentReference: json['payment_reference'],
      transactionId: json['transaction']?.toString(),
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
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
      'event': eventId,
      'amount': amount,
      'currency': currency,
      'kind': kind,
      'status': status,
    };

    if (participantId != null) json['participant'] = participantId;
    if (participantName != null && participantName!.isNotEmpty) {
      json['participant_name'] = participantName;
    }
    if (participantPhone != null && participantPhone!.isNotEmpty) {
      json['participant_phone'] = participantPhone;
    }
    if (itemDescription != null && itemDescription!.isNotEmpty) {
      json['item_description'] = itemDescription;
    }
    if (estimatedValue != null) json['estimated_value'] = estimatedValue;
    if (paymentReference != null && paymentReference!.isNotEmpty) {
      json['payment_reference'] = paymentReference;
    }

    return json;
  }

  ContributionModel copyWith({
    int? id,
    int? eventId,
    int? participantId,
    String? participantName,
    String? participantPhone,
    double? amount,
    String? currency,
    String? kind,
    String? status,
    String? disbursementStatus,
    String? itemDescription,
    double? estimatedValue,
    String? paymentReference,
    String? transactionId,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContributionModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      participantPhone: participantPhone ?? this.participantPhone,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      disbursementStatus: disbursementStatus ?? this.disbursementStatus,
      itemDescription: itemDescription ?? this.itemDescription,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      paymentReference: paymentReference ?? this.paymentReference,
      transactionId: transactionId ?? this.transactionId,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Contribution kind options
class ContributionKind {
  static const String cash = 'CASH';
  static const String mobileMoney = 'MOBILE_MONEY';
  static const String bankTransfer = 'BANK_TRANSFER';
  static const String item = 'ITEM';
  static const String service = 'SERVICE';

  static List<Map<String, String>> get options => [
    {'value': cash, 'label': 'Cash'},
    {'value': mobileMoney, 'label': 'Mobile Money'},
    {'value': bankTransfer, 'label': 'Bank Transfer'},
    {'value': item, 'label': 'Item/Gift'},
    {'value': service, 'label': 'Service'},
  ];
}

/// Contribution status options
class ContributionStatus {
  static const String pending = 'PENDING';
  static const String confirmed = 'CONFIRMED';
  static const String failed = 'FAILED';
  static const String refunded = 'REFUNDED';
}
