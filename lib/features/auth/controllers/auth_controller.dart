import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/auth_response.dart';
import '../services/auth_service.dart';
import '../../../core/routes/app_routes.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthController extends GetxController {
  final AuthService _authService;

  AuthController({required AuthService authService})
    : _authService = authService;

  // Observable states
  final Rx<AuthStatus> status = AuthStatus.initial.obs;
  final Rx<User?> user = Rx<User?>(null);
  final RxString errorMessage = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool requiresPhoneLink = false.obs;

  // Computed property for auth check
  bool get isAuthenticated => status.value == AuthStatus.authenticated;

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  // Check if user is already logged in and fetch fresh user data
  Future<void> checkAuthStatus() async {
    status.value = AuthStatus.loading;

    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      // First load from local storage for quick display
      user.value = _authService.getCurrentUser();

      // Fetch fresh user data from server to validate token
      final refreshSuccess = await refreshUserProfile();
      if (refreshSuccess) {
        status.value = AuthStatus.authenticated;
      } else {
        // Token was invalid, user has been logged out
        status.value = AuthStatus.unauthenticated;
      }
    } else {
      status.value = AuthStatus.unauthenticated;
    }
  }

  // Fetch fresh user profile from server
  Future<bool> refreshUserProfile() async {
    try {
      final response = await _authService.getProfile();
      if (response.success && response.user != null) {
        user.value = response.user;
        update(); // Notify GetBuilder listeners
        return true;
      }
      return false;
    } catch (e) {
      // If profile fetch fails (e.g., token expired or user deleted), sign out
      await signOut();
      return false;
    }
  }

  // Google Sign-In
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _authService.signInWithGoogle();

      isLoading.value = false;

      if (response.success) {
        if (response.requiresPhoneLink) {
          requiresPhoneLink.value = true;
          status.value = AuthStatus.unauthenticated;
          Get.snackbar(
            'Phone Required',
            'Please link your phone number to continue',
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          user.value = response.user;
          status.value = AuthStatus.authenticated;
          Get.snackbar(
            'Success',
            'Welcome back!',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        errorMessage.value = response.message;
        status.value = AuthStatus.error;
        Get.snackbar(
          'Error',
          response.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Google sign-in failed: ${e.toString()}';
      Get.snackbar(
        'Error',
        'Google sign-in failed. Please check configuration.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Facebook Sign-In
  Future<void> signInWithFacebook() async {
    isLoading.value = true;
    errorMessage.value = '';

    final response = await _authService.signInWithFacebook();

    isLoading.value = false;

    if (response.success) {
      if (response.requiresPhoneLink) {
        requiresPhoneLink.value = true;
        status.value = AuthStatus.unauthenticated;
        Get.snackbar(
          'Phone Required',
          'Please link your phone number to continue',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        user.value = response.user;
        status.value = AuthStatus.authenticated;
        
        // Navigate to dashboard after successful Google sign-in
        await Future.delayed(const Duration(milliseconds: 300));
        Get.offAllNamed(AppRoutes.events);
        
        Get.snackbar(
          'Success',
          'Welcome back!',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } else {
      errorMessage.value = response.message;
      status.value = AuthStatus.error;
      Get.snackbar(
        'Error',
        response.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Request OTP
  Future<bool> requestOtp(String phone) async {
    isLoading.value = true;
    errorMessage.value = '';

    final response = await _authService.requestOtp(phone);

    isLoading.value = false;

    if (response.success) {
      Get.snackbar(
        'OTP Sent',
        'Please check your phone for the OTP',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } else {
      errorMessage.value = response.message;
      Get.snackbar(
        'Error',
        response.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  // Verify OTP
  Future<void> verifyOtp(String phone, String code) async {
    isLoading.value = true;
    errorMessage.value = '';

    final response = await _authService.verifyOtp(phone, code);

    isLoading.value = false;

    if (response.success) {
      user.value = response.user;
      status.value = AuthStatus.authenticated;
      
      // Navigate to dashboard after successful verification
      await Future.delayed(const Duration(milliseconds: 300));
      Get.offAllNamed(AppRoutes.events);
      
      Get.snackbar(
        'Success',
        'Phone verified successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      errorMessage.value = response.message;
      Get.snackbar(
        'Error',
        response.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Link phone number
  Future<void> linkPhone(String phone, String code) async {
    isLoading.value = true;
    errorMessage.value = '';

    final response = await _authService.linkPhone(phone, code);

    isLoading.value = false;

    if (response.success) {
      requiresPhoneLink.value = false;
      user.value = response.user;
      status.value = AuthStatus.authenticated;
      
      // Navigate to dashboard after successful phone linking
      await Future.delayed(const Duration(milliseconds: 300));
      Get.offAllNamed(AppRoutes.events);
      
      Get.snackbar(
        'Success',
        'Phone linked successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      errorMessage.value = response.message;
      Get.snackbar(
        'Error',
        response.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Refresh user profile
  Future<void> refreshProfile() async {
    final response = await _authService.getProfile();
    if (response.success) {
      user.value = response.user;
    }
  }

  // Sign out with confirmation
  Future<void> signOut({bool showConfirmation = true}) async {
    if (showConfirmation) {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Sign Out'),
          content: const Text(
            'Are you sure you want to sign out?\n\nYou will be redirected to browse events.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    isLoading.value = true;

    try {
      // Call auth service to clear backend session and local storage
      await _authService.signOut();

      // Reset all auth state
      user.value = null;
      status.value = AuthStatus.unauthenticated;
      requiresPhoneLink.value = false;
      errorMessage.value = '';

      // Delete all registered controllers to clear cached data
      _cleanupControllers();

      // Navigate to public events page and clear navigation stack
      Get.offAllNamed(AppRoutes.publicEvents);

      Get.snackbar(
        'Signed Out',
        'You have been signed out successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to sign out. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Clean up all controllers except essential ones
  void _cleanupControllers() {
    // List of controller types to delete
    final controllersToDelete = [
      'ProfileController',
      'ProfileService',
      'EventController',
      'EventsController',
      'DashboardController',
      'ChatController',
    ];

    for (final controller in controllersToDelete) {
      try {
        Get.delete(tag: controller, force: true);
      } catch (_) {
        // Controller not registered, ignore
      }
    }

    // Delete by type if registered
    try {
      if (Get.isRegistered<dynamic>(tag: 'ProfileController')) {
        Get.delete(tag: 'ProfileController', force: true);
      }
    } catch (_) {}
  }

  // Clear error
  void clearError() {
    errorMessage.value = '';
    if (status.value == AuthStatus.error) {
      status.value = AuthStatus.unauthenticated;
    }
  }
}
