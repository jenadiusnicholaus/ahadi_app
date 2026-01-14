import 'package:ahadi/core/config/app_config.dart';

class AuthResponse {
  final bool success;
  final String message;
  final String? accessToken;
  final String? refreshToken;
  final User? user;
  final bool requiresPhoneLink;
  final Map<String, dynamic>? errors;

  AuthResponse({
    required this.success,
    required this.message,
    this.accessToken,
    this.refreshToken,
    this.user,
    this.requiresPhoneLink = false,
    this.errors,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      accessToken: data?['access'] ?? data?['access_token'],
      refreshToken: data?['refresh'] ?? data?['refresh_token'],
      user: data?['user'] != null ? User.fromJson(data['user']) : null,
      requiresPhoneLink: data?['requires_phone_link'] ?? false,
      errors: json['errors'],
    );
  }
}

class User {
  final int id;
  final String phone;
  final String? email;
  final String? fullName;
  final String? profilePicture;
  final bool isActive;
  final DateTime? dateJoined;
  final Map<String, dynamic>? subscription;
  final Map<String, dynamic>? stats;

  User({
    required this.id,
    required this.phone,
    this.email,
    this.fullName,
    this.profilePicture,
    this.isActive = true,
    this.dateJoined,
    this.subscription,
    this.stats,
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
      dateJoined: json['date_joined'] != null
          ? DateTime.tryParse(json['date_joined'])
          : null,
      subscription: json['subscription'],
      stats: json['stats'],
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
      'date_joined': dateJoined?.toIso8601String(),
      'subscription': subscription,
      'stats': stats,
    };
  }
}
