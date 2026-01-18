import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../services/payment_service.dart';
import '../../events/models/event_model.dart';

class DisbursementScreen extends StatefulWidget {
  const DisbursementScreen({super.key});

  @override
  State<DisbursementScreen> createState() => _DisbursementScreenState();
}

class _DisbursementScreenState extends State<DisbursementScreen> {
  final PaymentService _paymentService = Get.find<PaymentService>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late EventModel event;
  String _selectedProvider = 'Mpesa';
  bool _isLoading = false;
  bool _disburseAll = true;
  double? _availableBalance;

  // Mobile money providers
  static final List<Map<String, dynamic>> _mobileProviders = [
    {'name': 'Mpesa', 'display': 'M-Pesa (Vodacom)', 'color': Color(0xFFE60000)},
    {'name': 'Tigo', 'display': 'Tigo Pesa', 'color': Color(0xFF002B5B)},
    {'name': 'Airtel', 'display': 'Airtel Money', 'color': Color(0xFFED1C24)},
    {'name': 'Halopesa', 'display': 'Halopesa', 'color': Color(0xFF00A651)},
  ];

  @override
  void initState() {
    super.initState();
    event = Get.arguments as EventModel;
    _availableBalance = event.availableBalance;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _requestDisbursement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _paymentService.disburseEventFunds(
        eventId: event.id,
        phone: _phoneController.text.trim(),
        provider: _selectedProvider,
        amount: _disburseAll ? null : double.parse(_amountController.text),
      );

      if (result['success'] == true) {
        Get.back();
        Get.snackbar(
          'Success',
          result['message'] ?? 'Disbursement request submitted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Disbursement failed',
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Disbursement'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Info Card
              _buildEventInfoCard(formatter),
              const SizedBox(height: 24),

              // Available Balance
              _buildBalanceCard(formatter),
              const SizedBox(height: 24),

              // Amount Selection
              const Text(
                'Disbursement Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              // Disburse All Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: CheckboxListTile(
                  title: const Text('Withdraw all available funds'),
                  subtitle: Text(
                    'TZS ${formatter.format(_availableBalance ?? 0)}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  value: _disburseAll,
                  onChanged: (value) {
                    setState(() => _disburseAll = value ?? true);
                  },
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              if (!_disburseAll) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount (TZS)',
                    hintText: 'Enter amount to withdraw',
                    prefixIcon: const Icon(Icons.money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (!_disburseAll) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      if (_availableBalance != null && amount > _availableBalance!) {
                        return 'Amount exceeds available balance';
                      }
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),

              // Payment Provider Selection
              const Text(
                'Select Payment Provider',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _mobileProviders.map((provider) {
                  final providerName = provider['name'] as String;
                  final displayName = provider['display'] as String;
                  final providerColor = provider['color'] as Color;
                  final isSelected = _selectedProvider == providerName;

                  return InkWell(
                    onTap: () => setState(() => _selectedProvider = providerName),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: MediaQuery.of(context).size.width / 2 - 24,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? providerColor.withOpacity(0.1)
                            : Colors.grey.shade50,
                        border: Border.all(
                          color: isSelected ? providerColor : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: providerColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                providerName.substring(0, 1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? providerColor
                                    : Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, color: providerColor, size: 20),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Phone Number Input
              const Text(
                'Receiving Phone Number',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '07XXXXXXXX',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
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

              // Fee Warning
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Transaction fees will be deducted based on your subscription plan.',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestDisbursement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Request Disbursement',
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

  Widget _buildEventInfoCard(NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: TZS ${formatter.format(event.totalContributions)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(NumberFormat formatter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Colors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available for Withdrawal',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'TZS ${formatter.format(_availableBalance ?? 0)}',
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
}
