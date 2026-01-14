import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../../../core/routes/app_routes.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  static const double mobileBreakpoint = 768;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= mobileBreakpoint;

    return Scaffold(
      backgroundColor: Colors.white,
      body: isDesktop ? _buildDesktopLayout(context) : _buildMobileLayout(context),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
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
                colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
              ),
            ),
            child: Stack(
              children: [
                // Background pattern
                Positioned.fill(
                  child: CustomPaint(painter: _PatternPainter()),
                ),
                // Content
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
                          child: Icon(Icons.celebration, size: 50, color: AppColors.primary),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Ahadi',
                          style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Celebrate Together, Contribute Seamlessly',
                          style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.9)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        // Feature highlights
                        _buildFeatureItem(Icons.event, 'Create & manage events effortlessly'),
                        const SizedBox(height: 16),
                        _buildFeatureItem(Icons.people, 'Connect with your community'),
                        const SizedBox(height: 16),
                        _buildFeatureItem(Icons.payments, 'Seamless contributions & tracking'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right side - Login form
        Expanded(
          flex: 4,
          child: _buildLoginForm(context, isDesktop: true),
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
        Flexible(
          child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
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
                  child: Text('Help', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          ),
          Expanded(child: _buildLoginForm(context, isDesktop: false)),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, {required bool isDesktop}) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isDesktop) ...[
                // Mobile logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.celebration, size: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Title
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: isDesktop ? 32 : 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to create and manage your events',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Phone Login Button
              ElevatedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.otp),
                icon: const Icon(Icons.phone_android),
                label: const Text('Continue with Phone'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 24),
              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('or continue with', style: TextStyle(color: AppColors.textHint, fontSize: 14)),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
              const SizedBox(height: 24),
              // Social Login Buttons
              Row(
                children: [
                  Expanded(
                    child: Obx(() => _SocialButton(
                      onPressed: controller.isLoading.value ? null : () => controller.signInWithGoogle(),
                      icon: 'G',
                      label: 'Google',
                      isLoading: controller.isLoading.value,
                    )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => _SocialButton(
                      onPressed: controller.isLoading.value ? null : () => controller.signInWithFacebook(),
                      iconWidget: Icon(Icons.facebook, color: AppColors.textSecondary, size: 24),
                      label: 'Facebook',
                      isLoading: controller.isLoading.value,
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Terms
              Text.rich(
                TextSpan(
                  style: TextStyle(color: AppColors.textHint, fontSize: 13),
                  children: [
                    const TextSpan(text: 'By continuing, you agree to our '),
                    TextSpan(text: 'Terms of Service', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                    const TextSpan(text: ' and '),
                    TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Create Event prompt
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Icon(Icons.add_circle_outline, color: AppColors.textPrimary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create your own event', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          Text('Sign in to start organizing', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textHint),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? icon;
  final Widget? iconWidget;
  final String label;
  final bool isLoading;

  const _SocialButton({required this.onPressed, this.icon, this.iconWidget, required this.label, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (iconWidget != null)
                  iconWidget!
                else if (icon != null)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: AppColors.textSecondary, borderRadius: BorderRadius.circular(4)),
                    child: Center(child: Text(icon!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                  ),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
              ],
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
