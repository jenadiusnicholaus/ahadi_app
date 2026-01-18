import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../services/payment_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final PaymentService _paymentService = Get.find<PaymentService>();
  final ScrollController _scrollController = ScrollController();
  
  final List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreTransactions();
    }
  }

  Future<void> _loadTransactions({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _transactions.clear();
      });
    }

    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final transactions = await _paymentService.getTransactions(
        page: _currentPage,
        pageSize: 20,
        status: _statusFilter.isEmpty ? null : _statusFilter,
      );

      setState(() {
        if (transactions.isEmpty) {
          _hasMore = false;
        } else {
          _transactions.addAll(transactions);
          _currentPage++;
        }
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load transactions',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (!_hasMore || _isLoading) return;
    await _loadTransactions();
  }

  void _setFilter(String status) {
    setState(() => _statusFilter = status);
    _loadTransactions(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(),
          
          // Transactions List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadTransactions(refresh: true),
              child: _transactions.isEmpty && !_isLoading
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _transactions.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _transactions.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return _buildTransactionItem(_transactions[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', ''),
            const SizedBox(width: 8),
            _buildFilterChip('Successful', 'SUCCESS'),
            const SizedBox(width: 8),
            _buildFilterChip('Pending', 'PENDING'),
            const SizedBox(width: 8),
            _buildFilterChip('Failed', 'FAILED'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _setFilter(value),
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _statusFilter.isEmpty
                ? 'Your transactions will appear here'
                : 'No ${_statusFilter.toLowerCase()} transactions',
            style: TextStyle(
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final formatter = NumberFormat('#,###');
    final dateFormatter = DateFormat('MMM d, yyyy • HH:mm');
    
    Color statusColor;
    IconData statusIcon;
    switch (transaction.status) {
      case 'SUCCESS':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'PENDING':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'FAILED':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showTransactionDetails(transaction),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.eventTitle ?? 'Transaction',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction.payerName ?? transaction.payerPhone,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_android,
                            size: 12,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            transaction.paymentMethod,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFormatter.format(transaction.createdAt),
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TZS ${formatter.format(transaction.amount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        transaction.statusDisplay,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
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
      ),
    );
  }

  void _showTransactionDetails(TransactionModel transaction) {
    final formatter = NumberFormat('#,###');
    final dateFormatter = DateFormat('MMM d, yyyy HH:mm:ss');
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Transaction Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Reference', transaction.reference),
            _buildDetailRow('Event', transaction.eventTitle ?? '-'),
            _buildDetailRow('Payer', transaction.payerName ?? transaction.payerPhone),
            _buildDetailRow('Phone', transaction.payerPhone),
            _buildDetailRow('Amount', 'TZS ${formatter.format(transaction.amount)}'),
            if (transaction.transactionFee != null)
              _buildDetailRow('Fee', 'TZS ${formatter.format(transaction.transactionFee!)}'),
            if (transaction.netAmount != null)
              _buildDetailRow('Net Amount', 'TZS ${formatter.format(transaction.netAmount!)}'),
            _buildDetailRow('Payment Method', transaction.paymentMethod),
            _buildDetailRow('Status', transaction.statusDisplay),
            _buildDetailRow('Date', dateFormatter.format(transaction.createdAt)),
            if (transaction.paidAt != null)
              _buildDetailRow('Paid At', dateFormatter.format(transaction.paidAt!)),
            if (transaction.failureReason != null)
              _buildDetailRow('Failure Reason', transaction.failureReason!),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
}
