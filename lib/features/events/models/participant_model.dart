class ParticipantModel {
  final int id;
  final int eventId;
  final int? userId;
  final String name;
  final String phone;
  final String email;
  final String status;
  final String notes;
  final double totalContributions;
  final DateTime createdAt;
  final DateTime updatedAt;

  ParticipantModel({
    required this.id,
    required this.eventId,
    this.userId,
    required this.name,
    this.phone = '',
    this.email = '',
    this.status = 'PENDING',
    this.notes = '',
    this.totalContributions = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  String get statusDisplay {
    switch (status) {
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PENDING':
        return 'Pending';
      case 'DECLINED':
        return 'Declined';
      case 'MAYBE':
        return 'Maybe';
      default:
        return status;
    }
  }

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      id: json['id'] ?? 0,
      eventId: json['event'] ?? 0,
      userId: json['user'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'PENDING',
      notes: json['notes'] ?? '',
      totalContributions:
          double.tryParse(json['total_contributions']?.toString() ?? '0') ?? 0,
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
      'user': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'status': status,
      'notes': notes,
    };
  }
}
