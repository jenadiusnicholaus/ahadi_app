import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/subscription_controller.dart';
import '../models/subscription_plan_model.dart';
import '../services/subscription_service.dart';

class SubscriptionPlansScreen extends StatelessWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final controller = Get.put(
      SubscriptionController(
        subscriptionService: SubscriptionService(Get.find<ApiService>()),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Subscription Plans',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.plans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('Failed to load plans'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Plan Card
              _buildCurrentPlanCard(controller),
              const SizedBox(height: 16),

              // Value Proposition Card
              _buildValuePropositionCard(controller),
              const SizedBox(height: 24),

              // Plans Header
              const Text(
                'Choose Your Plan',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upgrade to unlock more features and reduce fees',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              // Plans List
              ...controller.plans.map(
                (plan) => _buildPlanCard(controller, plan),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentPlanCard(SubscriptionController controller) {
    return Obx(() {
      final subscription = controller.currentSubscription.value;
      final planName = subscription?.planName ?? 'Free';
      final planType = subscription?.planType ?? 'FREE';

      Color planColor;
      IconData planIcon;

      switch (planType.toUpperCase()) {
        case 'INSTITUTIONAL':
          planColor = Colors.purple;
          planIcon = Icons.diamond;
          break;
        case 'PREMIUM':
          planColor = Colors.amber.shade700;
          planIcon = Icons.star;
          break;
        case 'BASIC':
          planColor = Colors.blue;
          planIcon = Icons.workspace_premium;
          break;
        default:
          planColor = Colors.grey;
          planIcon = Icons.card_membership;
      }

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [planColor.withOpacity(0.15), planColor.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: planColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: planColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    planName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: planColor,
                    ),
                  ),
                  if (subscription != null && subscription.expiresAt != null)
                    Text(
                      'Expires in ${subscription.daysRemaining} days',
                      style: TextStyle(
                        fontSize: 12,
                        color: subscription.daysRemaining < 7
                            ? Colors.red
                            : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Fee',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '${subscription?.transactionFeePercent ?? 5.0}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: planColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  /// Shows the value proposition - why users should subscribe
  Widget _buildValuePropositionCard(SubscriptionController controller) {
    return Obx(() {
      final recommendation = controller.recommendation.value;
      if (recommendation == null) return const SizedBox.shrink();

      final message = recommendation['message'] ?? '';
      final example = recommendation['example'] ?? '';

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade50, Colors.orange.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message.replaceAll('💡 ', ''),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
            if (example.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calculate_outlined,
                      size: 18,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        example,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Fee comparison
            _buildFeeComparisonRow(),
          ],
        ),
      );
    });
  }

  Widget _buildFeeComparisonRow() {
    final fees = [
      {'plan': 'Free', 'fee': '5%', 'amount': '50,000'},
      {'plan': 'Basic', 'fee': '4%', 'amount': '40,000'},
      {'plan': 'Premium', 'fee': '3%', 'amount': '30,000'},
      {'plan': 'VIP', 'fee': '2%', 'amount': '20,000'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fee on TZS 1,000,000 withdrawal:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: fees.map((fee) {
              final isFirst = fee['plan'] == 'Free';
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isFirst ? Colors.grey.shade200 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isFirst
                        ? Colors.grey.shade300
                        : Colors.green.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      fee['plan']!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isFirst
                            ? Colors.grey.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                    Text(
                      'TZS ${fee['amount']}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isFirst
                            ? Colors.grey.shade800
                            : Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(
    SubscriptionController controller,
    SubscriptionPlanModel plan,
  ) {
    final isCurrentPlan = plan.planType == controller.currentPlanType;
    final canUpgrade = controller.canUpgradeTo(plan);
    final yearlySavings = controller.getYearlySavingsPercent(plan);

    Color planColor;
    switch (plan.planType.toUpperCase()) {
      case 'INSTITUTIONAL':
        planColor = Colors.purple;
        break;
      case 'PREMIUM':
        planColor = Colors.amber.shade700;
        break;
      case 'BASIC':
        planColor = Colors.blue;
        break;
      default:
        planColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlan ? planColor : Colors.grey.shade200,
          width: isCurrentPlan ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: planColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: planColor,
                            ),
                          ),
                          if (isCurrentPlan) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: planColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'CURRENT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.description.isNotEmpty
                            ? plan.description
                            : 'Perfect for ${plan.planType.toLowerCase()} users',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.formattedMonthlyPrice,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: planColor,
                      ),
                    ),
                    if (!plan.isFree)
                      Text(
                        '/month',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Features
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Key stats
                Row(
                  children: [
                    _buildStatItem(
                      Icons.event,
                      plan.maxEvents == -1 ? 'Unlimited' : '${plan.maxEvents}',
                      'Events',
                    ),
                    _buildStatItem(
                      Icons.people,
                      '${plan.maxParticipantsPerEvent}',
                      'Participants',
                    ),
                    _buildStatItem(Icons.percent, plan.formattedFee, 'Fee'),
                  ],
                ),
                const SizedBox(height: 16),

                // Feature list
                ...plan.features.toFeatureList().map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 18, color: planColor),
                        const SizedBox(width: 10),
                        Text(feature, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),

                // Yearly savings badge
                if (!plan.isFree && yearlySavings > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.savings,
                          size: 16,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Save $yearlySavings% yearly (${plan.formattedYearlyPrice}/yr)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Action button
                if (!isCurrentPlan && canUpgrade)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showSubscribeDialog(controller, plan),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: planColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Upgrade to ${plan.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (!canUpgrade && !isCurrentPlan)
                  Center(
                    child: Text(
                      'You have a higher plan',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _showSubscribeDialog(
    SubscriptionController controller,
    SubscriptionPlanModel plan,
  ) {
    controller.selectPlan(plan);
    controller.selectedBillingCycle.value = 'MONTHLY';
    controller.phoneController.clear();

    Get.bottomSheet(
      _SubscribeBottomSheet(controller: controller, plan: plan),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }
}

class _SubscribeBottomSheet extends StatelessWidget {
  final SubscriptionController controller;
  final SubscriptionPlanModel plan;

  const _SubscribeBottomSheet({required this.controller, required this.plan});

  // Mobile money providers - same as contribution checkout
  static final List<Map<String, dynamic>> _mobileProviders = [
    {'name': 'Tigo', 'color': Color(0xFF002B5B)},
    {'name': 'Airtel', 'color': Color(0xFFED1C24)},
    {'name': 'Vodacom', 'color': Color(0xFFE60000)},
    {'name': 'Halotel', 'color': Color(0xFF00A651)},
  ];

  @override
  Widget build(BuildContext context) {
    Color planColor;
    switch (plan.planType.toUpperCase()) {
      case 'INSTITUTIONAL':
        planColor = Colors.purple;
        break;
      case 'PREMIUM':
        planColor = Colors.amber.shade700;
        break;
      case 'BASIC':
        planColor = Colors.blue;
        break;
      default:
        planColor = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Text(
              'Subscribe to ${plan.name}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: planColor,
              ),
            ),
            const SizedBox(height: 24),

            // Billing cycle selection
            const Text(
              'Billing Cycle',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: _buildBillingOption(
                      'MONTHLY',
                      'Monthly',
                      plan.formattedMonthlyPrice,
                      null,
                      controller.selectedBillingCycle.value == 'MONTHLY',
                      planColor,
                      () => controller.selectBillingCycle('MONTHLY'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBillingOption(
                      'YEARLY',
                      'Yearly',
                      plan.formattedYearlyPrice,
                      controller.getYearlySavingsPercent(plan) > 0
                          ? 'Save ${controller.getYearlySavingsPercent(plan)}%'
                          : null,
                      controller.selectedBillingCycle.value == 'YEARLY',
                      planColor,
                      () => controller.selectBillingCycle('YEARLY'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment provider selection
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Obx(() {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _mobileProviders.map((provider) {
                  final providerName = provider['name'] as String;
                  final providerColor = provider['color'] as Color;
                  final isSelected =
                      controller.selectedProvider.value == providerName;

                  return InkWell(
                    onTap: () => controller.selectProvider(providerName),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 100,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? providerColor.withOpacity(0.1)
                            : Colors.grey.shade50,
                        border: Border.all(
                          color: isSelected
                              ? providerColor
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: providerColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                providerName.substring(0, 1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            providerName,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? providerColor
                                  : Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
            const SizedBox(height: 24),

            // Phone number input
            const Text(
              'Phone Number',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '07XXXXXXXX',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: planColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Obx(
                () => Column(
                  children: [
                    _buildSummaryRow('Plan', plan.name),
                    _buildSummaryRow(
                      'Billing',
                      controller.selectedBillingCycle.value == 'YEARLY'
                          ? 'Yearly'
                          : 'Monthly',
                    ),
                    _buildSummaryRow(
                      'Amount',
                      '${plan.currency} ${controller.selectedPlanPrice.toStringAsFixed(0)}',
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Error message
            Obx(() {
              if (controller.errorMessage.value.isNotEmpty) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.errorMessage.value,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            // Subscribe button
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isProcessing.value
                      ? null
                      : () async {
                          final success = await controller.subscribe();
                          if (success) {
                            // Close bottom sheet first
                            Get.back();
                            // Close subscription plans screen
                            Get.back();
                            // Navigate to profile to see updated plan
                            Get.toNamed('/profile');
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: planColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isProcessing.value
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Subscribe Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel button
            Center(
              child: TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingOption(
    String value,
    String title,
    String price,
    String? badge,
    bool isSelected,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
