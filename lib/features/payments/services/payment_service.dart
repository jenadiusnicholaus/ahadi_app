import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/api_service.dart';
import '../models/event_wallet_model.dart';

/// Payment provider model
class PaymentProviderModel {
  final int id;
  final String name;
  final String code;
  final String providerType; // MOBILE_MONEY, BANK, CARD
  final bool isActive;

  PaymentProviderModel({
    required this.id,
    required this.name,
    required this.code,
    required this.providerType,
    this.isActive = true,
  });

  String get providerTypeDisplay {
    switch (providerType) {
      case 'MOBILE_MONEY':
        return 'Mobile Money';
      case 'BANK':
        return 'Bank';
      case 'CARD':
        return 'Card';
      default:
        return providerType;
    }
  }

  factory PaymentProviderModel.fromJson(Map<String, dynamic> json) {
    return PaymentProviderModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      providerType: json['provider_type'] ?? 'MOBILE_MONEY',
      isActive: json['is_active'] ?? true,
    );
  }
}

/// Transaction model
class TransactionModel {
  final String reference;
  final String? externalId;
  final int? contributionId;
  final int? eventId;
  final String? eventTitle;
  final int? payerId;
  final String? payerName;
  final String payerPhone;
  final double amount;
  final double? transactionFee;
  final double? netAmount;
  final String paymentMethod;
  final String status; // PENDING, SUCCESS, FAILED
  final String? failureReason;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.reference,
    this.externalId,
    this.contributionId,
    this.eventId,
    this.eventTitle,
    this.payerId,
    this.payerName,
    required this.payerPhone,
    required this.amount,
    this.transactionFee,
    this.netAmount,
    required this.paymentMethod,
    this.status = 'PENDING',
    this.failureReason,
    this.paidAt,
    required this.createdAt,
    required this.updatedAt,
  });

  String get statusDisplay {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'SUCCESS':
        return 'Successful';
      case 'FAILED':
        return 'Failed';
      default:
        return status;
    }
  }

  bool get isPending => status == 'PENDING';
  bool get isSuccess => status == 'SUCCESS';
  bool get isFailed => status == 'FAILED';

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      reference: json['reference'] ?? '',
      externalId: json['external_id'],
      contributionId: json['contribution'],
      eventId: json['event'],
      eventTitle: json['event_title'],
      payerId: json['payer'],
      payerName: json['payer_name'],
      payerPhone: json['payer_phone'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      transactionFee: double.tryParse(
        json['transaction_fee']?.toString() ?? '',
      ),
      netAmount: double.tryParse(json['net_amount']?.toString() ?? ''),
      paymentMethod: json['payment_method'] ?? '',
      status: json['status'] ?? 'PENDING',
      failureReason: json['failure_reason'],
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }
}

/// Checkout response model
class CheckoutResponseModel {
  final bool success;
  final String? message;
  final String? transactionRef;
  final String? externalId;
  final double? amount;
  final double? transactionFee;
  final double? totalAmount;

  CheckoutResponseModel({
    required this.success,
    this.message,
    this.transactionRef,
    this.externalId,
    this.amount,
    this.transactionFee,
    this.totalAmount,
  });

  factory CheckoutResponseModel.fromJson(Map<String, dynamic> json) {
    return CheckoutResponseModel(
      success: json['success'] ?? false,
      message: json['message'],
      transactionRef: json['transaction_ref'],
      externalId: json['external_id'],
      amount: double.tryParse(json['amount']?.toString() ?? ''),
      transactionFee: double.tryParse(
        json['transaction_fee']?.toString() ?? '',
      ),
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? ''),
    );
  }
}

/// Wallet model
class WalletModel {
  final double balance;
  final String currency;
  final double pendingDisbursements;
  final double totalDisbursed;
  final List<TransactionModel> recentTransactions;

