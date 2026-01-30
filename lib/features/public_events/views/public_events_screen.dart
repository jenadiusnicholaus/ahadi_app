import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../events/controllers/events_controller.dart';
import '../../events/models/event_model.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/public_events_controller.dart';
import '../widgets/how_it_works_section.dart';
import '../widgets/pricing_section.dart';
import '../widgets/about_section.dart';

class PublicEventsScreen extends StatelessWidget {
  const PublicEventsScreen({super.key});

  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1280;

  // Global keys for scrolling to sections
  static final GlobalKey discoverKey = GlobalKey();
  static final GlobalKey howItWorksKey = GlobalKey();
  static final GlobalKey pricingKey = GlobalKey();
  static final GlobalKey aboutKey = GlobalKey();

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use permanent controller to prevent disposal when navigating away
    final controller = Get.put(PublicEventsController(), permanent: true);

    // Ensure the controller is properly loaded when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.ensureLoaded();
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= mobileBreakpoint;

    return Scaffold(
      backgroundColor: Colors.white,
      body: isDesktop
          ? _buildWebLayout(context, controller, screenWidth)
          : _buildMobileLayout(context, controller, screenWidth),
    );
  }

  // ==================== WEB LAYOUT ====================
  Widget _buildWebLayout(
    BuildContext context,
    PublicEventsController controller,
    double screenWidth,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildWebNavbar(context, controller),
          _buildHeroSection(context, controller, screenWidth),
          Container(
            key: discoverKey,
            child: _buildEventTypesSection(controller, screenWidth),
          ),
          _buildEventsSection(context, controller, screenWidth),
          Container(
            key: howItWorksKey,
            child: HowItWorksSection(screenWidth: screenWidth),
          ),
          Container(
            key: pricingKey,
            child: PricingSection(screenWidth: screenWidth),
          ),
          Container(
            key: aboutKey,
            child: AboutSection(screenWidth: screenWidth),
          ),
          _buildFooter(screenWidth),
        ],
      ),
    );
  }

  Widget _buildWebNavbar(
    BuildContext context,
    PublicEventsController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Logo
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _scrollToSection(discoverKey),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.celebration,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Ahadi',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Nav links
          _NavLink(
            title: 'Discover',
            onTap: () => _scrollToSection(discoverKey),
          ),
          _NavLink(
            title: 'How It Works',
            onTap: () => _scrollToSection(howItWorksKey),
          ),
          _NavLink(title: 'Pricing', onTap: () => _scrollToSection(pricingKey)),
          _NavLink(title: 'About', onTap: () => _scrollToSection(aboutKey)),
          const SizedBox(width: 24),
          // Search
          Obx(
            () => controller.isSearching.value
                ? Container(
                    width: 280,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      autofocus: true,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search events...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: Color(0xFF6B7280),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Color(0xFF6B7280),
                          ),
                          onPressed: () {
                            controller.isSearching.value = false;
                            controller.search('');
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: controller.search,
                    ),
                  )
                : _SearchButton(
                    onTap: () => controller.isSearching.value = true,
                  ),
          ),
          const SizedBox(width: 20),
          _buildAuthButton(),
        ],
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    PublicEventsController controller,
    double screenWidth,
  ) {
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
        ),
      ),
      child: Column(
        children: [
          isMobile
              ? Column(
                  children: [
                    _buildHeroContent(context, controller, isMobile),
                    const SizedBox(height: 48),
                    _buildHeroStats(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildHeroContent(context, controller, isMobile),
                    ),
                    const SizedBox(width: 64),
                    Expanded(flex: 4, child: _buildHeroStats()),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildHeroContent(
    BuildContext context,
    PublicEventsController controller,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.trending_up, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Trusted by 50,000+ Tanzanians',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Celebrate Together,\nContribute Seamlessly',
          style: TextStyle(
            fontSize: isMobile ? 36 : 52,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.15,
            letterSpacing: -1,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 24),
        Text(
          'The simplest way to organize events and collect contributions from your community. Weddings, funerals, fundraisers—all in one secure platform.',
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            color: const Color(0xFFB8C1CC),
            height: 1.7,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 36),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            _HeroButton(
              text: 'Join with Code',
              icon: Icons.qr_code_scanner,
              isPrimary: true,
              onPressed: () => _showJoinByCodeDialog(context, controller),
            ),
            _HeroButton(
              text: 'Create Event',
              icon: Icons.add_circle_outline,
              isPrimary: false,
              onPressed: () => Get.toNamed(AppRoutes.login),
            ),
          ],
        ),
        const SizedBox(height: 40),
        // Trust indicators
        Wrap(
          spacing: 24,
          runSpacing: 12,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            _buildTrustIndicator(Icons.lock_outline, 'Secure Payments'),
            _buildTrustIndicator(Icons.flash_on_outlined, 'Instant Setup'),
            _buildTrustIndicator(Icons.support_agent_outlined, '24/7 Support'),
          ],
        ),
      ],
    );
  }

  Widget _buildTrustIndicator(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroStats() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildHeroStatItem('10,000+', 'Events Created', AppColors.primary),
          const SizedBox(height: 20),
          _buildHeroStatItem('50,000+', 'Happy Users', const Color(0xFF10B981)),
          const SizedBox(height: 20),
          _buildHeroStatItem(
            'TZS 2B+',
            'Total Raised',
            const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 20),
          _buildHeroStatItem('99.9%', 'Uptime', const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _buildHeroStatItem(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              value.contains('Events')
                  ? Icons.event
                  : value.contains('Users')
                  ? Icons.people
                  : value.contains('TZS')
                  ? Icons.monetization_on
                  : Icons.speed,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventTypesSection(
    PublicEventsController controller,
    double screenWidth,
  ) {
    final maxWidth = screenWidth > desktopBreakpoint
        ? desktopBreakpoint
        : screenWidth;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth > desktopBreakpoint
            ? (screenWidth - maxWidth) / 2 + 48
            : 48,
        vertical: 48,
      ),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Browse by Category',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Obx(() {
            final types = controller.eventTypes;
            return SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: types.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildCategoryChip(
                      controller,
                      null,
                      'All Events',
                      Icons.apps,
                    );
                  }
                  final type = types[index - 1];
                  return _buildCategoryChip(
                    controller,
                    type.id,
                    type.name,
                    _getIconForType(type.name),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    PublicEventsController controller,
    int? typeId,
    String name,
    IconData icon,
  ) {
    return Obx(() {
      final isSelected = controller.selectedEventTypeId.value == typeId;
      return InkWell(
        onTap: () => controller.filterByEventType(typeId),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey[300]!,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  IconData _getIconForType(String name) {
    switch (name.toLowerCase()) {
      case 'wedding':
        return Icons.favorite;
      case 'funeral':
        return Icons.sentiment_neutral;
      case 'fundraiser':
        return Icons.volunteer_activism;
      case 'birthday':
        return Icons.cake;
      case 'graduation':
        return Icons.school;
      case 'church event':
        return Icons.church;
      case 'baby shower':
        return Icons.child_care;
      case 'anniversary':
        return Icons.celebration;
      case 'community event':
        return Icons.groups;
      case 'corporate':
        return Icons.business;
      default:
        return Icons.event;
    }
  }

  Widget _buildEventsSection(
    BuildContext context,
    PublicEventsController controller,
    double screenWidth,
  ) {
    final maxWidth = screenWidth > desktopBreakpoint
        ? desktopBreakpoint
        : screenWidth;
    final crossAxisCount = _getGridCrossAxisCount(screenWidth);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth > desktopBreakpoint
            ? (screenWidth - maxWidth) / 2 + 48
            : 48,
        vertical: 48,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Discover Events',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Obx(
                () =>
                    controller.searchQuery.value.isNotEmpty ||
                        controller.selectedEventTypeId.value != null
                    ? TextButton.icon(
                        onPressed: controller.clearFilters,
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear filters'),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          PagedGridView<int, EventModel>(
            pagingController: controller.pagingController,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 0.85,
            ),
            builderDelegate: PagedChildBuilderDelegate<EventModel>(
              itemBuilder: (context, event, index) =>
                  _buildWebEventCard(context, controller, event),
              firstPageProgressIndicatorBuilder: (_) => _buildLoadingState(),
              newPageProgressIndicatorBuilder: (_) => _buildLoadingState(),
              firstPageErrorIndicatorBuilder: (context) => _buildErrorState(
                controller.pagingController.error.toString(),
                () => controller.pagingController.refresh(),
              ),
              noItemsFoundIndicatorBuilder: (_) => _buildEmptyState(controller),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebEventCard(
    BuildContext context,
    PublicEventsController controller,
    EventModel event,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showEventDetails(context, controller, event),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: event.displayCoverImage.isNotEmpty
                          ? Image.network(
                              event.displayCoverImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildImagePlaceholder(),
                            )
                          : _buildImagePlaceholder(),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat(
                                'dd',
                              ).format(event.startDate ?? DateTime.now()),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                height: 1,
                              ),
                            ),
                            Text(
                              DateFormat('MMM')
                                  .format(event.startDate ?? DateTime.now())
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (event.eventType != null)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            event.eventType!.name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (event.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (event.location.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${event.participantCount} participating',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          if ((event.contributionTarget ?? 0) > 0)
                            _buildProgressBadge(event),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(double screenWidth) {
    final maxWidth = screenWidth > desktopBreakpoint
        ? desktopBreakpoint
        : screenWidth;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth > desktopBreakpoint
            ? (screenWidth - maxWidth) / 2 + 48
            : 48,
        vertical: 48,
      ),
      color: Colors.grey[900],
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.celebration,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Ahadi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Making event contributions seamless and meaningful for communities across Tanzania.',
                      style: TextStyle(color: Colors.grey[400], height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Links',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFooterLink('Discover Events'),
                    _buildFooterLink('Create Event'),
                    _buildFooterLink('How It Works'),
                    _buildFooterLink('Pricing'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Support',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFooterLink('Help Center'),
                    _buildFooterLink('Contact Us'),
                    _buildFooterLink('Privacy Policy'),
                    _buildFooterLink('Terms of Service'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFooterContact(Icons.email, 'support@ahadi.co.tz'),
                    _buildFooterContact(Icons.phone, '+255 123 456 789'),
                    _buildFooterContact(
                      Icons.location_on,
                      'Dar es Salaam, Tanzania',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Divider(color: Colors.grey[800]),
          const SizedBox(height: 24),
          Text(
            '© 2026 Ahadi. All rights reserved.',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(text, style: TextStyle(color: Colors.grey[400])),
      ),
    );
  }

  Widget _buildFooterContact(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout(
    BuildContext context,
    PublicEventsController controller,
    double screenWidth,
  ) {
    return GetX<AuthController>(
      init: Get.find<AuthController>(),
      builder: (authController) {
        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          body: RefreshIndicator(
            onRefresh: () async {
              // Use controller's safe refresh method
              await controller.refreshEvents();
            },
            color: AppColors.textPrimary,
            backgroundColor: Colors.white,
            child: CustomScrollView(
              slivers: [
                _buildMobileSliverAppBar(context, controller),
                SliverToBoxAdapter(
                  child: _buildMobileEventTypeChips(controller),
                ),
                _buildMobileSliverEventsList(context, controller),
              ],
            ),
          ),
          bottomNavigationBar: authController.isAuthenticated
              ? _buildMobileBottomNav(context)
              : null,
        );
      },
    );
  }

  Widget _buildMobileBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.explore_rounded,
                label: 'Discover',
                onTap: () {}, // Already on this page
                isActive: true,
              ),
              _buildNavItem(
                icon: Icons.event_rounded,
                label: 'My Events',
                onTap: () => Get.toNamed(AppRoutes.events),
                isActive: false,
              ),
              _buildNavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                onTap: () => Get.toNamed(AppRoutes.dashboard),
                isActive: false,
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                onTap: () => Get.toNamed(AppRoutes.profile),
                isActive: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.textPrimary : AppColors.textHint,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.textPrimary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSliverAppBar(
    BuildContext context,
    PublicEventsController controller,
  ) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      centerTitle: false,
      title: null,
      actions: [
        IconButton(
          icon: Icon(Icons.search_rounded, color: AppColors.textPrimary),
          onPressed: () => controller.isSearching.value = true,
        ),
        Container(
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            onPressed: () => _showJoinByCodeDialog(context, controller),
          ),
        ),
        _buildMobileAuthButton(),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: LayoutBuilder(
          builder: (context, constraints) {
            final isCollapsed = constraints.maxHeight <= kToolbarHeight + 20;
            return Text(
              isCollapsed ? 'Discover' : 'Discover Events',
              style: TextStyle(
                fontSize: isCollapsed ? 18 : 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            );
          },
        ),
        background: Container(color: Colors.white),
      ),
    );
  }

  Widget _buildMobileAuthButton() {
    return GetX<AuthController>(
      init: Get.find<AuthController>(),
      builder: (authController) {
        if (authController.isAuthenticated) {
          final user = authController.user.value;
          final name = user?.fullName ?? '';
          final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

          return PopupMenuButton<String>(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            onSelected: (value) {
              switch (value) {
                case 'my_events':
                  Get.toNamed(AppRoutes.events);
                  break;
                case 'dashboard':
                  Get.toNamed(AppRoutes.dashboard);
                  break;
                case 'profile':
                  Get.toNamed(AppRoutes.profile);
                  break;
                case 'logout':
                  authController.signOut();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'my_events',
                child: Row(
                  children: [
                    Icon(
                      Icons.event_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text('My Events'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'dashboard',
                child: Row(
                  children: [
                    Icon(
                      Icons.dashboard_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text('Dashboard'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(
                      Icons.person_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text('Sign Out', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.textPrimary, width: 1.5),
          ),
          child: TextButton(
            onPressed: () => Get.toNamed(AppRoutes.login),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Sign In',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileEventTypeChips(PublicEventsController controller) {
    return Container(
      height: 32,
      margin: const EdgeInsets.only(top: 6),
      child: Obx(() {
        final types = controller.eventTypes;
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: types.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Obx(() {
                  final isSelected =
                      controller.selectedEventTypeId.value == null;
                  return GestureDetector(
                    onTap: () => controller.filterByEventType(null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.textPrimary
                              : const Color(0xFFE5E7EB),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        'All',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }),
              );
            }
            final type = types[index - 1];
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Obx(() {
                final isSelected =
                    controller.selectedEventTypeId.value == type.id;
                return GestureDetector(
                  onTap: () => controller.filterByEventType(type.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.textPrimary
                            : const Color(0xFFE5E7EB),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      type.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        );
      }),
    );
  }

  Widget _buildMobileSliverEventsList(
    BuildContext context,
    PublicEventsController controller,
  ) {
    return PagedSliverList<int, EventModel>(
      pagingController: controller.pagingController,
      builderDelegate: PagedChildBuilderDelegate<EventModel>(
        itemBuilder: (context, event, index) => Padding(
          padding: EdgeInsets.fromLTRB(16, index == 0 ? 16 : 0, 16, 16),
          child: _buildMobileEventCard(context, controller, event),
        ),
        firstPageProgressIndicatorBuilder: (_) => _buildLoadingState(),
        newPageProgressIndicatorBuilder: (_) => _buildLoadingState(),
        firstPageErrorIndicatorBuilder: (context) => _buildErrorState(
          controller.pagingController.error.toString(),
          () => controller.pagingController.refresh(),
        ),
        noItemsFoundIndicatorBuilder: (_) => _buildEmptyState(controller),
      ),
    );
  }

  Widget _buildMobileEventCard(
    BuildContext context,
    PublicEventsController controller,
    EventModel event,
  ) {
    final target = event.contributionTarget ?? 0;
    final progress = target > 0
        ? (event.totalContributions / target).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showEventDetails(context, controller, event),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Image with date overlay
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 90,
                        height: 90,
                        child: event.displayCoverImage.isNotEmpty
                            ? Image.network(
                                event.displayCoverImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildCompactPlaceholder(event),
                              )
                            : _buildCompactPlaceholder(event),
                      ),
                    ),
                    // Date badge overlay
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          DateFormat(
                            'dd MMM',
                          ).format(event.startDate ?? DateTime.now()),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Right: Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event type badge + Title row
                      Row(
                        children: [
                          if (event.eventType != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                event.eventType!.name,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // Description (1 line only)
                      if (event.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // Location row
                      if (event.location.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Progress bar + Bottom row
                      Row(
                        children: [
                          // Progress section
                          if (target > 0) ...[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Raised',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${(progress * 100).toInt()}%',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: progress >= 1.0
                                              ? AppColors.success
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 3,
                                      backgroundColor: const Color(0xFFE5E7EB),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        progress >= 1.0
                                            ? AppColors.success
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                          ] else ...[
                            // Participants count if no target
                            Row(
                              children: [
                                Icon(
                                  Icons.people_outline_rounded,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${event.participantCount}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                          ],
                          // View button
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.textPrimary,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildCompactPlaceholder(EventModel event) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          _getEventIcon(event.eventType?.slug),
          size: 32,
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  IconData _getEventIcon(String? slug) {
    switch (slug) {
      case 'wedding':
        return Icons.favorite_rounded;
      case 'fundraiser':
        return Icons.volunteer_activism_rounded;
      case 'church':
        return Icons.church_rounded;
      case 'graduation':
        return Icons.school_rounded;
      case 'birthday':
        return Icons.cake_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  // ==================== COMMON WIDGETS ====================
  Widget _buildAuthButton() {
    return GetX<AuthController>(
      init: Get.find<AuthController>(),
      builder: (authController) {
        if (authController.isAuthenticated) {
          return PopupMenuButton<String>(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.person, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'My Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            onSelected: (value) {
              if (value == 'my_events') {
                Get.toNamed(AppRoutes.events);
              } else if (value == 'dashboard') {
                Get.toNamed(AppRoutes.dashboard);
              } else if (value == 'profile') {
                Get.toNamed(AppRoutes.profile);
              } else if (value == 'logout') {
                authController.signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'my_events',
                child: Row(
                  children: [
                    Icon(Icons.event, color: Color(0xFF374151)),
                    SizedBox(width: 12),
                    Text('My Events'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'dashboard',
                child: Row(
                  children: [
                    Icon(Icons.dashboard_outlined, color: Color(0xFF374151)),
                    SizedBox(width: 12),
                    Text('Dashboard'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: Color(0xFF374151)),
                    SizedBox(width: 12),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red.shade600),
                    SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ],
                ),
              ),
            ],
          );
        } else {
          return Row(
            children: [
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.login),
                child: const Text('Log In'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Get.toNamed(AppRoutes.login),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Sign Up'),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildProgressBadge(EventModel event) {
    final target = event.contributionTarget ?? 0;
    final progress = target > 0
        ? (event.totalContributions / target).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${(progress * 100).toInt()}%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.success,
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[200]!, Colors.grey[100]!],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.celebration_rounded,
                size: 40,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Event',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(PublicEventsController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'No events found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search or category',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            if (controller.searchQuery.value.isNotEmpty ||
                controller.selectedEventTypeId.value != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: controller.clearFilters,
                icon: const Icon(Icons.clear),
                label: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _getGridCrossAxisCount(double screenWidth) {
    if (screenWidth >= desktopBreakpoint) return 4;
    if (screenWidth >= tabletBreakpoint) return 3;
    if (screenWidth >= mobileBreakpoint) return 2;
    return 1;
  }

  void _showJoinByCodeDialog(
    BuildContext context,
    PublicEventsController controller,
  ) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Join Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the event code to join:'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                hintText: 'e.g., ABC123',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.qr_code),
              ),
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, letterSpacing: 2),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (codeController.text.isNotEmpty) {
                _showJoinFormDialog(context, controller, codeController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showJoinFormDialog(
    BuildContext context,
    PublicEventsController controller,
    String joinCode, {
    EventModel? event,
  }) {
    final authController = Get.find<AuthController>();
    final isLoggedIn = authController.isAuthenticated;
    final user = authController.user.value;

    final nameController = TextEditingController(
      text: isLoggedIn ? (user?.fullName ?? '') : '',
    );
    final phoneController = TextEditingController(
      text: isLoggedIn ? (user?.phone ?? '') : '',
    );
    final emailController = TextEditingController(
      text: isLoggedIn ? (user?.email ?? '') : '',
    );

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.group_add, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Join Event'),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (event != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                event.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (isLoggedIn &&
                        user?.fullName != null &&
                        user!.fullName!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Joining as ${user.fullName}',
                              style: TextStyle(color: Colors.green.shade700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Your Name *',
                          hintText: 'Enter your full name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (!isLoggedIn ||
                        user?.phone == null ||
                        user!.phone.isEmpty) ...[
                      TextFormField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number *',
                          hintText: '0712345678',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (!isLoggedIn) ...[
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email (Optional)',
                          hintText: 'your@email.com',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                    Obx(() {
                      if (controller.errorMessage.value.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    controller.errorMessage.value,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  controller.errorMessage.value = '';
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              Obx(
                () => ElevatedButton(
                  onPressed: controller.isJoining.value
                      ? null
                      : () async {
                          if (formKey.currentState?.validate() ?? false) {
                            final name = nameController.text.trim().isNotEmpty
                                ? nameController.text.trim()
                                : user?.fullName ?? '';
                            final phone = phoneController.text.trim().isNotEmpty
                                ? phoneController.text.trim()
                                : user?.phone ?? '';

                            final success = await controller
                                .searchAndJoinByCode(
                                  joinCode,
                                  name,
                                  phone,
                                  email: emailController.text.trim().isNotEmpty
                                      ? emailController.text.trim()
                                      : user?.email,
                                );

                            if (success) {
                              Navigator.pop(context);

                              // Refresh events list and profile stats
                              try {
                                final eventsController =
                                    Get.find<EventsController>();
                                eventsController.invitedEventsPagingController
                                    .refresh();
                              } catch (e) {
                                debugPrint('EventsController not found: $e');
                              }

                              try {
                                final profileController =
                                    Get.find<ProfileController>();
                                profileController.loadProfile();
                              } catch (e) {
                                debugPrint('ProfileController not found: $e');
                              }

                              _showJoinSuccessDialog(
                                context,
                                controller,
                                event ?? controller.event.value,
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: controller.isJoining.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Join Event'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showJoinSuccessDialog(
    BuildContext context,
    PublicEventsController controller,
    EventModel? event,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 64,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              controller.successMessage.value.isNotEmpty
                  ? controller.successMessage.value
                  : 'Successfully joined!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (event != null) ...[
              const SizedBox(height: 8),
              Text(
                event.title,
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'You can now contribute to this event and receive updates.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          if (event != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Get.toNamed(
                  AppRoutes.publicContribute,
                  arguments: event.joinCode,
                );
              },
              child: const Text('Contribute Now'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Refresh events list if user is authenticated
              final authController = Get.find<AuthController>();
              if (authController.isAuthenticated) {
                // Reload events to show the newly joined event
                try {
                  final eventsController = Get.find<EventsController>();
                  eventsController.loadMyEvents(refresh: true);
                } catch (e) {
                  // EventsController not initialized yet
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _shareEvent(BuildContext context, EventModel event) {
    final shareText =
        '''
🎉 You're invited to "${event.title}"!

Join using code: ${event.joinCode}

Powered by Ahadi - Event Contributions Made Easy
''';

    // On mobile, use native share
    Share.share(shareText, subject: 'Join ${event.title}');
  }

  void _showEventDetails(
    BuildContext context,
    PublicEventsController controller,
    EventModel event,
  ) {
    controller.selectEvent(event);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: event.displayCoverImage.isNotEmpty
                              ? Image.network(
                                  event.displayCoverImage,
                                  fit: BoxFit.cover,
                                )
                              : _buildImagePlaceholder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary,
                            child: const Icon(
                              Icons.person,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'By ${event.ownerName ?? 'Unknown'}',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildDetailRow(
                        Icons.calendar_today,
                        'Date',
                        DateFormat(
                          'EEEE, MMMM d, yyyy',
                        ).format(event.startDate ?? DateTime.now()),
                      ),
                      _buildDetailRow(
                        Icons.location_on,
                        'Location',
                        event.location.isNotEmpty ? event.location : 'Online',
                      ),
                      _buildDetailRow(
                        Icons.people,
                        'Participants',
                        '${event.participantCount} participating',
                      ),
                      if ((event.contributionTarget ?? 0) > 0) ...[
                        const SizedBox(height: 24),
                        _buildProgressSection(event),
                      ],
                      const SizedBox(height: 32),
                      // Two buttons: Contribute and Join
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                // Navigate to public contribution with event code
                                Get.toNamed(
                                  AppRoutes.publicContribute,
                                  arguments: event.joinCode,
                                );
                              },
                              icon: const Icon(Icons.volunteer_activism),
                              label: const Text(
                                'Contribute',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showJoinFormDialog(
                                  context,
                                  controller,
                                  event.joinCode,
                                  event: event,
                                );
                              },
                              icon: const Icon(Icons.group_add),
                              label: const Text(
                                'Join',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Share button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _shareEvent(context, event);
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share Event'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(EventModel event) {
    final target = event.contributionTarget ?? 0;
    final progress = target > 0
        ? (event.totalContributions / target).clamp(0.0, 1.0)
        : 0.0;
    final formatter = NumberFormat.currency(
      symbol: event.currency,
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatter.format(event.totalContributions),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'of ${formatter.format(target)}',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== HELPER WIDGETS ====================

class _NavLink extends StatefulWidget {
  final String title;
  final VoidCallback onTap;

  const _NavLink({required this.title, required this.onTap});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            widget.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _isHovered ? AppColors.primary : const Color(0xFF4B5563),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _HeroButton({
    required this.text,
    required this.icon,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  State<_HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<_HeroButton> {
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
          _isHovered ? 1.03 : 1.0,
          _isHovered ? 1.03 : 1.0,
          1.0,
        ),
        child: widget.isPrimary
            ? ElevatedButton.icon(
                onPressed: widget.onPressed,
                icon: Icon(widget.icon, size: 20),
                label: Text(widget.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: _isHovered ? 8 : 0,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            : OutlinedButton.icon(
                onPressed: widget.onPressed,
                icon: Icon(widget.icon, size: 20),
                label: Text(widget.text),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: _isHovered
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
      ),
    );
  }
}

class _SearchButton extends StatefulWidget {
  final VoidCallback onTap;

  const _SearchButton({required this.onTap});

  @override
  State<_SearchButton> createState() => _SearchButtonState();
}

class _SearchButtonState extends State<_SearchButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFF3F4F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                size: 20,
                color: _isHovered
                    ? const Color(0xFF4B5563)
                    : const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 8),
              Text(
                'Search',
                style: TextStyle(
                  fontSize: 14,
                  color: _isHovered
                      ? const Color(0xFF4B5563)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
