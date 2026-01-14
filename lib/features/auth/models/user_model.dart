import 'package:ahadi/core/config/app_config.dart';

class User {
  final int id;
  final String phone;
  final String? email;
  final String? fullName;
  final String? profilePicture;
  final bool isActive;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.phone,
    this.email,
    this.fullName,
    this.profilePicture,
    this.isActive = true,
    this.createdAt,
  });

  /// Get full profile picture URL (handles relative paths from API)
  String? get fullProfilePictureUrl {
    if (profilePicture == null) return null;
    if (profilePicture!.startsWith('http')) return profilePicture;
    // Build full URL from API base URL (remove /api/v1 suffix)
    final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api/v1', '');
    return '$baseUrl$profilePicture';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      phone: json['phone'] ?? '',
      email: json['email'],
      fullName: json['full_name'] ?? json['fullName'],
      profilePicture: json['profile_picture'] ?? json['profilePicture'],
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'email': email,
      'full_name': fullName,
      'profile_picture': profilePicture,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? phone,
    String? email,
    String? fullName,
    String? profilePicture,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      profilePicture: profilePicture ?? this.profilePicture,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