  WalletModel({
    required this.balance,
    this.currency = 'TZS',
    this.pendingDisbursements = 0,
    this.totalDisbursed = 0,
    this.recentTransactions = const [],
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final transactionsList = json['recent_transactions'] as List? ?? [];
    return WalletModel(
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0,
      currency: json['currency'] ?? 'TZS',
      pendingDisbursements:
          double.tryParse(json['pending_disbursements']?.toString() ?? '0') ??
          0,
      totalDisbursed:
          double.tryParse(json['total_disbursed']?.toString() ?? '0') ?? 0,
      recentTransactions: transactionsList
          .map((t) => TransactionModel.fromJson(t))
          .toList(),
    );
  }
}

/// Payment service for handling mobile money and bank payments
class PaymentService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  // ============ Mobile Money Checkout ============
  Future<CheckoutResponseModel> checkoutMno({
    required int eventId,
    required double amount,
    required String phone,
    required String provider, // Mpesa, Airtel, Tigo, Halotel
    int? participantId,
    String? participantName,
  }) async {
    try {
      debugPrint(
        '📡 [PaymentService] MNO Checkout: $provider - $phone - $amount',
      );

      final response = await _api.dio.post(
        ApiEndpoints.paymentCheckoutMno,
        data: {
          'event_id': eventId,
          'amount': amount,
          'phone_number': phone,
          'provider': provider,
          if (participantId != null) 'participant_id': participantId,
          if (participantName != null) 'payer_name': participantName,
        },
      );

      debugPrint('📡 [PaymentService] Checkout response: ${response.data}');
      return CheckoutResponseModel.fromJson(response.data);
    } on dio_pkg.DioException catch (e) {
      debugPrint('❌ [PaymentService] DioException: ${e.message}');
      throw _handleError(e);
    }
  }

