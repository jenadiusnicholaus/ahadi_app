import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/subscription_plan_model.dart';
import '../services/subscription_service.dart';
import '../../profile/controllers/profile_controller.dart';

class SubscriptionController extends GetxController {
  final SubscriptionService _subscriptionService;

  SubscriptionController({required SubscriptionService subscriptionService})
      : _subscriptionService = subscriptionService;

  // Observable states
  final RxBool isLoading = false.obs;
  final RxBool isProcessing = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;

  // Plans
  final RxList<SubscriptionPlanModel> plans = <SubscriptionPlanModel>[].obs;
  final Rx<UserSubscriptionModel?> currentSubscription = Rx<UserSubscriptionModel?>(null);
  final RxBool hasSubscription = false.obs;

  // Payment
  final RxList<Map<String, dynamic>> paymentProviders = <Map<String, dynamic>>[].obs;
  final Rx<SubscriptionPlanModel?> selectedPlan = Rx<SubscriptionPlanModel?>(null);
  final RxString selectedBillingCycle = 'MONTHLY'.obs;
  final RxString selectedProvider = 'Tigo'.obs;  // Default to Tigo
  final phoneController = TextEditingController();

  // Recommendation
  final Rx<Map<String, dynamic>?> recommendation = Rx<Map<String, dynamic>?>(null);

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await Future.wait([
        loadPlans(),
        loadMySubscription(),
        loadPaymentProviders(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadPlans() async {
    final result = await _subscriptionService.getPlans();
    if (result['success'] == true) {
      plans.value = result['plans'] as List<SubscriptionPlanModel>;
    } else {
      errorMessage.value = result['message'] ?? 'Failed to load plans';
    }
  }

  Future<void> loadMySubscription() async {
    final result = await _subscriptionService.getMySubscription();
    if (result['success'] == true) {
      hasSubscription.value = result['hasSubscription'] ?? false;
      currentSubscription.value = result['subscription'];
      recommendation.value = result['recommendation'];
    }
  }

  Future<void> loadPaymentProviders() async {
    final result = await _subscriptionService.getPaymentProviders();
    if (result['success'] == true) {
      final providers = result['providers'] as List<dynamic>? ?? [];
      paymentProviders.value = providers.cast<Map<String, dynamic>>();
      
      // Select first provider by default
      if (paymentProviders.isNotEmpty) {
        selectedProvider.value = paymentProviders.first['provider'] ?? '';
      }
    }
  }

  void selectPlan(SubscriptionPlanModel plan) {
    selectedPlan.value = plan;
  }

  void selectBillingCycle(String cycle) {
    selectedBillingCycle.value = cycle;
  }

  void selectProvider(String provider) {
    selectedProvider.value = provider;
  }

  double get selectedPlanPrice {
    if (selectedPlan.value == null) return 0;
    return selectedBillingCycle.value == 'YEARLY'
        ? selectedPlan.value!.priceYearly
        : selectedPlan.value!.priceMonthly;
  }

  String get currentPlanType {
    return currentSubscription.value?.planType ?? 'FREE';
  }

  bool canUpgradeTo(SubscriptionPlanModel plan) {
    // Order: FREE < BASIC < PREMIUM < INSTITUTIONAL
    const planOrder = ['FREE', 'BASIC', 'PREMIUM', 'INSTITUTIONAL'];
    final currentIndex = planOrder.indexOf(currentPlanType);
    final targetIndex = planOrder.indexOf(plan.planType);
    return targetIndex > currentIndex;
  }

  Future<bool> subscribe() async {
    if (selectedPlan.value == null) {
      errorMessage.value = 'Please select a plan';
      return false;
    }

    if (selectedPlan.value!.isFree) {
      errorMessage.value = 'This plan is free';
      return false;
    }

    if (selectedProvider.value.isEmpty) {
      errorMessage.value = 'Please select a payment method';
      return false;
    }

    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      errorMessage.value = 'Please enter your phone number';
      return false;
    }

    isProcessing.value = true;
    errorMessage.value = '';
    successMessage.value = '';

    try {
      final result = await _subscriptionService.subscribeMNO(
        planId: selectedPlan.value!.id,
        billingCycle: selectedBillingCycle.value,
        provider: selectedProvider.value,
        accountNumber: phone,
      );

      if (result['success'] == true) {
        successMessage.value = result['message'] ?? 'Subscription activated!';
        
        // Refresh subscription status
        await loadMySubscription();
        
        // Refresh profile to update subscription info
        if (Get.isRegistered<ProfileController>()) {
          Get.find<ProfileController>().loadProfile();
        }
        
        Get.snackbar(
          'Success',
          successMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        
        return true;
      } else {
        errorMessage.value = result['message'] ?? 'Subscription failed';
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isProcessing.value = false;
    }
  }

  /// Calculate savings percentage for yearly billing
  int getYearlySavingsPercent(SubscriptionPlanModel plan) {
    if (plan.priceMonthly == 0) return 0;
    final monthlyTotal = plan.priceMonthly * 12;
    final savings = ((monthlyTotal - plan.priceYearly) / monthlyTotal * 100).round();
    return savings;
  }
}
