import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/api_service.dart';
import '../models/invitation_card_template_model.dart';

/// Service for managing wedding invitation card templates
class InvitationTemplateService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  /// Get the base URL for API calls
  String getBaseUrl() {
    return _api.dio.options.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
  }

  // ============ Template Categories ============
  
  /// Get all available template categories
  Future<List<TemplateCategoryModel>> getCategories() async {
    try {
      final response = await _api.dio.get(ApiEndpoints.invitationTemplateCategories);
      final List<dynamic> data = response.data ?? [];
      return data.map((json) => TemplateCategoryModel.fromJson(json)).toList();
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ Templates ============
  
  /// Get all active invitation card templates
  Future<List<InvitationCardTemplateModel>> getTemplates({
    String? category,
    bool? isPremium,
  }) async {
    try {
      String endpoint = ApiEndpoints.invitationTemplates;
      
      if (isPremium == true) {
        endpoint = ApiEndpoints.premiumInvitationTemplates;
      } else if (isPremium == false) {
        endpoint = ApiEndpoints.freeInvitationTemplates;
      }
      
      final response = await _api.dio.get(
        endpoint,
        queryParameters: category != null ? {'category': category} : null,
      );
      
      final List<dynamic> data = response.data['results'] ?? response.data ?? [];
      return data.map((json) => InvitationCardTemplateModel.fromJson(json)).toList();
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get templates grouped by category
  Future<Map<String, List<InvitationCardTemplateModel>>> getTemplatesByCategory({
    String? category,
  }) async {
    try {
      final response = await _api.dio.get(
        ApiEndpoints.invitationTemplatesByCategory,
        queryParameters: category != null ? {'category': category} : null,
      );
      
      final Map<String, dynamic> data = response.data ?? {};
      final Map<String, List<InvitationCardTemplateModel>> result = {};
      
      data.forEach((key, value) {
        if (value is List) {
          result[key] = value
              .map((json) => InvitationCardTemplateModel.fromJson(json))
              .toList();
        }
      });
      
      return result;
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get free templates only
  Future<List<InvitationCardTemplateModel>> getFreeTemplates() async {
    return getTemplates(isPremium: false);
  }

  /// Get premium templates only
  Future<List<InvitationCardTemplateModel>> getPremiumTemplates() async {
    return getTemplates(isPremium: true);
  }

  /// Get a single template by ID
  Future<InvitationCardTemplateModel> getTemplate(int templateId) async {
    try {
      final response = await _api.dio.get(
        ApiEndpoints.invitationTemplateDetail(templateId),
      );
      return InvitationCardTemplateModel.fromJson(response.data);
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ Wedding Invitations ============
  
  /// Get wedding invitations for user's events
  Future<List<WeddingInvitationModel>> getWeddingInvitations({
    int? eventId,
  }) async {
    try {
      final response = await _api.dio.get(
        ApiEndpoints.weddingInvitations,
        queryParameters: eventId != null ? {'event': eventId} : null,
      );
      
      final List<dynamic> data = response.data['results'] ?? response.data ?? [];
      return data.map((json) => WeddingInvitationModel.fromJson(json)).toList();
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a wedding invitation
  Future<WeddingInvitationModel> createWeddingInvitation({
    required int eventId,
    required int participantId,
    int? templateId,
    String message = '',
    Map<String, dynamic>? cardData,
  }) async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.weddingInvitations,
        data: {
          'event': eventId,
          'participant': participantId,
          if (templateId != null) 'card_template': templateId,
          'message': message,
          'card_data': cardData ?? {},
        },
      );
      return WeddingInvitationModel.fromJson(response.data);
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Bulk create wedding invitations for multiple participants
  Future<Map<String, dynamic>> bulkCreateWeddingInvitations({
    required int eventId,
    required List<int> participantIds,
    int? templateId,
    String message = '',
  }) async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.weddingInvitationsBulkCreate,
        data: {
          'event_id': eventId,
          'participant_ids': participantIds,
          if (templateId != null) 'template_id': templateId,
          'message': message,
        },
      );
      return response.data;
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generate a personalized PDF card for an invitation
  /// Returns the PDF URL on success
  Future<Map<String, dynamic>> generateInvitationCard(int invitationId) async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.weddingInvitationGenerateCard(invitationId),
      );
      return response.data;
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generate PDF cards for multiple invitations at once
  /// Pass either invitationIds OR eventId (to generate all for an event)
  Future<Map<String, dynamic>> bulkGenerateCards({
    List<int>? invitationIds,
    int? eventId,
  }) async {
    try {
      final response = await _api.dio.post(
        '${ApiEndpoints.weddingInvitations}bulk_generate_cards/',
        data: {
          if (invitationIds != null) 'invitation_ids': invitationIds,
          if (eventId != null) 'event_id': eventId,
        },
      );
      return response.data;
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Download generated PDF card
  /// Returns the PDF file bytes
  Future<List<int>> downloadInvitationCard(int invitationId) async {
    try {
      final response = await _api.dio.post(
        '${ApiEndpoints.weddingInvitationGenerateCard(invitationId)}?download=true',
        options: dio_pkg.Options(responseType: dio_pkg.ResponseType.bytes),
      );
      return response.data;
    } on dio_pkg.DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============ Error Handling ============
  String _handleError(dio_pkg.DioException e) {
    debugPrint('❌ [InvitationTemplateService] Error: ${e.message}');
    
    if (e.response?.data is Map) {
      final data = e.response?.data as Map;
      if (data.containsKey('detail')) {
        return data['detail'].toString();
      }
      if (data.containsKey('error')) {
        return data['error'].toString();
      }
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
