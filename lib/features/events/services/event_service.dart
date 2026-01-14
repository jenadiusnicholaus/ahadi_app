import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/api_service.dart';
import '../models/event_model.dart';
import '../models/event_type_model.dart';
import '../models/participant_model.dart';
import '../models/contribution_model.dart';
import '../models/invitation_model.dart';
import '../models/message_model.dart';
import '../models/reminder_model.dart';

class EventService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  // ============ Event Types ============
  Future<List<EventTypeModel>> getEventTypes() async {
    try {
      final response = await _api.dio.get(ApiEndpoints.eventTypes);
      final List<dynamic> data = response.data['results'] ?? response.data;
      return data.map((json) => EventTypeModel.fromJson(json)).toList();
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ Events CRUD ============
  Future<List<EventModel>> getMyEvents({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? search,
  }) async {
    try {
      debugPrint(
        '📡 [EventService] Fetching my events from: ${ApiEndpoints.myEvents}',
      );

      final response = await _api.dio.get(ApiEndpoints.myEvents);

      debugPrint('📡 [EventService] Response status: ${response.statusCode}');
      debugPrint('📡 [EventService] Response data keys: ${response.data.keys}');

      // Backend returns {'success': true, 'data': [...]}
      final List<dynamic> results =
          response.data['data'] ?? response.data['results'] ?? [];
      debugPrint('📡 [EventService] Got ${results.length} events');

      final events = <EventModel>[];
      for (int i = 0; i < results.length; i++) {
        try {
          events.add(EventModel.fromJson(results[i]));
        } catch (e) {
          debugPrint('❌ [EventService] Error parsing event $i: $e');
          debugPrint('❌ [EventService] Event data: ${results[i]}');
        }
      }
      return events;
    } on dio_pkg.DioException catch (e) {
      debugPrint('❌ [EventService] DioException: ${e.message}');
      throw _handleError(e);
    }
  }

  Future<List<EventModel>> getInvitedEvents({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      debugPrint('📡 [EventService] Fetching invited events');

      final response = await _api.dio.get(
        ApiEndpoints.events,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          'participating': 'true',
        },
      );

      final List<dynamic> results = response.data['results'] ?? [];
      debugPrint('📡 [EventService] Got ${results.length} invited events');

      final events = <EventModel>[];
      for (int i = 0; i < results.length; i++) {
        try {
          events.add(EventModel.fromJson(results[i]));
        } catch (e) {
          debugPrint('❌ [EventService] Error parsing invited event $i: $e');
        }
      }
      return events;
    } on dio_pkg.DioException catch (e) {
      debugPrint('❌ [EventService] DioException: ${e.message}');
      throw _handleError(e);
    }
  }

  Future<List<EventModel>> getPublicEvents({
    int page = 1,
    int pageSize = 20,
    String? search,
    int? eventTypeId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'visibility': 'PUBLIC',
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (eventTypeId != null) queryParams['event_type'] = eventTypeId;

      debugPrint('📡 [EventService] Fetching public events: $queryParams');

      final response = await _api.dio.get(
        ApiEndpoints.events,
        queryParameters: queryParams,
      );

      final List<dynamic> results = response.data['results'] ?? [];
      debugPrint('📡 [EventService] Got ${results.length} public events');

      final events = <EventModel>[];
      for (int i = 0; i < results.length; i++) {
        try {
          events.add(EventModel.fromJson(results[i]));
        } catch (e) {
          debugPrint('❌ [EventService] Error parsing public event $i: $e');
        }
      }
      return events;
    } on dio_pkg.DioException catch (e) {
      debugPrint('❌ [EventService] DioException: ${e.message}');
      throw _handleError(e);
    }
  }

  Future<EventModel> getEvent(int eventId) async {
    try {
      final response = await _api.dio.get('${ApiEndpoints.events}$eventId/');
      return EventModel.fromJson(response.data);
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<EventModel> createEvent(EventModel event) async {
    try {
      debugPrint('📡 [EventService] Creating event: ${event.title}');
      debugPrint('📡 [EventService] Event data: ${event.toJson()}');

      final response = await _api.dio.post(
        ApiEndpoints.events,
        data: event.toJson(),
      );

      debugPrint('📡 [EventService] Create response: ${response.data}');

      // Backend returns {'success': true, 'data': eventData}
      final eventData = response.data['data'] ?? response.data;
      return EventModel.fromJson(eventData);
    } on dio_pkg.DioException catch (e) {
      debugPrint('❌ [EventService] Create error: ${e.message}');
      throw _handleError(e);
    }
  }

  Future<EventModel> updateEvent(int eventId, Map<String, dynamic> data) async {
    try {
      debugPrint('📡 [EventService] Updating event $eventId: $data');

      final response = await _api.dio.patch(
        '${ApiEndpoints.events}$eventId/',
        data: data,
      );

      debugPrint('📡 [EventService] Update response: ${response.data}');

      // Backend may return {'success': true, 'data': eventData} or direct eventData
      final eventData = response.data['data'] ?? response.data;
      return EventModel.fromJson(eventData);
    } on dio_pkg.DioException catch (e) {
      debugPrint('❌ [EventService] Update error: ${e.message}');
      throw _handleError(e);
    }
  }

  Future<void> deleteEvent(int eventId) async {
    try {
      await _api.dio.delete('${ApiEndpoints.events}$eventId/');
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ Event Join ============
  Future<EventModel> getEventByJoinCode(String joinCode) async {
    try {
      final response = await _api.dio.get(ApiEndpoints.eventJoinInfo(joinCode));
      return EventModel.fromJson(response.data);
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ParticipantModel> joinEvent(
    String joinCode, {
    required String name,
    String? phone,
    String? email,
  }) async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.eventJoinRegister(joinCode),
        data: {
          'name': name,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
        },
      );
      return ParticipantModel.fromJson(response.data);
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Join an event directly by ID (for authenticated users)
  Future<ParticipantModel> joinEventById(int eventId) async {
    try {
      final response = await _api.dio.post(
        '${ApiEndpoints.events}$eventId/join_event/',
      );
      // The backend returns data inside 'data' key
      final data = response.data['data'] ?? response.data;
      return ParticipantModel.fromJson(data);
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ Participants ============
  Future<List<ParticipantModel>> getEventParticipants(
    int eventId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _api.dio.get(
        ApiEndpoints.participants,
        queryParameters: {
          'event': eventId,
          'page': page,
          'page_size': pageSize,
        },
      );

      final List<dynamic> results = response.data['results'] ?? [];
      return results.map((json) => ParticipantModel.fromJson(json)).toList();
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ParticipantModel> addParticipant(ParticipantModel participant) async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.participants,
        data: participant.toJson(),
      );
      return ParticipantModel.fromJson(response.data);
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ParticipantModel> updateParticipant(
    int participantId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _api.dio.patch(
        '${ApiEndpoints.participants}$participantId/',
        data: data,
      );
      return ParticipantModel.fromJson(response.data);
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> removeParticipant(int participantId) async {
    try {
      await _api.dio.delete('${ApiEndpoints.participants}$participantId/');
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ Image Upload ============
  Future<String> uploadCoverImage(int eventId, String filePath) async {
    try {
      final formData = dio_pkg.FormData.fromMap({
        'cover_image': await dio_pkg.MultipartFile.fromFile(filePath),
      });

      final response = await _api.dio.patch(
        '${ApiEndpoints.events}$eventId/',
        data: formData,
      );

      return response.data['cover_image'] ?? '';
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ Contributions ============
  /// Get contributions with stats for an event
  Future<Map<String, dynamic>> getEventContributionsWithStats(
    int eventId, {
    String? status,
    String? kind,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (kind != null) queryParams['kind'] = kind;

      debugPrint(
        '📡 [EventService] Fetching contributions for event $eventId: $queryParams',
      );

      final response = await _api.dio.get(
        ApiEndpoints.paymentEventContributions(eventId),
        queryParameters: queryParams,
      );

      // Backend returns { success: true, data: { contributions: [...], stats: {...} } }
      final data = response.data['data'] ?? response.data;
      final List<dynamic> contributionsJson = data['contributions'] ?? [];
      final stats = data['stats'] ?? {};

      debugPrint(
        '📡 [EventService] Got ${contributionsJson.length} contributions',
      );

      final contributions = contributionsJson
          .map((json) => ContributionModel.fromJson(json))
          .toList();

      return {'contributions': contributions, 'stats': stats};
    } on dio_pkg.DioException catch (e) {
      debugPrint('❌ [EventService] DioException: ${e.message}');
      throw _handleError(e);
    }
  }

  Future<List<ContributionModel>> getEventContributions(
    int eventId, {
    int page = 1,
    int pageSize = 50,
    String? status,
    String? kind,
  }) async {
    try {
      final result = await getEventContributionsWithStats(
        eventId,
        status: status,
        kind: kind,
      );
      return result['contributions'] as List<ContributionModel>;
    } on dio_pkg.DioException catch (e) {
      debugPrint('❌ [EventService] DioException: ${e.message}');
      throw _handleError(e);
    }
  }

  Future<ContributionModel> addContribution(
    ContributionModel contribution,
  ) async {
    try {
      // Build data for manual contribution endpoint
      final data = <String, dynamic>{
        'event_id': contribution.eventId,
        'amount': contribution.amount,
        'kind': contribution.kind,
        'status': contribution.status,
      };

      // Add optional fields
      if (contribution.participantName != null &&
          contribution.participantName!.isNotEmpty) {
        data['contributor_name'] = contribution.participantName;
      }
      if (contribution.participantPhone != null &&
          contribution.participantPhone!.isNotEmpty) {
        data['contributor_phone'] = contribution.participantPhone;
      }
      if (contribution.paymentReference != null &&
          contribution.paymentReference!.isNotEmpty) {
        data['payment_reference'] = contribution.paymentReference;
      }
      if (contribution.itemDescription != null &&
          contribution.itemDescription!.isNotEmpty) {
        data['item_description'] = contribution.itemDescription;
      }

      debugPrint('📡 [EventService] Adding contribution: $data');

      final response = await _api.dio.post(
        ApiEndpoints.contributions,
        data: data,
      );

      // Backend returns data inside 'data' key
      final responseData = response.data['data'] ?? response.data;
      return ContributionModel.fromJson(responseData);
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ [EventService] Add contribution error: ${e.response?.data}',
      );
      throw _handleError(e);
    }
  }

  Future<ContributionModel> updateContribution(
    int contributionId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _api.dio.patch(
        '${ApiEndpoints.contributions}$contributionId/',
        data: data,
      );
      return ContributionModel.fromJson(response.data);
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteContribution(int contributionId) async {
    try {
      await _api.dio.delete('${ApiEndpoints.contributions}$contributionId/');
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ Invitations ============
  Future<List<InvitationModel>> getEventInvitations(
    int eventId, {
    int page = 1,
    int pageSize = 50,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'event': eventId,
        'page': page,
        'page_size': pageSize,
      };
      if (status != null) queryParams['status'] = status;

      final response = await _api.dio.get(
        ApiEndpoints.invitations,
        queryParameters: queryParams,
      );

      final List<dynamic> results = response.data['results'] ?? [];
      return results.map((json) => InvitationModel.fromJson(json)).toList();
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<InvitationModel> createInvitation(InvitationModel invitation) async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.invitations,
        data: invitation.toJson(),
      );
      return InvitationModel.fromJson(response.data);
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<InvitationModel> sendInvitation(int invitationId) async {
    try {
      final response = await _api.dio.post(
        '${ApiEndpoints.invitations}$invitationId/send/',
      );
      return InvitationModel.fromJson(response.data);
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteInvitation(int invitationId) async {
    try {
      await _api.dio.delete('${ApiEndpoints.invitations}$invitationId/');
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ Messages ============
  Future<List<MessageModel>> getEventMessages(
    int eventId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _api.dio.get(
        ApiEndpoints.eventMessages(eventId),
      );

      // Backend returns {success: true, message: '', data: [...]}
      final data = response.data['data'];
      if (data is List) {
        return data.map((json) => MessageModel.fromJson(json)).toList();
      }
      return [];
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markMessagesAsRead(int eventId) async {
    try {
      await _api.dio.post(
        ApiEndpoints.markMessagesRead(eventId),
      );
      debugPrint('✅ [EventService] Marked messages as read for event $eventId');
    } on dio_pkg.DioException catch (e) {
      debugPrint('❌ [EventService] Failed to mark messages as read: ${e.message}');
      throw _handleError(e);
    }
  }

  Future<MessageModel> sendMessage(int eventId, String content) async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.messages,
        data: {'event': eventId, 'content': content, 'message_type': 'TEXT'},
      );
      return MessageModel.fromJson(response.data);
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteMessage(int messageId) async {
    try {
      await _api.dio.delete('${ApiEndpoints.messages}$messageId/');
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<MessageModel> pinMessage(int messageId, bool isPinned) async {
    try {
      final response = await _api.dio.patch(
        '${ApiEndpoints.messages}$messageId/',
        data: {'is_pinned': isPinned},
      );
      return MessageModel.fromJson(response.data);
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ Announcements ============
  Future<List<AnnouncementModel>> getEventAnnouncements(
    int eventId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _api.dio.get(
        ApiEndpoints.announcements,
        queryParameters: {
          'event': eventId,
          'page': page,
          'page_size': pageSize,
        },
      );

      final List<dynamic> results = response.data['results'] ?? [];
      return results.map((json) => AnnouncementModel.fromJson(json)).toList();
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<AnnouncementModel> createAnnouncement(
    AnnouncementModel announcement,
  ) async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.announcements,
        data: announcement.toJson(),
      );
      return AnnouncementModel.fromJson(response.data);
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteAnnouncement(int announcementId) async {
    try {
      await _api.dio.delete('${ApiEndpoints.announcements}$announcementId/');
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ Reminders ============
  Future<List<ReminderModel>> getEventReminders(
    int eventId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _api.dio.get(
        ApiEndpoints.reminders,
        queryParameters: {
          'event': eventId,
          'page': page,
          'page_size': pageSize,
        },
      );

      final List<dynamic> results = response.data['results'] ?? [];
      return results.map((json) => ReminderModel.fromJson(json)).toList();
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ReminderModel> createReminder(ReminderModel reminder) async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.reminders,
        data: reminder.toJson(),
      );
      return ReminderModel.fromJson(response.data);
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> cancelReminder(int reminderId) async {
    try {
      await _api.dio.post('${ApiEndpoints.reminders}$reminderId/cancel/');
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteReminder(int reminderId) async {
    try {
      await _api.dio.delete('${ApiEndpoints.reminders}$reminderId/');
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ Event Report ============
  Future<Map<String, dynamic>> getEventReport(int eventId) async {
    try {
      final response = await _api.dio.get(ApiEndpoints.eventReport(eventId));
      return response.data;
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ Error Handling ============
  String _handleError(dio_pkg.DioException e) {
    if (e.response?.data is Map) {
      final data = e.response?.data as Map;
      if (data.containsKey('detail')) {
        return data['detail'].toString();
      }
      if (data.containsKey('error')) {
        return data['error'].toString();
      }
      // Handle field errors
      final errors = <String>[];
      data.forEach((key, value) {
        if (value is List) {
          errors.add('$key: ${value.join(", ")}');
        } else {
          errors.add('$key: $value');
        }
      });
      if (errors.isNotEmpty) {
        return errors.join('\n');
      }
    }

    switch (e.type) {
      case dio_pkg.DioExceptionType.connectionTimeout:
      case dio_pkg.DioExceptionType.receiveTimeout:
      case dio_pkg.DioExceptionType.sendTimeout:
        return 'Connection timed out. Please try again.';
      case dio_pkg.DioExceptionType.connectionError:
        return 'No internet connection.';
      default:
        return e.message ?? 'An error occurred';
    }
  }
}
