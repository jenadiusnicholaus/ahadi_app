import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../services/profile_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure dependencies are available
    if (!Get.isRegistered<ApiService>()) {
      Get.lazyPut<ApiService>(() => ApiService());
    }
    if (!Get.isRegistered<StorageService>()) {
      Get.lazyPut<StorageService>(() => StorageService());
    }

    // Register ProfileService
    Get.lazyPut<ProfileService>(
      () => ProfileService(
        apiService: Get.find<ApiService>(),
        storageService: Get.find<StorageService>(),
      ),
    );

    // Register ProfileController
    Get.lazyPut<ProfileController>(
      () => ProfileController(profileService: Get.find<ProfileService>()),
    );
  }
}
