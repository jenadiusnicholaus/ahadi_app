import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../models/event_model.dart';
import '../models/event_type_model.dart';
import '../models/participant_model.dart';
import '../models/contribution_model.dart';
import '../services/event_service.dart';

class EventsController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final EventService _eventService = Get.find<EventService>();

  // Disposal tracking to prevent usage after dispose
  bool _isDisposed = false;

  // Tab controller for My Events, Invited, Public
  late TabController tabController;

  // Paging controllers for infinite scroll
  final PagingController<int, EventModel> myEventsPagingController =
      PagingController(firstPageKey: 1);
  final PagingController<int, EventModel> invitedEventsPagingController =
      PagingController(firstPageKey: 1);
  final PagingController<int, EventModel> publicEventsPagingController =
      PagingController(firstPageKey: 1);

  static const int _pageSize = 20;

  // Loading states
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isCreating = false.obs;
  final isMyEventsFirstLoadComplete = false.obs;
  final isInvitedEventsFirstLoadComplete = false.obs;

  // Event lists (kept for compatibility)
  final myEvents = <EventModel>[].obs;
  final invitedEvents = <EventModel>[].obs;
  final publicEvents = <EventModel>[].obs;

  // Event types for filtering/creation
  final eventTypes = <EventTypeModel>[].obs;

  // Current event detail
  final currentEvent = Rxn<EventModel>();
  final currentEventParticipants = <ParticipantModel>[].obs;

  // Contributions for current event
  final contributions = <ContributionModel>[].obs;

  // Participants for current event (alias for dashboard)
  RxList<ParticipantModel> get participants => currentEventParticipants;

  // Search & filters
  final searchQuery = ''.obs;
  final selectedEventTypeId = Rxn<int>();
  final selectedStatus = Rxn<String>();
  final selectedTabIndex = 0.obs;

  // Error handling
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint('🔄 [EventsController] onInit called');
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(_onTabChanged);

    // Setup paging listeners - PagedListView will automatically trigger first page fetch
    myEventsPagingController.addPageRequestListener(_fetchMyEvents);
    invitedEventsPagingController.addPageRequestListener(_fetchInvitedEvents);
    publicEventsPagingController.addPageRequestListener(_fetchPublicEvents);

    loadInitialData();
    
    // Ensure first page is loaded
    ensureMyEventsLoaded();
  }
  
  /// Ensures my events are loaded - call this when screen is displayed
  void ensureMyEventsLoaded() {
    debugPrint('🔄 [EventsController] ensureMyEventsLoaded - itemList: ${myEventsPagingController.itemList}, status: ${myEventsPagingController.value.status}');
    if (myEventsPagingController.itemList == null) {
      // First page hasn't been requested yet, trigger it
      debugPrint('🔄 [EventsController] Notifying paging controller to load first page');
      myEventsPagingController.notifyPageRequestListeners(1);
    }
  }

  @override
  void onClose() {
    _isDisposed = true;
    tabController.removeListener(_onTabChanged);
    tabController.dispose();
    myEventsPagingController.dispose();
    invitedEventsPagingController.dispose();
    publicEventsPagingController.dispose();
    super.onClose();
  }

  void _onTabChanged() {
    if (!tabController.indexIsChanging) {
      selectedTabIndex.value = tabController.index;
      // Only trigger initial fetch if data hasn't been loaded yet
      // Don't auto-refresh on every tab change as it causes empty state flash
      switch (tabController.index) {
        case 0:
          if (myEventsPagingController.itemList == null) {
            myEventsPagingController.refresh();
          }
          break;
        case 1:
          if (invitedEventsPagingController.itemList == null) {
            invitedEventsPagingController.refresh();
          }
          break;
        case 2:
          if (publicEventsPagingController.itemList == null) {
            publicEventsPagingController.refresh();
          }
          break;
      }
    }
  }

  Future<void> loadInitialData() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await loadEventTypes();
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshCurrentTab() async {
    if (_isDisposed) return;

    switch (tabController.index) {
      case 0:
        myEventsPagingController.refresh();
        break;
      case 1:
        invitedEventsPagingController.refresh();
        break;
      case 2:
        publicEventsPagingController.refresh();
        break;
    }
  }

  Future<void> loadEventTypes() async {
    try {
      final types = await _eventService.getEventTypes();
      eventTypes.assignAll(types);
    } catch (e) {
      debugPrint('Error loading event types: $e');
    }
  }

  // ============ My Events (Infinite Scroll) ============
  Future<void> _fetchMyEvents(int pageKey) async {
    debugPrint('🔄 [EventsController] _fetchMyEvents called with pageKey: $pageKey');
    try {
      final events = await _eventService.getMyEvents(
        page: pageKey,
        pageSize: _pageSize,
        status: selectedStatus.value,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );

      debugPrint('🔄 [EventsController] _fetchMyEvents got ${events.length} events');

      // Check if controller was disposed during async operation
      if (_isDisposed) return;

      final isLastPage = events.length < _pageSize;
      if (isLastPage) {
        myEventsPagingController.appendLastPage(events);
      } else {
        myEventsPagingController.appendPage(events, pageKey + 1);
      }

      debugPrint('🔄 [EventsController] _fetchMyEvents appended to paging controller. itemList count: ${myEventsPagingController.itemList?.length}');

      // Update observable list for compatibility
      if (pageKey == 1) {
        myEvents.assignAll(events);
        isMyEventsFirstLoadComplete.value = true;
      } else {
        myEvents.addAll(events);
      }
    } catch (e) {
      debugPrint('❌ [EventsController] _fetchMyEvents error: $e');
      if (!_isDisposed) {
        myEventsPagingController.error = e;
        isMyEventsFirstLoadComplete.value = true;
      }
    }
  }

  // ============ Invited Events (Infinite Scroll) ============
  Future<void> _fetchInvitedEvents(int pageKey) async {
    try {
      final events = await _eventService.getInvitedEvents(
        page: pageKey,
        pageSize: _pageSize,
      );

      // Check if controller was disposed during async operation
      if (_isDisposed) return;

      final isLastPage = events.length < _pageSize;
      if (isLastPage) {
        invitedEventsPagingController.appendLastPage(events);
      } else {
        invitedEventsPagingController.appendPage(events, pageKey + 1);
      }

      // Update observable list for compatibility
      if (pageKey == 1) {
        invitedEvents.assignAll(events);
        isInvitedEventsFirstLoadComplete.value = true;
      } else {
        invitedEvents.addAll(events);
      }
    } catch (e) {
      if (!_isDisposed) {
        invitedEventsPagingController.error = e;
        isInvitedEventsFirstLoadComplete.value = true;
      }
    }
  }

  // ============ Public Events (Infinite Scroll) ============
  Future<void> _fetchPublicEvents(int pageKey) async {
    try {
      final events = await _eventService.getPublicEvents(
        page: pageKey,
        pageSize: _pageSize,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        eventTypeId: selectedEventTypeId.value,
      );

      // Check if controller was disposed during async operation
      if (_isDisposed) return;

      final isLastPage = events.length < _pageSize;
      if (isLastPage) {
        publicEventsPagingController.appendLastPage(events);
      } else {
        publicEventsPagingController.appendPage(events, pageKey + 1);
      }

      // Update observable list for compatibility
      if (pageKey == 1) {
        publicEvents.assignAll(events);
      } else {
        publicEvents.addAll(events);
      }
    } catch (e) {
      if (!_isDisposed) {
        publicEventsPagingController.error = e;
      }
    }
  }

  // Legacy methods for compatibility - now trigger paging refresh
  Future<void> loadMyEvents({bool refresh = false}) async {
    if (_isDisposed) return;
    if (refresh) {
      myEventsPagingController.refresh();
    }
  }

  Future<void> loadInvitedEvents({bool refresh = false}) async {
    if (_isDisposed) return;
    if (refresh) {
      invitedEventsPagingController.refresh();
    }
  }

  Future<void> loadPublicEvents({bool refresh = false}) async {
    if (_isDisposed) return;
    if (refresh) {
      publicEventsPagingController.refresh();
    }
  }

  // ============ Event Detail ============
  Future<void> loadEventDetail(int eventId) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final event = await _eventService.getEvent(eventId);
      currentEvent.value = event;

      // Load participants
      await loadEventParticipants(eventId);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadEventParticipants(int eventId) async {
    try {
      final participants = await _eventService.getEventParticipants(eventId);
      currentEventParticipants.assignAll(participants);
    } catch (e) {
      debugPrint('Error loading participants: $e');
    }
  }

  Future<void> removeParticipant(int participantId) async {
    try {
      await _eventService.removeParticipant(participantId);
      // Remove from local list
      currentEventParticipants.removeWhere((p) => p.id == participantId);
    } catch (e) {
      debugPrint('Error removing participant: $e');
      rethrow;
    }
  }

  // ============ Create Event ============
  Future<EventModel?> createEvent({
    required String title,
    String? description,
    int? eventTypeId,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? venueName,
    double? contributionTarget,
    String visibility = 'PRIVATE',
    String status = 'DRAFT',
    String? coverImageBase64,
    bool chatEnabled = true,
    // Wedding-specific fields
    int? invitationCardTemplateId,
    String? weddingGroomName,
    String? weddingBrideName,
    String? weddingCeremonyTime,
    String? weddingReceptionTime,
    String? weddingReceptionVenue,
    String? weddingDressCode,
    String? weddingRsvpPhone,
  }) async {
    isCreating.value = true;
    errorMessage.value = '';

    try {
      final event = EventModel(
        id: 0,
        title: title,
        description: description ?? '',
        eventTypeId: eventTypeId,
        startDate: startDate,
        endDate: endDate,
        location: location ?? '',
        venueName: venueName ?? '',
        contributionTarget: contributionTarget,
        visibility: visibility,
        status: status,
        ownerId: 0, // Will be set by backend
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        coverImageBase64: coverImageBase64,
        chatEnabled: chatEnabled,
        invitationCardTemplateId: invitationCardTemplateId,
        weddingGroomName: weddingGroomName,
        weddingBrideName: weddingBrideName,
        weddingCeremonyTime: weddingCeremonyTime,
        weddingReceptionTime: weddingReceptionTime,
        weddingReceptionVenue: weddingReceptionVenue,
        weddingDressCode: weddingDressCode,
        weddingRsvpPhone: weddingRsvpPhone,
      );

      debugPrint('📤 [EventsController] Creating event: ${event.title}');
      final createdEvent = await _eventService.createEvent(event);
      debugPrint(
        '✅ [EventsController] Event created: ${createdEvent.id} - ${createdEvent.title}',
      );
      debugPrint(
        '✅ [EventsController] Cover image URL: ${createdEvent.coverImageUrl}',
      );

      // Add to my events list and refresh paging controller
      myEvents.insert(0, createdEvent);
      if (!_isDisposed) {
        myEventsPagingController.refresh();
      }

      Get.snackbar(
        'Success',
        'Event created successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return createdEvent;
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } finally {
      isCreating.value = false;
    }
  }

  // ============ Update Event ============
  Future<bool> updateEvent(int eventId, Map<String, dynamic> data) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final updatedEvent = await _eventService.updateEvent(eventId, data);

      // Update in lists
      final myIndex = myEvents.indexWhere((e) => e.id == eventId);
      if (myIndex != -1) {
        myEvents[myIndex] = updatedEvent;
      }

      // Update current event if viewing detail
      if (currentEvent.value?.id == eventId) {
        currentEvent.value = updatedEvent;
      }

      Get.snackbar(
        'Success',
        'Event updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ============ Update Event Template ============
  Future<bool> updateEventTemplate(int eventId, int templateId) async {
    return updateEvent(eventId, {'invitation_card_template': templateId});
  }

  // ============ Delete Event ============
  Future<bool> deleteEvent(int eventId) async {
    try {
      await _eventService.deleteEvent(eventId);

      // Remove from lists
      myEvents.removeWhere((e) => e.id == eventId);
      invitedEvents.removeWhere((e) => e.id == eventId);
      publicEvents.removeWhere((e) => e.id == eventId);

      Get.snackbar(
        'Success',
        'Event deleted successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  // ============ Join Event ============
  Future<bool> joinEventByCode(
    String joinCode, {
    required String name,
    String? phone,
    String? email,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _eventService.joinEvent(
        joinCode,
        name: name,
        phone: phone,
        email: email,
      );

      Get.snackbar(
        'Success',
        'Successfully joined the event!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Refresh invited events
      await loadInvitedEvents(refresh: true);

      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Join an event directly by ID (for authenticated users viewing a public event)
  Future<bool> joinEventById(int eventId) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _eventService.joinEventById(eventId);

      Get.snackbar(
        'Success',
        'Successfully joined the event!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Refresh invited events
      await loadInvitedEvents(refresh: true);

      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ============ Search & Filter ============
  void setSearchQuery(String query) {
    searchQuery.value = query;
    if (!_isDisposed) {
      refreshCurrentTab();
    }
  }

  void setEventTypeFilter(int? typeId) {
    selectedEventTypeId.value = typeId;
    if (tabController.index == 2 && !_isDisposed) {
      loadPublicEvents(refresh: true);
    }
  }

  void setStatusFilter(String? status) {
    selectedStatus.value = status;
    if (tabController.index == 0 && !_isDisposed) {
      loadMyEvents(refresh: true);
    }
  }

  void clearFilters() {
    searchQuery.value = '';
    selectedEventTypeId.value = null;
    selectedStatus.value = null;
    if (!_isDisposed) {
      refreshCurrentTab();
    }
  }

  // ============ Contributions ============
  Future<void> loadEventContributions(int eventId) async {
    isLoading.value = true;
    try {
      final eventContributions = await _eventService.getEventContributions(
        eventId,
      );
      contributions.assignAll(eventContributions);
    } catch (e) {
      debugPrint('Error loading contributions: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addManualContribution({
    required int eventId,
    required double amount,
    required String contributorName,
    String? phone,
    String paymentMethod = 'CASH',
    String? reference,
    String? message,
  }) async {
    isLoading.value = true;
    try {
      final contribution = ContributionModel(
        id: 0,
        eventId: eventId,
        amount: amount,
        participantName: contributorName,
        participantPhone: phone,
        kind: paymentMethod,
        status: 'CONFIRMED',
        paymentReference: reference,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _eventService.addContribution(contribution);

      // Reload contributions
      await loadEventContributions(eventId);
      return true;
    } catch (e) {
      debugPrint('Error adding contribution: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
}
