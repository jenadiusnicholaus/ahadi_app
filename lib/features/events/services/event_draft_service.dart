import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/services/storage_service.dart';

/// Model for event draft
class EventDraft {
  final String? title;
  final String? description;
  final int? eventTypeId;
  final String? location;
  final String? venue;
  final String? startDate;
  final String? startTime;
  final String? endDate;
  final String? endTime;
  final double? targetAmount;
  final String? visibility;
  final bool? autoDisburse;
  final String? coverImageBase64;
  final String? coverImageName;
  final DateTime savedAt;

  EventDraft({
    this.title,
    this.description,
    this.eventTypeId,
    this.location,
    this.venue,
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    this.targetAmount,
    this.visibility,
    this.autoDisburse,
    this.coverImageBase64,
    this.coverImageName,
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  bool get isEmpty =>
      title == null &&
      description == null &&
      eventTypeId == null &&
      location == null &&
      venue == null &&
      startDate == null &&
      targetAmount == null;

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'event_type_id': eventTypeId,
    'location': location,
    'venue': venue,
    'start_date': startDate,
    'start_time': startTime,
    'end_date': endDate,
    'end_time': endTime,
    'target_amount': targetAmount,
    'visibility': visibility,
    'auto_disburse': autoDisburse,
    'cover_image_base64': coverImageBase64,
    'cover_image_name': coverImageName,
    'saved_at': savedAt.toIso8601String(),
  };

  factory EventDraft.fromJson(Map<String, dynamic> json) => EventDraft(
    title: json['title'],
    description: json['description'],
    eventTypeId: json['event_type_id'],
    location: json['location'],
    venue: json['venue'],
    startDate: json['start_date'],
    startTime: json['start_time'],
    endDate: json['end_date'],
    endTime: json['end_time'],
    targetAmount: json['target_amount']?.toDouble(),
    visibility: json['visibility'],
    autoDisburse: json['auto_disburse'],
    coverImageBase64: json['cover_image_base64'],
    coverImageName: json['cover_image_name'],
    savedAt: json['saved_at'] != null
        ? DateTime.parse(json['saved_at'])
        : DateTime.now(),
  );
}

/// Service to manage event drafts
class EventDraftService extends GetxService {
  static const String _draftKey = 'event_draft';

  StorageService get _storage => Get.find<StorageService>();

  /// Save event draft
  Future<void> saveDraft(EventDraft draft) async {
    try {
      final jsonString = jsonEncode(draft.toJson());
      await _storage.setString(_draftKey, jsonString);
      debugPrint('📝 [Draft] Saved draft: ${draft.title}');
    } catch (e) {
      debugPrint('📝 [Draft] Error saving: $e');
    }
  }

  /// Load saved draft
  EventDraft? loadDraft() {
    try {
      final jsonString = _storage.getString(_draftKey);
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final draft = EventDraft.fromJson(json);

      // Check if draft is older than 7 days
      final age = DateTime.now().difference(draft.savedAt);
      if (age.inDays > 7) {
        clearDraft();
        return null;
      }

      debugPrint('📝 [Draft] Loaded draft: ${draft.title}');
      return draft;
    } catch (e) {
      debugPrint('📝 [Draft] Error loading: $e');
      return null;
    }
  }

  /// Check if draft exists
  bool hasDraft() {
    final draft = loadDraft();
    return draft != null && !draft.isEmpty;
  }

  /// Clear saved draft
  Future<void> clearDraft() async {
    try {
      await _storage.setString(_draftKey, '');
      debugPrint('📝 [Draft] Cleared draft');
    } catch (e) {
      debugPrint('📝 [Draft] Error clearing: $e');
    }
  }

  /// Auto-save draft (debounced)
  void autoSave(EventDraft draft) {
    // Simple save without debounce for now
    saveDraft(draft);
  }
}
