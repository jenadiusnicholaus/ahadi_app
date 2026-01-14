import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';

class PricingSection extends StatelessWidget {
  final double screenWidth;
  static const double desktopBreakpoint = 1280;
  static const double tabletBreakpoint = 768;

  const PricingSection({super.key, required this.screenWidth});

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
      color: Colors.white,
      child: Column(
        children: [
          // Section label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'PRICING',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10B981),
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Main heading
          Text(
            'Simple, transparent pricing',
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
            constraints: const BoxConstraints(maxWidth: 550),
            child: Text(
              'No monthly fees. We only charge a small percentage when you receive contributions.',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                color: const Color(0xFF6B7280),
                height: 1.7,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: isMobile ? 48 : 64),
          // Pricing cards
          isMobile
              ? Column(
                  children: [
                    _buildPricingCard(
                      'Starter',
                      '5%',
                      'Free forever',
                      [
                        'Up to 50 contributors',
                        'Basic event analytics',
                        'M-Pesa & Airtel Money',
                        'Email support',
                      ],
                      false,
                      const Color(0xFF6B7280),
                    ),
                    const SizedBox(height: 20),
                    _buildPricingCard(
                      'Pro',
                      '3%',
                      'TZS 15,000/mo',
                      [
                        'Unlimited contributors',
                        'Advanced analytics',
                        'All payment methods',
                        'Event chat feature',
                        'Priority support',
                      ],
                      true,
                      AppColors.primary,
                    ),
                    const SizedBox(height: 20),
                    _buildPricingCard(
                      'Business',
                      '2%',
                      'TZS 40,000/mo',
                      [
                        'Everything in Pro',
                        'Custom branding',
                        'API access',
                        'Dedicated manager',
                        'Phone support',
                      ],
                      false,
                      const Color(0xFF8B5CF6),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildPricingCard(
                        'Starter',
                        '5%',
                        'Free forever',
                        [
                          'Up to 50 contributors',
                          'Basic event analytics',
                          'M-Pesa & Airtel Money',
                          'Email support',
                        ],
                        false,
                        const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildPricingCard(
                        'Pro',
                        '3%',
                        'TZS 15,000/mo',
                        [
                          'Unlimited contributors',
                          'Advanced analytics',
                          'All payment methods',
                          'Event chat feature',
                          'Priority support',
                        ],
                        true,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildPricingCard(
                        'Business',
                        '2%',
                        'TZS 40,000/mo',
                        [
                          'Everything in Pro',
                          'Custom branding',
                          'API access',
                          'Dedicated manager',
                          'Phone support',
                        ],
                        false,
                        const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(
    String plan,
    String fee,
    String price,
    List<String> features,
    bool isPopular,
    Color accentColor,
  ) {
    return _HoverPricingCard(
      isPopular: isPopular,
      accentColor: accentColor,
      child: Container(
        padding: EdgeInsets.all(isPopular ? 32 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'MOST POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            Text(
              plan,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fee,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                    height: 1,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8, left: 4),
                  child: Text(
                    'fee',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 24),
            Container(height: 1, color: const Color(0xFFE5E7EB)),
            const SizedBox(height: 24),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4B5563),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: isPopular
                  ? ElevatedButton(
                      onPressed: () => Get.toNamed(AppRoutes.login),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: () => Get.toNamed(AppRoutes.login),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4B5563),
                        side: const BorderSide(
                          color: Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverPricingCard extends StatefulWidget {
  final Widget child;
  final bool isPopular;
  final Color accentColor;

  const _HoverPricingCard({
    required this.child,
    required this.isPopular,
    required this.accentColor,
  });

  @override
  State<_HoverPricingCard> createState() => _HoverPricingCardState();
}

class _HoverPricingCardState extends State<_HoverPricingCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scaleMatrix = Matrix4.diagonal3Values(1.02, 1.02, 1.0);
    final translateMatrix = Matrix4.translationValues(0.0, -8.0, 0.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: _isHovered
            ? (translateMatrix..multiply(scaleMatrix))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isPopular
                ? widget.accentColor
                : (_isHovered
                      ? const Color(0xFFD1D5DB)
                      : const Color(0xFFE5E7EB)),
            width: widget.isPopular ? 2 : 1,
          ),
          boxShadow: [
            if (widget.isPopular || _isHovered)
              BoxShadow(
                color: widget.isPopular
                    ? widget.accentColor.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: _isHovered ? 40 : 30,
                offset: Offset(0, _isHovered ? 20 : 15),
              ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
