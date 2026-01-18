import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';

/// Service to handle deep links for the app
class DeepLinkService extends GetxService {
  /// Initialize deep link handling
  Future<DeepLinkService> init() async {
    // Handle initial deep link if app was opened via link
    // Web handling removed - mobile only
    return this;
  }

  /// Handle incoming deep link URL
  void handleDeepLink(Uri uri) {
    debugPrint('🔗 [DeepLink] Handling: $uri');

    final scheme = uri.scheme;
    final host = uri.host;
    final path = uri.path;
    final pathSegments = uri.pathSegments;

    // Handle ahadi:// scheme
    if (scheme == 'ahadi') {
      if (host == 'join' && pathSegments.isNotEmpty) {
        handleJoinCode(pathSegments.first);
        return;
      }
      if (pathSegments.isNotEmpty && pathSegments.first == 'join') {
        if (pathSegments.length > 1) {
          handleJoinCode(pathSegments[1]);
          return;
        }
      }
    }

    // Handle https://ahadi.app/join/CODE
    if (scheme == 'https' && (host == 'ahadi.app' || host == 'www.ahadi.app')) {
      if (pathSegments.isNotEmpty && pathSegments.first == 'join') {
        if (pathSegments.length > 1) {
          handleJoinCode(pathSegments[1]);
          return;
        }
      }
    }

    // Handle path-based: /join/CODE
    if (path.startsWith('/join/')) {
      final code = path.replaceFirst('/join/', '');
      if (code.isNotEmpty) {
        handleJoinCode(code);
        return;
      }
    }

    debugPrint('🔗 [DeepLink] Unhandled link: $uri');
  }

  /// Handle a join code
  void handleJoinCode(String code) {
    debugPrint('🔗 [DeepLink] Joining event with code: $code');

    // Navigate to join event dialog
    Get.dialog(
      JoinEventByCodeDialog(joinCode: code),
      barrierDismissible: false,
    );
  }

  /// Parse join code from any URL format
  static String? parseJoinCode(String url) {
    try {
      // Direct code (no URL)
      if (!url.contains('/') && !url.contains(':')) {
        return url.trim();
      }

      final uri = Uri.parse(url);

      // ahadi://join/CODE
      if (uri.scheme == 'ahadi' && uri.host == 'join') {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      }

      // Path: /join/CODE
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'join') {
        return uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Dialog to join event by code from deep link
class JoinEventByCodeDialog extends StatefulWidget {
  final String joinCode;

  const JoinEventByCodeDialog({super.key, required this.joinCode});

  @override
  State<JoinEventByCodeDialog> createState() => _JoinEventByCodeDialogState();
}

class _JoinEventByCodeDialogState extends State<JoinEventByCodeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.event, color: Colors.blue),
          SizedBox(width: 8),
          Text('Join Event'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Code: ${widget.joinCode}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter your details to join:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                hintText: '+255...',
              ),
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Phone is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Get.back(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _joinEvent,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Join Event'),
        ),
      ],
    );
  }

  Future<void> _joinEvent() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);

    try {
      // Import events controller dynamically to avoid circular dependency
      final controller = Get.find<dynamic>(tag: 'EventsController');

      final success = await controller.joinEventByCode(
        widget.joinCode,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
      );

      if (success) {
        Get.back();
        Get.snackbar(
          'Success! 🎉',
          'You have successfully joined the event',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF4CAF50),
          colorText: const Color(0xFFFFFFFF),
        );
        // Navigate to dashboard to see the event
        Get.offAllNamed(AppRoutes.dashboard);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to join event: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF44336),
        colorText: const Color(0xFFFFFFFF),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
