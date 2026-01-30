import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

/// Service to handle Firebase initialization
class FirebaseService {
  static bool _initialized = false;

  /// Initialize Firebase
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
      rethrow;
    }
  }

  /// Check if Firebase is initialized
  static bool get isInitialized => _initialized;
}
