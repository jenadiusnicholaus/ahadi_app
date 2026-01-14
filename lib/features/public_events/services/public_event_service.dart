import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/api_service.dart';
import '../../events/models/event_model.dart';
import '../../events/models/event_type_model.dart';

/// Paginated response wrapper
class PaginatedResponse<T> {
  final List<T> items;
  final int? nextPage;
  final int totalCount;
  final bool hasMore;

  PaginatedResponse({
    required this.items,
    this.nextPage,
    required this.totalCount,
    required this.hasMore,
  });
}

class PublicEventService {
  final ApiService _apiService;
  static const int pageSize = 10;

  PublicEventService(this._apiService);

  /// Get all public events with pagination (no auth required)
  Future<PaginatedResponse<EventModel>> getPublicEvents({
    int page = 1,
    int? eventTypeId,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (eventTypeId != null) queryParams['event_type'] = eventTypeId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      debugPrint(
        '📡 [PublicEventService] Fetching public events: $queryParams',
      );

      final response = await _apiService.dio.get(
        ApiEndpoints.publicEvents,
        queryParameters: queryParams,
      );

      debugPrint(
        '📡 [PublicEventService] Response status: ${response.statusCode}',
      );
      debugPrint(
        '📡 [PublicEventService] Response data type: ${response.data.runtimeType}',
      );

      List eventsJson;
      int totalCount = 0;
      bool hasMore = false;

      // Handle DRF's standard pagination response: { count, next, previous, results }
      if (response.data is Map && response.data['results'] != null) {
        eventsJson = response.data['results'] as List;
        totalCount = response.data['count'] ?? eventsJson.length;
        hasMore = response.data['next'] != null;
        debugPrint(
          '📡 [PublicEventService] DRF pagination - count: $totalCount, hasMore: $hasMore, items: ${eventsJson.length}',
        );
      } else if (response.data is Map && response.data['success'] == true) {
        // Handle custom response format: { success, data: { results, ... } }
        final data = response.data['data'];
        if (data is Map && data['results'] != null) {
          eventsJson = data['results'] as List;
          totalCount = data['count'] ?? eventsJson.length;
          hasMore = data['has_next'] ?? (data['next'] != null);
        } else if (data is List) {
          eventsJson = data;
          totalCount = eventsJson.length;
          hasMore = false;
        } else {
          eventsJson = [];
        }
        debugPrint(
          '📡 [PublicEventService] Custom format - count: $totalCount, items: ${eventsJson.length}',
        );
      } else if (response.data is List) {
        eventsJson = response.data as List;
        totalCount = eventsJson.length;
        hasMore = false;
        debugPrint(
          '📡 [PublicEventService] Direct list - items: ${eventsJson.length}',
        );
      } else {
        eventsJson = [];
        debugPrint(
          '📡 [PublicEventService] Unknown format, returning empty list',
        );
        debugPrint('📡 [PublicEventService] Response data: ${response.data}');
      }

      // Parse events with error handling for each item
      final events = <EventModel>[];
      for (int i = 0; i < eventsJson.length; i++) {
        try {
          final event = EventModel.fromJson(
            eventsJson[i] as Map<String, dynamic>,
          );
          events.add(event);
        } catch (e) {
          debugPrint(
            '❌ [PublicEventService] Error parsing event at index $i: $e',
          );
          debugPrint('❌ [PublicEventService] Event data: ${eventsJson[i]}');
        }
      }

      debugPrint(
        '✅ [PublicEventService] Successfully parsed ${events.length} events',
      );

      return PaginatedResponse(
        items: events,
        nextPage: hasMore ? page + 1 : null,
        totalCount: totalCount,
        hasMore: hasMore,
      );
    } on DioException catch (e) {
      debugPrint('❌ [PublicEventService] DioException: ${e.message}');
      debugPrint('❌ [PublicEventService] Response: ${e.response?.data}');
      throw Exception(e.response?.data?['message'] ?? 'Network error occurred');
    } catch (e, stackTrace) {
      debugPrint('❌ [PublicEventService] Error: $e');
      debugPrint('❌ [PublicEventService] StackTrace: $stackTrace');
      throw Exception('An error occurred: $e');
    }
  }

