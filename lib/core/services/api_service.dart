import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Track if we're currently refreshing to avoid multiple refresh calls
  bool _isRefreshing = false;
  // Queue of requests waiting for token refresh
  final List<_RetryRequest> _pendingRequests = [];

  // Expose Dio for direct access if needed
  Dio get dio => _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        // Timeouts from .env config (sandbox = 5 min, production = 1 min)
        connectTimeout: Duration(seconds: AppConfig.connectTimeoutSeconds),
        receiveTimeout: Duration(seconds: AppConfig.receiveTimeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add logging interceptor in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }

    // Add auth interceptor
    _dio.interceptors.add(_AuthInterceptor(this));
  }

  /// Add auth token to request headers
  Future<void> addAuthHeader(RequestOptions options) async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
  }

  /// Handle 401 error with token refresh and retry
  Future<Response<dynamic>?> handleUnauthorized(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = error.requestOptions;

    // Don't retry if it's a refresh token request (avoid infinite loop)
    if (requestOptions.path.contains('/token/refresh')) {
      await clearTokens();
      handler.reject(error);
      return null;
    }

    // If already refreshing, queue this request
    if (_isRefreshing) {
      final completer = Completer<Response<dynamic>>();
      _pendingRequests.add(_RetryRequest(requestOptions, completer));
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final refreshed = await _refreshToken();

      if (refreshed) {
        // Retry the original request
        final token = await _storage.read(key: StorageKeys.accessToken);
        requestOptions.headers['Authorization'] = 'Bearer $token';

        final response = await _dio.fetch(requestOptions);

        // Process pending requests
        _processPendingRequests(token);

        return response;
      } else {
        // Refresh failed - reject all pending requests
        _rejectPendingRequests(error);
        handler.reject(error);
        return null;
      }
    } catch (e) {
      _rejectPendingRequests(error);
      handler.reject(error);
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Process all pending requests after successful token refresh
  void _processPendingRequests(String? token) {
    for (final request in _pendingRequests) {
      request.options.headers['Authorization'] = 'Bearer $token';
      _dio
          .fetch(request.options)
          .then(
            (response) => request.completer.complete(response),
            onError: (e) => request.completer.completeError(e),
          );
    }
    _pendingRequests.clear();
  }

  /// Reject all pending requests when refresh fails
  void _rejectPendingRequests(DioException error) {
    for (final request in _pendingRequests) {
      request.completer.completeError(error);
    }
    _pendingRequests.clear();
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('No refresh token available');
        return false;
      }

      debugPrint('Attempting to refresh token...');

      // Create a new Dio instance to avoid interceptor loop
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final newAccessToken = data['access'];
        final newRefreshToken =
            data['refresh']; // If server rotates refresh tokens

        await _storage.write(
          key: StorageKeys.accessToken,
          value: newAccessToken,
        );

        // Update refresh token if provided (for rotating refresh tokens)
        if (newRefreshToken != null) {
          await _storage.write(
            key: StorageKeys.refreshToken,
            value: newRefreshToken,
          );
        }

        debugPrint('Token refreshed successfully');
        return true;
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      await clearTokens();
    }
    return false;
  }

  /// Check if user has valid tokens
  Future<bool> hasValidTokens() async {
    final accessToken = await _storage.read(key: StorageKeys.accessToken);
    final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
    return accessToken != null && refreshToken != null;
  }

  /// Clear all stored tokens (used when refresh fails or on logout)
  Future<void> clearTokens() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    debugPrint('Tokens cleared');
  }

  /// Save tokens after login
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: StorageKeys.accessToken, value: accessToken);
    await _storage.write(key: StorageKeys.refreshToken, value: refreshToken);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
}

/// Auth interceptor that handles token injection and refresh
class _AuthInterceptor extends Interceptor {
  final ApiService _apiService;

  _AuthInterceptor(this._apiService);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add auth token to request
    await _apiService.addAuthHeader(options);
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized - try to refresh token
    if (err.response?.statusCode == 401) {
      try {
        final response = await _apiService.handleUnauthorized(err, handler);
        if (response != null) {
          return handler.resolve(response);
        }
        // If response is null, handler.reject was already called
        return;
      } catch (e) {
        return handler.reject(err);
      }
    }

    handler.next(err);
  }
}

/// Helper class to track pending requests during token refresh
class _RetryRequest {
  final RequestOptions options;
  final Completer<Response<dynamic>> completer;

  _RetryRequest(this.options, this.completer);
}
