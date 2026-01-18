import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/payment_service.dart';

class WalletController extends GetxController {
  final PaymentService _paymentService = Get.find<PaymentService>();

  final Rx<WalletModel?> wallet = Rx<WalletModel?>(null);
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingTransactions = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Filtering
  final RxString statusFilter = ''.obs;
  final RxInt currentPage = 1.obs;
  final RxBool hasMoreTransactions = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadWallet();
  }

  Future<void> loadWallet() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      wallet.value = await _paymentService.getWallet();
    } catch (e) {
      errorMessage.value = e.toString();
      debugPrint('❌ [WalletController] Error loading wallet: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadTransactions({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      hasMoreTransactions.value = true;
      transactions.clear();
    }

    if (!hasMoreTransactions.value && !refresh) return;

    try {
      isLoadingTransactions.value = true;
      
      final newTransactions = await _paymentService.getTransactions(
        page: currentPage.value,
        pageSize: 20,
        status: statusFilter.value.isEmpty ? null : statusFilter.value,
      );

      if (newTransactions.isEmpty) {
        hasMoreTransactions.value = false;
      } else {
        transactions.addAll(newTransactions);
        currentPage.value++;
      }
    } catch (e) {
      debugPrint('❌ [WalletController] Error loading transactions: $e');
    } finally {
      isLoadingTransactions.value = false;
    }
  }

  void setStatusFilter(String status) {
    statusFilter.value = status;
    loadTransactions(refresh: true);
  }

  Future<void> refresh() async {
    await loadWallet();
    await loadTransactions(refresh: true);
  }
}
