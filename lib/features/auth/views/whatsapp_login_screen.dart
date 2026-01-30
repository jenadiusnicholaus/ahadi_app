import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../controllers/auth_controller.dart';
import '../services/whatsapp_auth_service.dart';

class WhatsAppLoginScreen extends StatefulWidget {
  const WhatsAppLoginScreen({super.key});

  @override
  State<WhatsAppLoginScreen> createState() => _WhatsAppLoginScreenState();
}

class _WhatsAppLoginScreenState extends State<WhatsAppLoginScreen> {
  final WhatsAppAuthService _whatsAppAuthService = Get.put(WhatsAppAuthService());
  final AuthController _authController = Get.find<AuthController>();
  
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _otpFocus = FocusNode();
  
  bool _isLoading = false;
  bool _otpSent = false;
  String? _errorMessage;
  String _phoneNumber = '';
  
  // Countdown timer for resend
  Timer? _resendTimer;
  int _resendCountdown = 0;
  
  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocus.dispose();
    _otpFocus.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _requestOTP() async {
    final phone = _phoneController.text.trim();
    
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Please enter your phone number');
      return;
    }
    
    if (!_whatsAppAuthService.isValidPhoneNumber(phone)) {
      setState(() => _errorMessage = 'Please enter a valid phone number');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final formattedPhone = _whatsAppAuthService.formatPhoneNumber(phone);
    final result = await _whatsAppAuthService.requestOTP(formattedPhone);
    
    setState(() => _isLoading = false);
    
    if (result['success'] == true) {
      setState(() {
        _otpSent = true;
        _phoneNumber = formattedPhone;
      });
      _startResendTimer();
      _otpFocus.requestFocus();
      
      Get.snackbar(
        'OTP Sent!',
        'Check your WhatsApp for the verification code',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } else {
      setState(() => _errorMessage = result['error']);
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();
    
    if (otp.isEmpty) {
      setState(() => _errorMessage = 'Please enter the OTP code');
      return;
    }
    
    if (otp.length != 6) {
      setState(() => _errorMessage = 'OTP must be 6 digits');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final result = await _whatsAppAuthService.verifyOTP(_phoneNumber, otp);
    
    setState(() => _isLoading = false);
    
    if (result['success'] == true) {
      // Refresh auth controller state to pick up the new tokens and user
      await _authController.checkAuthStatus();
      
      Get.snackbar(
        'Welcome!',
        result['is_new_user'] == true 
            ? 'Account created successfully' 
            : 'Login successful',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.celebration, color: Colors.white),
      );
      
      // Navigate to home or complete profile
      if (result['is_new_user'] == true) {
        Get.offAllNamed(AppRoutes.completeProfile);
      } else {
        Get.offAllNamed(AppRoutes.publicEvents);
      }
    } else {
      setState(() => _errorMessage = result['error']);
    }
  }

  Future<void> _resendOTP() async {
    if (_resendCountdown > 0) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final result = await _whatsAppAuthService.resendOTP(_phoneNumber);
    
    setState(() => _isLoading = false);
    
    if (result['success'] == true) {
      _startResendTimer();
      _otpController.clear();
      
      Get.snackbar(
        'OTP Resent!',
        'Check your WhatsApp for the new code',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } else {
      setState(() => _errorMessage = result['error']);
    }
  }

  void _goBack() {
    if (_otpSent) {
      setState(() {
        _otpSent = false;
        _otpController.clear();
        _errorMessage = null;
      });
      _resendTimer?.cancel();
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _goBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // WhatsApp Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.message_rounded,
                    size: 40,
                    color: Color(0xFF25D366),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              Text(
                _otpSent ? 'Enter Verification Code' : 'Login with WhatsApp',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              
              // Subtitle
              Text(
                _otpSent
                    ? 'We\'ve sent a 6-digit code to your WhatsApp\n+$_phoneNumber'
                    : 'Enter your phone number and we\'ll send a verification code to your WhatsApp',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              
              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Phone Number Input or OTP Input
              if (!_otpSent) ...[
                _buildPhoneInput(),
              ] else ...[
                _buildOTPInput(),
              ],
              
              const SizedBox(height: 24),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading 
                      ? null 
                      : (_otpSent ? _verifyOTP : _requestOTP),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _otpSent ? 'Verify Code' : 'Send Code',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              // Resend OTP
              if (_otpSent) ...[
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: _resendCountdown > 0 ? null : _resendOTP,
                    child: Text(
                      _resendCountdown > 0
                          ? 'Resend code in ${_resendCountdown}s'
                          : 'Didn\'t receive code? Resend',
                      style: TextStyle(
                        color: _resendCountdown > 0
                            ? AppColors.textSecondary
                            : const Color(0xFF25D366),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Alternative Login
              Center(
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'Use another login method',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Info Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'We\'ll send a WhatsApp message with a verification code. Standard messaging rates may apply.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
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

  Widget _buildPhoneInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // Country Code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '🇹🇿',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 6),
                Text(
                  '+255',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Phone Input
          Expanded(
            child: TextField(
              controller: _phoneController,
              focusNode: _phoneFocus,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: '712 345 678',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
              onSubmitted: (_) => _requestOTP(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPInput() {
    return Column(
      children: [
        // OTP Input Field
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: _otpController,
            focusNode: _otpFocus,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 16,
            ),
            decoration: const InputDecoration(
              hintText: '• • • • • •',
              hintStyle: TextStyle(
                letterSpacing: 8,
                color: Color(0xFFD1D5DB),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            ),
            onChanged: (value) {
              if (value.length == 6) {
                _verifyOTP();
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        
        // Change Number Link
        TextButton.icon(
          onPressed: _goBack,
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Change phone number'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
