import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/profile_controller.dart';
import '../../../core/controllers/theme_controller.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Get.toNamed('/profile/edit'),
          ),
        ],
      ),
      body: Obx(() {
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Picture Section
              _buildProfilePictureSection(),
              const SizedBox(height: 24),

              // User Info Card
              _buildUserInfoCard(user),
              const SizedBox(height: 16),

              // Subscription Card
              _buildSubscriptionCard(),
              const SizedBox(height: 16),

              // Stats Card
              _buildStatsCard(),
              const SizedBox(height: 16),

              // Finance Card - NEW
              _buildFinanceCard(),
              const SizedBox(height: 16),

              // Theme Settings Card
              _buildThemeSettingsCard(),
              const SizedBox(height: 16),

              // Features Card
              _buildFeaturesCard(),
              const SizedBox(height: 24),

              // Actions Section
              _buildActionsSection(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfilePictureSection() {
    return Obx(() {
      final user = controller.user.value;
      final isUpdating = controller.isUpdating.value;
      final selectedImage = controller.selectedImage.value;

      // Determine what to display: selected local image > server image > placeholder
      Widget avatarContent;

      if (selectedImage != null) {
        // Show locally selected file immediately
        avatarContent = Image.file(
          selectedImage,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
        );
      } else if (user?.fullProfilePictureUrl != null) {
        // Server image
        avatarContent = CachedNetworkImage(
          imageUrl: user!.fullProfilePictureUrl!,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
          placeholder: (context, url) => Container(
            color: AppColors.borderLight,
            child: Icon(Icons.person, size: 60, color: AppColors.textHint),
          ),
          errorWidget: (context, url, error) => Container(
            color: AppColors.borderLight,
            child: Icon(Icons.person, size: 60, color: AppColors.textHint),
          ),
        );
      } else {
        // Placeholder
        avatarContent = Container(
          color: AppColors.borderLight,
          child: Icon(Icons.person, size: 60, color: AppColors.textHint),
        );
      }

      return Stack(
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
              ),
              child: ClipOval(child: avatarContent),
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
      );
    });
  }

  Widget _buildUserInfoCard(user) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow(
              icon: Icons.person,
              label: 'Full Name',
              value: user.fullName ?? 'Not set',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.phone,
              label: 'Phone',
              value: user.phone ?? 'Not set',
            ),
            const SizedBox(height: 12),
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
        Icon(icon, size: 20, color: AppColors.textHint),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(value, style: const TextStyle(fontSize: 16)),
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
          side: BorderSide(color: AppColors.border),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [planColor.withOpacity(0.1), planColor.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: planColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(planIcon, color: planColor, size: 32),
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
              TextButton(
                onPressed: () => Get.toNamed('/subscriptions'),
                child: const Text('Upgrade'),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Obx(
                  () => _buildStatItem(
                    icon: Icons.event,
                    value: controller.ownedEventsCount.toString(),
                    label: 'Events Created',
                  ),
                ),
                _buildStatItem(
                  icon: Icons.group,
                  value: '0',
                  label: 'Participating',
                ),
                _buildStatItem(
                  icon: Icons.monetization_on,
                  value: '0',
                  label: 'Contributions',
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
  }) {
    return Column(
      children: [
        Icon(icon, size: 28, color: AppColors.primary),
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

  Widget _buildFinanceCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, size: 24, color: AppColors.primary),
                const SizedBox(width: 12),
                const Text(
                  'Finance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildFinanceOption(
              icon: Icons.wallet,
              title: 'My Wallet',
              subtitle: 'View balance and transactions',
              onTap: () => Get.toNamed('/wallet'),
            ),
            const SizedBox(height: 8),
            _buildFinanceOption(
              icon: Icons.history,
              title: 'Transaction History',
              subtitle: 'View all your transactions',
              onTap: () => Get.toNamed('/transactions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSettingsCard() {
    final themeController = Get.find<ThemeController>();
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, size: 24, color: Theme.of(Get.context!).primaryColor),
                const SizedBox(width: 12),
                const Text(
                  'Appearance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Theme Mode Selector
            Obx(() => Column(
              children: [
                _buildThemeOption(
                  title: 'Light Mode',
                  subtitle: 'Use light theme',
                  icon: Icons.light_mode,
                  isSelected: themeController.isLightMode,
                  onTap: () => themeController.setLightMode(),
                ),
                const SizedBox(height: 8),
                _buildThemeOption(
                  title: 'Dark Mode',
                  subtitle: 'Use dark theme',
                  icon: Icons.dark_mode,
                  isSelected: themeController.isDarkMode,
                  onTap: () => themeController.setDarkMode(),
                ),
                const SizedBox(height: 8),
                _buildThemeOption(
                  title: 'System Default',
                  subtitle: 'Follow device settings',
                  icon: Icons.brightness_auto,
                  isSelected: themeController.isSystemMode,
                  onTap: () => themeController.setSystemMode(),
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected 
              ? Theme.of(Get.context!).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected 
                ? Theme.of(Get.context!).primaryColor
                : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? Theme.of(Get.context!).primaryColor
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected 
                          ? Theme.of(Get.context!).primaryColor
                          : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(Get.context!).primaryColor,
              ),
          ],
        ),
      ),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plan Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Obx(
              () => _buildFeatureRow(
                icon: Icons.chat,
                label: 'Event Chat',
                isEnabled: controller.hasChatFeature,
              ),
            ),
            Obx(
              () => _buildFeatureRow(
                icon: Icons.mail,
                label: 'Send Invitations',
                isEnabled: controller.hasInvitationsFeature,
              ),
            ),
            Obx(
              () => _buildFeatureRow(
                icon: Icons.notifications,
                label: 'Payment Reminders',
                isEnabled: controller.hasRemindersFeature,
              ),
            ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isEnabled ? AppColors.success : AppColors.textHint),
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
      ),
    );
  }

  Widget _buildActionsSection() {
    return Column(
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
              padding: const EdgeInsets.symmetric(vertical: 12),
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
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
