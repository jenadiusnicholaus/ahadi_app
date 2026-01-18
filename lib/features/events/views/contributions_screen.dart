import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/dashboard_layout.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/contribution_controller.dart';
import '../models/contribution_model.dart';
import '../models/event_model.dart';

class ContributionsScreen extends StatefulWidget {
  const ContributionsScreen({super.key});

  @override
  State<ContributionsScreen> createState() => _ContributionsScreenState();
}

class _ContributionsScreenState extends State<ContributionsScreen> {
  late ContributionController controller;
  late EventModel event;

  @override
  void initState() {
    super.initState();
    event = Get.arguments as EventModel;

    // Initialize controller
    if (!Get.isRegistered<ContributionController>()) {
      Get.put(ContributionController());
    }
    controller = Get.find<ContributionController>();
    controller.init(event.id);
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentRoute: AppRoutes.events,
      showBackButton: true,
      onBack: () => Get.back(),
      breadcrumb: _buildBreadcrumb(),
      sidebarContent: null,
      floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAddContributionDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              backgroundColor: AppColors.primary,
            ),
      content: _buildContent(context),
    );
  }

  Widget _buildBreadcrumb() {
    return Row(
      children: [
        InkWell(
          onTap: () => Get.offAllNamed(AppRoutes.events),
          child: Text(
            'Events',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ),
        InkWell(
          onTap: () => Get.back(),
          child: Text(
            event.title,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ),
        const Text(
          'Contributions',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String currentValue,
    Function(String) onTap,
  ) {
    final isSelected = value == currentValue;
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.contributions.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.error.value.isNotEmpty && controller.contributions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                controller.error.value,
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: controller.refresh,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }

      if (controller.contributions.isEmpty) {
        return _buildEmptyState(context);
      }

      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Contributions',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${controller.contributions.length} total',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Contributions list
              _buildContributionsList(context),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.payments_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No contributions yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start collecting contributions for this event',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showAddContributionDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Manual'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _showMobilePaymentDialog(context),
                  icon: const Icon(Icons.phone_android),
                  label: const Text('Mobile Payment'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionsList(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.contributions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final contribution = controller.contributions[index];
        return _buildContributionCard(context, contribution);
      },
    );
  }

  Widget _buildContributionCard(BuildContext context, ContributionModel contribution) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showContributionDetails(context, contribution),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  (contribution.participantName ?? 'A')[0].toUpperCase(),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contribution.participantName ?? 'Anonymous',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildKindBadge(contribution.kind),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM d').format(contribution.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount and status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    controller.formatAmount(contribution.amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusBadge(contribution.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKindBadge(String kind) {
    final colors = {
      'CASH': Colors.green,
      'MOBILE_MONEY': Colors.blue,
      'BANK_TRANSFER': Colors.purple,
      'ITEM': Colors.orange,
      'SERVICE': Colors.teal,
    };
    final icons = {
      'CASH': Icons.payments,
      'MOBILE_MONEY': Icons.phone_android,
      'BANK_TRANSFER': Icons.account_balance,
      'ITEM': Icons.card_giftcard,
      'SERVICE': Icons.handyman,
    };
    final color = colors[kind] ?? Colors.grey;
    final icon = icons[kind] ?? Icons.payment;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            ContributionModel(
              id: 0,
              eventId: 0,
              amount: 0,
              kind: kind,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ).kindDisplay,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final colors = {
      'PENDING': Colors.orange,
      'CONFIRMED': Colors.green,
      'FAILED': Colors.red,
      'REFUNDED': Colors.grey,
    };
    final color = colors[status] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        ContributionModel(
          id: 0,
          eventId: 0,
          amount: 0,
          status: status,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ).statusDisplay,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _handleAction(String action, ContributionModel contribution) {
    switch (action) {
      case 'confirm':
        _confirmContribution(contribution);
        break;
      case 'delete':
        _deleteContribution(contribution);
        break;
    }
  }

  void _confirmContribution(ContributionModel contribution) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Contribution'),
        content: Text(
          'Are you sure you want to confirm this ${controller.formatAmount(contribution.amount)} contribution from ${contribution.participantName ?? "Anonymous"}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.updateContributionStatus(contribution.id, 'CONFIRMED');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _deleteContribution(ContributionModel contribution) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Contribution'),
        content: Text(
          'Are you sure you want to delete this contribution? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteContribution(contribution.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showContributionDetails(BuildContext context, ContributionModel contribution) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Contribution Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Amount', controller.formatAmount(contribution.amount)),
              _buildDetailRow('Contributor', contribution.participantName ?? 'Anonymous'),
              if (contribution.participantPhone != null)
                _buildDetailRow('Phone', contribution.participantPhone!),
              _buildDetailRow('Type', contribution.kindDisplay),
              _buildDetailRow('Status', contribution.statusDisplay),
              _buildDetailRow(
                'Date',
                DateFormat('MMM d, y • h:mm a').format(contribution.createdAt),
              ),
              if (contribution.paymentReference != null)
                _buildDetailRow('Reference', contribution.paymentReference!),
              if (contribution.itemDescription != null)
                _buildDetailRow('Description', contribution.itemDescription!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddContributionDialog(BuildContext context) {
    Get.toNamed(AppRoutes.addContribution, arguments: event);
  }

  void _showMobilePaymentDialog(BuildContext context) {
    Get.toNamed(AppRoutes.paymentCheckout, arguments: event);
  }
}
