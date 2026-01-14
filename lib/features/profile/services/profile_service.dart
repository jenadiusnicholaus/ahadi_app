import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/models/auth_response.dart';

class ProfileResponse {
  final bool success;
  final String message;
  final User? user;
  final Map<String, dynamic>? errors;

  ProfileResponse({
    required this.success,
    required this.message,
    this.user,
    this.errors,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      user: json['data'] != null ? User.fromJson(json['data']) : null,
      errors: json['errors'],
    );
  }
}

class ProfileService {
  final ApiService _apiService;
  final StorageService _storageService;

  ProfileService({
    required ApiService apiService,
    required StorageService storageService,
  }) : _apiService = apiService,
       _storageService = storageService;

  /// Get user profile from API
  Future<ProfileResponse> getProfile() async {
    try {
      final response = await _apiService.get(ApiEndpoints.me);

      if (response.statusCode == 200) {
        final profileResponse = ProfileResponse.fromJson(response.data);

        // Save user data to storage
        if (profileResponse.user != null) {
          await _storageService.saveUser(response.data['data']);
        }

        return profileResponse;
      }

      return ProfileResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to fetch profile',
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ProfileResponse(
        success: false,
        message: 'Failed to fetch profile: ${e.toString()}',
      );
    }
  }

  /// Update user profile (name, email)
  Future<ProfileResponse> updateProfile({
    String? fullName,
    String? email,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['full_name'] = fullName;
      if (email != null) data['email'] = email;

      final response = await _apiService.patch(ApiEndpoints.me, data: data);

      if (response.statusCode == 200) {
        final profileResponse = ProfileResponse.fromJson(response.data);

        // Update stored user data
        if (profileResponse.user != null) {
          await _storageService.saveUser(response.data['data']);
        }

        return profileResponse;
      }

      return ProfileResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to update profile',
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ProfileResponse(
        success: false,
        message: 'Failed to update profile: ${e.toString()}',
      );
    }
  }

  /// Update profile picture
  Future<ProfileResponse> updateProfilePicture(File imageFile) async {
    try {
      debugPrint('📸 [ProfileService] updateProfilePicture: ${imageFile.path}');
      final formData = FormData.fromMap({
        'profile_picture': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      debugPrint('📸 [ProfileService] Sending PATCH to ${ApiEndpoints.me}');
      final response = await _apiService.patch(ApiEndpoints.me, data: formData);
      debugPrint('📸 [ProfileService] Response status: ${response.statusCode}');
      debugPrint('📸 [ProfileService] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final profileResponse = ProfileResponse.fromJson(response.data);
        debugPrint(
          '📸 [ProfileService] Profile picture URL: ${profileResponse.user?.profilePicture}',
        );

        // Update stored user data
        if (profileResponse.user != null) {
          await _storageService.saveUser(response.data['data']);
        }

        return profileResponse;
      }

      return ProfileResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to update profile picture',
      );
    } on DioException catch (e) {
      debugPrint('📸 [ProfileService] DioException: ${e.message}');
      return _handleDioError(e);
    } catch (e) {
      debugPrint('📸 [ProfileService] Exception: $e');
      return ProfileResponse(
        success: false,
        message: 'Failed to update profile picture: ${e.toString()}',
      );
    }
  }

  /// Update profile picture from bytes (for web)
  Future<ProfileResponse> updateProfilePictureFromBytes(
    Uint8List imageBytes,
    String filename,
  ) async {
    try {
      debugPrint(
        '📸 [ProfileService] updateProfilePictureFromBytes: ${imageBytes.length} bytes, filename: $filename',
      );
      final formData = FormData.fromMap({
        'profile_picture': MultipartFile.fromBytes(
          imageBytes,
          filename: filename,
        ),
      });

      debugPrint('📸 [ProfileService] Sending PATCH to ${ApiEndpoints.me}');
      final response = await _apiService.patch(ApiEndpoints.me, data: formData);
      debugPrint('📸 [ProfileService] Response status: ${response.statusCode}');
      debugPrint('📸 [ProfileService] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final profileResponse = ProfileResponse.fromJson(response.data);
        debugPrint(
          '📸 [ProfileService] Profile picture URL: ${profileResponse.user?.profilePicture}',
        );

        // Update stored user data
        if (profileResponse.user != null) {
          await _storageService.saveUser(response.data['data']);
        }

        return profileResponse;
      }

      return ProfileResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to update profile picture',
      );
    } on DioException catch (e) {
      debugPrint('📸 [ProfileService] DioException: ${e.message}');
      return _handleDioError(e);
    } catch (e) {
      debugPrint('📸 [ProfileService] Exception: $e');
      return ProfileResponse(
        success: false,
        message: 'Failed to update profile picture: ${e.toString()}',
      );
    }
  }

  /// Remove profile picture
  Future<ProfileResponse> removeProfilePicture() async {
    try {
      final response = await _apiService.patch(
        ApiEndpoints.me,
        data: {'remove_profile_picture': 'true'},
      );

      if (response.statusCode == 200) {
        final profileResponse = ProfileResponse.fromJson(response.data);

        // Update stored user data
        if (profileResponse.user != null) {
          await _storageService.saveUser(response.data['data']);
        }

        return profileResponse;
      }

      return ProfileResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to remove profile picture',
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ProfileResponse(
        success: false,
        message: 'Failed to remove profile picture: ${e.toString()}',
      );
    }
  }

  /// Logout user
  Future<ProfileResponse> logout() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();

      if (refreshToken != null) {
        // Call backend to blacklist token
        await _apiService.post(
          ApiEndpoints.logout,
          data: {'refresh': refreshToken},
        );
      }

      // Clear local storage regardless of API response
      await _storageService.clearTokens();
      await _storageService.clearUser();

      return ProfileResponse(success: true, message: 'Logged out successfully');
    } catch (e) {
      // Still clear local data even if API call fails
      await _storageService.clearTokens();
      await _storageService.clearUser();

      return ProfileResponse(success: true, message: 'Logged out successfully');
    }
  }

  /// Delete user account
  Future<ProfileResponse> deleteAccount() async {
    try {
      final response = await _apiService.delete(ApiEndpoints.me);

      if (response.statusCode == 200) {
        // Clear local storage
        await _storageService.clearTokens();
        await _storageService.clearUser();

        return ProfileResponse(
          success: true,
          message: response.data['message'] ?? 'Account deleted successfully',
        );
      }

      return ProfileResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to delete account',
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ProfileResponse(
        success: false,
        message: 'Failed to delete account: ${e.toString()}',
      );
    }
  }

  /// Handle Dio errors
  ProfileResponse _handleDioError(DioException e) {
    String message;
    Map<String, dynamic>? errors;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timed out. Please try again.';
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection. Please check your network.';
        break;
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          message = data['message'] ?? 'Server error. Please try again.';
          errors = data['errors'] as Map<String, dynamic>?;
        } else {
          message =
              'Server error (${e.response?.statusCode}). Please try again.';
        }
        break;
      default:
        message = 'Something went wrong. Please try again.';
    }

    return ProfileResponse(success: false, message: message, errors: errors);
  }
}
