import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
      body: isDesktop
          ? _buildDesktopLayout(context)
          : _buildMobileLayout(context),
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
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.85),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Background pattern
                Positioned.fill(child: CustomPaint(painter: _PatternPainter())),
                // Floating shapes
                Positioned(
                  top: 50,
                  right: 50,
                  child: _buildFloatingShape(80, 0.1),
                ),
                Positioned(
                  bottom: 100,
                  left: 30,
                  child: _buildFloatingShape(60, 0.08),
                ),
                Positioned(
                  top: 200,
                  left: 100,
                  child: _buildFloatingShape(40, 0.06),
                ),
                // Content
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.asset(
                              'assets/images/ahadi_logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Ahadi',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Celebrate Together, Contribute Seamlessly',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 60),
                        // Feature highlights
                        _buildFeatureItem(
                          FontAwesomeIcons.calendarCheck,
                          'Create & manage events effortlessly',
                        ),
                        const SizedBox(height: 20),
                        _buildFeatureItem(
                          FontAwesomeIcons.userGroup,
                          'Connect with your community',
                        ),
                        const SizedBox(height: 20),
                        _buildFeatureItem(
                          FontAwesomeIcons.wallet,
                          'Seamless contributions & tracking',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right side - Login form
        Expanded(flex: 4, child: _buildLoginForm(context, isDesktop: true)),
      ],
    );
  }

  Widget _buildFloatingShape(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: FaIcon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SafeArea(child: _buildLoginForm(context, isDesktop: false));
  }

  Widget _buildLoginForm(BuildContext context, {required bool isDesktop}) {
    return Container(
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 48 : 28,
              vertical: isDesktop ? 24 : 40,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!isDesktop) ...[
                  // Mobile logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.asset(
                        'assets/images/ahadi_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                // Title
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: isDesktop ? 32 : 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Sign in to manage your events and contributions',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // WhatsApp Button (Primary)
                _buildPrimaryButton(
                  onPressed: () => Get.toNamed(AppRoutes.whatsappLogin),
                  icon: FontAwesomeIcons.whatsapp,
                  label: 'Continue with WhatsApp',
                  color: const Color(0xFF25D366),
                  isLoading: false,
                ),
                const SizedBox(height: 32),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.grey[300]!],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'or continue with',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey[300]!, Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Social Icons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google
                    Obx(
                      () => _SocialIconButtonCustom(
                        onPressed: controller.isLoading.value
                            ? null
                            : () => controller.signInWithGoogle(),
                        iconWidget: const _GoogleIcon(),
                        isLoading: controller.isGoogleLoading.value,
                        label: 'Google',
                        loadingColor: const Color(0xFFDB4437),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Facebook
                    Obx(
                      () => _SocialIconButtonCustom(
                        onPressed: controller.isLoading.value
                            ? null
                            : () => controller.signInWithFacebook(),
                        iconWidget: const _FacebookIcon(),
                        isLoading: controller.isFacebookLoading.value,
                        label: 'Facebook',
                        loadingColor: const Color(0xFF1877F2),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Apple
                    _SocialIconButton(
                      onPressed: () {
                        Get.snackbar(
                          'Coming Soon',
                          'Apple Sign-In will be available soon',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      icon: FontAwesomeIcons.apple,
                      color: Colors.black,
                      isLoading: false,
                      label: 'Apple',
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Terms
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 13,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(
                          text: 'By continuing, you agree to our ',
                        ),
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),

                // Create Event Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.05),
                        AppColors.primary.withValues(alpha: 0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: FaIcon(
                          FontAwesomeIcons.plus,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create your first event',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sign in to start organizing',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: FaIcon(
                          FontAwesomeIcons.arrowRight,
                          size: 14,
                          color: AppColors.primary,
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

  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required bool isLoading,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: color.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(icon, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Round Social Icon Button
class _SocialIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final String label;

  const _SocialIconButton({
    required this.onPressed,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.grey[200]!, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: color,
                      ),
                    ),
                  )
                : Center(child: FaIcon(icon, color: color, size: 24)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    for (double i = 0; i < size.width + size.height; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(0, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Social Icon Button with Widget icon
class _SocialIconButtonCustom extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget iconWidget;
  final bool isLoading;
  final String label;
  final Color loadingColor;

  const _SocialIconButtonCustom({
    required this.onPressed,
    required this.iconWidget,
    required this.isLoading,
    required this.label,
    required this.loadingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.grey[200]!, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: loadingColor,
                      ),
                    ),
                  )
                : Center(child: iconWidget),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Official Google "G" Logo - Multi-colored
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        size: const Size(24, 24),
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Google brand colors
    const Color blue = Color(0xFF4285F4);
    const Color red = Color(0xFFEA4335);
    const Color yellow = Color(0xFFFBBC05);
    const Color green = Color(0xFF34A853);

    // Center the logo with padding
    final center = Offset(w / 2, h / 2);
    final radius = (w / 2) * 0.75;  // 75% of half width
    final strokeWidth = w * 0.15;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw in correct order: blue, green, yellow, red
    // Using radians: 0 = 3 o'clock, PI/2 = 6 o'clock, PI = 9 o'clock, 3*PI/2 = 12 o'clock
    
    // Blue section (right side, from ~2 o'clock to ~5 o'clock)
    final bluePaint = Paint()
      ..color = blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, -0.3, 1.1, false, bluePaint);

    // Green section (bottom, from ~5 o'clock to ~7 o'clock)
    final greenPaint = Paint()
      ..color = green
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, 0.8, 0.8, false, greenPaint);

    // Yellow section (left bottom, from ~7 o'clock to ~10 o'clock)
    final yellowPaint = Paint()
      ..color = yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, 1.6, 0.9, false, yellowPaint);

    // Red section (top, from ~10 o'clock to ~2 o'clock)
    final redPaint = Paint()
      ..color = red
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, 2.5, 0.95, false, redPaint);

    // Blue horizontal bar (the horizontal part of the G)
    final barPaint = Paint()
      ..color = blue
      ..style = PaintingStyle.fill;
    final barHeight = strokeWidth * 0.9;
    final barTop = (h / 2) - (barHeight / 2);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.5, barTop, w * 0.38, barHeight),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Official Facebook "f" Logo
class _FacebookIcon extends StatelessWidget {
  const _FacebookIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF1877F2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(14, 20),
          painter: _FacebookLogoPainter(),
        ),
      ),
    );
  }
}

class _FacebookLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Facebook "f" shape
    path.moveTo(w * 0.65, h);
    path.lineTo(w * 0.65, h * 0.55);
    path.lineTo(w, h * 0.55);
    path.lineTo(w, h * 0.35);
    path.lineTo(w * 0.65, h * 0.35);
    path.lineTo(w * 0.65, h * 0.22);
    path.quadraticBezierTo(w * 0.65, h * 0.05, w * 0.85, h * 0.05);
    path.lineTo(w, h * 0.05);
    path.lineTo(w, 0);
    path.lineTo(w * 0.75, 0);
    path.quadraticBezierTo(w * 0.35, 0, w * 0.35, h * 0.22);
    path.lineTo(w * 0.35, h * 0.35);
    path.lineTo(0, h * 0.35);
    path.lineTo(0, h * 0.55);
    path.lineTo(w * 0.35, h * 0.55);
    path.lineTo(w * 0.35, h);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
