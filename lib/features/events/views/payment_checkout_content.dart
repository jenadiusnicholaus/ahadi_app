import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../payments/services/payment_service.dart';
import '../models/event_model.dart';

/// Payment Checkout content - renders inside DashboardShell
class PaymentCheckoutContent extends StatefulWidget {
  final EventModel event;
  final VoidCallback onCancel;
  final VoidCallback onSuccess;

  const PaymentCheckoutContent({
    super.key,
    required this.event,
    required this.onCancel,
    required this.onSuccess,
  });

  @override
  State<PaymentCheckoutContent> createState() => _PaymentCheckoutContentState();
}

class _PaymentCheckoutContentState extends State<PaymentCheckoutContent> {
  final _formKey = GlobalKey<FormState>();
  final PaymentService _paymentService = Get.find<PaymentService>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedProvider = 'Tigo';
  bool _isAnonymous = false;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _mobileProviders = [
    {
      'name': 'Tigo',
      'color': Color(0xFF002B5B),
      'logo': 'assets/images/tigo_pesa.png',
    },
    {
      'name': 'Airtel',
      'color': Color(0xFFED1C24),
      'logo': 'assets/images/airtel_money.png',
    },
    {
      'name': 'Vodacom',
      'color': Color(0xFFE60000),
      'logo': 'assets/images/mpesa.png',
    },
    {
      'name': 'Halotel',
      'color': Color(0xFF00A651),
      'logo': 'assets/images/halopesa.png',
    },
  ];

  final List<int> _quickAmounts = [5000, 10000, 25000, 50000, 100000, 200000];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contribute via Mobile Money',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.event.title,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Main content (mobile layout)
          Column(
            children: [
              _buildPaymentForm(),
              const SizedBox(height: 24),
              _buildOrderSummary(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Form(
      key: _formKey,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 1: Select Provider
              _buildSectionHeader('1', 'Select Mobile Money Provider'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _mobileProviders.map((provider) {
                  final isSelected = _selectedProvider == provider['name'];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedProvider = provider['name'];
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 100,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (provider['color'] as Color).withOpacity(0.1)
                            : Colors.grey.shade50,
                        border: Border.all(
                          color: isSelected
                              ? provider['color'] as Color
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
                              color: provider['color'] as Color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                provider['name'].toString().substring(0, 1),
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
                            provider['name'],
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? provider['color'] as Color
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Step 2: Your Info
              _buildSectionHeader('2', 'Your Information'),
              const SizedBox(height: 16),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Contribute anonymously'),
                value: _isAnonymous,
                onChanged: (value) {
                  setState(() {
                    _isAnonymous = value;
                  });
                },
              ),
              const SizedBox(height: 12),

              if (!_isAnonymous)
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Your Name *',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (!_isAnonymous && (value == null || value.isEmpty)) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
              if (!_isAnonymous) const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: '0712345678',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Mobile money payment request will be sent to this number',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Step 3: Amount
              _buildSectionHeader('3', 'Contribution Amount'),
              const SizedBox(height: 16),

              // Quick amounts
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAmounts.map((amount) {
                  return ActionChip(
                    label: Text('TZS ${_formatAmount(amount.toDouble())}'),
                    onPressed: () {
                      setState(() {
                        _amountController.text = amount.toString();
                      });
                    },
                    backgroundColor: Colors.grey.shade100,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (TZS) *',
                  prefixText: 'TZS ',
                  prefixIcon: const Icon(Icons.payments),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value.replaceAll(',', ''));
                  if (amount == null || amount < 1000) {
                    return 'Minimum amount is TZS 1,000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Message (Optional)',
                  hintText: 'Send a word of encouragement',
                  prefixIcon: const Icon(Icons.message),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Security note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Secure Payment',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          Text(
                            'Your payment is processed securely via $_selectedProvider',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _processPayment,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.lock),
                    label: Text(_isProcessing ? 'Processing...' : 'Pay Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
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

  Widget _buildSectionHeader(String number, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    final processingFee = amount * 0.03; // 3% processing fee
    final total = amount + processingFee;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Event info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: widget.event.displayCoverImage.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.event.displayCoverImage,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.event,
                            color: AppColors.primary,
                            size: 30,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Contribution',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Progress info
            if (widget.event.contributionTarget != null &&
                widget.event.contributionTarget! > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Progress'),
                  Text(
                    '${widget.event.progressPercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (widget.event.progressPercentage / 100).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'TZS ${_formatAmount(widget.event.totalContributions)} of TZS ${_formatAmount(widget.event.contributionTarget!)} raised',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Divider(),
            const SizedBox(height: 16),

            // Price breakdown
            _buildPriceRow('Contribution', 'TZS ${_formatAmount(amount)}'),
            const SizedBox(height: 8),
            _buildPriceRow(
              'Processing fee (3%)',
              'TZS ${_formatAmount(processingFee)}',
              isSubtle: true,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildPriceRow(
              'Total',
              'TZS ${_formatAmount(total)}',
              isBold: true,
              isLarge: true,
            ),
            const SizedBox(height: 24),

            // Payment method indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _mobileProviders.firstWhere(
                        (p) => p['name'] == _selectedProvider,
                      )['color'] as Color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        _selectedProvider.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedProvider,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (_phoneController.text.isNotEmpty)
                          Text(
                            _phoneController.text,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isSubtle = false,
    bool isBold = false,
    bool isLarge = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isSubtle ? Colors.grey.shade600 : Colors.black,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isLarge ? 18 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isBold ? AppColors.primary : Colors.black,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isLarge ? 18 : 14,
          ),
        ),
      ],
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));

      final result = await _paymentService.checkoutMno(
        eventId: widget.event.id,
        amount: amount,
        phone: _phoneController.text,
        provider: _selectedProvider,
        participantName: _isAnonymous ? 'Anonymous' : _nameController.text,
      );

      if (result.success) {
        Get.snackbar(
          'Payment Initiated',
          'Please check your phone to complete the payment',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );

        // Show waiting dialog
        _showWaitingDialog();
      } else {
        Get.snackbar(
          'Payment Failed',
          result.message ?? 'Something went wrong',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to process payment: $e',
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

  void _showWaitingDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.phone_android,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Check Your Phone',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'A payment request has been sent to\n${_phoneController.text}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                Get.back();
                widget.onSuccess();
              },
              child: const Text('I\'ve completed the payment'),
            ),
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
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
}
