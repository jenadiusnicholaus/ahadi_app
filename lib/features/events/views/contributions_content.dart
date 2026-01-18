import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/events_controller.dart';
import '../models/contribution_model.dart';
import '../models/event_model.dart';

/// Contributions content - renders inside DashboardShell
class ContributionsContent extends StatefulWidget {
  final EventModel event;
  final VoidCallback onAddContribution;
  final VoidCallback onPaymentCheckout;
  final void Function(ContributionModel contribution)? onSendMessage;

  const ContributionsContent({
    super.key,
    required this.event,
    required this.onAddContribution,
    required this.onPaymentCheckout,
    this.onSendMessage,
  });

  @override
  State<ContributionsContent> createState() => _ContributionsContentState();
}

class _ContributionsContentState extends State<ContributionsContent>
    with SingleTickerProviderStateMixin {
  final EventsController controller = Get.find<EventsController>();
  late TabController _tabController;

  String _selectedFilter = 'all';
  final List<Map<String, String>> _filters = [
    {'key': 'all', 'label': 'All'},
    {'key': 'CONFIRMED', 'label': 'Completed'},
    {'key': 'PENDING', 'label': 'Pending'},
    {'key': 'FAILED', 'label': 'Failed'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    controller.loadEventContributions(widget.event.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contributions',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.event.title,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats cards
              _buildStatsCards(),
            ],
          ),
        ),

        // Filters and search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'All Contributions'),
                  Tab(text: 'By Contributor'),
                ],
              ),
              const SizedBox(height: 16),

              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter['key'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter['label']!),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = filter['key']!;
                          });
                        },
                        selectedColor: AppColors.primary.withOpacity(0.1),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            return TabBarView(
              controller: _tabController,
              children: [_buildContributionsList(), _buildContributorsList()],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Obx(() {
      final contributions = controller.contributions;
      final completedContributions = contributions
          .where((c) => c.status == 'CONFIRMED' || c.status == 'COMPLETED')
          .toList();
      final totalAmount = completedContributions.fold<double>(
        0,
        (sum, c) => sum + c.amount,
      );
      final avgAmount = completedContributions.isNotEmpty
          ? totalAmount / completedContributions.length
          : 0.0;

      final stats = [
        {
          'label': 'Total Collected',
          'value': 'TZS ${_formatAmount(totalAmount)}',
          'icon': Icons.account_balance_wallet,
          'color': Colors.green,
        },
        {
          'label': 'Total Contributions',
          'value': '${completedContributions.length}',
          'icon': Icons.payment,
          'color': Colors.blue,
        },
        {
          'label': 'Average Amount',
          'value': 'TZS ${_formatAmount(avgAmount)}',
          'icon': Icons.analytics,
          'color': Colors.purple,
        },
        {
          'label': 'Target Progress',
          'value': '${widget.event.progressPercentage.toStringAsFixed(0)}%',
          'icon': Icons.flag,
          'color': Colors.orange,
        },
      ];

      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.85,
        children: stats.map((stat) => _buildStatCard(stat)).toList(),
      );
    });
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              stat['icon'] as IconData,
              color: stat['color'] as Color,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              stat['value'] as String,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              stat['label'] as String,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionsList() {
    return Obx(() {
      var contributions = controller.contributions.toList();

      // Apply filter
      if (_selectedFilter != 'all') {
        contributions = contributions
            .where((c) => c.status == _selectedFilter)
            .toList();
      }

      if (contributions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.payments_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No contributions yet',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: widget.onPaymentCheckout,
                icon: const Icon(Icons.volunteer_activism),
                label: const Text('Be the first to contribute'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: contributions.length,
        itemBuilder: (context, index) {
          return _buildContributionCard(contributions[index]);
        },
      );
    });
  }

  Widget _buildContributionCard(ContributionModel contribution) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    contribution.contributorName.isNotEmpty
                        ? contribution.contributorName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contribution.contributorName.isNotEmpty
                            ? contribution.contributorName
                            : 'Anonymous',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatDate(contribution.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TZS ${_formatAmount(contribution.amount)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    _buildStatusBadge(contribution.status),
                    if (widget.onSendMessage != null &&
                        contribution.participantId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: InkWell(
                          onTap: () => widget.onSendMessage!(contribution),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.message_outlined,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Message',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (contribution.message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        contribution.message,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContributorsList() {
    return Obx(() {
      final contributions = controller.contributions
          .where((c) => c.status == 'CONFIRMED' || c.status == 'COMPLETED')
          .toList();

      // Group by contributor
      final Map<String, List<ContributionModel>> groupedContributions = {};
      for (var contribution in contributions) {
        final key = contribution.contributorName.isNotEmpty
            ? contribution.contributorName
            : 'Anonymous';
        groupedContributions.putIfAbsent(key, () => []);
        groupedContributions[key]!.add(contribution);
      }

      // Sort by total amount
      final sortedContributors = groupedContributions.entries.toList()
        ..sort((a, b) {
          final totalA = a.value.fold<double>(0, (sum, c) => sum + c.amount);
          final totalB = b.value.fold<double>(0, (sum, c) => sum + c.amount);
          return totalB.compareTo(totalA);
        });

      if (sortedContributors.isEmpty) {
        return const Center(child: Text('No contributors yet'));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedContributors.length,
        itemBuilder: (context, index) {
          final entry = sortedContributors[index];
          final totalAmount = entry.value.fold<double>(
            0,
            (sum, c) => sum + c.amount,
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      entry.key[0].toUpperCase(),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (index < 3)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: _getRankColor(index),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.star, size: 12, color: Colors.white),
                      ),
                    ),
                ],
              ),
              title: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${entry.value.length} contribution(s)'),
              trailing: Text(
                'TZS ${_formatAmount(totalAmount)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'CONFIRMED':
      case 'COMPLETED':
        color = Colors.green;
        break;
      case 'PENDING':
        color = Colors.orange;
        break;
      case 'FAILED':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey.shade400;
      case 2:
        return Colors.brown;
      default:
        return Colors.transparent;
    }
  }

  void _showContributionActions(ContributionModel contribution) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Get.back();
              },
            ),
            if (contribution.status == 'PENDING')
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Mark as Completed'),
                onTap: () {
                  Get.back();
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} min ago';
      }
      return '${diff.inHours} hours ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    }
    return DateFormat('MMM d, y').format(date);
  }
}
