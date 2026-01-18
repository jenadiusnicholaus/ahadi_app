import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../events/models/event_model.dart';
import '../models/event_wallet_model.dart';
import '../services/payment_service.dart';

/// Event-level transactions screen showing all payment records
class EventTransactionsScreen extends StatefulWidget {
  final EventModel event;

  const EventTransactionsScreen({super.key, required this.event});

  @override
  State<EventTransactionsScreen> createState() =>
      _EventTransactionsScreenState();
}

class _EventTransactionsScreenState extends State<EventTransactionsScreen> {
  final PaymentService _paymentService = Get.find<PaymentService>();
  final currencyFormat = NumberFormat('#,###');
  final dateFormat = DateFormat('MMM d, yyyy');
  final timeFormat = DateFormat('h:mm a');

  List<EventTransactionModel> _transactions = [];
  bool _isLoading = true;
  String? _error;

  // Stats
  double _totalCompleted = 0;
  int _completedCount = 0;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final transactions = await _paymentService.getEventTransactions(
        widget.event.id,
      );

      // Calculate stats
      double total = 0;
      int completed = 0;
      int pending = 0;

      for (final t in transactions) {
        if (t.isCompleted) {
          total += t.amount;
          completed++;
        } else if (!t.isFailed) {
          pending++;
        }
      }

      setState(() {
        _transactions = transactions;
        _totalCompleted = total;
        _completedCount = completed;
        _pendingCount = pending;
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
        title: const Text('Transactions'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
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
                onPressed: _loadTransactions,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: Column(
        children: [
          // Stats Header
          _buildStatsHeader(),

          // Transaction List
          Expanded(
            child: _transactions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionItem(_transactions[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total Received',
              'TZS ${currencyFormat.format(_totalCompleted)}',
              Icons.arrow_downward,
              Colors.green,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          Expanded(
            child: _buildStatItem(
              'Completed',
              '$_completedCount',
              Icons.check_circle_outline,
              Colors.green,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          Expanded(
            child: _buildStatItem(
              'Pending',
              '$_pendingCount',
              Icons.pending_outlined,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contributions will appear here',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(EventTransactionModel transaction) {
    final statusColor = _getStatusColor(transaction.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  transaction.isCompleted
                      ? Icons.check_circle
                      : transaction.isFailed
                      ? Icons.cancel
                      : Icons.pending,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.payerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            transaction.payerPhone,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '•',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            transaction.methodDisplay,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount & Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TZS ${currencyFormat.format(transaction.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: transaction.isCompleted
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      transaction.statusDisplay,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
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

  void _showTransactionDetails(EventTransactionModel transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(transaction.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    transaction.isCompleted
                        ? Icons.check_circle
                        : Icons.pending,
                    color: _getStatusColor(transaction.status),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TZS ${currencyFormat.format(transaction.amount)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        transaction.statusDisplay,
                        style: TextStyle(
                          color: _getStatusColor(transaction.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Details
            _buildDetailRow('From', transaction.payerName),
            _buildDetailRow('Phone', transaction.payerPhone),
            _buildDetailRow('Method', transaction.methodDisplay),
            _buildDetailRow('Reference', transaction.reference),
            _buildDetailRow(
              'Date',
              '${dateFormat.format(transaction.createdAt)} at ${timeFormat.format(transaction.createdAt)}',
            ),
            if (transaction.completedAt != null)
              _buildDetailRow(
                'Completed',
                '${dateFormat.format(transaction.completedAt!)} at ${timeFormat.format(transaction.completedAt!)}',
              ),
            if (transaction.transactionId != null)
              _buildDetailRow('Transaction ID', transaction.transactionId!),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
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
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
