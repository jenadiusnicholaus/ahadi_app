import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../services/public_event_service.dart';

/// Public contribution screen - allows anyone to contribute without login
class PublicContributionScreen extends StatefulWidget {
  const PublicContributionScreen({super.key});

  @override
  State<PublicContributionScreen> createState() =>
      _PublicContributionScreenState();
}

class _PublicContributionScreenState extends State<PublicContributionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();

  late final PublicEventService _publicEventService;
  AuthController? _authController;

  bool _isLoadingEvent = false;
  bool _isSubmitting = false;
  Map<String, dynamic>? _eventData;
  String? _errorMessage;
  String _selectedProvider = 'Mpesa';

  // Check if user is logged in
  bool get _isLoggedIn => _authController?.isAuthenticated ?? false;

  // Check if user has a proper name set (not empty)
  bool get _hasUserName {
    final name = _authController?.user.value?.fullName;
    return name != null && name.isNotEmpty;
  }

  String? get _userFullName => _authController?.user.value?.fullName;

  // Primary color for this screen
  static const Color _primaryColor = Color(0xFF111827);

  final List<Map<String, String>> _providers = [
    {'value': 'Mpesa', 'label': 'M-Pesa (Vodacom)'},
    {'value': 'Airtel', 'label': 'Airtel Money'},
    {'value': 'Tigo', 'label': 'Tigo Pesa'},
    {'value': 'Halopesa', 'label': 'Halopesa'},
    {'value': 'Azampesa', 'label': 'Azam Pesa'},
  ];

  @override
  void initState() {
    super.initState();
    _publicEventService = PublicEventService(Get.find<ApiService>());

    // Try to get AuthController if available (user may or may not be logged in)
    try {
      _authController = Get.find<AuthController>();
    } catch (_) {
      // AuthController not registered, user is not logged in
    }

    // Event code must be passed as argument
    final args = Get.arguments;
    if (args != null && args is String && args.isNotEmpty) {
      _codeController.text = args;
      _fetchEvent();
    } else {
      // No event code provided, go back to events listing
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
        Get.snackbar(
          'Select an Event',
          'Please browse events and click "Contribute" on an event to contribute.',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade900,
          duration: const Duration(seconds: 4),
        );
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _amountController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchEvent() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter an event code');
      return;
    }

    setState(() {
      _isLoadingEvent = true;
      _errorMessage = null;
      _eventData = null;
    });

    final result = await _publicEventService.getEventForContribution(code);

    setState(() {
      _isLoadingEvent = false;
      if (result['success'] == true) {
        _eventData = result['data'];
      } else {
        _errorMessage = result['message'] ?? 'Event not found';
      }
    });
  }

  Future<void> _submitContribution() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventData == null) return;

    setState(() => _isSubmitting = true);

    // Show processing dialog for sandbox (can take a while)
    _showProcessingDialog();

    // Use logged-in user's name if they have one, otherwise use form input
    final payerName = _hasUserName
        ? _userFullName!
        : _nameController.text.trim();

    final result = await _publicEventService.makePublicContribution(
      eventId: _eventData!['id'],
      amount: double.parse(_amountController.text),
      provider: _selectedProvider,
      phoneNumber: _phoneController.text.trim(),
      payerName: payerName,
      message: _messageController.text.trim(),
    );

    // Close processing dialog
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      _showSuccessDialog();
    } else {
      Get.snackbar(
        'Error',
        result['message'] ?? 'Contribution failed',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 5),
      );
    }
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            const Text(
              'Processing Payment...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait. This may take a moment.\nDo not close this screen.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Thank You!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your contribution to "${_eventData!['title']}" has been processed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your phone to confirm the payment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Reset form
              setState(() {
                _eventData = null;
                _amountController.clear();
                _phoneController.clear();
                _nameController.clear();
                _messageController.clear();
                _codeController.clear();
              });
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Keep event, allow another contribution
              _amountController.clear();
              _phoneController.clear();
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            child: const Text('Contribute Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: isDesktop
          ? const Color(0xFFF3F4F6)
          : Colors.grey.shade100,
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('Contribute'),
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
      body: isDesktop
          ? _buildDesktopLayout(screenWidth)
          : _buildMobileLayout(isTablet),
    );
  }

  Widget _buildDesktopLayout(double screenWidth) {
    return Stack(
      children: [
        Row(
          children: [
            // Left side - Branding
            Expanded(
              flex: 2,
              child: Container(
                color: _primaryColor,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.volunteer_activism,
                          size: 80,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Ahadi',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Make a contribution to support events\nyou care about',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Trust badges
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildTrustBadge(Icons.lock_outline, 'Secure'),
                            const SizedBox(width: 24),
                            _buildTrustBadge(Icons.flash_on, 'Instant'),
                            const SizedBox(width: 24),
                            _buildTrustBadge(
                              Icons.verified_outlined,
                              'Trusted',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Right side - Form
            Expanded(
              flex: 3,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(48),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: _eventData == null
                        ? _buildLoadingCard()
                        : _buildContributionForm(),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Back button
        Positioned(
          top: 16,
          left: 16,
          child: Material(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isTablet) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 32 : 16),
        child: Container(
          constraints: BoxConstraints(maxWidth: isTablet ? 500 : 400),
          child: _eventData == null
              ? _buildLoadingCard()
              : _buildContributionForm(),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoadingEvent) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              const Text(
                'Loading event...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ] else if (_errorMessage != null) ...[
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go Back'),
              ),
            ] else ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              const Text('Loading...'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContributionForm() {
    final currencyFormat = NumberFormat('#,###', 'en_US');
    final target = _eventData!['contribution_target'] != null
        ? double.tryParse(_eventData!['contribution_target'].toString())
        : null;
    final raised =
        double.tryParse(_eventData!['total_raised']?.toString() ?? '0') ?? 0;
    final progress = _eventData!['progress_percent'] ?? 0;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Event Info Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover image
                if (_eventData!['cover_image_url'] != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      _eventData!['cover_image_url'],
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: _primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.event,
                          size: 64,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _eventData!['title'] ?? 'Event',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _eventData = null;
                                _errorMessage = null;
                              });
                            },
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Change'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      if (_eventData!['description'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _eventData!['description'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'By ${_eventData!['organizer_name'] ?? 'Organizer'}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      // Progress bar
                      if (target != null && target > 0) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TZS ${currencyFormat.format(raised)} raised',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                            ),
                            Text(
                              'of TZS ${currencyFormat.format(target)}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _primaryColor,
                          ),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$progress% • ${_eventData!['contributor_count'] ?? 0} contributors',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Contribution Form Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Contribution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Amount
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount (TZS) *',
                      hintText: 'e.g., 10000',
                      prefixIcon: const Icon(Icons.payments_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount < 1000) {
                        return 'Minimum amount is TZS 1,000';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Provider dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedProvider,
                    decoration: InputDecoration(
                      labelText: 'Payment Method *',
                      prefixIcon: const Icon(Icons.phone_android),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _providers
                        .map(
                          (p) => DropdownMenuItem(
                            value: p['value'],
                            child: Text(p['label']!),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedProvider = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number *',
                      hintText: '0712345678',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (value.length < 9) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Name field - show for anonymous users OR logged-in users without a name
                  if (!_isLoggedIn || !_hasUserName) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Your Name (optional)',
                        hintText: 'John Doe',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Show logged-in user info only if they have a name
                  if (_isLoggedIn && _hasUserName) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: Colors.green.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Contributing as',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                Text(
                                  _userFullName!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade700,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Message (optional)
                  TextFormField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Message (optional)',
                      hintText: 'Best wishes!',
                      prefixIcon: const Icon(Icons.message_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitContribution,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      label: Text(
                        _isSubmitting ? 'Processing...' : 'Send Contribution',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'You will receive a USSD prompt to confirm payment',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// TextInputFormatter to convert text to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