  // ============ Bank Checkout ============
  Future<CheckoutResponseModel> checkoutBank({
    required int eventId,
    required double amount,
    required String bankName,
    required String accountNumber,
    int? participantId,
    String? participantName,
  }) async {
    try {
      debugPrint(
        '📡 [PaymentService] Bank Checkout: $bankName - $accountNumber - $amount',
      );

      final response = await _api.dio.post(
        ApiEndpoints.paymentCheckoutBank,
        data: {
          'event_id': eventId,
          'amount': amount,
          'provider': bankName,
          'merchant_account_number': accountNumber,
          if (participantId != null) 'participant_id': participantId,
          if (participantName != null) 'payer_name': participantName,
        },
      );

      return CheckoutResponseModel.fromJson(response.data);
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ Get Transaction Fee ============
  Future<Map<String, dynamic>> calculateTransactionFee({
    required double amount,
    required String provider,
  }) async {
    try {
      final response = await _api.dio.get(
        '${ApiEndpoints.paymentCheckoutMno}fee/',
        queryParameters: {'amount': amount, 'provider': provider},
      );
      return response.data;
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ Get Wallet Info ============
  Future<WalletModel> getWallet() async {
    try {
      final response = await _api.dio.get(ApiEndpoints.paymentWallet);
      return WalletModel.fromJson(response.data);
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ Get Transactions ============
  Future<List<TransactionModel>> getTransactions({
    int page = 1,
    int pageSize = 50,
    int? eventId,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (eventId != null) queryParams['event'] = eventId;
      if (status != null) queryParams['status'] = status;

      final response = await _api.dio.get(
        ApiEndpoints.paymentTransactions,
        queryParameters: queryParams,
      );

      final List<dynamic> results = response.data['results'] ?? [];
      return results.map((json) => TransactionModel.fromJson(json)).toList();
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ Disburse Funds ============
  Future<Map<String, dynamic>> disburseEventFunds({
    required int eventId,
    required String phone,
    required String provider,
    double? amount, // If null, disburse all available funds
  }) async {
    try {
      debugPrint('📡 [PaymentService] Disbursing funds for event $eventId');

      final response = await _api.dio.post(
        ApiEndpoints.paymentDisburse(eventId),
        data: {
          'phone': phone,
          'provider': provider,
          if (amount != null) 'amount': amount,
        },
      );

      return response.data;
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ Get Event Contributions (via payments endpoint) ============
  Future<Map<String, dynamic>> getEventContributionStats(int eventId) async {
    try {
      final response = await _api.dio.get(
        ApiEndpoints.paymentEventContributions(eventId),
      );
      return response.data;
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ Event Wallet (Event-level financial data) ============
  
  /// Get event wallet with disbursement history
  Future<EventWalletModel> getEventWallet(int eventId) async {
    try {
      debugPrint('📡 [PaymentService] Getting wallet for event $eventId');
      final response = await _api.dio.get(
        ApiEndpoints.paymentEventDisbursements(eventId),
      );
      
      debugPrint('📡 [PaymentService] Event wallet response: ${response.data}');
      
      final data = response.data['data'] ?? response.data;
      return EventWalletModel.fromJson(data);
    } on dio_pkg.DioException catch (e) {
      debugPrint('❌ [PaymentService] Error getting event wallet: ${e.message}');
      throw _handleError(e);
    }
  }

  /// Get payout summary (gross, fees, net)
  Future<Map<String, dynamic>> getEventPayoutSummary(int eventId) async {
    try {
      final response = await _api.dio.get(
        ApiEndpoints.paymentEventPayout(eventId),
      );
      return response.data['data'] ?? response.data;
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get event transactions (contribution payments)
  Future<List<EventTransactionModel>> getEventTransactions(int eventId) async {
    try {
      final response = await _api.dio.get(
        ApiEndpoints.paymentEventTransactions(eventId),
      );
      
      final data = response.data['data'] ?? response.data;
      final transactions = data['transactions'] as List? ?? [];
      
      return transactions
          .map((t) => EventTransactionModel.fromJson(t))
          .toList();
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all user's disbursements across events
  Future<List<EventDisbursementModel>> getMyDisbursements() async {
    try {
      final response = await _api.dio.get(
        ApiEndpoints.paymentMyDisbursements,
      );
      
      final data = response.data['data'] ?? response.data;
      final disbursements = data['disbursements'] as List? ?? [];
      
      return disbursements
          .map((d) => EventDisbursementModel.fromJson(d))
          .toList();
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ Error Handling ============
  String _handleError(dio_pkg.DioException e) {
    if (e.response?.data is Map) {
      final data = e.response?.data as Map;
      if (data.containsKey('detail')) {
        return data['detail'].toString();
      }
      if (data.containsKey('error')) {
        return data['error'].toString();
      }
      if (data.containsKey('message')) {
        return data['message'].toString();
      }
      // Handle field errors
      final errors = <String>[];
      data.forEach((key, value) {
        if (value is List) {
          errors.add('$key: ${value.join(", ")}');
        } else {
          errors.add('$key: $value');
        }
      });
      if (errors.isNotEmpty) {
        return errors.join('\n');
      }
    }

    switch (e.type) {
      case dio_pkg.DioExceptionType.connectionTimeout:
      case dio_pkg.DioExceptionType.receiveTimeout:
      case dio_pkg.DioExceptionType.sendTimeout:
        return 'Connection timed out. Please try again.';
      case dio_pkg.DioExceptionType.connectionError:
        return 'No internet connection.';
      default:
        return e.message ?? 'An error occurred';
    }
  }
}

/// Mobile money provider options for Tanzania
class MobileMoneyProvider {
  static const String mpesa = 'Mpesa';
  static const String airtel = 'Airtel';
  static const String tigo = 'Tigo';
  static const String halotel = 'Halotel';

  static List<Map<String, String>> get options => [
    {'value': mpesa, 'label': 'M-Pesa (Vodacom)'},
    {'value': airtel, 'label': 'Airtel Money'},
    {'value': tigo, 'label': 'Tigo Pesa'},
    {'value': halotel, 'label': 'Halotel'},
  ];

  /// Get provider from phone number prefix
  static String? detectFromPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.startsWith('255')) {
      final prefix = cleanPhone.substring(3, 5);
      return _getProviderFromPrefix(prefix);
    } else if (cleanPhone.startsWith('0')) {
      final prefix = cleanPhone.substring(1, 3);
      return _getProviderFromPrefix(prefix);
    } else if (cleanPhone.length >= 2) {
      return _getProviderFromPrefix(cleanPhone.substring(0, 2));
    }
    return null;
  }

  static String? _getProviderFromPrefix(String prefix) {
    // Vodacom (M-Pesa): 74, 75, 76
    if (['74', '75', '76'].contains(prefix)) return mpesa;
    // Airtel: 68, 69, 78
    if (['68', '69', '78'].contains(prefix)) return airtel;
    // Tigo: 65, 67, 71
    if (['65', '67', '71'].contains(prefix)) return tigo;
    // Halotel: 62
    if (prefix == '62') return halotel;
    return null;
  }
}
