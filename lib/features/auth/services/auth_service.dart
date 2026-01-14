import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/auth_response.dart';

enum AuthProvider { google, facebook, phone }

class AuthService {
  final ApiService _apiService;
  final StorageService _storageService;

  late final GoogleSignIn _googleSignIn;

  AuthService({
    required ApiService apiService,
    required StorageService storageService,
  }) : _apiService = apiService,
       _storageService = storageService {
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: AppConfig.googleIosClientId.isNotEmpty
          ? AppConfig.googleIosClientId
          : null,
    );
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storageService.getAccessToken();
    return token != null;
  }

  // Get current user from storage
  User? getCurrentUser() {
    final userData = _storageService.getUser();
    if (userData != null) {
      return User.fromJson(userData);
    }
    return null;
  }

  // Google Sign-In
  Future<AuthResponse> signInWithGoogle() async {
    try {
      // Start Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResponse(
          success: false,
          message: 'Google sign-in was cancelled',
        );
      }

      // Get auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Send token to backend
      final response = await _apiService.post(
        ApiEndpoints.googleLogin,
        data: {
          'id_token': googleAuth.idToken,
          'access_token': googleAuth.accessToken,
          'platform': 'mobile',
        },
      );

      return _handleAuthResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Google sign-in failed: ${e.toString()}',
      );
    }
  }

  // Facebook Sign-In
  Future<AuthResponse> signInWithFacebook() async {
    try {
      // Start Facebook login flow
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      switch (result.status) {
        case LoginStatus.success:
          final accessToken = result.accessToken!;

          // Send token to backend
          final response = await _apiService.post(
            ApiEndpoints.facebookLogin,
            data: {
              'access_token': accessToken.tokenString,
              'platform': 'mobile',
            },
          );

          return _handleAuthResponse(response);

        case LoginStatus.cancelled:
          return AuthResponse(
            success: false,
            message: 'Facebook login was cancelled',
          );

        case LoginStatus.failed:
          return AuthResponse(
            success: false,
            message: result.message ?? 'Facebook login failed',
          );

        default:
          return AuthResponse(success: false, message: 'Facebook login failed');
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Facebook sign-in failed: ${e.toString()}',
      );
    }
  }

  // Phone OTP - Request OTP
  Future<AuthResponse> requestOtp(String phone) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.requestOtp,
        data: {'phone': phone},
      );

      if (response.statusCode == 200) {
        return AuthResponse(
          success: true,
          message: response.data['message'] ?? 'OTP sent successfully',
        );
      }

      return AuthResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to send OTP',
        errors: response.data['errors'],
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Failed to request OTP: ${e.toString()}',
      );
    }
  }

  // Phone OTP - Verify OTP
  Future<AuthResponse> verifyOtp(String phone, String code) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.verifyOtp,
        data: {'phone': phone, 'code': code},
      );

      return _handleAuthResponse(response);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Failed to verify OTP: ${e.toString()}',
      );
    }
  }

  // Link phone number (for social auth users)
  Future<AuthResponse> linkPhone(String phone, String code) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.linkPhone,
        data: {'phone': phone, 'code': code},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['data']?['user'] != null) {
          await _storageService.saveUser(data['data']['user']);
        }
        return AuthResponse(
          success: true,
          message: data['message'] ?? 'Phone linked successfully',
          user: data['data']?['user'] != null
              ? User.fromJson(data['data']['user'])
              : null,
        );
      }

      return AuthResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to link phone',
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Failed to link phone: ${e.toString()}',
      );
    }
  }

  // Get user profile
  Future<AuthResponse> getProfile() async {
    try {
      final response = await _apiService.get(ApiEndpoints.me);

      if (response.statusCode == 200) {
        final data = response.data;
        final user = User.fromJson(data['data']);
        await _storageService.saveUser(data['data']);

        return AuthResponse(
          success: true,
          message: 'Profile fetched successfully',
          user: user,
        );
      }

      return AuthResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to fetch profile',
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Failed to fetch profile: ${e.toString()}',
      );
    }
  }

  // Update profile
  Future<AuthResponse> updateProfile({
    String? fullName,
    String? email,
    String? profilePicturePath,
    bool removeProfilePicture = false,
  }) async {
    try {
      final formData = FormData();

      if (fullName != null) {
        formData.fields.add(MapEntry('full_name', fullName));
      }
      if (email != null) {
        formData.fields.add(MapEntry('email', email));
      }
      if (removeProfilePicture) {
        formData.fields.add(const MapEntry('remove_profile_picture', 'true'));
      }
      if (profilePicturePath != null) {
        formData.files.add(
          MapEntry(
            'profile_picture',
            await MultipartFile.fromFile(profilePicturePath),
          ),
        );
      }

      final response = await _apiService.patch(ApiEndpoints.me, data: formData);

      if (response.statusCode == 200) {
        final data = response.data;
        final user = User.fromJson(data['data']);
        await _storageService.saveUser(data['data']);

        return AuthResponse(
          success: true,
          message: data['message'] ?? 'Profile updated successfully',
          user: user,
        );
      }

      return AuthResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to update profile',
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Failed to update profile: ${e.toString()}',
      );
    }
  }

  // Delete account
  Future<AuthResponse> deleteAccount() async {
    try {
      final response = await _apiService.delete(ApiEndpoints.me);

      if (response.statusCode == 200) {
        // Clear local data
        await _storageService.clearTokens();
        await _storageService.clearUser();

        return AuthResponse(
          success: true,
          message: response.data['message'] ?? 'Account deleted successfully',
        );
      }

      return AuthResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to delete account',
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Failed to delete account: ${e.toString()}',
      );
    }
  }

  // Sign out - clears all sessions and local data
  Future<void> signOut() async {
    try {
      // Call backend logout to blacklist token
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken != null) {
        try {
          await _apiService.post(
            ApiEndpoints.logout,
            data: {'refresh': refreshToken},
          );
        } catch (_) {
          // Ignore errors - still clear local data
        }
      }

      // Sign out from Google if signed in
      try {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
          await _googleSignIn.disconnect(); // Revoke access completely
        }
      } catch (_) {}

      // Sign out from Facebook if signed in
      try {
        await FacebookAuth.instance.logOut();
      } catch (_) {}

      // Clear ALL local storage (tokens, user data, preferences)
      await _storageService.clearAll();
    } catch (e) {
      // Still clear local data even if anything fails
      await _storageService.clearAll();
    }
  }

  // Handle successful auth response
  Future<AuthResponse> _handleAuthResponse(Response response) async {
    final data = response.data;

    if (response.statusCode == 200 || response.statusCode == 201) {
      final authResponse = AuthResponse.fromJson(data);

      if (authResponse.success && authResponse.accessToken != null) {
        // Save tokens
        await _storageService.saveTokens(
          accessToken: authResponse.accessToken!,
          refreshToken: authResponse.refreshToken ?? '',
        );

        // Save user data if available
        if (authResponse.user != null) {
          await _storageService.saveUser(authResponse.user!.toJson());
        }
      }

      return authResponse;
    }

    return AuthResponse(
      success: false,
      message: data['message'] ?? 'Authentication failed',
      errors: data['errors'],
    );
  }

  // Handle Dio errors
  AuthResponse _handleDioError(DioException e) {
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

    return AuthResponse(success: false, message: message, errors: errors);
  }
}
