import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/contribution_controller.dart';
import '../models/event_model.dart';
import '../../payments/services/payment_service.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({super.key});

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  late ContributionController controller;
  late EventModel event;

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  String? _selectedProvider;
  bool _isSubmitting = false;
  Map<String, dynamic>? _feeInfo;
  bool _isCalculatingFee = false;

  @override
  void initState() {
    super.initState();
    event = Get.arguments as EventModel;

    if (!Get.isRegistered<ContributionController>()) {
      Get.put(ContributionController());
    }
    controller = Get.find<ContributionController>();
    controller.init(event.id);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Money Payment'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            event.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (event.contributionTarget != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Collected',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                controller.formatAmount(event.totalContributions),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Target',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                controller.formatAmount(event.contributionTarget!),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (event.totalContributions /
                                  event.contributionTarget!)
                              .clamp(0.0, 1.0),
                          backgroundColor: Colors.white30,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Provider selection
              const Text(
                'Select Payment Provider',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: MobileMoneyProvider.options.map((option) {
                  final isSelected = _selectedProvider == option['value'];
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedProvider = option['value']);
                      _calculateFee();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getProviderColor(option['value']!).withOpacity(0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? _getProviderColor(option['value']!)
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _getProviderColor(option['value']!)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.phone_android,
                              size: 20,
                              color: _getProviderColor(option['value']!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option['label']!,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? _getProviderColor(option['value']!)
                                    : Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: _getProviderColor(option['value']!),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Phone number field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'e.g., 0712345678',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  prefixText: '+255 ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'Enter the mobile money registered phone number',
                ),
                onChanged: (value) {
                  // Auto-detect provider from phone number
                  if (_selectedProvider == null && value.length >= 2) {
                    final detected = MobileMoneyProvider.detectFromPhone(value);
                    if (detected != null) {
                      setState(() => _selectedProvider = detected);
                    }
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  final cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
                  if (cleanPhone.length < 9 || cleanPhone.length > 12) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Amount (TZS)',
                  hintText: 'Enter amount',
                  prefixText: 'TZS ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => _calculateFee(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount < 1000) {
                    return 'Minimum amount is TZS 1,000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Contributor name (optional)
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Your Name (Optional)',
                  hintText: 'How should we recognize you?',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Fee breakdown
              if (_feeInfo != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildFeeRow(
                        'Amount',
                        controller.formatAmount(
                          double.tryParse(_amountController.text) ?? 0,
                        ),
                      ),
                      const Divider(height: 24),
                      _buildFeeRow(
                        'Transaction Fee',
                        controller.formatAmount(
                          (_feeInfo!['fee'] as num?)?.toDouble() ?? 0,
                        ),
                        isHighlighted: true,
                      ),
                      const Divider(height: 24),
                      _buildFeeRow(
                        'Total to Pay',
                        controller.formatAmount(
                          (_feeInfo!['total'] as num?)?.toDouble() ?? 0,
                        ),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else if (_isCalculatingFee) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _selectedProvider == null || _isSubmitting
                      ? null
                      : _initiatePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedProvider != null
                        ? _getProviderColor(_selectedProvider!)
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.phone_android),
                            const SizedBox(width: 8),
                            const Text(
                              'Pay Now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You will receive a prompt on your phone to complete the payment. Make sure your phone is on and has sufficient balance.',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeeRow(String label, String value,
      {bool isBold = false, bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isHighlighted ? Colors.orange.shade700 : Colors.grey.shade700,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isHighlighted ? Colors.orange.shade700 : Colors.black87,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Color _getProviderColor(String provider) {
    switch (provider) {
      case 'Mpesa':
        return const Color(0xFFE60000); // Vodacom red
      case 'Airtel':
        return const Color(0xFFFF0000); // Airtel red
      case 'Tigo':
        return const Color(0xFF003366); // Tigo blue
      case 'Halotel':
        return const Color(0xFFFF6B00); // Halotel orange
      default:
        return AppColors.primary;
    }
  }

  Future<void> _calculateFee() async {
    if (_selectedProvider == null || _amountController.text.isEmpty) {
      setState(() => _feeInfo = null);
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _feeInfo = null);
      return;
    }

    setState(() => _isCalculatingFee = true);

    try {
      final feeInfo = await controller.calculateFee(
        amount: amount,
        provider: _selectedProvider!,
      );

      setState(() {
        _feeInfo = feeInfo;
        _isCalculatingFee = false;
      });
    } catch (e) {
      setState(() {
        _feeInfo = null;
        _isCalculatingFee = false;
      });
    }
  }

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProvider == null) {
      Get.snackbar(
        'Error',
        'Please select a payment provider',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final amount = double.parse(_amountController.text);
      final phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
      final formattedPhone =
          phone.startsWith('0') ? '255${phone.substring(1)}' : phone;

      final result = await controller.initiateMobilePayment(
        amount: amount,
        phone: formattedPhone,
        provider: _selectedProvider!,
        participantName:
            _nameController.text.isNotEmpty ? _nameController.text : null,
      );

      if (result != null && result.success) {
        _showPaymentInitiatedDialog();
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showPaymentInitiatedDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.phone_android,
                size: 48,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Initiated!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'A payment prompt has been sent to your phone. Please enter your PIN to complete the payment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back(); // Close dialog
                  Get.back(); // Go back to contributions
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }
}
