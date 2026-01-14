import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';

class AboutSection extends StatelessWidget {
  final double screenWidth;
  static const double desktopBreakpoint = 1280;
  static const double tabletBreakpoint = 768;

  const AboutSection({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final maxWidth = screenWidth > desktopBreakpoint ? 1100.0 : screenWidth;
    final isMobile = screenWidth < tabletBreakpoint;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        ),
      ),
      child: Column(
        children: [
          // About content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > desktopBreakpoint
                  ? (screenWidth - maxWidth) / 2
                  : isMobile
                  ? 24
                  : 64,
              vertical: isMobile ? 60 : 100,
            ),
            child: isMobile
                ? Column(
                    children: [
                      _buildAboutContent(isMobile),
                      const SizedBox(height: 48),
                      _buildStatsGrid(isMobile),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 5, child: _buildAboutContent(isMobile)),
                      const SizedBox(width: 80),
                      Expanded(flex: 4, child: _buildStatsGrid(isMobile)),
                    ],
                  ),
          ),
          // CTA Section
          _buildCTASection(isMobile, maxWidth),
        ],
      ),
    );
  }

  Widget _buildAboutContent(bool isMobile) {
    return Column(
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        // Section label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'ABOUT US',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3B82F6),
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Tanzania's trusted platform for community contributions",
          style: TextStyle(
            fontSize: isMobile ? 28 : 38,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
            letterSpacing: -0.5,
            height: 1.25,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 24),
        Text(
          "Ahadi was built with a simple mission: to make it easier for communities to come together and support each other. Whether it's a wedding, funeral, graduation, or any life event, we provide the tools to collect contributions transparently and securely.",
          style: TextStyle(
            fontSize: isMobile ? 16 : 17,
            color: const Color(0xFF6B7280),
            height: 1.8,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 20),
        Text(
          "We believe in the power of community. Our platform handles the complexity of payments so you can focus on what matters most—celebrating life's moments together.",
          style: TextStyle(
            fontSize: isMobile ? 16 : 17,
            color: const Color(0xFF6B7280),
            height: 1.8,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 32),
        // Trust badges
        Wrap(
          spacing: 24,
          runSpacing: 16,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            _buildTrustBadge(Icons.verified_user_outlined, 'Secure Payments'),
            _buildTrustBadge(Icons.support_agent_outlined, '24/7 Support'),
            _buildTrustBadge(Icons.speed_outlined, 'Instant Transfers'),
          ],
        ),
      ],
    );
  }

  Widget _buildTrustBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B5563),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '10,000+',
                  'Events Created',
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildStatItem(
                  '50,000+',
                  'Happy Users',
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'TZS 2B+',
                  'Total Raised',
                  const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildStatItem(
                  '99.9%',
                  'Uptime',
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection(bool isMobile, double maxWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 64,
        vertical: isMobile ? 48 : 64,
      ),
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
      child: Column(
        children: [
          Text(
            'Ready to bring your community together?',
            style: TextStyle(
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Text(
              'Join thousands of Tanzanians using Ahadi to organize events and collect contributions effortlessly.',
              style: TextStyle(
                fontSize: isMobile ? 15 : 17,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _CTAButton(
                text: 'Create Free Event',
                isPrimary: true,
                onPressed: () => Get.toNamed(AppRoutes.login),
              ),
              _CTAButton(
                text: 'Learn More',
                isPrimary: false,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CTAButton extends StatefulWidget {
  final String text;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _CTAButton({
    required this.text,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  State<_CTAButton> createState() => _CTAButtonState();
}

class _CTAButtonState extends State<_CTAButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.diagonal3Values(
          _isHovered ? 1.05 : 1.0,
          _isHovered ? 1.05 : 1.0,
          1.0,
        ),
        child: widget.isPrimary
            ? ElevatedButton(
                onPressed: widget.onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: _isHovered ? 8 : 0,
                  shadowColor: Colors.black.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              )
            : OutlinedButton(
                onPressed: widget.onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: _isHovered ? 1 : 0.5),
                    width: 2,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
      ),
    );
  }
}
