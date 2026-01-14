import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Secure storage methods (for tokens, sensitive data)
  Future<void> saveSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> readSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<void> clearSecure() async {
    await _secureStorage.deleteAll();
  }

  // Token management
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await saveSecure(StorageKeys.accessToken, accessToken);
    await saveSecure(StorageKeys.refreshToken, refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await readSecure(StorageKeys.accessToken);
  }

  Future<String?> getRefreshToken() async {
    return await readSecure(StorageKeys.refreshToken);
  }

  Future<void> clearTokens() async {
    await deleteSecure(StorageKeys.accessToken);
    await deleteSecure(StorageKeys.refreshToken);
  }

  // User data management
  Future<void> saveUser(Map<String, dynamic> user) async {
    await _prefs?.setString(StorageKeys.user, jsonEncode(user));
  }

  Map<String, dynamic>? getUser() {
    final userStr = _prefs?.getString(StorageKeys.user);
    if (userStr != null) {
      return jsonDecode(userStr);
    }
    return null;
  }

  Future<void> clearUser() async {
    await _prefs?.remove(StorageKeys.user);
  }

  // General preferences
  Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  String? getString(String key) {
    return _prefs?.getString(key);
  }

  // First launch check
  bool get isFirstLaunch {
    return _prefs?.getBool(StorageKeys.isFirstLaunch) ?? true;
  }

  Future<void> setFirstLaunchComplete() async {
    await _prefs?.setBool(StorageKeys.isFirstLaunch, false);
  }

  // Theme mode management
  Future<void> saveThemeMode(String themeMode) async {
    await _prefs?.setString(StorageKeys.themeMode, themeMode);
  }

  Future<String?> getThemeMode() async {
    return _prefs?.getString(StorageKeys.themeMode);
  }

  // Clear all data
  Future<void> clearAll() async {
    await clearSecure();
    await _prefs?.clear();
  }
}
