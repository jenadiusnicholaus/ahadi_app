import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../events/models/event_model.dart';
import '../services/payment_service.dart';

/// Screen for requesting withdrawal of funds from event wallet
class WithdrawRequestScreen extends StatefulWidget {
  final EventModel event;
  final double availableBalance;
  final double feePercentage;

  const WithdrawRequestScreen({
    super.key,
    required this.event,
    required this.availableBalance,
    this.feePercentage = 3.0, // Default 3% for free plan
  });

  @override
  State<WithdrawRequestScreen> createState() => _WithdrawRequestScreenState();
}

class _WithdrawRequestScreenState extends State<WithdrawRequestScreen> {
  final PaymentService _paymentService = Get.find<PaymentService>();
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final currencyFormat = NumberFormat('#,###');

  String _selectedProvider = 'Mpesa';
  bool _isProcessing = false;
  double _calculatedFee = 0;
  double _netAmount = 0;

  final List<Map<String, dynamic>> _providers = [
    {
      'name': 'Mpesa',
      'code': 'MPESA',
      'icon': Icons.phone_android,
      'color': Colors.green,
      'prefix': '255',
    },
    {
      'name': 'Airtel Money',
      'code': 'AIRTEL',
      'icon': Icons.phone_android,
      'color': Colors.red,
      'prefix': '255',
    },
    {
      'name': 'Tigo Pesa',
      'code': 'TIGO',
      'icon': Icons.phone_android,
      'color': Colors.blue,
      'prefix': '255',
    },
    {
      'name': 'Halopesa',
      'code': 'HALO',
      'icon': Icons.phone_android,
      'color': Colors.orange,
      'prefix': '255',
    },
  ];

  @override
  void initState() {
    super.initState();
    _calculateFees();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _calculateFees() {
    setState(() {
      _calculatedFee = widget.availableBalance * (widget.feePercentage / 100);
      _netAmount = widget.availableBalance - _calculatedFee;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw Funds'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Summary Card
              _buildAmountCard(),
              const SizedBox(height: 24),

              // Provider Selection
              const Text(
                'Select Withdrawal Method',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildProviderSelection(),
              const SizedBox(height: 24),

              // Phone Number Input
              const Text(
                'Phone Number',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildPhoneInput(),
              const SizedBox(height: 24),

              // Fee Breakdown
              _buildFeeBreakdown(),
              const SizedBox(height: 32),

              // Important Notice
              _buildNotice(),
              const SizedBox(height: 24),

              // Withdraw Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.availableBalance > 0 && !_isProcessing
                      ? _processWithdrawal
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                  ),
                  child: _isProcessing
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
                      : const Text(
                          'Request Withdrawal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.event.title,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Available to Withdraw',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'TZS ${currencyFormat.format(widget.availableBalance)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSelection() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: _providers.length,
      itemBuilder: (context, index) {
        final provider = _providers[index];
        final isSelected = _selectedProvider == provider['name'];

        return InkWell(
          onTap: () {
            setState(() {
              _selectedProvider = provider['name'];
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? provider['color'] : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? (provider['color'] as Color).withOpacity(0.1)
                  : Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(provider['icon'], color: provider['color'], size: 24),
                const SizedBox(width: 8),
                Text(
                  provider['name'],
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? provider['color']
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhoneInput() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(12),
      ],
      decoration: InputDecoration(
        hintText: 'e.g., 255712345678',
        prefixIcon: const Icon(Icons.phone),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        helperText: 'Enter your mobile money number',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your phone number';
        }
        if (!value.startsWith('255')) {
          return 'Phone number must start with 255';
        }
        if (value.length < 12) {
          return 'Invalid phone number';
        }
        return null;
      },
    );
  }

  Widget _buildFeeBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildFeeRow(
            'Gross Amount',
            'TZS ${currencyFormat.format(widget.availableBalance)}',
          ),
          const SizedBox(height: 8),
          _buildFeeRow(
            'Platform Fee (${widget.feePercentage}%)',
            '- TZS ${currencyFormat.format(_calculatedFee)}',
            valueColor: Colors.red,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          _buildFeeRow(
            'You will receive',
            'TZS ${currencyFormat.format(_netAmount)}',
            isBold: true,
            valueColor: Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important Notice',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Withdrawals are processed within 24-48 hours. The funds will be sent to your mobile money account.',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.availableBalance <= 0) {
      Get.snackbar(
        'Error',
        'No funds available for withdrawal',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Withdrawal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to withdraw:',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Text(
              'TZS ${currencyFormat.format(_netAmount)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'To: $_selectedProvider - ${_phoneController.text}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Find the provider code
      final providerCode = _providers.firstWhere(
        (p) => p['name'] == _selectedProvider,
      )['code'];

      final result = await _paymentService.disburseEventFunds(
        eventId: widget.event.id,
        phone: _phoneController.text.trim(),
        provider: providerCode as String,
        amount: widget.availableBalance,
      );

      if (result['success'] == true) {
        Get.snackbar(
          'Success',
          result['message'] ?? 'Withdrawal request submitted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Navigator.pop(context, true); // Return success
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Failed to process withdrawal request',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}
