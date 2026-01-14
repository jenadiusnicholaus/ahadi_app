import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class HowItWorksSection extends StatelessWidget {
  final double screenWidth;
  static const double desktopBreakpoint = 1280;
  static const double tabletBreakpoint = 768;

  const HowItWorksSection({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final maxWidth = screenWidth > desktopBreakpoint ? 1100.0 : screenWidth;
    final isMobile = screenWidth < tabletBreakpoint;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth > desktopBreakpoint
            ? (screenWidth - maxWidth) / 2
            : isMobile
            ? 24
            : 64,
        vertical: isMobile ? 60 : 100,
      ),
      decoration: const BoxDecoration(color: Color(0xFFFAFAFA)),
      child: Column(
        children: [
          // Section label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'HOW IT WORKS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Main heading
          Text(
            'Get started in minutes',
            style: TextStyle(
              fontSize: isMobile ? 28 : 42,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
              letterSpacing: -0.5,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Subheading
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              'Create your event, share with your community, and start receiving contributions seamlessly.',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                color: const Color(0xFF6B7280),
                height: 1.7,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: isMobile ? 48 : 72),
          // Steps
          isMobile
              ? Column(
                  children: [
                    _buildStep(
                      1,
                      'Create Your Event',
                      'Set up your event in minutes with our intuitive form. Add details, set your goal, and customize the experience.',
                    ),
                    _buildConnector(true),
                    _buildStep(
                      2,
                      'Share & Invite',
                      'Get a unique event code and link. Share via WhatsApp, SMS, or social media to reach your community.',
                    ),
                    _buildConnector(true),
                    _buildStep(
                      3,
                      'Collect Contributions',
                      'Receive payments via M-Pesa, Airtel Money, Tigo Pesa, and bank transfers. All in one place.',
                    ),
                    _buildConnector(true),
                    _buildStep(
                      4,
                      'Track & Withdraw',
                      'Monitor contributions in real-time. Withdraw funds directly to your mobile money or bank account.',
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildStepCard(
                        1,
                        'Create Your Event',
                        'Set up your event in minutes with our intuitive form. Add details, set your goal, and customize the experience.',
                      ),
                    ),
                    _buildConnector(false),
                    Expanded(
                      child: _buildStepCard(
                        2,
                        'Share & Invite',
                        'Get a unique event code and link. Share via WhatsApp, SMS, or social media to reach your community.',
                      ),
                    ),
                    _buildConnector(false),
                    Expanded(
                      child: _buildStepCard(
                        3,
                        'Collect Contributions',
                        'Receive payments via M-Pesa, Airtel Money, Tigo Pesa, and bank transfers. All in one place.',
                      ),
                    ),
                    _buildConnector(false),
                    Expanded(
                      child: _buildStepCard(
                        4,
                        'Track & Withdraw',
                        'Monitor contributions in real-time. Withdraw funds directly to your mobile money or bank account.',
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildConnector(bool isVertical) {
    if (isVertical) {
      return Container(
        width: 2,
        height: 40,
        margin: const EdgeInsets.only(left: 29),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.3),
              AppColors.primary.withValues(alpha: 0.1),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 35),
      child: SizedBox(
        width: 40,
        child: CustomPaint(
          painter: _DashedLinePainter(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          size: const Size(40, 2),
        ),
      ),
    );
  }

  Widget _buildStep(int step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(int step, String title, String description) {
    return _HoverCard(
      child: Container(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$step',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.7,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverCard extends StatefulWidget {
  final Widget child;
  const _HoverCard({required this.child});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0.0, _isHovered ? -8.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? Colors.black.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _isHovered ? 30 : 20,
              offset: Offset(0, _isHovered ? 15 : 8),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
