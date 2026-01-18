import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/event_model.dart';

/// Add Contribution content - Simple MNO payment form
class AddContributionContent extends StatefulWidget {
  final EventModel event;
  final VoidCallback onCancel;
  final VoidCallback onSuccess;

  const AddContributionContent({
    super.key,
    required this.event,
    required this.onCancel,
    required this.onSuccess,
  });

  @override
  State<AddContributionContent> createState() => _AddContributionContentState();
}

class _AddContributionContentState extends State<AddContributionContent> {
  final _formKey = GlobalKey<FormState>();
  final AuthController authController = Get.find<AuthController>();
  final ApiService _api = Get.find<ApiService>();

  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedProvider = 'Mpesa';
  bool _isLoading = false;

  final List<Map<String, String>> _providers = [
    {'value': 'Mpesa', 'label': 'M-Pesa'},
    {'value': 'Tigo', 'label': 'Tigo Pesa'},
    {'value': 'Airtel', 'label': 'Airtel Money'},
    {'value': 'Halopesa', 'label': 'Halo Pesa'},
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill phone from logged in user
    final user = authController.user.value;
    if (user != null) {
      _phoneController.text = user.phone;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Contribute to Event',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.event.title,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // Form Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amount field
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Amount (TZS)',
                            hintText: '50,000',
                            prefixText: 'TZS ',
                            prefixStyle: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter amount';
                            }
                            final amount = double.tryParse(
                              value.replaceAll(',', ''),
                            );
                            if (amount == null || amount <= 0) {
                              return 'Please enter a valid amount';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Provider dropdown & Phone in row
                        Row(
                          children: [
                            // Provider dropdown
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedProvider,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Provider',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                ),
                                items: _providers.map((p) {
                                  return DropdownMenuItem(
                                    value: p['value'],
                                    child: Text(
                                      p['label']!,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedProvider = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Phone number
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Phone',
                                  hintText: '0712345678',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (value.length < 10) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Message (optional)
                        TextFormField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            labelText: 'Message (Optional)',
                            hintText: 'Congratulations!',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Buttons row
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: widget.onCancel,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _submitContribution,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Pay Now',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
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

              // Info note
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'You\'ll receive a payment prompt on your phone.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitContribution() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));

      final payload = {
        'event_id': widget.event.id,
        'amount': amount,
        'provider': _selectedProvider,
        'phone_number': _phoneController.text,
        'message': _messageController.text,
      };

      debugPrint('📡 Submitting MNO payment: $payload');

      final response = await _api.dio.post(
        ApiEndpoints.paymentCheckoutMno,
        data: payload,
      );

      debugPrint('📡 MNO response: ${response.data}');

      Get.snackbar(
        'Payment Initiated!',
        'Check your phone for the payment prompt',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

      widget.onSuccess();
    } catch (e) {
      debugPrint('❌ MNO payment error: $e');
      Get.snackbar(
        'Payment Failed',
        'Could not initiate payment. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
