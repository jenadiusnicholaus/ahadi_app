import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/auth_controller.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const String _testPhone = '+255123456789';
  static const double mobileBreakpoint = 768;
  
  late final TextEditingController phoneController;
  late final TextEditingController otpController;
  final isOtpSent = false.obs;
  final phone = ''.obs;
  final isSubmitting = false.obs;
  
  AuthController get controller => Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController(text: _testPhone);
    otpController = TextEditingController();
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= mobileBreakpoint;

    return WillPopScope(
      onWillPop: () async {
        // Allow back navigation only if not submitting
        return !isSubmitting.value;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true, // Important for Android keyboard
        body: isDesktop
            ? _buildDesktopLayout(context, isDesktop)
            : _buildMobileLayout(context, isDesktop),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isDesktop) {
    return Row(
      children: [
        // Left side - Branding
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _PatternPainter())),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            Icons.phone_android,
                            size: 50,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Phone Verification',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Secure login with your phone number.\nWe\'ll send you a verification code.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        _buildFeatureItem(Icons.security, 'Secure & encrypted'),
                        const SizedBox(height: 16),
                        _buildFeatureItem(Icons.flash_on, 'Quick verification'),
                        const SizedBox(height: 16),
                        _buildFeatureItem(
                          Icons.check_circle,
                          'No password needed',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right side - OTP Form
        Expanded(
          flex: 4,
          child: _buildOtpForm(context, isDesktop),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isDesktop) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => Get.back(),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Help',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildOtpForm(context, isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpForm(BuildContext context, bool isDesktop) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 48 : 24,
          vertical: 24,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Obx(
            () => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isDesktop) ...[
                  // Mobile icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        isOtpSent.value ? Icons.message : Icons.phone_android,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // Title
                Text(
                  isOtpSent.value
                      ? 'Enter Verification Code'
                      : 'Enter Phone Number',
                  style: TextStyle(
                    fontSize: isDesktop ? 32 : 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isOtpSent.value
                      ? 'We sent a 6-digit code to\n${phone.value}'
                      : 'We\'ll send you a verification code',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                if (!isOtpSent.value) ...[
                  // Phone Input
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                    ],
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+255 XXX XXX XXX',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Request OTP Button
                  Obx(
                    () => ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () async {
                              final phoneNumber = phoneController.text.trim();
                              if (phoneNumber.isEmpty) {
                                Get.snackbar(
                                  'Error',
                                  'Please enter your phone number',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                return;
                              }
                              final success = await controller.requestOtp(
                                phoneNumber,
                              );
                              if (success) {
                                phone.value = phoneNumber;
                                isOtpSent.value = true;
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Send Verification Code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ] else ...[
                  // OTP Input with Pinput
                  Pinput(
                    length: 6,
                    controller: otpController,
                    autofocus: false,
                    keyboardType: TextInputType.number,
                    hapticFeedbackType: HapticFeedbackType.lightImpact,
                    closeKeyboardWhenCompleted: false,
                    onTap: () {
                      // Prevent any navigation when tapping input
                      if (mounted) {
                        isSubmitting.value = false;
                      }
                    },
                    defaultPinTheme: PinTheme(
                      width: 52,
                      height: 60,
                      textStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                    ),
                    focusedPinTheme: PinTheme(
                      width: 52,
                      height: 60,
                      textStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                    ),
                    submittedPinTheme: PinTheme(
                      width: 52,
                      height: 60,
                      textStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary),
                      ),
                    ),
                    errorPinTheme: PinTheme(
                      width: 52,
                      height: 60,
                      textStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red),
                      ),
                    ),
                    pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                    showCursor: true,
                    cursor: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          width: 22,
                          height: 2,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    onCompleted: (pin) async {
                      if (isSubmitting.value) return; // Prevent double submission
                      isSubmitting.value = true;
                      
                      // Dismiss keyboard
                      FocusScope.of(context).unfocus();
                      
                      // Wait for keyboard to dismiss
                      await Future.delayed(const Duration(milliseconds: 250));
                      
                      // Submit
                      if (controller.requiresPhoneLink.value) {
                        await controller.linkPhone(phone.value, pin);
                      } else {
                        await controller.verifyOtp(phone.value, pin);
                      }
                      
                      isSubmitting.value = false;
                    },
                  ),
                  const SizedBox(height: 32),
                  // Verify OTP Button
                  Obx(
                    () => ElevatedButton(
                      onPressed: (controller.isLoading.value || isSubmitting.value)
                          ? null
                          : () async {
                              if (isSubmitting.value) return;
                              isSubmitting.value = true;
                              
                              // Dismiss keyboard first
                              FocusScope.of(context).unfocus();
                              
                              final code = otpController.text.trim();
                              if (code.length != 6) {
                                Get.snackbar(
                                  'Error',
                                  'Please enter a valid 6-digit code',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                isSubmitting.value = false;
                                return;
                              }
                              
                              // Wait for keyboard to dismiss
                              await Future.delayed(const Duration(milliseconds: 250));
                              
                              if (controller.requiresPhoneLink.value) {
                                await controller.linkPhone(phone.value, code);
                              } else {
                                await controller.verifyOtp(phone.value, code);
                              }
                              
                              isSubmitting.value = false;
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Verify Code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Resend & Change number
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : () async =>
                                  await controller.requestOtp(phone.value),
                        child: Text(
                          'Resend Code',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                      Text('|', style: TextStyle(color: Colors.grey[300])),
                      TextButton(
                        onPressed: () {
                          isOtpSent.value = false;
                          otpController.clear();
                        },
                        child: Text(
                          'Change Number',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),
                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isOtpSent.value
                              ? 'Code expires in 5 minutes. Check your SMS messages.'
                              : 'Standard SMS rates may apply. We\'ll only use this for verification.',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 30.0;
    for (double i = 0; i < size.width + size.height; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(0, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
