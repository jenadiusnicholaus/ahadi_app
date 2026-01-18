import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../services/payment_service.dart';

class PaymentStatusScreen extends StatefulWidget {
  const PaymentStatusScreen({super.key});

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Timer? _pollingTimer;
  
  String? transactionRef;
  String? eventTitle;
  double? amount;
  String? paymentMethod;
  
  String _status = 'PENDING';
  String? _errorMessage;
  bool _isPolling = true;
  int _pollCount = 0;
  static const int _maxPollCount = 60; // 5 minutes at 5-second intervals

  @override
  void initState() {
    super.initState();
    
    // Get arguments
    final args = Get.arguments as Map<String, dynamic>?;
    transactionRef = args?['transactionRef'];
    eventTitle = args?['eventTitle'];
    amount = args?['amount'];
    paymentMethod = args?['paymentMethod'];
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    // Start polling
    _startPolling();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!_isPolling) {
        timer.cancel();
        return;
      }

      _pollCount++;
      
      if (_pollCount >= _maxPollCount) {
        setState(() {
          _isPolling = false;
          _status = 'TIMEOUT';
          _errorMessage = 'Payment verification timed out. Please check your transaction history.';
        });
        timer.cancel();
        return;
      }

      await _checkTransactionStatus();
    });
  }

  Future<void> _checkTransactionStatus() async {
    if (transactionRef == null) return;

    try {
      final paymentService = Get.find<PaymentService>();
      final transactions = await paymentService.getTransactions(
        pageSize: 1,
      );
      
      // Find the transaction by reference
      final transaction = transactions.firstWhereOrNull(
        (t) => t.reference == transactionRef,
      );

      if (transaction != null) {
        if (transaction.status != 'PENDING') {
          setState(() {
            _status = transaction.status;
            _isPolling = false;
            if (transaction.isFailed) {
              _errorMessage = transaction.failureReason ?? 'Payment failed';
            }
          });
          _pollingTimer?.cancel();
        }
      }
    } catch (e) {
      debugPrint('❌ Error polling transaction: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    
    return PopScope(
      canPop: !_isPolling,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isPolling) {
          _showExitConfirmation();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payment Status'),
          centerTitle: true,
          automaticallyImplyLeading: !_isPolling,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                
                // Status Animation/Icon
                _buildStatusIcon(),
                const SizedBox(height: 32),
                
                // Status Text
                Text(
                  _getStatusTitle(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                Text(
                  _getStatusDescription(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Transaction Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Event', eventTitle ?? '-'),
                      const Divider(height: 24),
                      _buildDetailRow('Amount', 'TZS ${formatter.format(amount ?? 0)}'),
                      const Divider(height: 24),
                      _buildDetailRow('Method', paymentMethod ?? '-'),
                      const Divider(height: 24),
                      _buildDetailRow('Reference', transactionRef ?? '-'),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Action Buttons
                if (!_isPolling) ...[
                  if (_status == 'SUCCESS')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back(result: true);
                          Get.back(result: true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Try Again',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Get.offAllNamed('/dashboard'),
                      child: const Text('Go to Dashboard'),
                    ),
                  ],
                ] else ...[
                  // Polling indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Checking payment status... ($_pollCount/$_maxPollCount)',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _showExitConfirmation,
                    child: const Text('Cancel and go back'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (_status) {
      case 'SUCCESS':
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green,
          ),
        );
      case 'FAILED':
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cancel,
            size: 80,
            color: Colors.red,
          ),
        );
      case 'TIMEOUT':
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.access_time,
            size: 80,
            color: Colors.orange,
          ),
        );
      default: // PENDING
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animationController.value * 2 * 3.14159,
                child: const Icon(
                  Icons.sync,
                  size: 60,
                  color: AppColors.primary,
                ),
              );
            },
          ),
        );
    }
  }

  String _getStatusTitle() {
    switch (_status) {
      case 'SUCCESS':
        return 'Payment Successful!';
      case 'FAILED':
        return 'Payment Failed';
      case 'TIMEOUT':
        return 'Verification Timeout';
      default:
        return 'Waiting for Payment';
    }
  }

  String _getStatusDescription() {
    switch (_status) {
      case 'SUCCESS':
        return 'Your contribution has been received successfully.';
      case 'FAILED':
        return _errorMessage ?? 'The payment could not be completed.';
      case 'TIMEOUT':
        return _errorMessage ?? 'We couldn\'t verify your payment in time.';
      default:
        return 'Please complete the payment on your phone.\nA USSD prompt should appear shortly.';
    }
  }

  Color _getStatusColor() {
    switch (_status) {
      case 'SUCCESS':
        return Colors.green;
      case 'FAILED':
        return Colors.red;
      case 'TIMEOUT':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _showExitConfirmation() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text(
          'Are you sure you want to cancel? If you\'ve already entered your PIN, '
          'the payment may still go through.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Keep Waiting'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.back();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
