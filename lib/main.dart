import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'core/bindings/app_bindings.dart';
import 'core/services/storage_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/controllers/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Failed to load .env file: $e');
  }

  // Initialize storage service
  final storageService = StorageService();
  await storageService.init();
  Get.put(storageService);

  // Initialize deep link service
  final deepLinkService = DeepLinkService();
  await deepLinkService.init();
  Get.put(deepLinkService);

  // Initialize theme controller
  final themeController = ThemeController();
  Get.put(themeController);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    
    return Obx(() => GetMaterialApp(
      title: 'Ahadi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: themeController.themeMode,
      initialBinding: AppBindings(),
      getPages: AppPages.pages,
      initialRoute: AppRoutes.publicEvents, // Start with public browse page
      builder: (context, child) {
        return _AuthWrapper(child: child);
      },
    ));
  }
}

class _AuthWrapper extends StatelessWidget {
  final Widget? child;

  const _AuthWrapper({this.child});

  @override
  Widget build(BuildContext context) {
    // Simple wrapper - navigation is handled in auth controller
    return child ?? const SizedBox.shrink();
  }
}
