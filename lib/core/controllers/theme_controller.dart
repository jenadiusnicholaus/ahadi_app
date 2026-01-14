import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/storage_service.dart';

/// Controller for managing app theme (light/dark mode)
class ThemeController extends GetxController {
  final StorageService _storageService = Get.find();
  
  // Observable theme mode
  final Rx<ThemeMode> _themeMode = ThemeMode.system.obs;
  ThemeMode get themeMode => _themeMode.value;
  
  // Convenience getters
  bool get isDarkMode => _themeMode.value == ThemeMode.dark;
  bool get isLightMode => _themeMode.value == ThemeMode.light;
  bool get isSystemMode => _themeMode.value == ThemeMode.system;
  
  @override
  void onInit() {
    super.onInit();
    _loadThemeFromStorage();
  }
  
  /// Load saved theme preference from storage
  Future<void> _loadThemeFromStorage() async {
    final themeString = await _storageService.getThemeMode();
    if (themeString != null) {
      _themeMode.value = _themeModeFromString(themeString);
    }
  }
  
  /// Change theme mode and persist to storage
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode.value = mode;
    await _storageService.saveThemeMode(_themeModeToString(mode));
    Get.changeThemeMode(mode);
  }
  
  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    if (isDarkMode) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
  
  /// Set to light mode
  Future<void> setLightMode() async {
    await setThemeMode(ThemeMode.light);
  }
  
  /// Set to dark mode
  Future<void> setDarkMode() async {
    await setThemeMode(ThemeMode.dark);
  }
  
  /// Set to system mode (follow device settings)
  Future<void> setSystemMode() async {
    await setThemeMode(ThemeMode.system);
  }
  
  // Helper methods to convert ThemeMode to/from string
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
  
  ThemeMode _themeModeFromString(String modeString) {
    switch (modeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }
}
