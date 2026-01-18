import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/profile_controller.dart';
import '../services/profile_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../../core/theme/app_theme.dart';

/// Profile content widget for embedding in dashboard layout
class ProfileContent extends StatefulWidget {
  const ProfileContent({super.key});

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  late ProfileController controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    // Ensure dependencies are available
    if (!Get.isRegistered<ApiService>()) {
      Get.put<ApiService>(ApiService());
    }
    if (!Get.isRegistered<StorageService>()) {
      Get.put<StorageService>(StorageService());
    }

    // Register ProfileService if not already
    if (!Get.isRegistered<ProfileService>()) {
      Get.put<ProfileService>(
        ProfileService(
          apiService: Get.find<ApiService>(),
          storageService: Get.find<StorageService>(),
        ),
      );
    }

    // Register ProfileController if not already
    if (!Get.isRegistered<ProfileController>()) {
      Get.put<ProfileController>(
        ProfileController(profileService: Get.find<ProfileService>()),
      );
    }

    controller = Get.find<ProfileController>();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // Header - only show on larger screens (mobile has dashboard shell header)
          if (!isMobile) _buildHeader(),
          // Content
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        controller.errorMessage.value,
                        style: const TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.loadProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final user = controller.user.value;
              if (user == null) {
                return const Center(child: Text('No user data available'));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      children: [
                        // Profile Picture Section
                        _buildProfilePictureSection(),
                        const SizedBox(height: 32),

                        // Two column layout for larger screens
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 600) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildLeftColumn(user)),
                                  const SizedBox(width: 24),
                                  Expanded(child: _buildRightColumn()),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                _buildLeftColumn(user),
                                const SizedBox(height: 16),
                                _buildRightColumn(),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Actions Section
                        _buildActionsSection(),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              final dashboardController = Get.find<DashboardController>();
              if (dashboardController.canGoBack) {
                dashboardController.goBack();
              } else {
                dashboardController.goToRoot(DashboardContent.events);
              }
            },
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              'Profile Settings',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Edit button
          OutlinedButton.icon(
            onPressed: _showEditProfileDialog,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftColumn(user) {
    return Column(
      children: [
        _buildUserInfoCard(user),
        const SizedBox(height: 16),
        _buildSubscriptionCard(),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      children: [
        _buildStatsCard(),
        const SizedBox(height: 16),
        _buildFeaturesCard(),
      ],
    );
  }

  Widget _buildProfilePictureSection() {
    return Obx(() {
      final user = controller.user.value;
      final isUpdating = controller.isUpdating.value;
      final name = user?.fullName;
      final initial = (name != null && name.isNotEmpty)
          ? name[0].toUpperCase()
          : 'U';

      return Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: controller.showImagePickerOptions,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: user?.fullProfilePictureUrl != null
                        ? CachedNetworkImage(
                            imageUrl: user!.fullProfilePictureUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.borderLight,
                              child: Icon(
                                Icons.person,
                                size: 60,
                                color: AppColors.textHint,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.borderLight,
                              child: Icon(
                                Icons.person,
                                size: 60,
                                color: AppColors.textHint,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.primary.withOpacity(0.1),
                            child: Center(
                              child: Text(
                                initial,
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              if (isUpdating)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: controller.showImagePickerOptions,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user?.fullName ?? 'User',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            user?.phone ?? '',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          // Edit button for mobile (header is hidden on mobile)
          Builder(
            builder: (context) {
              final isMobile = MediaQuery.of(context).size.width < 600;
              if (!isMobile) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: OutlinedButton.icon(
                  onPressed: _showEditProfileDialog,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Profile'),
                ),
              );
            },
          ),
        ],
      );
    });
  }

  Widget _buildUserInfoCard(user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.person,
              label: 'Full Name',
              value: user.fullName ?? 'Not set',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.phone,
              label: 'Phone',
              value: user.phone ?? 'Not set',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.email,
              label: 'Email',
              value: user.email ?? 'Not set',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard() {
    return Obx(() {
      final planName = controller.subscriptionPlanName;
      final planType = controller.subscriptionPlanType;

      Color planColor;
      IconData planIcon;

      switch (planType.toUpperCase()) {
        case 'VIP':
          planColor = AppColors.premiumPurple;
          planIcon = Icons.diamond;
          break;
        case 'PREMIUM':
          planColor = AppColors.warningAmber;
          planIcon = Icons.star;
          break;
        case 'BASIC':
          planColor = AppColors.primary;
          planIcon = Icons.workspace_premium;
          break;
        default:
          planColor = AppColors.textHint;
          planIcon = Icons.card_membership;
      }

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: planColor.withOpacity(0.3)),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [planColor.withOpacity(0.1), planColor.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: planColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(planIcon, color: planColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Plan',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        Text(
                          planName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: planColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.toNamed('/subscriptions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: planColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Upgrade Plan'),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Obx(
                  () => _buildStatItem(
                    icon: Icons.event,
                    value: controller.ownedEventsCount.toString(),
                    label: 'Events',
                    color: AppColors.primary,
                  ),
                ),
                Obx(
                  () => _buildStatItem(
                    icon: Icons.group,
                    value: controller.participatingEventsCount.toString(),
                    label: 'Participating',
                    color: AppColors.success,
                  ),
                ),
                _buildStatItem(
                  icon: Icons.monetization_on,
                  value: '0',
                  label: 'Contributions',
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeaturesCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plan Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(
              () => _buildFeatureRow(
                icon: Icons.chat,
                label: 'Event Chat',
                isEnabled: controller.hasChatFeature,
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => _buildFeatureRow(
                icon: Icons.mail,
                label: 'Send Invitations',
                isEnabled: controller.hasInvitationsFeature,
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => _buildFeatureRow(
                icon: Icons.notifications,
                label: 'Payment Reminders',
                isEnabled: controller.hasRemindersFeature,
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => _buildFeatureRow(
                icon: Icons.analytics,
                label: 'Advanced Reports',
                isEnabled: controller.hasReportsFeature,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String label,
    required bool isEnabled,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isEnabled
                ? AppColors.success.withOpacity(0.1)
                : AppColors.textHint.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isEnabled ? AppColors.success : AppColors.textHint,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isEnabled ? null : AppColors.textHint,
            ),
          ),
        ),
        Icon(
          isEnabled ? Icons.check_circle : Icons.lock,
          color: isEnabled ? AppColors.success : AppColors.textHint,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        children: [
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Delete Account Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.deleteAccount,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete Account'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller.fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  Obx(
                    () => ElevatedButton(
                      onPressed: controller.isUpdating.value
                          ? null
                          : () async {
                              final success = await controller.updateProfile();
                              if (success) {
                                Get.back();
                              }
                            },
                      child: controller.isUpdating.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
