import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/contribution_model.dart';
import '../models/participant_model.dart';
import '../services/event_service.dart';
import '../../payments/services/payment_service.dart';

class ContributionController extends GetxController {
  final EventService _eventService = Get.find<EventService>();
  late PaymentService _paymentService;

  // State
  final RxList<ContributionModel> contributions = <ContributionModel>[].obs;
  final RxList<ParticipantModel> participants = <ParticipantModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString error = ''.obs;
  final RxInt currentPage = 1.obs;
  final RxBool hasMore = true.obs;
  final RxInt eventId = 0.obs;

  // Filters
  final RxString statusFilter = ''.obs;
  final RxString kindFilter = ''.obs;

  // Stats
  final RxDouble totalAmount = 0.0.obs;
  final RxInt confirmedCount = 0.obs;
  final RxInt pendingCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize PaymentService if not already registered
    if (!Get.isRegistered<PaymentService>()) {
      Get.put(PaymentService());
    }
    _paymentService = Get.find<PaymentService>();
  }

  /// Initialize with event ID
  void init(int id) {
    eventId.value = id;
    refresh();
  }

  /// Refresh all data
  @override
  Future<void> refresh() async {
    if (eventId.value == 0) return;

    currentPage.value = 1;
    hasMore.value = true;
    error.value = '';

    await Future.wait([_loadContributions(), _loadParticipants()]);
  }

  /// Load contributions with stats
  Future<void> _loadContributions() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      error.value = '';

      final result = await _eventService.getEventContributionsWithStats(
        eventId.value,
        status: statusFilter.value.isEmpty ? null : statusFilter.value,
        kind: kindFilter.value.isEmpty ? null : kindFilter.value,
      );

      final contributionsList =
          result['contributions'] as List<ContributionModel>;
      final stats = result['stats'] as Map<String, dynamic>;

      contributions.value = contributionsList;

      // Update stats from backend
      final cashTotal =
          double.tryParse(stats['cash_total']?.toString() ?? '0') ?? 0;
      totalAmount.value = cashTotal;
      confirmedCount.value = stats['confirmed_contributions'] ?? 0;
      pendingCount.value =
          (stats['total_contributions'] ?? 0) -
          (stats['confirmed_contributions'] ?? 0);

      hasMore.value = false; // Backend doesn't paginate yet
    } catch (e) {
      error.value = e.toString();
      debugPrint('Error loading contributions: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more contributions (pagination)
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;

    try {
      isLoadingMore.value = true;
      currentPage.value++;

      final result = await _eventService.getEventContributions(
        eventId.value,
        page: currentPage.value,
        pageSize: 50,
        status: statusFilter.value.isEmpty ? null : statusFilter.value,
        kind: kindFilter.value.isEmpty ? null : kindFilter.value,
      );

      contributions.addAll(result);
      hasMore.value = result.length >= 50;
    } catch (e) {
      error.value = e.toString();
      currentPage.value--;
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Load participants for dropdown
  Future<void> _loadParticipants() async {
    try {
      final result = await _eventService.getEventParticipants(eventId.value);
      participants.value = result;
    } catch (e) {
      debugPrint('Error loading participants: $e');
    }
  }

  /// Calculate stats
  void _calculateStats() {
    totalAmount.value = contributions
        .where((c) => c.isConfirmed)
        .fold(0.0, (sum, c) => sum + c.amount);
    confirmedCount.value = contributions.where((c) => c.isConfirmed).length;
    pendingCount.value = contributions.where((c) => c.isPending).length;
  }

  /// Set status filter
  void setStatusFilter(String status) {
    statusFilter.value = status;
    refresh();
  }

  /// Set kind filter
  void setKindFilter(String kind) {
    kindFilter.value = kind;
    refresh();
  }

  /// Clear filters
  void clearFilters() {
    statusFilter.value = '';
    kindFilter.value = '';
    refresh();
  }

  /// Add manual contribution (cash, item, service)
  Future<bool> addManualContribution({
    required double amount,
    required String kind,
    int? participantId,
    String? participantName,
    String? participantPhone,
    String? itemDescription,
    double? estimatedValue,
    String? paymentReference,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final contribution = ContributionModel(
        id: 0,
        eventId: eventId.value,
        participantId: participantId,
        participantName: participantName,
        participantPhone: participantPhone,
        amount: amount,
        kind: kind,
        status: 'CONFIRMED', // Manual contributions are confirmed immediately
        itemDescription: itemDescription,
        estimatedValue: estimatedValue,
        paymentReference: paymentReference,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _eventService.addContribution(contribution);
      await refresh();

      Get.snackbar(
        'Success',
        'Contribution added successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Initiate mobile money payment
  Future<CheckoutResponseModel?> initiateMobilePayment({
    required double amount,
    required String phone,
    required String provider,
    int? participantId,
    String? participantName,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final result = await _paymentService.checkoutMno(
        eventId: eventId.value,
        amount: amount,
        phone: phone,
        provider: provider,
        participantId: participantId,
        participantName: participantName,
      );

      if (result.success) {
        Get.snackbar(
          'Payment Initiated',
          'Please check your phone to complete the payment',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        // Refresh after a delay to check for payment confirmation
        Future.delayed(const Duration(seconds: 30), refresh);
        return result;
      } else {
        error.value = result.message ?? 'Payment initiation failed';
        Get.snackbar(
          'Payment Failed',
          result.message ?? 'Payment initiation failed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return null;
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Calculate transaction fee
  Future<Map<String, dynamic>?> calculateFee({
    required double amount,
    required String provider,
  }) async {
    try {
      return await _paymentService.calculateTransactionFee(
        amount: amount,
        provider: provider,
      );
    } catch (e) {
      debugPrint('Error calculating fee: $e');
      return null;
    }
  }

  /// Update contribution status
  Future<bool> updateContributionStatus(
    int contributionId,
    String status,
  ) async {
    try {
      await _eventService.updateContribution(contributionId, {
        'status': status,
      });
      await refresh();
      return true;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Delete contribution
  Future<bool> deleteContribution(int contributionId) async {
    try {
      await _eventService.deleteContribution(contributionId);
      contributions.removeWhere((c) => c.id == contributionId);
      _calculateStats();
      Get.snackbar(
        'Success',
        'Contribution deleted',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Get participant by ID
  ParticipantModel? getParticipant(int? participantId) {
    if (participantId == null) return null;
    try {
      return participants.firstWhere((p) => p.id == participantId);
    } catch (_) {
      return null;
    }
  }

  /// Format currency
  String formatAmount(double amount, {String currency = 'TZS'}) {
    if (currency == 'TZS') {
      return 'TZS ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }
    return '$currency ${amount.toStringAsFixed(2)}';
  }
}
