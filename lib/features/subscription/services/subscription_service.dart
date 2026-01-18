import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';
import '../models/subscription_plan_model.dart';

class SubscriptionService {
  final ApiService _apiService;

  SubscriptionService(this._apiService);

  /// Get all available subscription plans
  Future<Map<String, dynamic>> getPlans() async {
    try {
      final response = await _apiService.get('/payments/subscriptions/plans/');

      if (response.statusCode == 200) {
        final data = response.data;
        final plansJson = data['plans'] as List<dynamic>? ?? [];
        final plans = plansJson
            .map((json) => SubscriptionPlanModel.fromJson(json))
            .toList();

        return {'success': true, 'plans': plans};
      }

      return {'success': false, 'message': 'Failed to load plans'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get current user's subscription
  Future<Map<String, dynamic>> getMySubscription() async {
    try {
      final response = await _apiService.get('/payments/subscriptions/my/');

      if (response.statusCode == 200) {
        final data = response.data;

        UserSubscriptionModel? subscription;
        if (data['has_subscription'] == true && data['subscription'] != null) {
          subscription = UserSubscriptionModel.fromJson(data['subscription']);
        }

        return {
          'success': true,
          'hasSubscription': data['has_subscription'] ?? false,
          'subscription': subscription,
          'recommendation': data['recommendation'],
        };
      }

      return {'success': false, 'message': 'Failed to load subscription'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Subscribe to a plan via MNO (Mobile Money)
  Future<Map<String, dynamic>> subscribeMNO({
    required int planId,
    required String billingCycle, // 'MONTHLY' or 'YEARLY'
    required String provider, // 'Mpesa', 'Tigopesa', 'Airtel', 'Halopesa'
    required String accountNumber,
  }) async {
    try {
      final response = await _apiService.post(
        '/payments/subscriptions/checkout/mno/',
        data: {
          'plan_id': planId,
          'billing_cycle': billingCycle,
          'provider': provider,
          'account_number': accountNumber,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return {
            'success': true,
            'message':
                data['message'] ??
                'Payment initiated. Please check your phone for the payment prompt.',
            'transactionReference': data['transaction_reference'],
            'plan': data['plan'],
            'amount': data['amount'],
            'currency': data['currency'],
          };
        }
        // API returned success=false
        return {
          'success': false,
          'message': _getPaymentErrorMessage(data['error']),
        };
      }

      // Non-200 status code
      final errorMsg = response.data?['error'] ?? response.data?['message'];
      return {'success': false, 'message': _getPaymentErrorMessage(errorMsg)};
    } on DioException catch (e) {
      // Handle Dio-specific errors
      return {'success': false, 'message': _getDioErrorMessage(e)};
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again later.',
      };
    }
  }

  /// Convert backend error messages to user-friendly messages
  String _getPaymentErrorMessage(String? error) {
    if (error == null || error.isEmpty) {
      return 'Payment could not be processed. Please try again.';
    }

    final lowerError = error.toLowerCase();

    if (lowerError.contains('empty response') ||
        lowerError.contains('no response')) {
      return 'The payment service is temporarily unavailable. Please try again in a few minutes.';
    }
    if (lowerError.contains('timeout') || lowerError.contains('timed out')) {
      return 'The payment request timed out. Please check your connection and try again.';
    }
    if (lowerError.contains('invalid') && lowerError.contains('phone')) {
      return 'Please enter a valid phone number for your mobile money account.';
    }
    if (lowerError.contains('invalid') && lowerError.contains('provider')) {
      return 'The selected payment provider is not available. Please choose another.';
    }
    if (lowerError.contains('insufficient') || lowerError.contains('balance')) {
      return 'Insufficient balance in your mobile money account.';
    }
    if (lowerError.contains('limit')) {
      return 'Transaction limit exceeded. Please try a smaller amount or contact your provider.';
    }
    if (lowerError.contains('blocked') || lowerError.contains('suspended')) {
      return 'Your mobile money account appears to be blocked. Please contact your provider.';
    }
    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    if (lowerError.contains('unauthorized') ||
        lowerError.contains('authentication')) {
      return 'Session expired. Please log in again and retry.';
    }

    // Return a generic but friendly message if we can't match
    return 'Payment could not be processed: $error';
  }

  /// Convert Dio errors to user-friendly messages
  String _getDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your internet and try again.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to the server. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        if (data is Map) {
          return _getPaymentErrorMessage(
            data['error']?.toString() ?? data['message']?.toString(),
          );
        }
        return 'The server returned an error. Please try again later.';
      case DioExceptionType.cancel:
        return 'Request was cancelled. Please try again.';
      default:
        return 'An error occurred. Please try again later.';
    }
  }

  /// Get available payment providers
  Future<Map<String, dynamic>> getPaymentProviders() async {
    try {
      final response = await _apiService.get('/payments/providers/');

      if (response.statusCode == 200) {
        final data = response.data;
        return {'success': true, 'providers': data['providers'] ?? []};
      }

      return {'success': false, 'message': 'Failed to load providers'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