  /// Get event types (no auth required)
  Future<Map<String, dynamic>> getEventTypes() async {
    try {
      debugPrint('📡 [PublicEventService] Fetching event types');
      final response = await _apiService.dio.get(ApiEndpoints.eventTypes);

      debugPrint(
        '📡 [PublicEventService] Event types response: ${response.data.runtimeType}',
      );

      final data = response.data;
      List typesJson;

      // Handle DRF pagination format: { count, next, previous, results }
      if (data is Map && data['results'] != null) {
        typesJson = data['results'] as List;
        debugPrint(
          '📡 [PublicEventService] DRF pagination format - ${typesJson.length} types',
        );
      } else if (data is List) {
        // Direct array
        typesJson = data;
        debugPrint(
          '📡 [PublicEventService] Direct list format - ${typesJson.length} types',
        );
      } else if (data is Map && data['data'] != null) {
        // Custom format: { success: true, data: [...] }
        typesJson = data['data'] as List;
        debugPrint(
          '📡 [PublicEventService] Custom format - ${typesJson.length} types',
        );
      } else {
        typesJson = [];
        debugPrint('❌ [PublicEventService] Unknown format, empty list');
        debugPrint('❌ [PublicEventService] Response data: $data');
      }

      final eventTypes = typesJson
          .map((e) => EventTypeModel.fromJson(e))
          .toList();
      debugPrint(
        '✅ [PublicEventService] Parsed ${eventTypes.length} event types',
      );

      return {'success': true, 'eventTypes': eventTypes};
    } on DioException catch (e) {
      debugPrint(
        '❌ [PublicEventService] DioException fetching event types: ${e.message}',
      );
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      debugPrint('❌ [PublicEventService] Error fetching event types: $e');
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  /// Get event details by ID (no auth required for public events)
  Future<Map<String, dynamic>> getEventById(int eventId) async {
    try {
      final response = await _apiService.dio.get(
        ApiEndpoints.eventDetail(eventId),
      );

      if (response.data['success'] == true) {
        return {
          'success': true,
          'event': EventModel.fromJson(response.data['data']),
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Event not found',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  /// Get event details by join code (no auth required)
  Future<Map<String, dynamic>> getEventByJoinCode(String joinCode) async {
    try {
      final response = await _apiService.dio.get(
        ApiEndpoints.eventJoinInfo(joinCode.toUpperCase()),
      );

      if (response.data['success'] == true) {
        return {
          'success': true,
          'event': EventModel.fromJson(response.data['data']),
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Event not found',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  /// Join event publicly (no auth required)
  Future<Map<String, dynamic>> joinEventPublic({
    required String joinCode,
    required String name,
    required String phone,
    String? email,
  }) async {
    try {
      final response = await _apiService.dio.post(
        ApiEndpoints.eventJoinRegister(joinCode.toUpperCase()),
        data: {
          'name': name,
          'phone': phone,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );

      if (response.data['success'] == true) {
        return {
          'success': true,
          'data': response.data['data'],
          'message': response.data['message'],
          'alreadyJoined': response.data['data']['already_joined'] ?? false,
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to join event',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  /// Get app info (stats for landing page)
  Future<Map<String, dynamic>> getAppInfo() async {
    try {
      final response = await _apiService.dio.get(ApiEndpoints.publicInfo);

      if (response.data['success'] == true) {
        return {'success': true, 'data': response.data['data']};
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to fetch app info',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // ==================== PUBLIC CONTRIBUTION ====================

  /// Get event details for public contribution (no login, no join required)
  Future<Map<String, dynamic>> getEventForContribution(String joinCode) async {
    try {
      debugPrint(
        '📡 [PublicEventService] Fetching event for contribution: $joinCode',
      );
      final response = await _apiService.dio.get(
        ApiEndpoints.eventContributeInfo(joinCode),
      );

      if (response.data['success'] == true) {
        return {'success': true, 'data': response.data['data']};
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to fetch event',
      };
    } on DioException catch (e) {
      debugPrint('❌ [PublicEventService] Error: ${e.response?.data}');
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Event not found',
      };
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  /// Make a public contribution (no login, no join required)
  Future<Map<String, dynamic>> makePublicContribution({
    required int eventId,
    required double amount,
    required String provider,
    required String phoneNumber,
    String? payerName,
    String? message,
  }) async {
    try {
      debugPrint(
        '📡 [PublicEventService] Making public contribution to event $eventId',
      );

      final response = await _apiService.dio.post(
        ApiEndpoints.paymentCheckoutMno,
        data: {
          'event_id': eventId,
          'amount': amount,
          'provider': provider,
          'phone_number': phoneNumber,
          'payer_name': payerName ?? '',
          'message': message ?? '',
        },
      );

      if (response.data['success'] == true) {
        return {'success': true, 'data': response.data['data']};
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to process contribution',
      };
    } on DioException catch (e) {
      debugPrint(
        '❌ [PublicEventService] Contribution error: ${e.response?.data}',
      );
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Payment failed',
      };
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }
}
