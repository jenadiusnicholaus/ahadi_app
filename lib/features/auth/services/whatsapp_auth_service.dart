import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

/// Service for WhatsApp-based authentication
class WhatsAppAuthService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  /// Request OTP to be sent via WhatsApp
  /// 
  /// Returns a map with:
  /// - success: bool
  /// - message: String
  /// - expires_in: int (seconds)
  /// - phone_number: String
  Future<Map<String, dynamic>> requestOTP(String phoneNumber) async {
    try {
      final formattedPhone = formatPhoneNumber(phoneNumber);
      
      final response = await _apiService.post(
        '/whatsapp/auth/request-otp/',
        data: {'phone_number': formattedPhone},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      // Handle rate limit error
      if (e.toString().contains('429')) {
        return {
          'success': false,
          'error': 'Please wait before requesting another OTP',
        };
      }
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  /// Verify OTP and authenticate
  /// 
  /// Returns a map with:
  /// - success: bool
  /// - message: String
  /// - user: Map (user data)
  /// - access: String (JWT token)
  /// - refresh: String (refresh token)
  /// - is_new_user: bool
  Future<Map<String, dynamic>> verifyOTP(String phoneNumber, String otpCode) async {
    try {
      final formattedPhone = formatPhoneNumber(phoneNumber);
      
      final response = await _apiService.post(
        '/whatsapp/auth/verify-otp/',
        data: {
          'phone_number': formattedPhone,
          'otp_code': otpCode,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Save tokens using the correct method
        await _storageService.saveTokens(
          accessToken: response.data['access'],
          refreshToken: response.data['refresh'],
        );
        
        return response.data;
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Verification failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error. Please try again.',
      };
    }
  }

  /// Resend OTP via WhatsApp
  Future<Map<String, dynamic>> resendOTP(String phoneNumber) async {
    try {
      final formattedPhone = formatPhoneNumber(phoneNumber);
      
      final response = await _apiService.post(
        '/whatsapp/auth/resend-otp/',
        data: {'phone_number': formattedPhone},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {
          'success': false,
          'error': response.data['error'] ?? 'Failed to resend OTP',
        };
      }
    } catch (e) {
      if (e.toString().contains('429')) {
        return {
          'success': false,
          'error': 'Please wait before requesting another OTP',
        };
      }
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  /// Format phone number for API
  String formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Add Tanzania country code if needed
    if (cleaned.startsWith('0')) {
      cleaned = '255${cleaned.substring(1)}';
    } else if (cleaned.length == 9) {
      cleaned = '255$cleaned';
    } else if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }
    
    return cleaned;
  }

  /// Validate phone number format
  bool isValidPhoneNumber(String phone) {
    final cleaned = formatPhoneNumber(phone);
    
    // Tanzanian numbers: 255 + 9 digits = 12 digits
    if (cleaned.startsWith('255')) {
      return cleaned.length == 12;
    }
    
    // Generic: 10-15 digits
    return cleaned.length >= 10 && cleaned.length <= 15;
  }
}
