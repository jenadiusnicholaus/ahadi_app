import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_service.dart';
import '../../auth/models/auth_response.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/routes/app_routes.dart';

class ProfileController extends GetxController {
  final ProfileService _profileService;

  ProfileController({required ProfileService profileService})
    : _profileService = profileService;

  // Observable states
  final Rx<User?> user = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;
  final RxString errorMessage = ''.obs;

  // Form controllers
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  final Rx<File?> selectedImage = Rx<File?>(null);
  final Rx<Uint8List?> selectedImageBytes = Rx<Uint8List?>(null);
  final RxString selectedImageName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    super.onClose();
  }

  /// Load user profile from API
  Future<void> loadProfile() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await _profileService.getProfile();

      if (response.success && response.user != null) {
        user.value = response.user;
        _populateFormFields();
      } else {
        errorMessage.value = response.message;
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Populate form fields with current user data
  void _populateFormFields() {
    fullNameController.text = user.value?.fullName ?? '';
    emailController.text = user.value?.email ?? '';
  }

  /// Update profile (name and email)
  Future<bool> updateProfile() async {
    if (isUpdating.value) return false;

    isUpdating.value = true;
    errorMessage.value = '';

    try {
      final response = await _profileService.updateProfile(
        fullName: fullNameController.text.trim(),
        email: emailController.text.trim(),
      );

      if (response.success && response.user != null) {
        user.value = response.user;
        Get.snackbar(
          'Success',
          'Profile updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        errorMessage.value = response.message;
        Get.snackbar(
          'Error',
          response.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isUpdating.value = false;
    }
  }

  /// Pick image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        // For mobile, use File
        selectedImage.value = File(image.path);
        await _uploadProfilePicture();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Pick image from camera
  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        // For mobile, use File
        selectedImage.value = File(image.path);
        await _uploadProfilePicture();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to take photo: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Upload profile picture
  Future<void> _uploadProfilePicture() async {
    // Check if we have image data to upload
    debugPrint('📸 [ProfileController] _uploadProfilePicture called');
    debugPrint(
      '📸 [ProfileController] selectedImage.value: ${selectedImage.value}',
    );

    if (selectedImage.value == null) {
      debugPrint(
        '📸 [ProfileController] No image selected, returning',
      );
      return;
    }

    isUpdating.value = true;

    try {
      ProfileResponse response;

      // For mobile, use File
      debugPrint(
        '📸 [ProfileController] Uploading via File: ${selectedImage.value!.path}',
      );
      response = await _profileService.updateProfilePicture(
        selectedImage.value!,
      );

      debugPrint(
        '📸 [ProfileController] Upload response: success=${response.success}, message=${response.message}',
      );

      if (response.success && response.user != null) {
        user.value = response.user;
        selectedImage.value = null;
        selectedImageBytes.value = null;
        selectedImageName.value = '';
        debugPrint(
          '📸 [ProfileController] Profile picture updated successfully',
        );
        Get.snackbar(
          'Success',
          'Profile picture updated',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        debugPrint('📸 [ProfileController] Upload failed: ${response.message}');
        Get.snackbar(
          'Error',
          response.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('📸 [ProfileController] Upload exception: $e');
      Get.snackbar(
        'Error',
        'Failed to upload: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUpdating.value = false;
    }
  }

  /// Remove profile picture
  Future<void> removeProfilePicture() async {
    isUpdating.value = true;

    try {
      final response = await _profileService.removeProfilePicture();

      if (response.success) {
        user.value = response.user;
        Get.snackbar(
          'Success',
          'Profile picture removed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          response.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isUpdating.value = false;
    }
  }

  /// Show image picker options
  void showImagePickerOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Change Profile Picture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Get.back();
                pickImageFromGallery();
              },
            ),
            // Camera option
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Take a Photo'),
              onTap: () {
                Get.back();
                pickImageFromCamera();
              },
            ),
            if (user.value?.profilePicture != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo'),
                onTap: () {
                  Get.back();
                  _confirmRemovePhoto();
                },
              ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  /// Confirm remove photo
  void _confirmRemovePhoto() {
    Get.dialog(
      AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text(
          'Are you sure you want to remove your profile picture?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              removeProfilePicture();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  /// Logout user - delegates to AuthController for proper session cleanup
  Future<void> logout() async {
    try {
      final authController = Get.find<AuthController>();
      await authController.signOut();
    } catch (e) {
      // Fallback if AuthController not found
      Get.offAllNamed(AppRoutes.publicEvents);
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone. All your events and data will be permanently deleted.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => _confirmDeleteAccount(),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Second confirmation for delete
  void _confirmDeleteAccount() {
    Get.back();
    final deleteConfirmController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Final Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This is your final warning. Your account and all associated data will be permanently deleted.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: deleteConfirmController,
              decoration: const InputDecoration(
                hintText: 'Type DELETE to confirm',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              deleteConfirmController.dispose();
              Get.back();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (deleteConfirmController.text.toUpperCase() != 'DELETE') {
                Get.snackbar(
                  'Error',
                  'Please type DELETE to confirm',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              deleteConfirmController.dispose();
              Get.back();
              isLoading.value = true;

              final response = await _profileService.deleteAccount();

              if (response.success) {
                Get.snackbar(
                  'Account Deleted',
                  'Your account has been deleted successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
                // Navigate to login screen
                Get.offAllNamed(AppRoutes.login);
              } else {
                Get.snackbar(
                  'Error',
                  response.message,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }

              isLoading.value = false;
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  /// Get subscription plan name
  String get subscriptionPlanName {
    return user.value?.subscription?['plan'] ?? 'Free';
  }

  /// Get subscription plan type
  String get subscriptionPlanType {
    return user.value?.subscription?['plan_type'] ?? 'FREE';
  }

  /// Get owned events count
  int get ownedEventsCount {
    return user.value?.stats?['owned_events'] ?? 0;
  }

  /// Get participating events count
  int get participatingEventsCount {
    return user.value?.stats?['participating_events'] ?? 0;
  }

  /// Check if user has premium features
  bool get hasChatFeature {
    return user.value?.subscription?['features']?['chat'] ?? false;
  }

  bool get hasInvitationsFeature {
    return user.value?.subscription?['features']?['invitations'] ?? false;
  }

  bool get hasRemindersFeature {
    return user.value?.subscription?['features']?['reminders'] ?? false;
  }

  bool get hasReportsFeature {
    return user.value?.subscription?['features']?['reports'] ?? false;
  }
}
