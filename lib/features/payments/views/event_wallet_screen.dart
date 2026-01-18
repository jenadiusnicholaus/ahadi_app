import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../events/models/event_model.dart';
import '../models/event_wallet_model.dart';
import '../services/payment_service.dart';
import 'event_transactions_screen.dart';
import 'withdraw_request_screen.dart';

/// Event-level wallet screen showing financial summary for a specific event
class EventWalletScreen extends StatefulWidget {
  final EventModel event;

  const EventWalletScreen({super.key, required this.event});

  @override
  State<EventWalletScreen> createState() => _EventWalletScreenState();
}

class _EventWalletScreenState extends State<EventWalletScreen> {
  final PaymentService _paymentService = Get.find<PaymentService>();
  final currencyFormat = NumberFormat('#,###');

  EventWalletModel? _wallet;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final wallet = await _paymentService.getEventWallet(widget.event.id);
      setState(() {
        _wallet = wallet;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Wallet'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadWallet),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadWallet,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWallet,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Info Header
            _buildEventHeader(),
            const SizedBox(height: 20),

            // Balance Card
            _buildBalanceCard(),
            const SizedBox(height: 20),

            // Financial Summary
            _buildFinancialSummary(),
            const SizedBox(height: 20),

            // Action Buttons
            _buildActionButtons(),
            const SizedBox(height: 24),

            // Withdrawal History
            _buildWithdrawalHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.event, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_wallet?.contributionsCount ?? 0} contributions',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final wallet = _wallet;
    final available = wallet?.availableBalance ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${wallet?.feePercent ?? "3"}% fee',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Available for Withdrawal',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'TZS ${currencyFormat.format(available)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (wallet?.hasPendingWithdrawal ?? false) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pending, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'TZS ${currencyFormat.format(wallet?.pendingWithdrawals ?? 0)} pending',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    final wallet = _wallet;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Financial Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Total Contributions',
            wallet?.grossAmount ?? 0,
            Colors.green,
            Icons.arrow_downward,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            'Platform Fees (${wallet?.feePercent ?? "3"}%)',
            -(wallet?.totalFees ?? 0),
            Colors.orange,
            Icons.remove_circle_outline,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            'Net Amount',
            wallet?.netAmount ?? 0,
            AppColors.primary,
            Icons.account_balance,
            isBold: true,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            'Already Withdrawn',
            -(wallet?.totalDisbursed ?? 0),
            Colors.grey,
            Icons.arrow_upward,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            'Available Balance',
            wallet?.availableBalance ?? 0,
            Colors.green.shade700,
            Icons.wallet,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount,
    Color color,
    IconData icon, {
    bool isBold = false,
  }) {
    final isNegative = amount < 0;
    final displayAmount = amount.abs();

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          '${isNegative ? "-" : ""}TZS ${currencyFormat.format(displayAmount)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? color : Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final wallet = _wallet;
    final canWithdraw = wallet?.canWithdraw ?? false;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Get.to(() => EventTransactionsScreen(event: widget.event));
            },
            icon: const Icon(Icons.receipt_long),
            label: const Text('Transactions'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canWithdraw
                ? () async {
                    final result = await Get.to(
                      () => WithdrawRequestScreen(
                        event: widget.event,
                        availableBalance: wallet?.availableBalance ?? 0,
                      ),
                    );
                    if (result == true) {
                      _loadWallet(); // Refresh after withdrawal
                    }
                  }
                : null,
            icon: const Icon(Icons.payments),
            label: const Text('Withdraw'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWithdrawalHistory() {
    final disbursements = _wallet?.disbursements ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Withdrawal History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (disbursements.isNotEmpty)
              TextButton(
                onPressed: () {
                  // View all disbursements
                },
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (disbursements.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No withdrawals yet',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          ...disbursements.take(5).map((d) => _buildDisbursementItem(d)),
      ],
    );
  }

  Widget _buildDisbursementItem(EventDisbursementModel disbursement) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final statusColor = _getStatusColor(disbursement.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  disbursement.isCompleted
                      ? Icons.check_circle
                      : disbursement.isFailed
                      ? Icons.error
                      : Icons.pending,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TZS ${currencyFormat.format(disbursement.netAmount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${disbursement.provider} • ${disbursement.recipientPhone}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      disbursement.statusDisplay,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(disbursement.createdAt),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          if (disbursement.statusMessage != null &&
              disbursement.statusMessage!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              disbursement.statusMessage!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'PROCESSING':
      case 'PENDING':
        return Colors.orange;
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
